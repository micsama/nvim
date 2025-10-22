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
local map = require('util.utils').map

-- ============================================================================
-- LSP 和诊断配置 (vim.diagnostic, vim.lsp)
-- ============================================================================
-- 启用 Inlay Hints
vim.lsp.inlay_hint.enable(true)

-- 全局 LSP 配置
vim.lsp.config('*', {
	capabilities = {
		textDocument = {
			semanticTokens = {
				multilineTokenSupport = true,
			}
		}
	},
	-- 添加了 rust 的 Cargo.toml 到 root_markers
	root_markers = { '.git', '.venv', 'Cargo.toml' },
})

-- 设置图标
vim.diagnostic.config({
	severity_sort = true,
	underline = true,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = '✘',
			[vim.diagnostic.severity.WARN] = '▲',
			[vim.diagnostic.severity.HINT] = '⚑',
			[vim.diagnostic.severity.INFO] = '»',
		},
		linehl = {
			[vim.diagnostic.severity.ERROR] = 'ErrorMsg',
		},
	},
	virtual_text = false,
	update_in_insert = false,
	float = true,
})


-- 启用的 Language Servers
vim.lsp.enable({ 'tombi', 'luals', 'jsonls', 'pyright', 'ruff', 'rust_analyzer', 'nushell', 'markdown-oxide','dockerls' })

-- 格式化整个文件并保留光标位置
map('n', '<D-S-f>', function()
	vim.notify('Formatting...')
	local cursor = vim.api.nvim_win_get_cursor(0)
	vim.lsp.buf.format({ async = false })
	-- pcall 防止在格式化失败时报错
	pcall(vim.api.nvim_win_set_cursor, 0, cursor)
end, '格式化文件')


-- ============================================================================
-- Treesitter 及其他辅助插件
-- ============================================================================

-- Treesitter 要求禁用 smartindent
vim.opt.smartindent = false

-- Treesitter 配置
require('nvim-treesitter.configs').setup({
	auto_install = true,
	sync_install = false,
	-- 保持常用的语言列表
	ensure_installed = {
		'gitignore', 'json', 'nu', 'gitcommit', 'git_config', 'vimdoc', 'csv',
		'fish', 'markdown_inline', 'markdown', 'bash', 'lua', 'yaml', 'python',
		'toml', 'rust', 'cmake', 'dockerfile'
	},
	-- 核心功能启用
	highlight = { enable = true, additional_vim_regex_highlighting = false },
	indent = { enable = true },
	incremental_selection = {
		enable = true,
		keymaps = {
			init_selection = '<CR>',
			node_incremental = '<CR>',
			node_decremental = '<s-CR>',
			scope_incremental = '<c-l>',
		},
	},
})

-- Treesitter 辅助插件
require('treesitter-context').setup()
require('faster').setup()
require('render-markdown').setup({ completions = { lsp = { enabled = true } } })
