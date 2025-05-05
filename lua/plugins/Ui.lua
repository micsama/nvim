local now, add, later = MiniDeps.now, MiniDeps.add, MiniDeps.later
local map = require("util.utils").map

now(function()
    require('mini.notify').setup()
    vim.notify = require('mini.notify').make_notify()
end)

-- color主题
now(function()
    add("olimorris/onedarkpro.nvim")
    vim.cmd.colorscheme('onedark')
end)


-- now(function() require('mini.icons').setup() end)
-- now(function ()
--     add("akinsho/bufferline.nvim")
--     require("bufferline").setup()

-- end)


now(function() require('mini.tabline').setup() end)



now(function()
    add({ source = "nvim-lualine/lualine.nvim", depends = { 'nvim-tree/nvim-web-devicons' } })
    require('lualine').setup {
        options = {
            icons_enabled = true,
            theme = 'autO',
            component_separators = { left = '', right = '' },
            section_separators = { left = '', right = '' },
            disabled_filetypes = {
                statusline = {},
                winbar = {},
            },
            ignore_focus = {},
            always_divide_middle = true,
            globalstatus = true,
            refresh = {
                statusline = 1000,
                tabline = 1000,
                winbar = 1000,
            }
        },
        sections = {
            lualine_a = { 'filename' },
            lualine_b = { 'branch', 'diff', 'diagnostics' },
            lualine_c = { 'overseer' },
            lualine_x = { {
                "swenv",
                cond = function()
                    -- 检查文件类型是否为 Python 或 buf 类型是命令行
                    local ft = vim.bo.filetype
                    local buftype = vim.bo.buftype
                    return ft == "python" or buftype == "terminal" or buftype == "prompt"
                end,
                icon = ""
            } },
            lualine_y = { 'filesize', 'filetype' },
            lualine_z = { 'location' }
        },
        inactive_sections = {
            lualine_a = {},
            lualine_b = {},
            lualine_c = { 'filename' },
            lualine_x = { 'location' },
            lualine_y = {},
            lualine_z = {}
        },
        tabline = {},
        winbar = {},
        inactive_winbar = {},
        extensions = {}
    }
end)

later(function()
    add("akinsho/toggleterm.nvim")
    require("toggleterm").setup({
        shade_terminals = false,
        autochdir = true,

    })
end)

later(function()
    add('akinsho/toggleterm.nvim')
    require('toggleterm').setup()
end)


now(function()
    add("dstein64/nvim-scrollview")
    require("scrollview").setup({
        mode = "virtual",
        excluded_filetypes = { 'nerdtree' },
        current_only = true,
        base = 'right',
        column = 1,
        signs_on_startup = { 'all' },
        diagnostics_severities = { vim.diagnostic.severity.ERROR }
    })
end)
-- "Bekaboo/dropbar.nvim",


now(function()
    require('mini.completion').setup()
end)


later(function()
    add("folke/which-key.nvim")
    require("which-key").setup()
end)


now(function()
    add({
        source = 'nvim-telescope/telescope.nvim',
        branch = "0.1.x",
        depends = {
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope-fzf-native.nvim' },
    })

    local telescope = require('telescope')
    telescope.setup({
        extensions = {
            -- fzf = {
            --     fuzzy = true,               -- false will only do exact matching
            --     override_generic_sorter = true, -- override the generic sorter
            --     override_file_sorter = true, -- override the file sorter
            --     case_mode = "smart_case",   -- or "ignore_case" or "respect_case"
            -- }
        }
    })
    -- telescope.load_extension("workspaces")
    -- telescope.load_extension('fzf')


    map("nv", '<leader>ff', function() require('telescope.builtin').find_files() end, 'Find Files')
    map("nv", '<leader>fg', function() require('telescope.builtin').live_grep() end, 'Live Grep')
    map("nv", '<leader>fb', function() require('telescope.builtin').buffers() end, 'Find Buffers')
    map("nv", '<leader>fh', function() require('telescope.builtin').help_tags() end, 'Find Help Tags')
    map("nv", '<leader>fw', "<CMD>Telescope workspaces<CR>", 'Find workspaces')
end)



