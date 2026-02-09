vim.o.background = "dark"
require("catppuccin").setup({
	flavour = "mocha",
	custom_highlights = function(colors)
		return {
			-- Treesitter & Syntax
			["@variable"] = { link = "@variable.parameter" },
			["@punctuation.bracket"] = { fg = colors.overlay0 },
			TreesitterContext = { bg = colors.mantle },
			TreesitterContextLineNumber = { fg = colors.green, bg = colors.mantle },

			-- UI 基础
			LineNr = { fg = colors.surface1 },
			CursorLineNr = { fg = colors.mauve, bold = true },
			Visual = { bg = colors.surface1 },

			-- Telescope
			TelescopeSelectionCaret = { fg = colors.red },
			TelescopePromptPrefix = { fg = colors.red },
			TelescopeMatching = { fg = colors.red, bold = true, underline = true },
			TelescopeSelection = { bg = colors.surface1, fg = colors.mauve, bold = true },
			TelescopePromptTitle = { fg = colors.crust, bg = colors.red, bold = true },
			TelescopeResultsTitle = { fg = colors.crust, bg = colors.blue, bold = true },
			TelescopePreviewTitle = { fg = colors.crust, bg = colors.green, bold = true },

			-- TabLine / StatusLine
			TabLineFill = { bg = colors.base },
			TabLineSel = { fg = colors.mauve, bg = colors.surface1, bold = true, italic = true },
			TabProject = { fg = colors.crust, bg = colors.mauve, bold = true },

			StatusLineNormal = { link = "TabProject" },
			StatusLineInsert = { fg = colors.green, bold = true },
			StatusLineVisual = { fg = colors.yellow, bold = true },
			StatusLineCmd = { fg = colors.blue, bold = true },
			StatusLineReplace = { fg = colors.red, bold = true },

			-- MiniDiff
			-- MiniDiffSignAdd = { fg = colors.green },
			-- MiniDiffSignChange = { fg = colors.yellow },
			-- MiniDiffSignDelete = { fg = colors.red },

			-- Diagnostics
			-- DiagnosticError = { fg = colors.red },
			-- DiagnosticWarn = { fg = colors.yellow },
			-- DiagnosticInfo = { fg = colors.blue },
			-- DiagnosticHint = { fg = colors.sky },
		}
	end,
})

vim.cmd.colorscheme("catppuccin")

-- 终端颜色同步到 Catppuccin
local p = require("catppuccin.palettes").get_palette("mocha")
local colors = {
	p.mantle, -- 0 Black
	p.red, -- 1 Red
	p.green, -- 2 Green
	p.yellow, -- 3 Yellow
	p.blue, -- 4 Blue
	p.mauve, -- 5 Magenta
	p.sky, -- 6 Cyan
	p.text, -- 7 White
	p.surface1, -- 8 Bright Black
	p.red, -- 9 Bright Red
	p.green, -- 10 Bright Green
	p.yellow, -- 11 Bright Yellow
	p.blue, -- 12 Bright Blue
	p.mauve, -- 13 Bright Magenta
	p.sky, -- 14 Bright Cyan
	p.text, -- 15 Bright White
}

for i, color in ipairs(colors) do
	vim.g["terminal_color_" .. (i - 1)] = color
end
