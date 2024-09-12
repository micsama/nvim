return {
	{
		"lewis6991/gitsigns.nvim",
		event = { 'BufReadPre', 'BufNewFile' },
		config = function()
			require('gitsigns').setup({
				signs = {
					add          = { text = '▎' },
					change       = { text = '░' },
					delete       = { text = '_' },
					topdelete    = { text = '▔' },
					changedelete = { text = '▒' },
					untracked    = { text = '┆' },
				},
			})
		end,
		keys = {
			{ "<leader>g-", ":Gitsigns prev_hunk<CR>",    { noremap = true, silent = true } },
			{ "<leader>g=", ":Gitsigns next_hunk<CR>",    { noremap = true, silent = true } },
			{ "<leader>gb", ":Gitsigns blame_line<CR>",   { noremap = true, silent = true } },
			{ "<leader>gr", ":Gitsigns reset_hunk<CR>",   { noremap = true, silent = true } },
			{ "H",          ":Gitsigns preview_hunk<CR>", { noremap = true, silent = true } },
		},
	},
	{
		"kdheepak/lazygit.nvim",
		keys = {
			{ "<leader>gg", ":LazyGit<CR>", { noremap = true, silent = true } },
		},
		config = function()
			vim.g.lazygit_floating_window_scaling_factor = 1.0
			vim.g.lazygit_floating_window_winblend = 0
			vim.g.lazygit_use_neovim_remote = true
		end,
	},
}
