local now, add, later = MiniDeps.now, MiniDeps.add, MiniDeps.later
local map = require("util.utils").map

later(function()
    add('stevearc/overseer.nvim')
    require('overseer').setup({
        templates = {"mypython","builtin"},
        task_defaults = {
            cmd = { 'fish', '-c' },
        },
    })
    map("nv", "<leader>or", ":OverseerRun<CR>", "Run Overseer Task")
    map("nv", "<leader>oo", ":OverseerToggle<CR>", "Toggle Overseer")
end)
