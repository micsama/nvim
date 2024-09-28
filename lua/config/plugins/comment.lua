return {
	{
		"folke/todo-comments.nvim",
		-- event = "BufRead", -- Lazy load when a buffer is read
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {
			keywords = {
				MODIFIED = {
					icon = " ",
					color = "hint",
					alt = { "CHANGED", "UPDATED", "MOD" }
				},
			}
		}
	},
}
