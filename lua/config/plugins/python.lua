return {
	{
		"alexpasmantier/pymple.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			-- optional (nicer ui)
			"stevearc/dressing.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		build = ":PympleBuild",
		config = function()
			require("pymple").setup()
		end,
	},
	{
		'AckslD/swenv.nvim',
		config = function()
			require('swenv').setup({
				-- Should return a list of tables with a `name` and a `path` entry each.
				-- Gets the argument `venvs_path` set below.
				-- By default just lists the entries in `venvs_path`.
				get_venvs = function(venvs_path)
					return require('swenv.api').get_venvs(venvs_path)
				end,
				-- Path passed to `get_venvs`.
				venvs_path = vim.fn.expand('~/venvs'),
				-- Something to do after setting an environment, for example call vim.cmd.LspRestart
				post_set_venv = nil,
			})
		end

	}
}
