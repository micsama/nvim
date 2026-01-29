-- ~/.config/nvim/lua/component/utils.lua
local M = {}
local api = vim.api

-- =============================================================================
-- 1. 调色板 (Palette)
-- =============================================================================
M.palette = {
	-- 背景色系
	base = "#1e1e2e",
	mantle = "#181825",
	crust = "#11111b",
	surface0 = "#313244",
	surface1 = "#45475a",
	selection = "#585b70",

	-- 前景色系
	text = "#cdd6f4",
	subtext = "#a6adc8",
	overlay = "#7f849c",

	-- 标准颜色
	red = "#f38ba8",
	green = "#a6e3a1",
	yellow = "#f9e2af",
	blue = "#89b4fa",
	magenta = "#cba6f7",
	cyan = "#89dceb",
	orange = "#fab387",
	lavender = "#b4befe",
}

-- =============================================================================
-- 2. 统一图标库
-- =============================================================================
M.icons = {
	SELECTED = "󰄲 ",
	UNSELECTED = "󰄱 ",
	MODIFIED = " 󰷫▕",
	DUPLICATE = " 󰆏",
	SEPARATOR = " ▕",
	CWD = " ",
	git = {
		branch = "",
		user = " ",
		added = "+",
		changed = "~",
		deleted = "-",
	},
	diag = {
		[vim.diagnostic.severity.ERROR] = { icon = " ✘", hl = "DiagnosticError" },
		[vim.diagnostic.severity.WARN] = { icon = " 󱓈", hl = "DiagnosticWarn" },
		[vim.diagnostic.severity.INFO] = { icon = " 󰋽", hl = "DiagnosticInfo" },
		[vim.diagnostic.severity.HINT] = { icon = " 󰛩", hl = "DiagnosticHint" },
	},
	misc = { ronly = "", top = "󰘣", bottom = "󰘡" },
	R_ROUND = "",
	L_ROUND = "",
}

-- =============================================================================
-- 3. 工具函数
-- =============================================================================

local has_icons, mini_icons = pcall(require, "mini.icons")

function M.get_icon(category, name)
	if has_icons then
		return mini_icons.get(category, name)
	end
	return "", ""
end

local hl_cache = {}

function M.reset_hl_cache()
	hl_cache = {}
end

---合成高亮组：混合指定的前景、背景及样式
function M.get_compound_hl(fg_name, bg_name, attr)
	local is_bold = (attr == true) or (type(attr) == "table" and attr.bold)
	local is_italic = (type(attr) == "table" and attr.italic)

	local key = string.format("%s_%s_%s_%s", fg_name, bg_name or "NONE", tostring(is_bold), tostring(is_italic))
	if hl_cache[key] then
		return hl_cache[key]
	end

	local name = "CmpHL_" .. key:gsub("[^%w_]", "_")
	local fg_def = api.nvim_get_hl(0, { name = fg_name, link = false })
	local bg_def = bg_name and api.nvim_get_hl(0, { name = bg_name, link = false }) or {}

	api.nvim_set_hl(0, name, {
		fg = fg_def.fg,
		bg = bg_def.bg,
		bold = is_bold,
		italic = is_italic,
	})

	hl_cache[key] = name
	return name
end

---获取融合了指定背景色的文件图标及其高亮组
---@param buf number Buffer handle
---@param bg_name string 背景高亮组名 (e.g. "StatusLine")
---@param attr? table|boolean 字体属性
---@return string icon, string hl_name
function M.get_file_icon_with_bg(buf, bg_name, attr)
	local path = api.nvim_buf_get_name(buf)
	local icon, icon_hl = M.get_icon("file", path)

	if icon == "" then
		return "", bg_name
	end

	-- 合成高亮: FG=图标原色, BG=传入的背景组颜色
	local final_hl = M.get_compound_hl(icon_hl, bg_name, attr)
	return icon, final_hl
end

return M
