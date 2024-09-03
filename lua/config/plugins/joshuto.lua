return {
	"micsama/joshuto.nvim",
	lazy = true,
	cmd = "Joshuto",
	config = function()
		vim.g.joshuto_floating_window_scaling_factor = 0.85
		vim.g.joshuto_use_neovim_remote = 1
		vim.g.joshuto_floating_window_winblend = 0
	end
}

