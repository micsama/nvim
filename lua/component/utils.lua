-- ~/.config/nvim/lua/component/utils.lua
local M = {}
local api = vim.api

M.icons = {
	diag = {
		[vim.diagnostic.severity.ERROR] = { icon = " ✘", hl = "DiagnosticError" },
		[vim.diagnostic.severity.WARN] = { icon = " 󱓈", hl = "DiagnosticWarn" },
		[vim.diagnostic.severity.INFO] = { icon = " 󰋽", hl = "DiagnosticInfo" },
		[vim.diagnostic.severity.HINT] = { icon = " 󰛩", hl = "DiagnosticHint" },
	},
}

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

function M.get_file_icon_with_bg(buf, bg_name, attr)
	local path = api.nvim_buf_get_name(buf)
	local icon, icon_hl = M.get_icon("file", path)

	if icon == "" then
		return "", bg_name
	end

	local final_hl = M.get_compound_hl(icon_hl, bg_name, attr)
	return icon, final_hl
end

return M
