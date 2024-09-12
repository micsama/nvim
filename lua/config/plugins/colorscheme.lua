return {
	"olimorris/onedarkpro.nvim",
	priority = 1000, -- Ensure it loads first
	config = function()
		require("onedarkpro").setup({
			colors = {
				cursorline = "#113032" -- This is optional. The default cursorline color is based on the background
			},
			options = {
				cursorline = true,
				transparency = false,
			}
		})
		vim.cmd("colorscheme onedark")
	end
}
