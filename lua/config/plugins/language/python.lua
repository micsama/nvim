return {
	{
		"AckslD/swenv.nvim",
		dependencies = {
			-- "VonHeikemen/lsp-zero.nvim",
			"nvim-lua/plenary.nvim",
		},
		ft = { "python" },
		keys = {
			{ "<leader>pp", function() require('swenv.api').pick_venv() end, desc = "Choice the python environment" }
		},
		config = function()
			require('swenv').setup({
				-- Should return a list of tables with a `name` and a `path` entry each.
				-- Gets the argument `venvs_path` set below.
				-- By default just lists the entries in `venvs_path`.
				get_venvs = function(venvs_path)
					return require('swenv.api').get_venvs(venvs_path)
				end,
				-- Path passed to `get_venvs`.
				venvs_path = vim.fn.expand('~/workspace/tools/envs'),
				-- Something to do after setting an environment, for example call vim.cmd.LspRestart
				post_set_venv = function()
					vim.cmd.LspRestart()
				end,
				-- NOTE:在对应目录下创建.venv文件，来设置目录默认使用的环境
				-- vim.api.nvim_create_autocmd("FileType", {
				-- 	pattern = { "python" },
				-- 	callback = function()
				-- 		require('swenv.api').auto_venv()
				-- 	end
				-- })
			})
		end
	},

	{
		"alexpasmantier/pymple.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"stevearc/dressing.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		ft = { "python" },
		build = ":PympleBuild",
		config = function()
			require("pymple").setup()
		end,
	},
	{
		-- NOTE:查看官方对venv的支持～～
		"benlubas/molten-nvim",
		version = "^1.0.0", -- use version <2.0.0 to avoid breaking changes
		dependencies = { "3rd/image.nvim" },
		build = ":UpdateRemotePlugins",
		keys = {
			{ "<leader>mi", ":MoltenInit<CR>",             desc = "Initialize the plugin",     mode = "n", silent = true },
			{ "<leader>e",  ":MoltenEvaluateOperator<CR>", desc = "Run operator selection",    mode = "n", silent = true },
			{ "<leader>rl", ":MoltenEvaluateLine<CR>",     desc = "Evaluate line",             mode = "n", silent = true },
			{ "<leader>rr", ":MoltenReevaluateCell<CR>",   desc = "Re-evaluate cell",          mode = "n", silent = true },
			{ "<leader>r",  ":<C-u>MoltenEvaluateVisual<CR>gv",   desc = "Evaluate visual selection", mode = "v", silent = true },
		},
		config = function()
			-- 设置插件的全局变量
			vim.g.molten_output_win_max_height = 20
			vim.g.molten_auto_image_popup = true
			vim.g.molten_auto_open_output = false
			vim.g.molten_cover_empty_lines = true
			vim.g.molten_use_border_highlights = true
			vim.g.molten_virt_text_output = true
			vim.g.molten_output_virt_lines = true
			vim.g.molten_split_size = 0.3
			-- 设置样式
			vim.api.nvim_set_hl(0, "MoltenOutputBorder", { link = "FloatBorder" })
			vim.api.nvim_set_hl(0, "MoltenCell", { bold = true, bg = "#364646" })
		end,
	}
	,
}
