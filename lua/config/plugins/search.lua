return {
	-- hlslens 插件配置
	{
		"kevinhwang91/nvim-hlslens",
		keys = {
			-- { "=",  [[<cmd>execute('normal! ' . v:count1 . 'n')<cr>]] .. [[<cmd>lua require("hlslens").start()<cr>]], desc = "Next match" },
			-- { "-",  [[<cmd>execute('normal! ' . v:count1 . 'N')<cr>]] .. [[<cmd>lua require("hlslens").start()<cr>]], desc = "Previous match" },
			{ "*",  "*" .. [[<cmd>lua require("hlslens").start()<cr>]],  desc = "Search forward" },
			{ "#",  "#" .. [[<cmd>lua require("hlslens").start()<cr>]],  desc = "Search backward" },
			{ "g*", "g*" .. [[<cmd>lua require("hlslens").start()<cr>]], desc = "Search word forward" },
			{ "g#", "g#" .. [[<cmd>lua require("hlslens").start()<cr>]], desc = "Search word backward" },
		},
		config = function()
			require("scrollbar.handlers.search").setup()
		end,
	},

	-- any-jump 插件配置
	-- {
	-- 	"pechorin/any-jump.vim",
	-- 	keys = {
	-- 		{ "j", ":AnyJump<CR>",       mode = "n", desc = "Jump to definition" },
	-- 	},
	-- 	config = function()
	-- 		vim.g.any_jump_disable_default_keybindings = true
	-- 		vim.g.any_jump_window_width_ratio = 0.9
	-- 		vim.g.any_jump_window_height_ratio = 0.9
	-- 	end,
	-- },

	-- nvim-spectre 插件配置
	{
		"nvim-pack/nvim-spectre",
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			{
				"<leader>F",
				mode = "n",
				function()
					require("spectre").open()
				end,
				desc = "Project find and replace"
			},
		},
	},

	-- nvim-scrollbar 插件配置
	{
		"petertriho/nvim-scrollbar",
		dependencies = { "kevinhwang91/nvim-hlslens" },
		event = "BufReadPost", -- 懒加载，打开文件时加载
		config = function()
			local group = vim.api.nvim_create_augroup("scrollbar_set_git_colors", {})
			vim.api.nvim_create_autocmd("BufEnter", {
				pattern = "*",
				callback = function()
					vim.cmd([[
                        hi! ScrollbarGitAdd guifg=#8CC85F
                        hi! ScrollbarGitAddHandle guifg=#A0CF5D
                        hi! ScrollbarGitChange guifg=#E6B450
                        hi! ScrollbarGitChangeHandle guifg=#F0C454
                        hi! ScrollbarGitDelete guifg=#F87070
                        hi! ScrollbarGitDeleteHandle guifg=#FF7B7B
                    ]])
				end,
				group = group,
			})
			require("scrollbar.handlers.search").setup({})
			require("scrollbar").setup({
				show = true,
				handle = {
					text = " ",
					color = "#928374",
					hide_if_all_visible = true,
				},
				marks = {
					Search = { color = "yellow" },
					Misc = { color = "purple" },
				},
				handlers = {
					cursor = false,
					diagnostic = true,
					gitsigns = true,
					handle = true,
					search = true,
				},
			})
		end,
	},
}
