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

require('onedarkpro').setup({
	colors = {
		cursorline = '#303442' -- 自定义光标行颜色 (可选，默认基于背景)
	},
	options = {
		cursorline = true -- 启用 onedarkpro 对光标行的着色
	}
})
vim.cmd.colorscheme('onedark') -- 应用 onedark 主题


-- 加载功能模块配置 (Loading Functional Plugin Configurations)
require('plugins.Ui')        -- 用户界面和外观
require('plugins.lsp')       -- 语言服务器协议 (LSP)
require('plugins.editor')    -- 编辑器增强功能
-- require('plugins.dap')       -- 调试适配器协议 (DAP)
require('plugins.llm.codecompanion') -- 大型语言模型相关插件
