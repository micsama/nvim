local now, add, later = MiniDeps.now, MiniDeps.add, MiniDeps.later
later(function ()
    add({source="nvim-treesitter/nvim-treesitter",depends={"nushell/tree-sitter-nu"}})
    vim.opt.smartindent = false
    require("nvim-treesitter.configs").setup({
        modules = {},
        auto_install = true,
        sync_install = false,
        ensure_installed = {
            "gitignore",
            "gitcommit",
            "git_config",
            "typst",
            "vimdoc",
            "csv",
            "cmake",
            "fish",
            "html",
            "markdown_inline",
            "markdown",
            "bash",
            "lua",
            "yaml",
            "python",
            "toml",
            "rust"
        },
        ignore_install = { "all" },
        highlight = {
            enable = true,
            disable = {}, -- list of language that will be disabled
            additional_vim_regex_highlighting = false,

        },
        indent = {
            enable = true
        },
        incremental_selection = {
            enable = true,
            keymaps = {
                init_selection    = "<CR>",
                node_incremental  = "<CR>",
                node_decremental  = "<s-CR>",
                scope_incremental = "<c-l>",
            },
        }
    })

end)


later(function ()
    add("nvim-treesitter/nvim-treesitter-context")
    local tscontext = require('treesitter-context')
    tscontext.setup {
        enable = true,
        max_lines = 6,        -- How many lines the window should span. Values <= 0 mean no limit
        min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
        line_numbers = true,
        multiline_threshold = 20, -- Maximum number of lines to collapse for a single context line
        trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
        mode = 'cursor',      -- Line used to calculate context. Choices: 'cursor', 'topline'
        -- Separator between context and content. Should be a single character string, like '-'.
        -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
        separator = nil,
        zindex = 20, -- The Z-index of the context window
        on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
    }
    vim.keymap.set("n", "[c", function()
        tscontext.go_to_context()
    end, { silent = true })
end)