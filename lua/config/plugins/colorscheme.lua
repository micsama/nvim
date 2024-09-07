return {
	"olimorris/onedarkpro.nvim",
	priority = 1000, -- Ensure it loads first
	config = function()
		vim.cmd("colorscheme onedark")
	end
}
-- return {
-- 	"micsama/nvim-deus",
-- 	lazy = false,
-- 	priority = 1000,
-- 	config = function()
-- 		vim.cmd([[colorscheme deus]])
-- 	end,
-- }

