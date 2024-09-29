return {
	{
		"nyngwang/NeoZoom.lua",
		keys = {
			{ '<D-f>', "<CMD>NeoZoomToggle<CR>", desc = "Zoom your window largr" }
		},
		config = function()
			require('neo-zoom').setup {
				popup = { enabled = true }, -- this is the default.
				exclude_buftypes = { 'terminal' },
				winopts = {
					offset = {
						width = 1.0,
						height = 1.0,
					},
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
