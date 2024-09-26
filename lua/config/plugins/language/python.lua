return {
	{
		"AckslD/swenv.nvim",
		dependencies = {
			-- "VonHeikemen/lsp-zero.nvim",
			"nvim-lua/plenary.nvim",
		},
		ft = { "python" },
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
			})
		end
	},

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
		-- NOTE:查看官方对venv的支持～～
		"benlubas/molten-nvim",
		version = "^1.0.0", -- use version <2.0.0 to avoid breaking changes
		dependencies = { "3rd/image.nvim" },
		build = ":UpdateRemotePlugins",
		keys = {
			{ "<leader>mi", ":MoltenInit<CR>",             desc = "Initialize the plugin",  mode = "n", silent = true },
			{ "<leader>e",  ":MoltenEvaluateOperator<CR>", desc = "Run operator selection", mode = "n", silent = true },
			{ "<leader>rl", ":MoltenEvaluateLine<CR>",     desc = "Evaluate line",          mode = "n", silent = true },
			{ "<leader>rr", ":MoltenReevaluateCell<CR>",   desc = "Re-evaluate cell",       mode = "n", silent = true },
			{
				"<leader>r",
				function()
					-- 获取内核列表并将 venv 设置为 "0" 如果内核存在
					local kernels = table.concat(vim.fn.MoLtenRunningKerneLs(true), ", ")
					local venv = (#kernels > 0 and "") or string.match(os.getenv("VIRTUAL_ENV") or "", "/.+/(.+)") or "python3"
					vim.cmd(("MoltenEvaluateVisual %s"):format(venv))
				end,
				desc = "Evaluate visual selection",
				mode = "v",
				silent = true,
			},
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

			local init_env = function()
				-- 获取当前运行的内核列表，并检查是否为空
				local kernels = vim.fn.MoLtenRunningKerneLs(true)
				local kernels_str = table.concat(kernels, ", ")

				-- 如果内核不为空，则执行 MoltenEvaluateVisual
				if #kernels_str > 0 then
					vim.cmd("MoltenEvaluateVisual")
					return
				end
				local venv = os.getenv("VIRTUAL_ENV")
				if venv then
					local matched_venv = string.match(venv, "/.+/(.+)") or "python3"
					vim.cmd(("MoltenEvaluateVisual %s"):format(matched_venv))
				else
					vim.cmd("MoltenEvaluateVisual python3")
				end
			end
			-- 设置样式
			vim.api.nvim_set_hl(0, "MoltenOutputBorder", { link = "FloatBorder" })
			vim.api.nvim_set_hl(0, "MoltenCell", { bold = true, bg = "#364646" })
		end,
	}
	,
}
