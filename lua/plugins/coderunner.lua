local now, add, later = MiniDeps.now, MiniDeps.add, MiniDeps.later
later(function()
    add('stevearc/overseer.nvim')
    local map = require("util.utils").map
    map("nv", "<leader>or", ":OverseerRun<CR>", "Run Overseer Task")
    map("nv", "<leader>oo", ":OverseerToggle<CR>", "Toggle Overseer")
    require('overseer').setup({
        templates = {"mypython","builtin"},
        task_defaults = {
            cmd = { 'fish', '-c' },
        },
    })
end)
