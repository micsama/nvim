vim.lsp.config('*', {
	capabilities = {
		textDocument = {
			semanticTokens = {
				multilineTokenSupport = true,
			}
		}
	},
	root_markers = { '.git' },
})

vim.lsp.enable({ 'luals', 'jsonls', 'pyright', 'ruff', 'rust_analyzer' })

-- 设置键映射，直接使用 Lua 闭包函数
vim.keymap.set('n', '<D-S-f>', function()
	vim.notify("Formatting...")
	local lineno = vim.api.nvim_win_get_cursor(0)
	vim.lsp.buf.format({ async = false })
	pcall(vim.api.nvim_win_set_cursor, 0, lineno)
end, { noremap = true, silent = true })
