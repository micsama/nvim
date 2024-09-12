return {
	{
		"nvim-zh/colorful-winsep.nvim",
		opts = { smooth = true, },
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
		-- keys = {
		-- 	'<D-f>', "<CMD>NeoZoomToggle<CR>", { mode = 'n', desc = "Zoom your window largr" },
		-- },
		config = function()
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
