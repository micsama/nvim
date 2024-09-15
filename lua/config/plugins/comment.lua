return {
	{
		'numToStr/Comment.nvim',
		keys = {
			{ 'gc', '<Plug>(comment_toggle_linewise)',        mode = 'n', desc = 'Toggle comment in NORMAL mode' },
			{ 'gc', '<Plug>(comment_toggle_linewise_visual)', mode = 'x', desc = 'Toggle comment in VISUAL mode' },
		}
	},
	{
		"folke/todo-comments.nvim",
		event = "BufRead", -- Lazy load when a buffer is read
		dependencies = { "nvim-lua/plenary.nvim" },
	}
}
