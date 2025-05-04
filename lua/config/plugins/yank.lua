return {
	{
		    "rachartier/tiny-inline-diagnostic.nvim",
		    event = "VeryLazy", -- Or `LspAttach`
		    priority = 1000, -- needs to be loaded in first
		    config = function()
		        require('tiny-inline-diagnostic').setup()
	        vim.diagnostic.config({ virtual_text = false }) -- Only if needed in your configuration, if you already have native LSP diagnostics
	    end
	},
	{
		"AckslD/nvim-neoclip.lua",
		dependencies = {
			'nvim-telescope/telescope.nvim',
			{ 'kkharji/sqlite.lua', module = 'sqlite' },
		},
		event = "VeryLazy",
		keys = {
			{ "<leader>y", "<CMD>lua require('telescope').extensions.neoclip.default()<CR>", desc = "Open neoclip" }
		},
		config = function()
			require('neoclip').setup({
				history = 1000,
				enable_persistent_history = true,
				keys = {
					telescope = {
						i = {
							select = '<c-y>',
							paste = '<cr>',
							paste_behind = '<c-g>',
							replay = '<c-q>', -- replay a macro
							delete = '<c-d>', -- delete an entry
							edit = '<c-k>', -- edit an entry
							custom = {},
						},
					},
				},
			})
		end
	},
}
