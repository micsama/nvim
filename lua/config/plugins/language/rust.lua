return {
	{
		'saecki/crates.nvim',
		event = { "BufRead Cargo.toml" },
		config = function()
			require('crates').setup(
				{
					lsp = {
						enabled = true,
						on_attach = function(client, bufnr)
							-- the same on_attach function as for your other lsp's
						end,
						actions = true,
						completion = true,
						hover = true,
					},
				}
			)
		end,
	},
	{
		'mrcjkb/rustaceanvim',
		version = '^5', -- Recommended
		lazy = false, -- This plugin is already lazy
	},
	{
		'vxpm/ferris.nvim',
		opts = {
			-- your options here
		}
	}
}
