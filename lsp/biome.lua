-- ===========================================================================
-- LSP: biome
-- ===========================================================================

---@type vim.lsp.Config
return {
	cmd = { "biome", "lsp-proxy" },
	filetypes = { "json", "jsonc" },
	root_markers = { "biome.json", "biome.jsonc", ".git" },
	single_file_support = true,
}
