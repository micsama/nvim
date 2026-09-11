-- ===========================================================================
-- ftplugin: markdown
-- ===========================================================================

vim.opt_local.complete = { ".", "b" }
vim.pack.add(vim.g.pack_ft_markdown)

require("render-markdown").setup({
	file_types = { "markdown", "codecompanion", "vimwiki" },
	completions = { lsp = { enabled = true } },
})

require("Bullets").setup({}) -- 默认配置
