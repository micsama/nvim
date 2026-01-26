-- my tabline for neovim v0.12
local M = {}
local H = {}
local icons_ok, icons = pcall(require, "mini.icons")

-- 常量定义
local ICONS =
	{ SELECTED = "󰄲 ", UNSELECTED = "󰄱 ", MODIFIED = " 󰷫▕", SEPARATOR = " ▕", DUPLICATE = " " }

-- 按严重程度排序
local DIAG_ORDER = {
	{ vim.diagnostic.severity.ERROR, " ✘", "DiagnosticError" },
	{ vim.diagnostic.severity.WARN, " 󱓈", "DiagnosticWarn" },
	{ vim.diagnostic.severity.INFO, " 󰋽", "DiagnosticInfo" },
	{ vim.diagnostic.severity.HINT, " 󰛩", "DiagnosticHint" },
}

local state = {
	hl_cache = {},
	diag_cache = {},
	name_cnt = {},
	buf_cnt = {},
	scroll_offset = 0,
	timer = vim.uv.new_timer(),
}

local function get_hl(fg, bg, is_bold)
	local key = fg .. "_" .. bg .. (is_bold and "_b" or "")
	if not state.hl_cache[key] then
		local fg_def = vim.api.nvim_get_hl(0, { name = fg, link = false })
		local bg_def = vim.api.nvim_get_hl(0, { name = bg, link = false })
		local name = "TabHL_" .. key
		vim.api.nvim_set_hl(0, name, { fg = fg_def.fg, bg = bg_def.bg, bold = is_bold })
		state.hl_cache[key] = name
	end
	return state.hl_cache[key]
end

local function update_tab_stats(tabs)
	state.name_cnt = {}
	state.buf_cnt = {}
	for _, t in ipairs(tabs) do
		local win = vim.api.nvim_tabpage_get_win(t)
		local buf = vim.api.nvim_win_get_buf(win)
		local name = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t")
		name = name == "" and "[No Name]" or name

		state.name_cnt[name] = (state.name_cnt[name] or 0) + 1
		state.buf_cnt[buf] = (state.buf_cnt[buf] or 0) + 1
	end
end

function H.prepare_tab_data(i, tab, cur)
	local win = vim.api.nvim_tabpage_get_win(tab)
	local buf = vim.api.nvim_win_get_buf(win)
	local path = vim.api.nvim_buf_get_name(buf)
	local is_sel = tab == cur
	local base_hl = is_sel and "TabLineSel" or "TabLine"

	local diag_data = state.diag_cache[buf] or { "", base_hl }

	local icon, icon_hl = "", base_hl
	if icons_ok and path ~= "" then
		icon, icon_hl = icons.get("file", path)
	end

	local name = path ~= "" and vim.fn.fnamemodify(path, ":t") or "[No Name]"
	if path ~= "" and (state.name_cnt[name] or 0) > 1 then
		local p = vim.fn.fnamemodify(path, ":p:h:t")
		if p ~= "" and p ~= "." then
			name = p .. "/" .. name
		end
	end
	if #name > 20 then
		name = vim.fn.strcharpart(name, 0, 19) .. "…"
	end

	local indicator = is_sel and ICONS.SELECTED or ICONS.UNSELECTED
	local modified_icon = vim.bo[buf].modified and ICONS.MODIFIED or ICONS.SEPARATOR
	local dup_icon = (state.buf_cnt[buf] or 0) > 1 and ICONS.DUPLICATE or ""

	local d = {
		id = i,
		base_hl = base_hl,
		indicator = indicator,
		icon_hl = get_hl(icon_hl, base_hl, is_sel),
		icon = icon,
		name_hl = is_sel and base_hl or get_hl(diag_data[2], base_hl, false),
		name = name:gsub("%%", "%%%%"),
		diag_hl = get_hl(diag_data[2], base_hl, is_sel),
		diag_icon = diag_data[1],
		modified_hl = get_hl("DiagnosticOk", base_hl, is_sel),
		modified_content = dup_icon .. modified_icon,
	}

	local width = 4
		+ (i >= 10 and 2 or 1)
		+ vim.fn.strdisplaywidth(icon)
		+ vim.fn.strdisplaywidth(name)
		+ vim.fn.strdisplaywidth(diag_data[1])
		+ vim.fn.strdisplaywidth(d.modified_content)

	return d, width
end

function M.render()
	local tabs = vim.api.nvim_list_tabpages()
	local cur = vim.api.nvim_get_current_tabpage()
	update_tab_stats(tabs)

	local items, cur_idx = {}, 1
	for i, t in ipairs(tabs) do
		local d, w = H.prepare_tab_data(i, t, cur)
		items[i] = { data = d, width = w }
		if t == cur then
			cur_idx = i
		end
	end

	local avail = vim.o.columns - 4

	local function get_range(off)
		local w, last = 0, off + 1
		for i = off + 1, #items do
			if w + items[i].width > avail then
				break
			end
			w, last = w + items[i].width, i
		end
		return off + 1, last
	end

	local first, last = get_range(state.scroll_offset)
	if cur_idx < first then
		state.scroll_offset = cur_idx - 1
	elseif cur_idx > last then
		while cur_idx > last and state.scroll_offset < #tabs do
			state.scroll_offset = state.scroll_offset + 1
			first, last = get_range(state.scroll_offset)
		end
	end

	local res = { "%#Special#▌%#TabLine# " }
	for i = first, last do
		local d = items[i].data
		res[#res + 1] = string.format(
			"%%%dT%%#%s# %s%d %%#%s#%s %%#%s#%s%%#%s#%s%%#%s#%s",
			d.id,
			d.base_hl,
			d.indicator,
			d.id,
			d.icon_hl,
			d.icon,
			d.name_hl,
			d.name,
			d.diag_hl,
			d.diag_icon,
			d.modified_hl,
			d.modified_content
		)
	end

	return table.concat(res) .. "%#TabLineFill#%T"
end

local function async_update_diag(buf)
	state.timer:stop()
	state.timer:start(
		50,
		0,
		vim.schedule_wrap(function()
			if not vim.api.nvim_buf_is_valid(buf) then
				return
			end
			local counts = vim.diagnostic.count(buf)
			state.diag_cache[buf] = nil

			for _, item in ipairs(DIAG_ORDER) do
				if (counts[item[1]] or 0) > 0 then
					state.diag_cache[buf] = { item[2], item[3] }
					break
				end
			end
			vim.cmd.redrawtabline()
		end)
	)
end

local g = vim.api.nvim_create_augroup("Tabline", { clear = true })

vim.api.nvim_create_autocmd({ "DiagnosticChanged", "BufEnter" }, {
	group = g,
	callback = function(a)
		async_update_diag(a.buf)
	end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
	group = g,
	callback = function()
		state.hl_cache = {}
	end,
})

vim.api.nvim_create_autocmd("BufDelete", {
	group = g,
	callback = function(a)
		state.diag_cache[a.buf] = nil
	end,
})

return M
