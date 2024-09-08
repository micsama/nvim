return {
	{
		"shellRaining/hlchunk.nvim",
		init = function()
			vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, { pattern = "*", command = "EnableHL", })
			require('hlchunk').setup({
				chunk = {
					enable = true,
					use_treesitter = true,
					style = {
						{ fg = "#b06d9c" },
					},
				},
				blank = {
					enable = true,
				},
				-- TODO 等官方修复bug
				-- line_num = {
				-- 	enable = true,
				-- 	use_treesitter = true,
				-- },
			})
		end
	},
}

