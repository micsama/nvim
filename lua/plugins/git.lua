local now, add, later = MiniDeps.now, MiniDeps.add, MiniDeps.later
local map = require("util.utils").map

later(function()
    add("lewis6991/gitsigns.nvim")
    require('gitsigns').setup({
        signs = {
            add          = { text = '▎' },
            change       = { text = '░' },
            delete       = { text = '_' },
            topdelete    = { text = '▔' },
            changedelete = { text = '▒' },
            untracked    = { text = '┆' },
        },
    })

    map("nv", "<leader>g-", ":Gitsigns prev_hunk<CR>", "prev_hunk")
    map("nv", "<leader>g=", ":Gitsigns next_hunk<CR>", "next_hunk")
    map("nv", "<leader>gb", ":Gitsigns blame_line<CR>", "blame_line")
    map("nv", "<leader>gr", ":Gitsigns reset_hunk<CR>", "reset_hunk")
    map("nv", "H", ":Gitsigns preview_hunk<CR>", "preview_hunk")
end)
