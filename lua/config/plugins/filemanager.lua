return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
			"MunifTanjim/nui.nvim",
		},
		config = function()
			require("neo-tree").setup({
				source_selector = {
					winbar = true,
				},
				filesystem = {
					follow_current_file = { enable = false }, -- 当切换文件时，自动切换到文件所在的目录
					hijack_netrw_behavior = "open_default", -- 使用neo-tree替代netrw
					use_libuv_file_watcher = true,       -- 使用libuv来监听文件变化
					cwd_target = {
						in_terminal = false,               -- 使用当前终端工作目录
						from_neotree = false,              -- 使用neo-tree窗口的工作目录
					},
					filtered_items = {
						hide_dotfiles = true,
						hide_gitignored = true,
					},
				},
			})
		end
	},
	{
		"micsama/joshuto.nvim",
		lazy = true,
		cmd = "Joshuto",
		config = function()
			vim.g.joshuto_floating_window_scaling_factor = 0.85
			vim.g.joshuto_use_neovim_remote = 1
			vim.g.joshuto_floating_window_winblend = 0
		end
	}
}
