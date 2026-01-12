---@type vim.lsp.Config
return {
	cmd = { "ty", "server" },
	filetypes = { "python" },
	root_markers = { "ty.toml", "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" },
	settings = {
		ty = {
			diagnosticMode = "off",
		},
	},
	on_attach = function(client, bufnr)
		client.server_capabilities.semanticTokensProvider = nil
		client.server_capabilities.hoverProvider = nil
		client.server_capabilities.inlayHintProvider = nil
	end,
}
