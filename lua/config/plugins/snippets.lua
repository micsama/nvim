return {
	-- {
	-- 	"L3MON4D3/LuaSnip",
	-- 	dependencies = { "rafamadriz/friendly-snippets" },
	-- },
	{
		"SirVer/ultisnips",
		dependencies = {
			"honza/vim-snippets",
		},
		config = function()
			vim.g.UltiSnipsSnippetDirectories = { "~/.config/nvim/Ultisnips" }
		end
	},
}
