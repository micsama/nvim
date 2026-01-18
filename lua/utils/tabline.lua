local M = {}
local hl_cache, diag_cache, cached_result = {}, {}, ""
local dirty, scheduled = true, false
local icons_ok, icons = pcall(require, "mini.icons")

local DIAG_MAP = { -- 诊断优先级：Error > Warn > Info > Hint
	{ vim.diagnostic.severity.ERROR, " ✘", "DiagnosticError" },
	{ vim.diagnostic.severity.WARN, " 󱓈", "DiagnosticWarn" },
	{ vim.diagnostic.severity.INFO, " 󰋽", "DiagnosticInfo" },
	{ vim.diagnostic.severity.HINT, " 󰛩", "DiagnosticHint" },
}

local function mark_dirty() -- 合并调度，防止事件风暴
	dirty = true
	if not scheduled then
		scheduled = true
		vim.schedule(function()
			scheduled = false
			vim.cmd.redrawtabline()
		end)
	end
end

local function get_hl(fg, bg) -- 缓存合成高亮组
	local key = fg .. "_" .. bg
	if not hl_cache[key] then
		local hl = vim.tbl_extend("force", vim.api.nvim_get_hl(0, { name = fg, link = false }), {
			bg = vim.api.nvim_get_hl(0, { name = bg, link = false }).bg,
			bold = bg:find("Sel") and true or nil,
		})
		vim.api.nvim_set_hl(0, "TabHL_" .. key, hl)
		hl_cache[key] = "TabHL_" .. key
	end
	return hl_cache[key]
end

-- 事件监听 ────────────────────────────────────────────────────────────────────
local g = vim.api.nvim_create_augroup("Tabline", { clear = true })

vim.api.nvim_create_autocmd("ColorScheme", {
	group = g,
	callback = function()
		hl_cache = {}
		mark_dirty()
	end,
})

vim.api.nvim_create_autocmd(
	{ "BufEnter", "BufWritePost", "BufModifiedSet", "TabEnter", "TabNew", "TabClosed" },
	{ group = g, callback = mark_dirty }
)

vim.api.nvim_create_autocmd("DiagnosticChanged", { -- 诊断变化时更新缓存
	group = g,
	callback = function(a)
		diag_cache[a.buf] = nil
		for _, d in ipairs(DIAG_MAP) do
			if (vim.diagnostic.count(a.buf)[d[1]] or 0) > 0 then
				diag_cache[a.buf] = { d[2], d[3] } -- { icon, hl_group }
				break
			end
		end
		mark_dirty()
	end,
})

vim.api.nvim_create_autocmd("BufDelete", {
	group = g,
	callback = function(a)
		diag_cache[a.buf] = nil
	end,
})

-- 渲染主函数 ──────────────────────────────────────────────────────────────────
function M.render()
	if not dirty then
		return cached_result
	end -- 缓存命中
	dirty = false

	local tabs, cur = vim.api.nvim_list_tabpages(), vim.api.nvim_get_current_tabpage()

	local name_cnt = {} -- 预扫描：检测重复文件名
	for _, tab in ipairs(tabs) do
		local path = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_get_win(tab)))
		local name = path ~= "" and vim.fn.fnamemodify(path, ":t") or "[No Name]"
		name_cnt[name] = (name_cnt[name] or 0) + 1
	end

	local res = { ("%%#%s#▌%%#TabLine# "):format(get_hl("Special", "TabLine")) }

	for i, tab in ipairs(tabs) do
		local sel = tab == cur
		local hl = sel and "TabLineSel" or "TabLine"
		local buf = vim.api.nvim_win_get_buf(vim.api.nvim_tabpage_get_win(tab))
		local path = vim.api.nvim_buf_get_name(buf)
		local diag = diag_cache[buf] or { "", hl } -- { icon, hl_group }

		local icon, icon_hl = "", hl -- 文件图标
		if icons_ok and path ~= "" then
			icon, icon_hl = icons.get("file", path)
		end

		local name = path ~= "" and vim.fn.fnamemodify(path, ":t") or "[No Name]" -- 文件名
		if path ~= "" and name_cnt[name] > 1 then -- 重复时加父目录
			local p = vim.fn.fnamemodify(path, ":p:h:t")
			if p ~= "" and p ~= "." then
				name = p .. "/" .. name
			end
		end
		if #name > 20 then
			name = vim.fn.strcharpart(name, 0, 19) .. "…"
		end

		res[#res + 1] = ("%%%dT%%#%s# %s%d %%#%s#%s %%#%s#%s%%#%s#%s%%#%s#%s ▕"):format(
			i,
			hl, -- prefix: 直接用 TabLine/TabLineSel，不再合成
			sel and "󰄲 " or "󰄱 ",
			i,
			get_hl(icon_hl, hl),
			icon,
			get_hl(diag[2], hl),
			name:gsub("%%", "%%%%"),
			get_hl(diag[2], hl),
			diag[1],
			get_hl("DiagnosticOk", hl),
			vim.bo[buf].modified and " 󰷫" or ""
		)
	end

	res[#res + 1] = "%#TabLineFill#%T"
	cached_result = table.concat(res)
	return cached_result
end

return M
