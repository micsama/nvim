-- ===========================================================================
-- UI 与外观：状态栏 / 标签页 / 通知 / 查找器
-- ===========================================================================
-- ============================================================================
-- 1) Which-Key (Keymap Helper)
-- ============================================================================
require("which-key").setup({ preset = "modern" })
require("hlchunk").setup({ chunk = { delay = 110, enable = true } })

-- ============================================================================
-- 2) Notify (Notifications)
-- ============================================================================
require("notify").setup({
	timeout = 1500,
	render = "compact",
	background_colour = require("catppuccin.palettes").get_palette("mocha").base,
	icons = { ERROR = "✘ ", WARN = "󱓈 ", INFO = "󰋽 ", DEBUG = "󰛩 ", TRACE = "󰓎 " },
})
vim.notify = require("notify")

-- ============================================================================
-- 5) UI2 (实验性原生消息/命令行 UI，替代 Noice)
-- ============================================================================
-- 在 UIEnter 后启用 ui2，避免与 Neovide 冲突导致 tabline 消失
-- ref: https://github.com/neovide/neovide/issues/3446
vim.api.nvim_create_autocmd("UIEnter", {
	once = true,
	callback = function()
		-- msg 超时/最大高度改由 'messagesopt' 选项控制（ui2 新版 API，cmd.height 字段已废弃）
		vim.opt.messagesopt:append("timeout:4000,maxheight:50")
		require("vim._core.ui2").enable({
			enable = true,
			msg = {
				targets = "cmd",
				msg = { height = 0.5 },
				pager = { height = 0.999 },
				dialog = { height = 0.5 },
			},
		})
	end,
})
