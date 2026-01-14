--  ██╗   ██╗██╗
--  ██║   ██║██║
--  ██║   ██║██║
--  ██║   ██║██║
--  ╚██████╔╝██║
--   ╚═════╝ ╚═╝
-- UI & Appearance
-- Themes / Statusline / Tabs / Notifications / Finder
-- ============================================================================

-- ============================================================================
-- 0. 依赖与工具 (Deps & Utils)
-- ============================================================================
local map = require("utils.map").map

-- ============================================================================
-- 1. Which-Key (Keymap Helper)
-- ============================================================================
require("which-key").setup({ preset = "modern" })

-- ============================================================================
-- 2. Bufferline (Tabs)
-- ============================================================================
local function diagnostics_indicator(count, level)
	local icon = level:match("error") and " " or " "
	return (" %s%d"):format(icon, count)
end

require("bufferline").setup({
	options = {
		mode = "tabs",
		numbers = "ordinal",
		diagnostics = "nvim_lsp",
		diagnostics_indicator = diagnostics_indicator,
		indicator = { icon = "▎ ", style = "icon" },
		tab_size = 12,
		padding = 0,
	},
})

-- ============================================================================
-- 3. Notify (Notifications)
-- ============================================================================
require("notify").setup({
	timeout = 1500,
	render = "compact",
	icons = { ERROR = "✘ ", WARN = "󱓈 ", INFO = "󰋽 ", DEBUG = "󰛩 ", TRACE = "󰓎 " },
})
vim.notify = require("notify")

-- ============================================================================
-- 4. Lualine (Statusline)
-- ============================================================================
local function short_cwd(max_len)
	local dir = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
	return (#dir > max_len) and (dir:sub(1, max_len) .. "...") or dir
end

require("lualine").setup({
	sections = {
		lualine_a = { {
			function()
				return short_cwd(10)
			end,
			icon = "󰉖",
		}, "filename" },
		lualine_b = { "branch" },
		lualine_c = { "diff", "diagnostics" },
		lualine_x = { "filesize", "filetype" },
		lualine_y = { "progress" },
		lualine_z = { "location" },
	},
})
