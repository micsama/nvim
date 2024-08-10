vim.g.mapleader = " "

local mode_nv = { "n", "v" }
local mode_v = { "v" }
local mode_i = { "i" }

local nmappings = {
    -- quick save and quit
    { from = "S", to = ":w<CR>" },
    { from = "Q", to = ":q<CR>" },

    -- bind to quick scollor
    -- { from = "H", to = "7h",    mode = mode_nv },
    { from = "J", to = "5j",    mode = mode_nv },
    { from = "K", to = "5k",    mode = mode_nv },
    -- { from = "L", to = "7l",    mode = mode_nv },

    -- no shift ^_^
    { from = ";", to = ":",     mode = mode_nv },
    { from = "`", to = "~",     mode = mode_nv },

    -- plugins
    { from = "R",             to = ":Joshuto<CR>" },

    -- comment
    { from = "<c-/>", to = ":TComment<CR>",     mode = {"n","v","i"} },


}


vim.keymap.set("n", "q", "<nop>", { noremap = true })
vim.keymap.set("n", ",q", "q", { noremap = true })

for _, mapping in ipairs(nmappings) do
    vim.keymap.set(mapping.mode or "n", mapping.from, mapping.to, { noremap = true })
end



local function run_vim_shortcut(shortcut)
    local escaped_shortcut = vim.api.nvim_replace_termcodes(shortcut, true, false, true)
    vim.api.nvim_feedkeys(escaped_shortcut, 'n', true)
end


-- close win below
vim.keymap.set("n", "<leader>q", function()
    require("trouble").close()
    local wins = vim.api.nvim_tabpage_list_wins(0)
    if #wins > 1 then
        run_vim_shortcut([[<C-w>j:q<CR>]])
    end
end, { noremap = true, silent = true })
