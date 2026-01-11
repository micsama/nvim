local M = {}
local map = vim.keymap.set

-- 状态管理
local state = {
	terms = {},
	last_id = nil,
	runner_cache = nil, -- 记住最后一次执行的 Runner 配置
}

local runners = {
	python = "uv run %s",
	lua = "lua %s",
	sh = "bash %s",
	go = "go run %s",
}

-- 1. 增强元数据获取 (适配终端模式)
local function get_meta()
	local cwd = vim.fn.getcwd()
	return {
		cwd = cwd,
		display_path = vim.fn.fnamemodify(cwd, ":~"),
		rel_file = vim.fn.expand("%:."),
		ft = vim.bo.filetype,
		is_term = vim.bo.buftype == "terminal",
	}
end

-- 2. 窗口参数计算 (保持动态 Title)
local function get_win_opts(cfg)
	local meta = get_meta()
	local w, h = cfg.width or 0.8, cfg.height or 0.8
	local width = math.floor(vim.o.columns * (w > 1 and w / vim.o.columns or w))
	local height = math.floor(vim.o.lines * (h > 1 and h / vim.o.lines or h))

	-- 如果在终端里 resize，从缓存或 meta 获取路径
	local path = meta.is_term and state.runner_cache and state.runner_cache.path or meta.display_path

	return {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
		zindex = 50,
		title = string.format(" %s %s │ %s ", cfg.icon or "", cfg.name or "Term", path),
		title_pos = "center",
	}
end

-- 3. 核心 Toggle 函数
function M.toggle(cfg)
	local meta = get_meta()
	local raw_cmd = type(cfg.cmd) == "function" and cfg.cmd() or cfg.cmd or vim.o.shell
	local id = cfg.id or (raw_cmd .. "\0" .. meta.cwd)
	local term = state.terms[id] or {}

	-- A. 互斥逻辑：如果点开了别的，关掉上一个
	if state.last_id and state.last_id ~= id then
		local last = state.terms[state.last_id]
		if last and vim.api.nvim_win_is_valid(last.win or -1) then
			vim.api.nvim_win_close(last.win, true)
		end
	end

	-- B. Toggle 关闭逻辑 (现在支持从终端模式直接触发)
	if term.win and vim.api.nvim_win_is_valid(term.win) then
		vim.api.nvim_win_close(term.win, true)
		state.last_id = nil
		return
	end

	-- C. 初始化/重开窗口
	local is_new = not (term.buf and vim.api.nvim_buf_is_valid(term.buf))
	if is_new then
		term.buf = vim.api.nvim_create_buf(false, true)
	end
	term.win = vim.api.nvim_open_win(term.buf, true, get_win_opts(cfg))

	-- D. 运行命令
	if is_new then
		local final_cmd = raw_cmd
		if cfg.keep then
			final_cmd = string.format(
				[[sh -c '%s; printf "\n\033[32m[Process finished]\033[0m\nPress Enter or %s to close..."; read']],
				raw_cmd:gsub("'", "'\\''"),
				cfg.key or "<D-r>"
			)
		end

		vim.api.nvim_buf_call(term.buf, function()
			vim.fn.jobstart(final_cmd, {
				term = true,
				cwd = meta.cwd,
				on_exit = function()
					if term.buf and vim.api.nvim_buf_is_valid(term.buf) then
						vim.api.nvim_buf_delete(term.buf, { force = true })
					end
					state.terms[id] = nil
				end,
			})
		end)
	end

	vim.wo[term.win].wrap = cfg.wrap or false
	vim.cmd("startinsert")
	term.cfg = cfg
	state.terms[id], state.last_id = term, id
end

-- 4. 自动缩放适配
vim.api.nvim_create_autocmd("VimResized", {
	callback = function()
		local term = state.terms[state.last_id]
		if term and vim.api.nvim_win_is_valid(term.win or -1) then
			vim.api.nvim_win_set_config(term.win, get_win_opts(term.cfg))
		end
	end,
})

-- 5. 业务配置与映射
local function setup()
	local apps = {
		["<D-g>"] = { name = "Terminal", icon = "", wrap = true },
		["<D-i>"] = { name = "Lazygit", icon = "󰊢", cmd = "lazygit", width = 0.98, height = 0.98 },
		["<D-e>"] = { name = "Codex", icon = "󰚩", cmd = "codex", width = 0.9, height = 0.95 },
	}

	-- 基础 App 绑定 (nvt 三模式)
	for key, cfg in pairs(apps) do
		map({ "n", "v", "t" }, key, function()
			M.toggle(cfg)
		end)
	end

	-- Runner 专用逻辑 (<D-r>)
	map({ "n", "v", "t" }, "<D-r>", function()
		local meta = get_meta()

		-- 如果不在终端里，说明是发起运行，更新缓存
		if not meta.is_term then
			local pattern = runners[meta.ft]
			if not pattern then
				return vim.notify("未定义执行器: " .. meta.ft, 2)
			end

			state.runner_cache = {
				id = "RUNNER_INSTANCE", -- 固定 ID 保证在同一个 CWD 下只有一个 Runner 窗口
				cmd = string.format(pattern, meta.rel_file),
				name = "Runner",
				icon = "󰐊",
				path = meta.display_path,
				width = 0.5,
				height = 0.4,
				keep = true,
				key = "<D-r>",
			}
		end

		-- 执行 Toggle (如果 cache 为空说明没跑过，不操作)
		if state.runner_cache then
			M.toggle(state.runner_cache)
		end
	end)
end

setup()

return M
