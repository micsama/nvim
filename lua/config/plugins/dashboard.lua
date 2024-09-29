return {
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
					project = { enable = true, limit = 8, icon = '󱠿', label = '\t近期 ^_^ 目录', action = 'Telescope find_files cwd=' },
					mru = { limit = 10, icon = '', label = '\t近期 $_$ 文件', cwd_only = false },
					footer = {}, -- footer
				}

			}
		end,
		dependencies = { { 'nvim-tree/nvim-web-devicons' } }
	},
}
