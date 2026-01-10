--  ██╗     ███████╗██████╗
--  ██║     ██╔════╝██╔══██╗
--  ██║     ███████╗██████╔╝
--  ██║     ╚════██║██╔═══╝
--  ███████╗███████║██║
--  ╚══════╝╚══════╝╚═╝
-- Language Server Protocol Configuration
-- 💻 Intelligent Code Completion & Analysis
-- ============================================================================
-- 模块引入与实用工具
-- ============================================================================
-- ============================================================================
-- LSP Configuration (Neovim 0.12+ Native Style)
-- ============================================================================
-- 1. Global Defaults
vim.filetype.add({
	-- 1. 处理特定的文件名
	filename = {
		["docker-compose.yaml"] = "yaml",
		["docker-compose.yml"] = "yaml",
		["compose.yaml"] = "yaml",
		["compose.yml"] = "yaml",
	},
	-- 2. 处理后缀名（解决 typescript.tsx 这种非标准识别）
	extension = {
		tsx = "typescriptreact",
		jsx = "javascriptreact",
	},
})
vim.lsp.config("*", {
	root_markers = { ".git", ".venv", "pyproject.toml", "Cargo.toml", "package.json", "init.lua" },
	capabilities = {
		textDocument = { semanticTokens = { multilineTokenSupport = true } },
	},
})

vim.diagnostic.config({
	severity_sort = true,
	underline = true,
	signs = {
		priority = 200,
		text = {
			[vim.diagnostic.severity.ERROR] = "✘",
			[vim.diagnostic.severity.WARN] = "󱓈", -- 闪电：警示，但不像牌子那么笨重
			[vim.diagnostic.severity.INFO] = "󰋽", -- 气泡：对话/信息
			[vim.diagnostic.severity.HINT] = "󰛩", -- 萤火虫/微光：微妙的暗示
		},
	},
	float = {
		border = "rounded",
		source = "if_many",
		header = "", -- 禁用旧的 header 样式。用title
		title = { { "  Diagnostics ", "DiagnosticFloatingInfo" } },
		title_pos = "left",
		prefix = function(diag, i, _)
			local icons = { "✘ ", "󱓈 ", "󰋽 ", "󰛩 " }
			local severity_name = vim.diagnostic.severity[diag.severity]
			local prefix_text = string.format("%d. %s", i, icons[diag.severity] or "")
			return prefix_text, "DiagnosticFloating" .. severity_name
		end,
	},
	virtual_text = {
		severity = { min = vim.diagnostic.severity.WARN },
		spacing = 2,
		prefix = "●",
		format = function(diagnostic)
			local first_line = vim.split(diagnostic.message, "\n", { plain = true })[1]
			return vim.trim(first_line)
		end,
		hl_mode = "blend",
	},
})

vim.lsp.enable({
	"lua_ls", -- Lua: 针对 Neovim 配置的核心支持
	"ty",
	"ruff", -- Python: 极速的代码规范检查与格式化 (替代 flake8/isort)
	"rust_analyzer", -- Rust: 官方推荐的高级语言支持
	"markdown-oxide", -- Markdown: 基于 PKM 理念的超强双向链接与补全
	"docker_language_server", -- Docker: Dockerfile 的官方语法支持与 Lint
	"bashls", -- Bash: 脚本自动补全与 shellcheck 集成
	"nushell", -- Nushell: 针对这个现代 Shell 的脚本支持
	"tombi", -- Taplo/TOML: 如果是用于 TOML 文件 (通常包名为 taplo)
	"stylua", -- Lua Formatter:
	"jsonls", -- JSON: 官方提供的模式验证与属性补全
})

-- Inlay Hints (Optional: Toggle with <leader>ih)
vim.keymap.set("n", "<leader>th", function()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "LSP: Toggle Inlay Hints" })

require("mason").setup({ ui = { icons = { package_installed = "✓" } } })

-- 格式化整个文件并保留光标位置
local map = require("utils").map
map("niv", "<D-S-f>", function()
	vim.notify("Formatting...")
	local cursor = vim.api.nvim_win_get_cursor(0)
	vim.lsp.buf.format({ async = false })
	pcall(vim.api.nvim_win_set_cursor, 0, cursor)
end, "格式化文件")

-- ============================================================================
-- Treesitter 及其他辅助插件
-- ============================================================================


require("nvim-treesitter").setup({
	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = "<CR>",
			node_incremental = "<CR>",
			node_decremental = "<s-CR>",
			scope_incremental = "<c-l>",
		},
	},
	install_dir = vim.fn.stdpath("data") .. "/site",
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "<filetype>" },
	callback = function()
		vim.treesitter.start()
	end,
})

-- Treesitter 辅助插件
require("treesitter-context").setup()

require("faster").setup({
	behaviours = {
		bigfile = {
			features_disabled = {
				"illuminate",
				"matchparen",
				"lsp",
				"treesitter",
				"indent_blankline",
				"vimopts",
				-- "syntax",
				-- "filetype",
			},
			filesize = 10,
		},
	},
})
