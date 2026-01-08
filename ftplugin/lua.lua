vim.lsp.inlay_hint.enable(false)
vim.treesitter.start()
vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
