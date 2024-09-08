return {
	{
		"ahmedkhalf/project.nvim",
		config = function()
			require("project_nvim").setup {
				patterns = { ".git", "Makefile", "package.json" }
			}
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
	config = function()
		require('telescope').load_extension('projects')
	end
}
