return {
	cmd = { 'rust-analyzer' },
	filetypes = { 'rust' },
	on_attach = function(client, bufnr)
		-- 启用 inlay hints
		if client.server_capabilities.inlayHintProvider then
			vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
		end
		if client.supports_method("textDocument/inlayHint", { bufnr = bufnr }) then
			vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
		end
	end,
	settings = {
		["rust-analyzer"] = {
			completion = { autoimport = { enable = false } },
			inlayHints = { typeHints = true },
			cargo = { allFeatures = true },
			checkOnSave = true,
			hover = {
				actions = {
					run = { enable = true },
					enable = true,
				}
			},
		}
	},
}
