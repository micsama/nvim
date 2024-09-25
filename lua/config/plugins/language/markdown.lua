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
			list_items = {
				enable = true,
				shift_width = 2,
				indent_size = 2,
			},
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
		ft = {"markdown"}, -- If you decide to lazy-load anyway
		opts = {},
	},
	{
		'ChuufMaster/markdown-toc',
		ft={"markdown"},
		opts = {
			heading_level_to_match = -1,
			-- Set to True display a dropdown to allow you to select the heading level
			ask_for_heading_level = true,
			toc_format = '%s- [%s](<%s#%s>)',
		}
	},
}
