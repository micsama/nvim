return {
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			-- your configuration comes here
			-- or leave it empty to use the default settings
			-- refer to the configuration section below
		},
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer Local Keymaps (which-key)",
			},
		},
		config = function()
			require("which-key").add({
			})
		end
	},
	-- {
	-- 	'mrjones2014/legendary.nvim',
	-- 	-- since legendary.nvim handles all your keymaps/commands,
	-- 	-- its recommended to load legendary.nvim before other plugins
	-- 	priority = 10000,
	-- 	lazy = false,
	-- 	-- sqlite is only needed if you want to use frecency sorting
	-- 	-- dependencies = { 'kkharji/sqlite.lua' }
	-- }
}
