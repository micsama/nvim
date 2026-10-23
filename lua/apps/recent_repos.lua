-- ===========================================================================
-- 最近打开的 Git 仓库：记录 / 别名 / frecency 排序 / Telescope picker
-- ===========================================================================

local M = {}

local json_store = require("utils.json_store")

local data_path = vim.fn.stdpath("data") .. "/recent_repos.json"
-- 每次访问单独衰减，7 天权重减半。
-- weighted_count 保存 last 时刻的累计权重，无需保存完整访问历史。
local half_life_days = 7
local active_repo
local alias_hl = "RecentRepoAlias"
local function ensure_alias_hl()
	local palette = require("catppuccin.palettes").get_palette("mocha")
	vim.api.nvim_set_hl(0, alias_hl, { fg = palette.mauve, bold = true, underline = true })
end

local function load()
	local result = {}
	for _, e in ipairs(json_store.read(data_path, {})) do
		if
			type(e) == "table"
			and type(e.path) == "string"
			and e.path ~= ""
			and type(e.days) == "number"
			and e.days >= 1
			and e.days < math.huge
			and e.days % 1 == 0
			and type(e.last) == "number"
			and e.last >= 0
			and e.last <= os.time()
			and (e.alias == nil or type(e.alias) == "string")
			and (e.pin == nil or e.pin == 1 or e.pin == -1)
		then
			result[#result + 1] = e
		end
	end
	return result
end

local function save(data)
	if not json_store.write(data_path, data) then
		vim.notify("无法保存最近仓库记录", vim.log.levels.WARN)
	end
end

local function visit_count(entry)
	local count = entry.count
	if type(count) ~= "number" or count < 1 or count >= math.huge or count % 1 ~= 0 then
		count = entry.days
	end
	return count
end

local function score(entry, now)
	local age = math.max(0, now - entry.last) / 86400
	local weight = entry.weighted_count
	if type(weight) ~= "number" or not (weight >= 0 and weight < math.huge) then
		-- 旧数据没有逐次访问时间，按最后访问时刻初始化；保留原 count。
		weight = visit_count(entry)
	end
	return weight * 0.5 ^ (age / half_life_days)
end

function M.record(path)
	if not path or path == "" then
		return
	end
	local now = os.time()
	local today = os.date("%Y-%m-%d", now)
	local data = load()
	for _, e in ipairs(data) do
		if e.path == path then
			-- 先衰减旧分数再加本次访问，不能用新的 last 复活全部历史权重。
			e.weighted_count = score(e, now) + 1
			e.count = visit_count(e) + 1
			if os.date("%Y-%m-%d", e.last) ~= today then
				e.days = e.days + 1
			end
			e.last = now
			save(data)
			active_repo = path
			return
		end
	end
	data[#data + 1] = { path = path, count = 1, weighted_count = 1, days = 1, last = now }
	save(data)
	active_repo = path
end

-- 切入仓库才算访问，同仓库内切换文件不重复计数；没有时间冷却。
function M.enter(path)
	if path ~= active_repo then
		active_repo = path
		M.record(path)
	end
end

local function update(path, fn)
	local data = load()
	for _, e in ipairs(data) do
		if e.path == path then
			fn(e)
			break
		end
	end
	save(data)
end

function M.set_alias(path, alias)
	alias = vim.trim(alias)
	update(path, function(e)
		e.alias = alias ~= "" and alias or nil
	end)
end

local function sorted_entries()
	local data, now = load(), os.time()
	table.sort(data, function(a, b)
		-- pin：1 置顶 / -1 沉底。不能并进 score()：record() 会把 score 写回 weighted_count
		if (a.pin or 0) ~= (b.pin or 0) then
			return (a.pin or 0) > (b.pin or 0)
		end
		local sa, sb = score(a, now), score(b, now)
		if sa ~= sb then
			return sa > sb
		end
		if a.last ~= b.last then
			return a.last > b.last
		end
		return a.path < b.path
	end)
	return data
end

function M.open(path)
	if vim.fn.isdirectory(path) ~= 1 then
		vim.notify("仓库目录不存在：" .. path, vim.log.levels.WARN)
		return
	end

	-- 最近项目入口只保留一个项目标签页，沿用当前 Tab，关闭其他 Tab。
	if #vim.api.nvim_list_tabpages() > 1 then
		vim.cmd.tabonly()
	end
	if #vim.api.nvim_tabpage_list_wins(0) > 1 then
		vim.cmd.only()
	end
	vim.cmd.tcd({ args = { path } })
	M.enter(path) -- tcd 通常已经触发 DirChanged 计数；这里兜底，enter 自带去重

	-- 文件名先统一小写，兼容 README.md / Readme.MD / claude.md 等写法。
	local root_files = {}
	local scan = vim.uv.fs_scandir(path)
	while scan do
		local name, kind = vim.uv.fs_scandir_next(scan)
		if not name then
			break
		end
		if kind == "file" or kind == "link" then
			root_files[name:lower()] = name
		end
	end

	local entry_file = root_files["readme.md"] or root_files["readme"]
	if not entry_file then
		for name, actual_name in pairs(root_files) do
			if name:match("^readme%.") and (not entry_file or name < entry_file:lower()) then
				entry_file = actual_name
			end
		end
	end
	for _, name in ipairs({ "claude.md", "agents.md", "contributing.md" }) do
		entry_file = entry_file or root_files[name]
	end

	if entry_file then
		vim.cmd.edit(vim.fn.fnameescape(path .. "/" .. entry_file))
	else
		require("mini.files").open(path)
	end
end

-- 预览头部：当前分支 + 最近 5 条提交，之后 exec 目录列表命令（"$@"）
local git_header_script = [[
cd "$1" 2>/dev/null || exit 1
shift
branch=$(git branch --show-current 2>/dev/null)
[ -z "$branch" ] && branch="(detached) $(git rev-parse --short HEAD 2>/dev/null)"
printf '\033[1;35m\356\202\240 %s\033[0m\n' "$branch"
git --no-pager log -n 5 --color=always --format='%C(dim)•%C(reset) %s' 2>/dev/null
echo
exec "$@"
]]

-- 目录预览：优先用 eza（图标 + 颜色），否则退回 ls；只看一层，不递归子目录
local function list_cmd(path)
	if vim.fn.executable("eza") == 1 then
		return {
			"eza",
			"-l", -- 长格式：每项独立一行，附带时间/大小
			"--git", -- 每项后面标注 git 状态（M/N/D…）
			"--icons=always",
			"--group-directories-first",
			"--color=always",
			"--no-permissions", -- 自己的仓库不需要看权限位
			"--no-user",
			"--time-style=relative", -- "3 hours ago" 这种相对时间
			"--header",
			path,
		}
	elseif vim.fn.executable("ls") == 1 then
		return { "ls", "-1p", path }
	end
end

local function preview_cmd(path)
	local cmd = list_cmd(path)
	if not cmd or vim.fn.executable("git") ~= 1 then
		return cmd
	end
	return { "sh", "-c", git_header_script, "sh", path, unpack(cmd) }
end

-- 进入一个 git 仓库根目录（cwd 变化 / 切 tab / 启动）才算访问；
-- cwd 不是 git 根时清空 active_repo，之后回到仓库会重新计数。
local function track_cwd()
	local cwd = vim.fn.getcwd()
	M.enter(vim.fs.root(cwd, ".git") == cwd and cwd or nil)
end

function M.setup()
	local group = vim.api.nvim_create_augroup("apps.recent_repos", { clear = true })
	vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged", "TabEnter" }, { group = group, callback = track_cwd })

	-- "[Process exited N]" 其实是 nvim 内置的 nested TermClose 自动命令用 extmark（虚拟文本）
	-- 叠加上去的（namespace: nvim.terminal.exitmsg），不是真实 buffer 内容，直接清掉这个 namespace 即可
	local exitmsg_ns = vim.api.nvim_create_namespace("nvim.terminal.exitmsg")
	vim.api.nvim_create_autocmd("TermClose", {
		group = group,
		nested = true, -- 必须晚于内置的那个自动命令执行，等它把 extmark 打上去之后再清
		callback = function(args)
			if not vim.b[args.buf].recent_repos_preview then
				return
			end
			vim.schedule(function()
				if vim.api.nvim_buf_is_valid(args.buf) then
					vim.api.nvim_buf_clear_namespace(args.buf, exitmsg_ns, 0, -1)
				end
			end)
		end,
	})
end

function M.picker(opts)
	opts = opts or {}
	require("plugins.telescope").load()
	local pickers = require("telescope.pickers")
	local finders = require("telescope.finders")
	local conf = require("telescope.config").values
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")
	local entry_display = require("telescope.pickers.entry_display")
	local previewers = require("telescope.previewers")

	ensure_alias_hl()
	local displayer = entry_display.create({
		separator = " ",
		items = { { width = 22 }, { remaining = true } },
	})

	local function make_finder()
		return finders.new_table({
			results = sorted_entries(),
			entry_maker = function(e)
				local dim = e.pin == -1 and "Comment" or nil
				local tag = (e.pin == 1 and "📌[" or "[") .. (e.alias or "") .. "]"
				local path = vim.fn.fnamemodify(e.path, ":~")
				return {
					value = e,
					path = e.path,
					ordinal = (e.alias or "") .. " " .. e.path,
					display = function()
						return displayer({ { tag, dim or e.alias and alias_hl }, { path, dim } })
					end,
				}
			end,
		})
	end

	local tree_previewer = previewers.new_termopen_previewer({
		title = "目录预览",
		get_command = function(entry, status)
			-- 标记这个 buffer 是本 picker 的预览，退出后好清掉 "[Process exited]" 提示行
			local bufnr = vim.api.nvim_win_get_buf(status.layout.preview.winid)
			vim.b[bufnr].recent_repos_preview = true
			return preview_cmd(entry.value.path)
		end,
	})

	-- 标题显示目录名，有别名时追加 [别名]。dyn_title 要全局开 dynamic_preview_title 才生效，
	-- 这里直接覆盖本 previewer 的 title，不影响其他 picker
	function tree_previewer:title(entry)
		if not entry then
			return "目录预览"
		end
		local e = entry.value
		local name = vim.fs.basename(e.path)
		return e.alias and ("%s  [%s]"):format(name, e.alias) or name
	end

	pickers
		.new(opts, {
			prompt_title = "🕒 最近 Git 仓库",
			finder = make_finder(),
			previewer = tree_previewer,
			sorter = conf.generic_sorter(opts),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					if not selection then
						return
					end
					local path = selection.value.path
					-- 连续切换仓库时曾在 :edit 触发 E812（自动命令改变了 buffer）。
					-- 延后一轮事件循环，让 Telescope 关闭窗口及预览的清理事件先结束，
					-- 避免在选择器动作的调用栈内立即切目录、打开文件；不要改回直接调用。
					vim.schedule(function()
						M.open(path)
					end)
				end)

				local function refresh()
					action_state.get_current_picker(prompt_bufnr):refresh(make_finder(), { reset_prompt = false })
				end
				local function on_selected(key, fn)
					map({ "n", "i" }, key, function()
						local selection = action_state.get_selected_entry()
						if selection then
							fn(selection.value)
						end
					end)
				end

				-- 仅移除历史记录，不操作磁盘目录。
				on_selected("<C-d>", function(e)
					save(vim.tbl_filter(function(x)
						return x.path ~= e.path
					end, load()))
					if active_repo == e.path then
						active_repo = nil
					end
					refresh()
				end)

				-- 置顶/沉底，再按一次取消；只在输入框为空时体现，输入后按模糊匹配度排序
				for key, pin in pairs({ ["<C-t>"] = 1, ["<C-b>"] = -1 }) do
					on_selected(key, function(e)
						update(e.path, function(x)
							x.pin = x.pin ~= pin and pin or nil
						end)
						refresh()
					end)
				end

				-- 不用 <C-r>：telescope 有 <C-r><C-w> 等组合键，单按会等 timeoutlen
				on_selected("<C-e>", function(e)
					vim.ui.input({ prompt = "别名: ", default = e.alias or "" }, function(input)
						if input then
							M.set_alias(e.path, input)
							refresh()
						end
					end)
				end)

				return true
			end,
		})
		:find()
end

return M
