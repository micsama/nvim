-- ~/.config/nvim/lua/component/utils.lua
local M = {}
local api = vim.api

-- 1. 统一图标库
M.icons = {
	-- Tabline Legacy
	SELECTED   = "󰄲 ", UNSELECTED = "󰄱 ", MODIFIED = " 󰷫▕", SEPARATOR = " ▕", CWD = " ",
	-- Statusline & Git
	git = {
		branch  = "",
		user    = " ",
		added   = " ", -- 对应 mini.diff add
		changed = " ", -- 对应 mini.diff change
		deleted = " ", -- 对应 mini.diff delete
	},
	-- LSP & Diagnostics
	lsp = { server = " " },
	diag = {
		[vim.diagnostic.severity.ERROR] = { icon = " ✘", hl = "DiagnosticError" },
		[vim.diagnostic.severity.WARN]  = { icon = " 󱓈", hl = "DiagnosticWarn" },
		[vim.diagnostic.severity.INFO]  = { icon = " 󰋽", hl = "DiagnosticInfo" },
		[vim.diagnostic.severity.HINT]  = { icon = " 󰛩", hl = "DiagnosticHint" },
	},
	misc = { file = " ", ronly = "" }
}

-- 2. Mini Icons 包装 (安全调用)
local has_icons, mini_icons = pcall(require, "mini.icons")
function M.get_icon(category, name)
	if has_icons then
		return mini_icons.get(category, name)
	end
	return "", "" -- Fallback
end

-- 3. 高亮合成器 (核心组件)
local hl_cache = {}

function M.reset_hl_cache()
	hl_cache = {}
end

-- 参数 attr 可以是布尔值(兼容旧代码) 或 table { bold=true, italic=true }
function M.get_compound_hl(fg_name, bg_name, attr)
	local is_bold = (attr == true) or (type(attr) == "table" and attr.bold)
	local is_italic = (type(attr) == "table" and attr.italic)

	-- 生成缓存 Key：FG_BG_BOLD_ITALIC
	local key = string.format("%s_%s_%s_%s", fg_name, bg_name or "NONE", tostring(is_bold), tostring(is_italic))
	if hl_cache[key] then return hl_cache[key] end

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
