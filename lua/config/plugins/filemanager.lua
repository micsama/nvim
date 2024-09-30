return {
	---@type LazySpec
	{


	},
	{
		"mikavilpas/yazi.nvim",
		event = "VeryLazy",
		keys = {
			{ "<D-b>", "<cmd>Yazi<cr>", desc = "Open yazi at the current file", },
		},
		---@type YaziConfig
		opts = {
			-- if you want to open yazi instead of netrw, see below for more info
			open_for_directories = false,
			keymaps = {
				show_help = '<F1>',
			},
		},
	},
	{
		-- big file & large file
		"LunarVim/bigfile.nvim",
		lazy = false,
		opts = {
			filesize = 4,
			features = { -- features to disable
				-- "indent_blankline",
				"illuminate",
				"lsp",
				-- "treesitter",
				-- "syntax",
				-- "matchparen",
				"vimopts",
				-- "filetype",
			},
		},
	},
	{
		"natecraddock/workspaces.nvim",
		-- dependencies={"nvim-telescope/telescope.nvim"},
		opts = {
			path = vim.fn.stdpath("data") .. "/workspaces",
			cd_type = "local",
			hooks = {
				open = { "Yazi" },
			}
		},
	}
}
