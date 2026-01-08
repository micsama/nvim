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
				["@variable"] = { link = "@variable.parameter" },
				["LineNr"] = { fg = colors.overlay0 },
				["CursorLineNr"] = { fg = colors.mauve },
			}
		end,
	},
})

vim.cmd.colorscheme("catppuccin-mocha") -- 应用 onedark 主题

local get_root = require("utils").get_root
vim.api.nvim_create_autocmd("BufEnter", {
    callback = function(ctx)
        local root = get_root(ctx.buf)
        if root and root ~= vim.fn.getcwd() then
            vim.cmd.tcd(root)
            vim.notify(root, 2, { title = "CWD" })
        end
    end,
})

-- 加载功能模块配置 (Loading Functional Plugin Configurations)
require("plugins.Ui") -- 用户界面和外观
require("plugins.editor") -- 编辑器增强功能
require("plugins.lsp") -- 语言服务器协议 (LSP)
-- require('plugins.dap')       -- 调试适配器协议 (DAP)
require("plugins.llm.codecompanion") -- 大型语言模型相关插件
