local M = {}
local hl_cache = {}
local icons_ok, icons = pcall(require, "mini.icons")

local DIAG_MAP = {
	{ vim.diagnostic.severity.ERROR, "✘", "DiagnosticError" },
	{ vim.diagnostic.severity.WARN, "󱓈", "DiagnosticWarn" },
	{ vim.diagnostic.severity.INFO, "󰋽", "DiagnosticInfo" },
	{ vim.diagnostic.severity.HINT, "󰛩", "DiagnosticHint" },
}

-- 优化点：直接利用 tbl_extend 和 link=false 获取最终颜色，消除冗余赋值
local function get_hl_id(fg_group, bg_group)
	local key = fg_group .. "_" .. bg_group
	if hl_cache[key] then
		return hl_cache[key]
	end

	local fg_info = vim.api.nvim_get_hl(0, { name = fg_group, link = false })
	local bg_info = vim.api.nvim_get_hl(0, { name = bg_group, link = false })

	-- 0.12 最佳实践：直接合并，bg 覆盖 fg 的背景，保留所有其他属性（sp, underline, bold等）
	local new_hl = vim.tbl_extend("force", fg_info, { bg = bg_info.bg })

	if bg_group:find("Sel") then
		new_hl.bold = true
	end

	local hl_name = "TabHL_" .. key
	vim.api.nvim_set_hl(0, hl_name, new_hl)
	hl_cache[key] = hl_name
	return hl_name
end

vim.api.nvim_create_autocmd("ColorScheme", {
	callback = function()
		hl_cache = {}
	end,
})

function M.render()
	local tabs = vim.api.nvim_list_tabpages()
	local current_tab = vim.api.nvim_get_current_tabpage()

	-- 移除 #tabs == 0 的冗余判断，Neovim 运行时至少有 1 个 tab
	local res = { ("%%#%s#▎ %%#TabLine# "):format(get_hl_id("Special", "TabLine")) }
	for i, tab in ipairs(tabs) do
		local is_curr = (tab == current_tab)
		local base_hl = is_curr and "TabLineSel" or "TabLine"
		local win = vim.api.nvim_tabpage_get_win(tab)
		local buf = vim.api.nvim_win_get_buf(win)

		-- 1. 诊断获取 (移除 or 0，counts[key] 为 nil 时 if 自动判定为 false)
		local diag_icon, diag_hl = "", base_hl
		local counts = vim.diagnostic.count(buf)
		for _, d in ipairs(DIAG_MAP) do
			if counts[d[1]] then
				diag_icon, diag_hl = d[2], d[3]
				break
			end
		end

		-- 2. 文件信息
		local path = vim.api.nvim_buf_get_name(buf)
		local icon, icon_hl = "", base_hl
		if icons_ok and path ~= "" then
			icon, icon_hl = icons.get("file", path)
		end

		-- 3. 文件名 (使用 strcharpart 确保中文截断不乱码)
		local name = (path == "" and "[No Name]") or vim.fn.fnamemodify(path, ":t")
		name = name:gsub("%%", "%%%%")
		if #name > 16 then
			name = vim.fn.strcharpart(name, 0, 15) .. "…"
		end

		-- 4. 组装 (减少变量创建，直接在 table 中 format)
		table.insert(res, ("%%%dT"):format(i))
		local prefix_fg = is_curr and "Special" or diag_hl
		table.insert(res, ("%%#%s# %s%d "):format(get_hl_id(prefix_fg, base_hl), is_curr and "󰄲 " or "󰄱 ", i))
		table.insert(res, ("%%#%s#%s "):format(get_hl_id(icon_hl, base_hl), icon))
		table.insert(res, ("%%#%s#%s"):format(get_hl_id(diag_hl, base_hl), name))
		table.insert(res, ("%%#%s#%s"):format(get_hl_id(diag_hl, base_hl), diag_icon))
		-- 使用 get_option_value 替代 vim.bo，提升循环内的性能
		local mod = vim.api.nvim_get_option_value("modified", { buf = buf }) and " ●" or ""
		table.insert(res, ("%%#%s#%s ▕"):format(get_hl_id("DiagnosticOk", base_hl), mod))
	end

	table.insert(res, "%#TabLineFill#%T")
	return table.concat(res)
end

return M
