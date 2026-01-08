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

require("catppuccin").setup({
	highlight_overrides = {
		all = function(colors)
			return {
				-- Core / Editor
				["@variable"] = { link = "@variable.parameter" }, -- 变量高亮：与参数风格对齐，降低噪声
				["LineNr"] = { fg = colors.overlay0 }, -- 行号：弱化到 overlay0，避免抢内容视线
				["CursorLineNr"] = { fg = colors.mauve, bold = true }, -- 当前行号：强调定位（mauve + bold）

				-- Telescope
				TelescopeMatching = { fg = colors.red, bold = true }, -- 匹配高亮：红色+加粗，提升命中感
				TelescopeSelection = { bg = colors.surface1, fg = colors.lavender, bold = true }, -- 选中行：surface1 背景 + lavender 前景
				TelescopeSelectionCaret = { fg = colors.red }, -- 选中 caret：红色箭头，定位更清晰
				TelescopePromptPrefix = { fg = colors.red }, -- 提示符前缀：红色，与匹配色一致
				TelescopePromptTitle = { fg = colors.base, bg = colors.red, bold = true }, -- Prompt 标题：红底，最高优先级
				TelescopeResultsTitle = { fg = colors.base, bg = colors.lavender, bold = true }, -- Results 标题：lavender 区分面板
				TelescopePreviewTitle = { fg = colors.base, bg = colors.green, bold = true }, -- Preview 标题：green 提示“预览区域”
			}
		end,
	},
})

vim.cmd.colorscheme("catppuccin-mocha") -- 应用 catppuccin-mocha  主题

-- 加载功能模块配置 (Loading Functional Plugin Configurations)
require("plugins.Ui") -- 用户界面和外观
require("plugins.editor") -- 编辑器增强功能
require("plugins.lsp") -- 语言服务器协议 (LSP)
-- require('plugins.dap')       -- 调试适配器协议 (DAP)
require("plugins.llm.codecompanion") -- 大型语言模型相关插件
