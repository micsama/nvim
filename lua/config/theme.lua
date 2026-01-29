-- ===========================================================================
-- 主题配置：基于 vim.iter 的动态高亮加载
-- ===========================================================================
vim.o.background = "dark"

local function apply_theme_overrides()
	-- 1. 辅助函数：动态抓取当前主题的颜色
	local function get_color(name, attr)
		local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
		return hl[attr]
	end

	-- 2. 准备颜色变量 (从当前加载的 catppuccin 中实时提取)
	local cp = {
		base     = get_color("Normal", "bg"),
		mauve    = get_color("Keyword", "fg"),
		red      = get_color("Error", "fg"),
		green    = get_color("String", "fg"),
		lavender = get_color("CursorLineNr", "fg"),
		overlay0 = get_color("Conceal", "fg"),
		surface0 = get_color("Pmenu", "bg"),
		surface1 = get_color("Visual", "bg"),
		crust    = get_color("StatusLine", "bg"),
		subtext1 = get_color("Special", "fg"),
	}

	-- 3. 定义高亮组列表 (声明式结构)
	local highlight_groups = { 
		-- { "组名", { 配置参数 } }
		{ "@variable",                   { link = "@variable.parameter" } },
		{ "LineNr",                      { fg = cp.overlay0 } },
		{ "CursorLineNr",                { fg = cp.mauve, bold = true } },
		{ "@punctuation.bracket",        { fg = cp.subtext1 } },
		{ "TreesitterContext",           { bg = cp.surface0 } },
		{ "TreesitterContextLineNumber", { fg = cp.green, bg = cp.surface0 } },
		{ "DiffChange",                  { bg = "#6b5a39" } }, -- 依然保留这一个特殊硬编码

		-- Telescope
		{ "TelescopeSelectionCaret",     { fg = cp.red } },
		{ "TelescopePromptPrefix",       { fg = cp.red } },
		{ "TelescopeMatching",           { fg = cp.red, bold = true, underline = true } },
		{ "TelescopeSelection",          { bg = cp.surface1, fg = cp.lavender, bold = true } },
		{ "TelescopePromptTitle",        { fg = cp.base, bg = cp.red, bold = true } },
		{ "TelescopeResultsTitle",       { fg = cp.base, bg = cp.lavender, bold = true } },
		{ "TelescopePreviewTitle",       { fg = cp.base, bg = cp.green, bold = true } },

		-- TabLine
		{ "TabLineFill",                 { bg = cp.base } },
		{ "TabLineSel", { fg = cp.mauve, bg = cp.surface1, bold = true, italic = true } },
		{ "TabProject", { fg = cp.crust, bg = cp.mauve, bold = true } },

	}

	-- 4. 使用 vim.iter 进行循环加载
	vim.iter(highlight_groups):each(function(group)
		vim.api.nvim_set_hl(0, group[1], {})
		vim.api.nvim_set_hl(0, group[1], group[2])
	end)
end

-- 5. 绑定自动命令
vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "catppuccin",
	callback = apply_theme_overrides,
})

-- 应用主题
vim.cmd.colorscheme("catppuccin")
