return {
	{
		"alexpasmantier/pymple.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"stevearc/dressing.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		ft = { "python" },
		build = ":PympleBuild",
		config = function()
			require("pymple").setup()
		end,
	},
	{
		"benlubas/molten-nvim",
		version = "^1.0.0", -- use version <2.0.0 to avoid breaking changes
		dependencies = { "3rd/image.nvim" },
		build = ":UpdateRemotePlugins",
		init = function()
			-- these are examples, not defaults. Please see the readme
			-- vim.g.molten_image_provider = "wezterm"
			vim.g.molten_output_win_max_height = 20
			vim.g.molten_auto_open_output = false
			vim.g.molten_cover_empty_lines = true
			vim.g.molten_use_border_highlights = true
			vim.g.molten_virt_text_output = true
			vim.g.molten_output_virt_lines = true
			vim.g.molten_split_size = 0.3
			-- vim.g.molten_image_provider = "wezterm"
			vim.keymap.set("n", "<leader>mi", ":MoltenInit<CR>",
				{ silent = true, desc = "Initialize the plugin" })
			vim.keymap.set("n", "<leader>e", ":MoltenEvaluateOperator<CR>",
				{ silent = true, desc = "run operator selection" })
			vim.keymap.set("n", "<leader>rl", ":MoltenEvaluateLine<CR>",
				{ silent = true, desc = "evaluate line" })
			vim.keymap.set("n", "<leader>rr", ":MoltenReevaluateCell<CR>",
				{ silent = true, desc = "re-evaluate cell" })
			vim.keymap.set("v", "<leader>r", ":<C-u>MoltenEvaluateVisual<CR>gv",
				{ silent = true, desc = "evaluate visual selection" })
			-- 设置输出窗口边框的样式，链接到 FloatBorder
			vim.api.nvim_set_hl(0, "MoltenOutputBorder", { link = "FloatBorder" })
			-- 在原有 MoltenCell 样式的基础上添加加粗效果
			vim.api.nvim_set_hl(0, "MoltenCell", { bold = true })
		end,

	},
}
