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
							default = "qwen3:4b",
						},
						temperature = {
							order = 2,
							mapping = "parameters",
							type = "number",
							optional = true,
							default = 0.6,
							desc =
							"What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. We generally recommend altering this or top_p but not both.",
							validate = function(n)
								return n >= 0 and n <= 2, "Must be between 0 and 2"
							end,
						},
            MinP = {
              order = 5,
              mapping = "parameters",
              type = "number",
              optional = true,
              default = 0,
              desc = "A higher value (e.g., 0.95) will lead to more diverse text, while a lower value (e.g., 0.5) will generate more focused and conservative text. (Default: 0.9)",
            },
            top_k = {
              order = 5,
              mapping = "parameters",
              type = "number",
              optional = true,
              default = 20,
              desc = "A higher value (e.g., 0.95) will lead to more diverse text, while a lower value (e.g., 0.5) will generate more focused and conservative text. (Default: 0.9)",
            },
						top_p = {
							order = 5,
							mapping = "parameters",
							type = "number",
							optional = true,
							default = 0.95,
							desc =
							"A higher value (e.g., 0.95) will lead to more diverse text, while a lower value (e.g., 0.5) will generate more focused and conservative text. (Default: 0.9)",
							validate = function(n)
								return n >= 0 and n <= 1, "Must be between 0 and 1"
							end,
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
