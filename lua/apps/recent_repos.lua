-- ===========================================================================
-- 最近打开的 Git 仓库：记录 / 别名 / frecency 排序 / Telescope picker
-- ===========================================================================

local M = {}

local json_store = require("utils.json_store")

local data_path = vim.fn.stdpath("data") .. "/recent_repos.json"
local half_life_days = 7 -- 指数衰减半衰期：多久没打开分数掉一半

local alias_hl = "RecentRepoAlias"
local function ensure_alias_hl()
	local palette = require("catppuccin.palettes").get_palette("mocha")
	vim.api.nvim_set_hl(0, alias_hl, { fg = palette.mauve, bold = true, underline = true })
end

local function load()
	return json_store.read(data_path, {})
end

local function save(data)
	json_store.write(data_path, data)
end

local function score(entry)
	local days = (os.time() - (entry.last or 0)) / 86400
	return (entry.count or 1) * (0.5 ^ (days / half_life_days))
end

-- 记录一次仓库访问（新增或计数 +1、刷新最近访问时间）
function M.record(path)
	if not path or path == "" then
		return
	end
	local data = load()
	for _, e in ipairs(data) do
		if e.path == path then
			e.count = (e.count or 1) + 1
			e.last = os.time()
			save(data)
			return
		end
	end
	table.insert(data, { path = path, count = 1, last = os.time() })
	save(data)
end

function M.set_alias(path, alias)
	local data = load()
	for _, e in ipairs(data) do
		if e.path == path then
			e.alias = (alias ~= "" and alias) or nil
			break
		end
	end
	save(data)
end

local function sorted_entries()
	local data = load()
	table.sort(data, function(a, b)
		return score(a) > score(b)
	end)
	return data
end

-- 目录预览：优先用 eza（图标 + 颜色），否则退回 ls；只看一层，不递归子目录
local function preview_cmd(path)
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

-- "[Process exited N]" 其实是 nvim 内置的 nested TermClose 自动命令用 extmark（虚拟文本）
-- 叠加上去的（namespace: nvim.terminal.exitmsg），不是真实 buffer 内容，直接清掉这个 namespace 即可
local exitmsg_ns = vim.api.nvim_create_namespace("nvim.terminal.exitmsg")
vim.api.nvim_create_autocmd("TermClose", {
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

function M.picker(opts)
	opts = opts or {}
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
				local tag = e.alias and { "[" .. e.alias .. "]", alias_hl } or { "[]" }
				return {
					value = e,
					path = e.path,
					ordinal = (e.alias or "") .. " " .. e.path,
					display = function()
						return displayer({ tag, vim.fn.fnamemodify(e.path, ":~") })
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
					vim.cmd.cd(path)
					vim.notify(path, nil, { title = "cd ->", icon = "" })

					-- 项目里留有 Session.vim 就新开一个 tab 恢复上次的窗口布局，
					-- 避免直接 source 覆盖掉当前 tab 正在看的东西
					local session_file = path .. "/Session.vim"
					if vim.fn.filereadable(session_file) == 1 then
						vim.cmd.tabnew()
						vim.cmd.source(session_file)
					else
						-- 没有 Session.vim 时，按顺序尝试打开常见项目入口文件
						-- 顺序即优先级：先看文档说明，再退回各语言的工程清单文件
						local fallback_files = {
							-- 文档 / 说明
							"README.md",
							"README.rst",
							"README.txt",
							"README",
							-- AI 助理配置
							"CLAUDE.md",
							"AGENTS.md",
							-- Neovim / Lua
							"init.lua",
							-- Rust
							"Cargo.toml",
							-- Node / Deno / Bun
							"package.json",
							"deno.json",
							"bun.lock",
							-- Python
							"pyproject.toml",
							"setup.py",
							"requirements.txt",
							-- Go
							"go.mod",
							-- Elixir
							"mix.exs",
							-- Ruby / PHP
							"Gemfile",
							"composer.json",
							-- JVM
							"pom.xml",
							"build.gradle",
							"build.gradle.kts",
							-- C / C++
							"CMakeLists.txt",
							"meson.build",
							-- Zig
							"build.zig",
							-- Dart / Flutter
							"pubspec.yaml",
							-- Swift
							"Package.swift",
							-- Nix
							"flake.nix",
							"default.nix",
							-- 通用构建
							"Makefile",
							"justfile",
							"Justfile",
							-- 容器 / 编排
							"docker-compose.yml",
							"Dockerfile",
						}
						for _, file in ipairs(fallback_files) do
							local filepath = path .. "/" .. file
							if vim.fn.filereadable(filepath) == 1 then
								vim.cmd.tabnew()
								vim.cmd.edit(filepath)
								break
							end
						end
					end
				end)

				map({ "n", "i" }, "<C-r>", function()
					local selection = action_state.get_selected_entry()
					if not selection then
						return
					end
					local current_picker = action_state.get_current_picker(prompt_bufnr)
					vim.ui.input({ prompt = "别名: ", default = selection.value.alias or "" }, function(input)
						if input == nil then
							return
						end
						M.set_alias(selection.value.path, input)
						current_picker:refresh(make_finder(), { reset_prompt = false })
					end)
				end)

				return true
			end,
		})
		:find()
end

return M
