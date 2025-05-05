local now, add, later = MiniDeps.now, MiniDeps.add, MiniDeps.later
local map = require("util.utils").map
later(function()
    add({
        source = "olimorris/codecompanion.nvim",
        depends = { "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
            "hrsh7th/nvim-cmp",
            "nvim-telescope/telescope.nvim",
            "stevearc/dressing.nvim", }
    })
    require("codecompanion").setup({
        strategies = {
            chat = { adapter = "qwen3" },
            inline = { adapter = "qwen3" },
            agent = { adapter = "qwen3" },
        },
        adapters = {
            qwen3 = function()
                return require("codecompanion.adapters").extend("ollama", {
                    name = "qwen3",
                    schema = {
                        model = {
                            default = "qwen3:14b",
                        },
                        num_ctx = {
                            default = 16384,
                        },
                        num_predict = {
                            default = -1,
                        },
                    },
                })
            end,
        },
    })
    map("nv", "<D-o>", "<CMD>CodeCompanionChat Toggle<CR>", "Open the LLM")
end)
