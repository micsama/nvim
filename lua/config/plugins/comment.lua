return {
	{
		'numToStr/Comment.nvim',
		config = function()
			require('Comment').setup({
				toggler = {
					line = "<D-/>"
				},
				opleader = {
					line = '<D-/>',
				},
				mappings = {
					basic = true,
				},
			})
		end
	},
	{
		"folke/todo-comments.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {
		}
	}
}
