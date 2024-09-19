return {
	{
		"folke/todo-comments.nvim",
		-- event = "BufRead", -- Lazy load when a buffer is read
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {}
	},
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
}
