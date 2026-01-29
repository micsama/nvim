-- ===========================================================================
-- 主题配置：基于静态 Palette 的高亮修正
-- ===========================================================================
local utils = require("component.utils")
local p = utils.palette

vim.o.background = "dark"

local function apply_theme_overrides()
	-- 1. 获取静态调色板

	-- 2. 定义高亮组列表
	local highlight_groups = {
		-- Treesitter & Syntax
		{ "@variable", { link = "@variable.parameter" } },
		{ "@punctuation.bracket", { fg = p.overlay } },
		{ "TreesitterContext", { bg = p.mantle } },
		{ "TreesitterContextLineNumber", { fg = p.green, bg = p.mantle } },

		-- UI 基础
		{ "LineNr", { fg = p.surface1 } },
		{ "CursorLineNr", { fg = p.magenta, bold = true } },
		{ "Visual", { bg = p.surface1 } },

		-- Telescope (使用 Palette 定制)
		{ "TelescopeSelectionCaret", { fg = p.red } },
		{ "TelescopePromptPrefix", { fg = p.red } },
		{ "TelescopeMatching", { fg = p.red, bold = true, underline = true } },
		{ "TelescopeSelection", { bg = p.surface1, fg = p.magenta, bold = true } },
		{ "TelescopePromptTitle", { fg = p.crust, bg = p.red, bold = true } },
		{ "TelescopeResultsTitle", { fg = p.crust, bg = p.blue, bold = true } },
		{ "TelescopePreviewTitle", { fg = p.crust, bg = p.green, bold = true } },

		-- TabLine (核心 UI)
		{ "TabLineFill", { bg = p.base } },
		{ "TabLineSel", { fg = p.magenta, bg = p.surface1, bold = true, italic = true } },
		{ "TabProject", { fg = p.crust, bg = p.magenta, bold = true } },

		-- MiniDiff (Git Signs)
		{ "MiniDiffSignAdd", { fg = p.green } },
		{ "MiniDiffSignChange", { fg = p.yellow } },
		{ "MiniDiffSignDelete", { fg = p.red } },
	}

	-- 3. 应用高亮
	for _, group in ipairs(highlight_groups) do
		vim.api.nvim_set_hl(0, group[1], group[2])
	end
end

-- 4. 绑定自动命令
local grp = vim.api.nvim_create_augroup("ThemeOverrides", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
	group = grp,
	callback = apply_theme_overrides,
})

-- 5. 应用默认主题
pcall(vim.cmd.colorscheme, "catppuccin")

-- 6. 初始化终端颜色 (全局变量，只需设置一次)
local colors = {
	p.mantle, -- 0 Black
	p.red, -- 1 Red
	p.green, -- 2 Green
	p.yellow, -- 3 Yellow
	p.blue, -- 4 Blue
	p.magenta, -- 5 Magenta
	p.cyan, -- 6 Cyan
	p.text, -- 7 White
	p.surface1, -- 8 Bright Black
	p.red, -- 9 Bright Red
	p.green, -- 10 Bright Green
	p.yellow, -- 11 Bright Yellow
	p.blue, -- 12 Bright Blue
	p.magenta, -- 13 Bright Magenta
	p.cyan, -- 14 Bright Cyan
	p.text, -- 15 Bright White
}

for i, color in ipairs(colors) do
	vim.g["terminal_color_" .. (i - 1)] = color
end
