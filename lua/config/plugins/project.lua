return {
	"natecraddock/workspaces.nvim",
	enent = "VeryLazy",
	opts = {
		-- on a unix system this would be ~/.local/share/nvim/workspaces
		path = vim.fn.stdpath("data") .. "/workspaces",
		-- controls how the directory is changed. valid options are "global", "local", and "tab"
		--   "global" changes directory for the neovim process. same as the :cd command
		--   "local" changes directory for the current window. same as the :lcd command
		--   "tab" changes directory for the current tab. same as the :tcd command
		cd_type = "tab",

		-- sort the list of workspaces by name after loading from the workspaces path.
		sort = true,

		-- sort by recent use rather than by name. requires sort to be true
		mru_sort = true,

		-- option to automatically activate workspace when opening neovim in a workspace directory
		auto_open = true,

		-- option to automatically activate workspace when changing directory not via this plugin
		auto_dir = false,

		-- enable info-level notifications after adding or removing a workspace
		notify_info = true,

		-- lists of hooks to run after specific actions
		-- hooks can be a lua function or a vim command (string)
		-- lua hooks take a name, a path, and an optional state table
		-- if only one hook is needed, the list may be omitted
		hooks = {
			add = {},
			remove = {},
			rename = {},
			open_pre = {},
			open = { "Telescope find_files" },
		},
	},
}
