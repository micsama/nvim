return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
			"MunifTanjim/nui.nvim",
		},
		keys = {
			{ '<D-b>', '<CMD>Neotree reveal toggle dir=./<CR> ', desc = 'Toggle NeoTree' }, -- 设置快捷键  为懒加载触发
		},
		config = function()
			require("neo-tree").setup({
				open_files_do_not_replace_types = { "terminal", "trouble", "qf", "nofile" },
				close_if_last_window = true,
				popup_border_style = "rounded",
				source_selector = {
					winbar = true,
				},
				window = {
					width = 25,
					mappings = {
						["O"] = vim.ui.open and {
							function(state)
								local path = state.tree:get_node().path
								local cmd, err = vim.ui.open(path)

								-- 检查是否成功调用 `vim.ui.open`，如果失败则使用 `vim.notify` 显示错误
								if not cmd then
									vim.notify("Failed to open file: " .. (err or "Unknown error"), vim.log.levels.ERROR)
									return
								end

								-- 同步等待命令执行完成
								local result = cmd:wait()

								-- 检查命令执行结果，如果 `code` 不为 0 则说明执行失败
								if result.code ~= 0 then
									vim.notify(
										"Failed to open file with exit code " .. result.code ..
										"\nError output: " .. (result.stderr or "No stderr") ..
										"\nOutput: " .. (result.stdout or "No stdout"),
										vim.log.levels.ERROR
									)
								end
							end,
							desc = "open with system default application",
						} or nil,
					}
				},
				filesystem = {
					-- window = { position = "current" },
					follow_current_file = { enable = true }, -- 当切换文件时，自动切换到文件所在的目录
					hijack_netrw_behavior = "open_default", -- 使用neo-tree替代netrw
					use_libuv_file_watcher = true,      -- 使用libuv来监听文件变化
					cwd_target = {
						in_terminal = false,              -- 使用当前终端工作目录
						from_neotree = true,              -- 使用neo-tree窗口的工作目录
					},
					filtered_items = {
						hide_dotfiles = true,
						hide_gitignored = true,
					},
				},
			})
		end
	},
	---@type LazySpec
	{
		"mikavilpas/yazi.nvim",
		event = "VeryLazy",
		keys = {
			{
				"<s-r>",
				"<cmd>Yazi<cr>",
				desc = "Open yazi at the current file",
			},
			{
				"<leader>cw",
				"<cmd>Yazi cwd<cr>",
				desc = "Open the file manager in nvim's working directory",
			},
			{
				'<c-up>',
				"<cmd>Yazi toggle<cr>",
				desc = "Resume the last yazi session",
			},
		},
		---@type YaziConfig
		opts = {
			-- if you want to open yazi instead of netrw, see below for more info
			open_for_directories = false,
			keymaps = {
				show_help = '<f1>',
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
	}
}
