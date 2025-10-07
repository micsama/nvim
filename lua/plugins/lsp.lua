local map = require('util.utils').map

-- 设置诊断配置
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
		numhl = {
			[vim.diagnostic.severity.WARN] = 'WarningMsg',
		},
	},
	virtual_text = false,
	update_in_insert = false,
	float = true,
})


vim.lsp.config('*', {
	capabilities = {
		textDocument = {
			semanticTokens = {
				multilineTokenSupport = true,
			}
		}
	},
	root_markers = { '.git', '.venv', 'Cargo.toml' },
})
vim.lsp.enable({ 'tombi', 'luals', 'jsonls', 'pyright', 'ruff', 'rust_analyzer', 'nushell', 'markdown-oxide' })

-- 设置键映射，直接使用 Lua 闭包函数
map('n', '<D-S-f>', function()
	vim.notify('Formatting...')
	local lineno = vim.api.nvim_win_get_cursor(0)
	vim.lsp.buf.format({ async = false })
	pcall(vim.api.nvim_win_set_cursor, 0, lineno)
end, 'format full file')
