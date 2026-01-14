-- ===========================================================================
-- ftplugin: lua
-- ===========================================================================

vim.lsp.inlay_hint.enable(false)
vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
