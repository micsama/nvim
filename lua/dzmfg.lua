-- filepath: lua/dzmfg.lua
--  ██████╗ ███████╗███╗   ███╗███████╗ ██████╗
-- ██╔════╝ ██╔════╝████╗ ████║██╔════╝██╔════╝
-- ██║  ███╗█████╗  ██╔████╔██║█████╗  ██║  ███╗
-- ██║   ██║██╔══╝  ██║╚██╔╝██║██╔══╝  ██║   ██║
-- ╚██████╔╝███████╗██║ ╚═╝ ██║███████╗╚██████╔╝
--  ╚═════╝ ╚══════╝╚═╝     ╚═╝╚══════╝ ╚═════╝
-- Neovim Configuration by dzmfg
-- 🚀 Powered by LunarVim-inspired setup
-- 🎨 Themes, LSP, DAP, and AI companions ready!
-- 📅 Last updated: 2025-10-16

-- 加载功能模块配置 (Loading Functional Plugin Configurations)
-- require('plugins.dap')       -- 调试适配器协议 (DAP)


local map = require("utils.map").map
local lsp_maps = require("config.keymaps").lsp_maps


vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		require("config.lspconfig")
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
		vim.notify("lspattach")
		vim.iter(lsp_maps):each(function(m)
			map(unpack(m))
		end)
	end,
})
