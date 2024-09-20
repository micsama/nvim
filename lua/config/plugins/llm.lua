return {
	{
		"olimorris/codecompanion.nvim",
		lazy = false,
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"hrsh7th/nvim-cmp",                   -- Optional: For using slash commands and variables in the chat buffer
			"nvim-telescope/telescope.nvim",      -- Optional: For using slash commands
			{ "stevearc/dressing.nvim", opts = {} }, -- Optional: Improves the default Neovim UI
		},
		opts = {
			-- strategies = {
			-- 	chat = { adapters = "codeq" },
			-- 	inline = { adapters = "codeq" },
			-- 	agent = { adapters = "codeq" },
			-- },
			strategies = {
				chat = { adapter = "codeq" },
				inline = { adapter = "codeq" },
				agent = { adapter = "codeq" },
			},
			adapters = {
				codeq = function()
					return require("codecompanion.adapters").extend("ollama", {
						name = "codeq", -- Give this adapter a different name to differentiate it from the default ollama adapter
						schema = {
							model = {
								default = "qwen2.5-coder:latest",
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
		}
	}
}
