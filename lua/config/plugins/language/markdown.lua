return {
	-- {
	-- 	"instant-markdown/vim-instant-markdown",
	-- 	ft = { "markdown" },
	-- 	build = "yarn install",
	-- 	config = function()
	-- 		vim.g.instant_markdown_autostart = 0
	-- 	end,
	-- },
	{
		"OXY2DEV/markview.nvim",
		lazy = false, -- Recommended
		-- ft = "markdown" -- If you decide to lazy-load anyway
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons"
		}
	}
}
