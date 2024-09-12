return {
	{
		'stevearc/overseer.nvim',
		opts = {},
		config = function()
			require('overseer').setup({
				task_defaults = {
					-- 设置默认 shell 为 Fish
					cmd = { 'fish', '-c' },
				},
			})
			-- require('overseer').register_template({
			-- 	name = "Open Terminal",
			-- 	builder = function()
			-- 		-- 定义任务的具体行为
			-- 		return {
			-- 			cmd = { "fish" }, -- 这里可以指定你想要的终端，比如 'bash', 'zsh', 'fish' 等
			-- 			name = "Terminal", -- 任务的名字
			-- 			components = { "default" },
			-- 		}
			-- 	end,
			-- 	-- 定义任务的描述和标签
			-- 	description = "Open a new terminal window",
			-- 	tags = { "terminal" },
			-- 	params = {}, -- 如果需要，可以在这里添加任务参数
			-- })
		end
	}, {
	-- TODO:继续配置，不同标签页不统一
	'akinsho/toggleterm.nvim',
	version = "*",
	opts = { --[[ things you want to change go here]]
		config = function()
			require("toggleterm").setup {
				shade_terminals = false
			}
		end
	}
},
	{ "folke/trouble.nvim" },
	{
		-- big file & large file
		"LunarVim/bigfile.nvim",
		lazy = false,
		opt = {
			filesize = 4,
			features = { -- features to disable
				"indent_blankline",
				"illuminate",
				"lsp",
				"treesitter",
				-- "syntax",
				"matchparen",
				"vimopts",
				-- "filetype",
			},
		},
	}
}
