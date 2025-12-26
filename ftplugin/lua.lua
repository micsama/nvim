vim.lsp.inlay_hint.enable(false)
vim.lsp.config("lua_ls", {})
vim.treesitter.start()
vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
