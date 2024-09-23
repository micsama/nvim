return {
	{
		"OXY2DEV/markview.nvim",
		-- lazy = false, -- Recommended
		ft = "markdown", -- If you decide to lazy-load anyway
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons"
		},
		keys = {
			{ "<leader>mk", "<CMD>Markview<CR>", desc = "Toggle Markdown View" }
		},
		opts = {
			modes = { "n", "i", "no", "c" },
			hybrid_modes = { "i" },
			callbacks = {
				on_enable = function(_, win)
					vim.wo[win].conceallevel = 2;
					vim.wo[win].concealcursor = "nc";
				end
			}
		}
	},
	{
		'Kicamon/markdown-table-mode.nvim',
		ft = "markdown", -- If you decide to lazy-load anyway
		opts = {},
	}
}
