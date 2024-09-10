return {
	{
		"ahmedkhalf/project.nvim",
		dependencies = { 'nvim-telescope/telescope.nvim' },
		config = function()
			require("project_nvim").setup {
				patterns = { ".git", "Makefile", "package.json" }
			}
			require('telescope').load_extension('projects')
		end
	},
	{
		'nvimdev/dashboard-nvim',
		event = 'VimEnter',
		config = function()
			require('dashboard').setup {
				-- config
			}
		end,
		dependencies = { { 'nvim-tree/nvim-web-devicons' } }
	},
}
