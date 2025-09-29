require("neo-tree").setup({
	open_files_do_not_replace_types = { "terminal", "trouble", "qf", "nofile" },
	window = {
		width = 30,
		mappings = {
			["O"] = "system_open",
		},
	},
	filesystem = {
		filtered_items = {
			always_show = { -- remains visible even if other settings would normally hide it
				".gitignore",
			},
			always_show_by_pattern = { -- uses glob style patterns
				".json",
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
			enabled = true,       -- This will find and focus the file in the active buffer every time
			leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
		},
		group_empty_dirs = true,
	},
	commands = {
		system_open = function(state)
			local node = state.tree:get_node()
			local path = node:get_id()
			-- macOs: open file in default application in the background.
			vim.fn.jobstart({ "open", "-g", path }, { detach = true })

			--NOTE: Linux: open file in default application
			-- vim.fn.jobstart({ "xdg-open", path }, { detach = true })
		end,
	},
})

require("yazi").setup()
require("workspaces").setup({
	path = vim.fn.stdpath("data") .. "/workspaces",
	cd_type = "local",
	hooks = {
		open = { "Yazi" },
	}
})
