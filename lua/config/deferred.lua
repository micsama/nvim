-- ===========================================================================
-- 延迟加载：依赖插件的初始化
-- ===========================================================================

local map = require("utils.map").map
local lsp_maps = require("config.keymaps").lsp_maps

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		require("config.lsp")
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	callback = function(args)
		require("plugins.llm.codecompanion")
		pcall(vim.treesitter.start, args.buf)
	end,
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("LspKeymaps", { clear = true }),
	once = true,
	callback = function()
		vim.iter(lsp_maps):each(function(m)
			map(unpack(m))
		end)
	end,
})
