-- ===========================================================================
-- LSP: biome
-- ===========================================================================

---@type vim.lsp.Config
return {
	cmd = { "biome", "lsp-proxy" },
	-- 核心优化点：扩大接管范围，让它真正处理 TS/JS 以及 React 代码
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
		"json",
		"jsonc",
		"css", -- Biome 现在也支持 CSS 格式化了
		"html",
		"graphql", -- 顺手接管 GraphQL
	},
	root_markers = { "biome.json", "biome.jsonc", ".git" },
	single_file_support = true,
}
