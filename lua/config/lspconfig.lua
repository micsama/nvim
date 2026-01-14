--  ██╗     ███████╗██████╗
--  ██║     ██╔════╝██╔══██╗
--  ██║     ███████╗██████╔╝
--  ██║     ╚════██║██╔═══╝
--  ███████╗███████║██║
--  ╚══════╝╚══════╝╚═╝
-- Language Server Protocol Configuration
-- Intelligent Code Completion & Analysis
-- ============================================================================

local map = require("utils").map

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

require("faster").setup({
	behaviours = {
		bigfile = {
			filesize = 10,
			features_disabled = {
				"illuminate",       -- 引用高亮：大文件下频繁扫描，容易卡顿
				"matchparen",       -- 括号匹配：嵌套复杂时重绘/计算开销高
				"lsp",              -- LSP：诊断/语义分析在大文件下成本很高
				"treesitter",       -- Treesitter：AST 构建与查询开销大，优先保障流畅
				"indent_blankline", -- 缩进线：大量虚拟文本影响渲染性能
				"vimopts",          -- 自动本地选项：避免隐式副作用（大文件以稳定为先）
				-- "syntax",        -- 传统语法高亮：开启通常会明显拖慢
				-- "filetype",      -- 文件类型检测：一般无需禁用，除非极端场景
			},
		},
	},
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
require("mason").setup({ ui = { icons = { package_installed = "✓" } } })
