--  ██╗     ███████╗██████╗
--  ██║     ██╔════╝██╔══██╗
--  ██║     ███████╗██████╔╝
--  ██║     ╚════██║██╔═══╝
--  ███████╗███████║██║
--  ╚══════╝╚══════╝╚═╝
-- Language Server Protocol Configuration
-- Intelligent Code Completion & Analysis
-- ============================================================================

local map = require("utils.map").map

-- ============================================================================
-- 1) Diagnostics UI
-- ============================================================================
vim.diagnostic.config({
	jump = {
		on_jump = function(_, bufnr)
			vim.diagnostic.open_float({ bufnr = bufnr, focus = false, scope = "cursor" })
		end,
	},
	severity_sort = true,
	signs = {
		priority = 200,
		text = {
			[vim.diagnostic.severity.ERROR] = "✘",
			[vim.diagnostic.severity.WARN] = "󱓈",
			[vim.diagnostic.severity.INFO] = "󰋽",
			[vim.diagnostic.severity.HINT] = "󰛩",
		},
	},
	float = {
		border = "rounded",
		source = "if_many",
		header = "",
		title = { { "  Diagnostics ", "DiagnosticFloatingInfo" } },
		title_pos = "left",
		prefix = function(diag, i)
			local icons = { "✘ ", "󱓈 ", "󰋽 ", "󰛩 " }
			local sev = vim.diagnostic.severity[diag.severity]
			return string.format("%d. %s", i, icons[diag.severity] or ""), "DiagnosticFloating" .. sev
		end,
	},
	virtual_text = {
		severity = { min = vim.diagnostic.severity.WARN },
		spacing = 4,
		prefix = "●",
		format = function(d)
			return vim.trim(vim.split(d.message, "\n", { plain = true })[1])
		end,
		hl_mode = "blend",
	},
})

-- ============================================================================
-- 2) LSP Defaults & Enabled Servers 
-- stylua: ignore start
-- ============================================================================
vim.lsp.config("*", {
	root_markers = { ".git", ".venv", "pyproject.toml", "Cargo.toml", "package.json", "init.lua" },
	capabilities = { textDocument = { semanticTokens = { multilineTokenSupport = true } } },
})

vim.lsp.enable({
	"lua_ls",                 -- Lua：Neovim 配置 / 插件开发的核心语言服务器
	"stylua",                 -- Lua Formatter：Lua 代码格式化（通常通过 LSP/formatter 统一触发）

	"ty",                     -- Python：Astral 出品的类型分析器（实验性、更快）
	"ruff",                   -- Python：超快 lint + formatter（替代 flake8/isort 等）
	"basedpyright",           -- Python：强类型检查（比官方 pyright 更激进）

	"tombi",                  -- TOML：TOML 校验与格式化（Taplo/TOML 生态）
	"rust_analyzer",          -- Rust：官方推荐的语言服务器

	"biome",                  -- JS/TS/JSON：lint + format + code actions（Rome 继任）
	"bashls",                 -- Bash：脚本补全、诊断、ShellCheck 集成
	"nushell",                -- Nushell：现代 shell 的语法与补全支持
	"markdown_oxide",         -- Markdown：双链补全（PKM / wiki 风格）
	"docker_language_server", -- Dockerfile：语法补全 + lint
})

-- ============================================================================
-- stylua: ignore end
-- 3) LSP UX (Inlay Hints / Format)
-- ============================================================================
map("n", "<leader>th", function()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, "LSP Toggle Inlay Hints")

map("niv", "<D-S-f>", function()
	vim.notify("Formatting…", nil, { title = "LSP", icon = "󰏫", timeout = 500 })
	local cursor = vim.api.nvim_win_get_cursor(0)
	vim.lsp.buf.format({ async = false })
	pcall(vim.api.nvim_win_set_cursor, 0, cursor)
end, "格式化文件")

-- ============================================================================
-- 4) Treesitter & Helpers
-- ============================================================================
require("treesitter-context").setup()

-- ============================================================================
-- 5. Telescope (Finder) + Keymaps
-- ============================================================================
local telescope, builtin = require("telescope"), require("telescope.builtin")
telescope.setup({
	defaults = {
		path_display = { "filename_first" },
		sorting_strategy = "ascending",
		layout_config = { prompt_position = "top" }, -- ascending + top prompt
	},
})
telescope.load_extension("fzf")

-- stylua: ignore start
local telescope_maps = {
  -- 文件 / 搜索（高频）
  { "nv", "<leader>ff", builtin.find_files,           "📁 查找文件" },
  { "nv", "<leader>fr", builtin.oldfiles,             "🕒 最近文件" },
  { "nv", "<leader>fg", builtin.live_grep,            "🔎 全局搜索" },
  { "nv", "<leader>fw", builtin.grep_string,          "🔦 搜索光标词" },
  { "nv", "<leader>f/", builtin.search_history,       "📜 搜索历史（/）" },
  { "nv", "<leader>f:", builtin.command_history,      "⌨️ 指令历史" },
  { "nv", "<leader>fs", builtin.treesitter,           "🌳 语法树符号" },
  { "nv", "<leader>fy", "<CMD>Telescope neoclip<CR>", "📋 剪贴板历史" },
  { "nv", "<leader>fn", "<CMD>Telescope notify<CR>",  "🔔 通知历史" },
  { "nv", "<leader>fp", "<CMD>Telescope pickers<CR>", "🧰 Picker 历史" },
}
vim.iter(telescope_maps):each(function(m) map(unpack(m)) end)
-- stylua: ignore end
