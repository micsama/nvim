return {
	{
		'numToStr/Comment.nvim',
		config = function()
			require('Comment').setup({
				toggler = {
					line = "<a-/>"
				},
				opleader = {
					line = '<a-/>',
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
