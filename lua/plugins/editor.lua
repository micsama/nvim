local now, add, later = MiniDeps.now, MiniDeps.add, MiniDeps.later
local map = require("util.utils").map

later(function()
    add("shellRaining/hlchunk.nvim")
    require("hlchunk").setup({
        chunk = {
            enable = true
        },
        indent = {
            enable = true
        }
    })
end)

now(function()
    require('mini.surround').setup()
end)


later(function()
    add({ source = "folke/todo-comments.nvim", depends = { "nvim-lua/plenary.nvim" } })
    require("todo-comments").setup(
        {
            keywords = {
                MODIFIED = {
                    icon = " ",
                    color = "hint",
                    alt = { "CHANGED", "UPDATED", "MOD" }
                },
            }
        })
end)


later(function()
    add("mbbill/undotree")
    vim.g.undotree_DiffAutoOpen = 1
    vim.g.undotree_SetFocusWhenToggle = 1
    vim.g.undotree_ShortIndicators = 1
    vim.g.undotree_WindowLayout = 2
    vim.g.undotree_DiffpanelHeight = 8
    vim.g.undotree_SplitWidth = 24

    vim.cmd([[
function! g:Undotree_CustomMap()
    nmap <buffer> k <plug>UndotreeNextState
    nmap <buffer> j <plug>UndotreePreviousState
    nmap <buffer> K 5<plug>UndotreeNextState
    nmap <buffer> J 5<plug>UndotreePreviousState
endfunction
]])
end)


later(function ()
    add("rachartier/tiny-inline-diagnostic.nvim")
    require("tiny-inline-diagnostic").setup()
    vim.diagnostic.config({ virtual_text = false })
end)


later(function ()
    add({source="AckslD/nvim-neoclip.lua",depends={'nvim-telescope/telescope.nvim','kkharji/sqlite.lua'}})
    require('neoclip').setup({
        history = 1000,
        enable_persistent_history = true,
        keys = {
            telescope = {
                i = {
                    select = '<c-y>',
                    paste = '<cr>',
                    paste_behind = '<c-g>',
                    replay = '<c-q>', -- replay a macro
                    delete = '<c-d>', -- delete an entry
                    edit = '<c-k>', -- edit an entry
                    custom = {},
                },
            },
        },
    })
end)



later(function ()
    add("windwp/nvim-autopairs")
    require("nvim-autopairs").setup({})
end)

later(function ()
    add("folke/trouble.nvim")
    require("trouble").setup({})
end)




