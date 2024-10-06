return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
			"MunifTanjim/nui.nvim",
		},
		keys = {
			{ "<D-b>", "<CMD>Neotree toggle reveal dir=./<CR>" }
		},
		opts = {
			open_files_do_not_replace_types = { "terminal", "trouble", "qf", "nofile" },
			window = {
				width = 25,
				mappings = {
					["O"] = "system_open",
				},
				filesystem = {
					filtered_items = {

						always_show = { -- remains visible even if other settings would normally hide it
							".gitignore",
						},
						always_show_by_pattern = { -- uses glob style patterns
							".env*",
						},
						never_show = { -- remains hidden even if visible is toggled to true, this overrides always_show
							".DS_Store",
							"thumbs.db"
						},
						never_show_by_pattern = { -- uses glob style patterns
							".null-ls_*",
						},
					},
					follow_current_file = {
						enabled = true,    -- This will find and focus the file in the active buffer every time
						leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
					},
					group_empty_dirs = true,
				}
			},
			commands = {
				system_open = function(state)
					local node = state.tree:get_node()
					local path = node:get_id()
					-- macOs: open file in default application in the background.
					vim.fn.jobstart({ "open", "-g", path }, { detach = true })
					-- Linux: open file in default application
					-- vim.fn.jobstart({ "xdg-open", path }, { detach = true })
				end,
			},
		}
	},
	---@type LazySpec
	{
		"mikavilpas/yazi.nvim",
		event = "VeryLazy",
		keys = {
			{ "<D-y>", "<cmd>Yazi<cr>", desc = "Open yazi at the current file", },
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
