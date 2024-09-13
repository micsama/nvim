return {
	{
		-- NOTE: vim.lsp.buf_get_clients()
		"ahmedkhalf/project.nvim",
		dependencies = { 'nvim-telescope/telescope.nvim' },
		event = "VeryLazy",
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
				theme = "hyper",
				config = {
					shortcut = {
						-- action can be a function type
					},
					packages = { enable = true }, -- show how many plugins neovim loaded
					-- limit how many projects list, action when you press key or enter it will run this action.
					-- action can be a functino type, e.g.
					-- action = func(path) vim.cmd('Telescope find_files cwd=' .. path) end
					project = { enable = true, limit = 8, icon = '󱠿', label = '\t近期 ^_^ 目录', action = 'Telescope find_files cwd=' },
					mru = { limit = 10, icon = '', label = '\t近期 $_$ 文件', cwd_only = false },
					footer = {}, -- footer
				}

			}
		end,
		dependencies = { { 'nvim-tree/nvim-web-devicons' } }
	},
}
