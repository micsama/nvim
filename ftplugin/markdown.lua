-- ===========================================================================
-- ftplugin: markdown
-- ===========================================================================

vim.opt.complete = { ".", "b" }
require("render-markdown").setup({
	file_types = { "markdown", "codecompanion", "vimwiki" },
	completions = { lsp = { enabled = true } },
})
