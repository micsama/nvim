-- ===========================================================================
-- ftplugin: lua
-- ===========================================================================

vim.lsp.inlay_hint.enable(false, { bufnr = 0 })
vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
