return {
	{
		'numToStr/Comment.nvim',
		config = function()
			require('Comment').setup(
				{
					toggler = {
						line = '<D-/>',
					},
					opleader = {
						---Line-comment keymap
						line = '<D-/>',
					},
				}
			)
		end
	},
	{
		"folke/todo-comments.nvim",
		lazy = false,
		--event = "BufRead", -- Lazy load when a buffer is read
		dependencies = { "nvim-lua/plenary.nvim" },
	}
}
