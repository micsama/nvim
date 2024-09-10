return {
	{
		"nvim-zh/colorful-winsep.nvim",
		config = { smooth = true, },
		event = { "WinNew" },
	},
	{
		's1n7ax/nvim-window-picker',
		name = 'window-picker',
		event = 'VeryLazy',
		version = '2.*',
		config = function()
			require 'window-picker'.setup()
		end,
	},
	{
		"nyngwang/NeoZoom.lua",
		config = function()
			vim.keymap.set('n', '<a-f>', ':NeoZoomToggle<CR>', { silent = true, nowait = true })
			require('neo-zoom').setup {
				popup = { enabled = true }, -- this is the default.
				exclude_buftypes = { 'terminal' },
				-- exclude_filetypes = { 'lspinfo', 'mason', 'lazy', 'fzf', 'qf' },
				winopts = {
					offset = {
						width = 1.0,
						height = 1.0,
					},
					-- NOTE: check :help nvim_open_win() for possible border values.
					border = 'thicc', -- this is a preset, try it :)
				},
				presets = {
					{
						filetypes = { 'markdown' },
						callbacks = {
							function() vim.wo.wrap = true end,
						},
					},
				},
			}
		end
	}
}
