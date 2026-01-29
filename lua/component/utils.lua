-- ~/.config/nvim/lua/component/utils.lua
local M = {}
local api = vim.api

-- =============================================================================
-- 1. 调色板 (Palette) & 终端颜色定义
-- =============================================================================

-- 集中管理颜色，便于 Theme/Statusline/Tabline 复用
M.palette = {
	-- Terminal Colors (Dracula 近似值)
	term = {
		black = "#000000", -- 0
		red = "#FF5555", -- 1
		green = "#50FA7B", -- 2
		yellow = "#F1FA8C", -- 3
		blue = "#BD93F9", -- 4
		magenta = "#FF79C6", -- 5
		cyan = "#8BE9FD", -- 6
		white = "#BFBFBF", -- 7
		bright_black = "#4D4D4D", -- 8
		bright_red = "#FF6E67", -- 9
		bright_green = "#5AF78E", -- 10
		bright_yellow = "#F4F99D", -- 11
		bright_blue = "#CAA9FA", -- 12
		bright_magenta = "#FF92D0", -- 13
		bright_cyan = "#9AEDFE", -- 14
		bright_white = "#FFFFFF", -- 15
	},
	-- 自定义 UI 颜色 (从原 Theme 中提取)
	ui = {
		diff_change_bg = "#6b5a39",
	},
}

---设置 Vim 全局终端颜色 (vim.g.terminal_color_*)
---应由 theme.lua 调用，避免在 require 时产生副作用
function M.setup_terminal_colors()
	local p = M.palette.term
	-- 顺序必须严格对应 0-15
	local colors = {
		p.black,
		p.red,
		p.green,
		p.yellow,
		p.blue,
		p.magenta,
		p.cyan,
		p.white,
		p.bright_black,
		p.bright_red,
		p.bright_green,
		p.bright_yellow,
		p.bright_blue,
		p.bright_magenta,
		p.bright_cyan,
		p.bright_white,
	}

	for i, color in ipairs(colors) do
		vim.g["terminal_color_" .. (i - 1)] = color
	end
end

-- =============================================================================
-- 2. 统一图标库
-- =============================================================================
M.icons = {
	-- Tabline Legacy
	SELECTED = "󰄲 ",
	UNSELECTED = "󰄱 ",
	MODIFIED = " 󰷫▕",
	DUPLICATE = " 󰆏",
	SEPARATOR = " ▕",
	CWD = " ",
	-- Statusline & Git
	git = {
		branch = "",
		user = " ",
		added = "+ ", -- 对应 mini.diff add
		changed = "~ ", -- 对应 mini.diff change
		deleted = "- ", -- 对应 mini.diff delete
	},
	-- LSP & Diagnostics
	lsp = { server = " " },
	diag = {
		[vim.diagnostic.severity.ERROR] = { icon = " ✘", hl = "DiagnosticError" },
		[vim.diagnostic.severity.WARN] = { icon = " 󱓈", hl = "DiagnosticWarn" },
		[vim.diagnostic.severity.INFO] = { icon = " 󰋽", hl = "DiagnosticInfo" },
		[vim.diagnostic.severity.HINT] = { icon = " 󰛩", hl = "DiagnosticHint" },
	},
	misc = { ronly = "" },
}

-- =============================================================================
-- 3. 工具函数
-- =============================================================================

-- Mini Icons 包装 (安全调用)
local has_icons, mini_icons = pcall(require, "mini.icons")
function M.get_icon(category, name)
	if has_icons then
		return mini_icons.get(category, name)
	end
	return "", "" -- Fallback
end

-- 高亮合成器 (核心组件)
local hl_cache = {}

function M.reset_hl_cache()
	hl_cache = {}
end

---合成高亮组 (Compound Highlight)
---@param fg_name string 前景色高亮组名 (如 "String")
---@param bg_name string 背景色高亮组名 (如 "StatusLine")
---@param attr table|boolean 属性表 { bold=true, italic=true } 或 布尔值(仅Bold)
---@return string 生成的新高亮组名称
function M.get_compound_hl(fg_name, bg_name, attr)
	local is_bold = (attr == true) or (type(attr) == "table" and attr.bold)
	local is_italic = (type(attr) == "table" and attr.italic)

	-- 生成缓存 Key：FG_BG_BOLD_ITALIC
	local key = string.format("%s_%s_%s_%s", fg_name, bg_name or "NONE", tostring(is_bold), tostring(is_italic))
	if hl_cache[key] then
		return hl_cache[key]
	end

	-- 生成高亮组名称
	local name = "CmpHL_" .. key:gsub("[^%w_]", "_")

	-- 获取原始定义
	local fg_def = api.nvim_get_hl(0, { name = fg_name, link = false })
	local bg_def = api.nvim_get_hl(0, { name = bg_name, link = false })

	-- 合成新属性
	local def = {
		fg = fg_def.fg,
		bg = bg_def.bg,
		bold = is_bold,
		italic = is_italic,
	}

	api.nvim_set_hl(0, name, def)
	hl_cache[key] = name
	return name
end

return M
