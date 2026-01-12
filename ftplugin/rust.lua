vim.lsp.inlay_hint.enable(true)
vim.treesitter.start()

vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
	buffer = 0, -- 只作用于当前 Rust buffer
	callback = function()
		pcall(vim.lsp.codelens.refresh)
	end,
})
