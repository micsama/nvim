-- ~/.config/nvim/lua/component/tabline.lua
local M = {}
local api = vim.api
local utils = require("component.utils") -- 引入公共组件
local icons = utils.icons

-- 状态管理
local state = {
	diag_cache = {},
	scroll_off = 0,
	timer = vim.uv.new_timer(),
	cwd_cache = { raw = nil, render = "", width = 0 },
	-- 核心缓存：[tabid] = bufid
	-- 渲染时只读此缓存，避免读取到 Session 加载过程中的中间态
	tab_bufs = {},
}

-- CWD 组件
local function get_cwd_component(max_chars)
	local current_raw = vim.fn.getcwd()
	if state.cwd_cache.raw == current_raw then
		return state.cwd_cache.render, state.cwd_cache.width
	end

	local name = vim.fn.fnamemodify(current_raw, ":t")
	if name == "" then
		name = "/"
	end

	if api.nvim_strwidth(name) > max_chars then
		name = vim.fn.strcharpart(name, 0, max_chars - 1) .. "…"
	end

	local text = " " .. icons.CWD .. name .. " "
	state.cwd_cache.raw = current_raw
	state.cwd_cache.render = text
	state.cwd_cache.width = api.nvim_strwidth(text)

	return text, state.cwd_cache.width
end

-- Tab 项工厂 (直接接收 buf 和 path)
local function make_tab_item(tabid, idx, is_sel, name_counts, path_counts, buf, path)
	local base_hl = is_sel and "TabLineSel" or "TabLine"
	local diag = state.diag_cache[buf]

	-- 1. 计算显示名称
	local filename = (path == "") and "[No Name]" or vim.fn.fnamemodify(path, ":t")

	-- 逻辑：同名不同路径 -> 显示 Parent
	if path ~= "" and (name_counts[filename] or 0) > 1 and (path_counts[path] or 0) == 1 then
		local parent = vim.fn.fnamemodify(path, ":p:h:t")
		if parent ~= "" and parent ~= "." then
			filename = parent .. "/" .. filename
		end
	end

	if api.nvim_strwidth(filename) > 20 then
		filename = vim.fn.strcharpart(filename, 0, 19) .. "…"
	end
	local label = filename:gsub("%%", "%%%%")

	-- 2. 获取图标
	local icon_txt, icon_hl = utils.get_icon("file", path)
	if not icon_hl then
		icon_hl = base_hl
	end

	-- 3. 状态标识
	local mod_txt = api.nvim_get_option_value("modified", { buf = buf }) and icons.MODIFIED
		or icons.SEPARATOR

	-- 逻辑：同路径 -> 显示副本图标
	local dup_txt = ""
	if path ~= "" and (path_counts[path] or 0) > 1 then
		dup_txt = icons.DUPLICATE
	end

	-- 4. 动态高亮计算
	local diag_icon = diag and diag.icon or ""
	local diag_hl = diag and diag.hl or base_hl

	local final_icon_hl = utils.get_compound_hl(icon_hl, base_hl, is_sel)
	local final_name_hl = is_sel and base_hl
		or (diag and utils.get_compound_hl(diag_hl, base_hl, false) or base_hl)
	local final_diag_hl = diag and utils.get_compound_hl(diag_hl, base_hl, is_sel) or base_hl
	local final_mod_hl = utils.get_compound_hl("DiagnosticOk", base_hl, is_sel)

	local width = 4
		+ (idx >= 10 and 2 or 1)
		+ api.nvim_strwidth(icon_txt)
		+ api.nvim_strwidth(filename)
		+ api.nvim_strwidth(diag_icon)
		+ api.nvim_strwidth(dup_txt)
		+ api.nvim_strwidth(mod_txt)

	local render_str = string.format(
		"%%%dT%%#%s# %s%d %%#%s#%s %%#%s#%s%%#%s#%s%%#%s#%s%s",
		tabid,
		base_hl,
		is_sel and icons.SELECTED or icons.UNSELECTED,
		idx,
		final_icon_hl,
		icon_txt,
		final_name_hl,
		label,
		final_diag_hl,
		diag_icon,
		final_mod_hl,
		dup_txt,
		mod_txt
	)

	return { width = width, render_str = render_str }
end

function M.render()
	local tabs = api.nvim_list_tabpages()
	local cur_tab = api.nvim_get_current_tabpage()
	local cur_idx = 1
	local cwd_str, cwd_w = get_cwd_component(15)

	-- 1. 数据收集 (基于缓存)
	local name_stats = {}
	local path_stats = {}
	local tab_data = {} -- [i] = {buf, path}

	-- 垃圾回收：清理已不存在的 tab 缓存
	local active_tabs = {}
	for _, t in ipairs(tabs) do
		active_tabs[t] = true
	end
	for t, _ in pairs(state.tab_bufs) do
		if not active_tabs[t] then
			state.tab_bufs[t] = nil
		end
	end

	for i, t in ipairs(tabs) do
		if t == cur_tab then
			cur_idx = i
		end

		-- 读缓存 (Read Cache)
		local buf = state.tab_bufs[t]

		-- 惰性初始化 (Lazy Init):
		-- 如果缓存缺失(首次加载/Session恢复后首次渲染)，则查询 API 并写入缓存。
		-- 这保证了初始状态可见，且由于只在缺失时查询，不会受到后续 Session 加载过程中的干扰。
		if not buf or not api.nvim_buf_is_valid(buf) then
			local win = api.nvim_tabpage_get_win(t)
			buf = api.nvim_win_get_buf(win)
			state.tab_bufs[t] = buf
		end

		local path = api.nvim_buf_get_name(buf)
		tab_data[i] = { buf = buf, path = path }

		-- 统计信息
		local name = (path == "") and "[No Name]" or vim.fn.fnamemodify(path, ":t")
		name_stats[name] = (name_stats[name] or 0) + 1
		if path ~= "" then
			path_stats[path] = (path_stats[path] or 0) + 1
		end
	end

	-- 2. 生成 Items
	local items = {}
	for i, t in ipairs(tabs) do
		local d = tab_data[i]
		items[i] = make_tab_item(t, i, t == cur_tab, name_stats, path_stats, d.buf, d.path)
	end

	-- 3. 布局计算 (滑动窗口)
	local avail_width = vim.o.columns - 4 - cwd_w - 1
	local start_idx = state.scroll_off + 1
	if cur_idx < start_idx then
		start_idx = cur_idx
	end

	local end_idx = start_idx
	local current_w = 0
	for i = start_idx, #items do
		current_w = current_w + items[i].width
		if current_w > avail_width then
			break
		end
		end_idx = i
	end

	if cur_idx > end_idx then
		local w = 0
		end_idx = cur_idx
		for i = cur_idx, 1, -1 do
			w = w + items[i].width
			if w > avail_width then
				start_idx = i + 1
				break
			end
			start_idx = i
		end
	end
	state.scroll_off = start_idx - 1

	local res = {
		"%#Special#▌ ",
		"%#TabProject#" .. cwd_str,
		"%#TabLine# ",
	}
	for i = start_idx, end_idx do
		if items[i] then
			table.insert(res, items[i].render_str)
		end
	end
	table.insert(res, "%#TabLineFill#%T")
	return table.concat(res)
end

-- 诊断更新
local function update_diag(buf)
	if not api.nvim_buf_is_valid(buf) then
		return
	end
	local counts = vim.diagnostic.count(buf)
	local new_data = nil
	if (counts[vim.diagnostic.severity.ERROR] or 0) > 0 then
		new_data = icons.diag[1]
	elseif (counts[vim.diagnostic.severity.WARN] or 0) > 0 then
		new_data = icons.diag[2]
	elseif (counts[vim.diagnostic.severity.INFO] or 0) > 0 then
		new_data = icons.diag[3]
	elseif (counts[vim.diagnostic.severity.HINT] or 0) > 0 then
		new_data = icons.diag[4]
	end

	if state.diag_cache[buf] ~= new_data then
		state.diag_cache[buf] = new_data
		vim.cmd.redrawtabline()
	end
end

local function debounced_diag_update(buf)
	state.timer:stop()
	state.timer:start(
		50,
		0,
		vim.schedule_wrap(function()
			update_diag(buf)
		end)
	)
end

-- 更新当前 Tab 的缓存
local function update_current_tab_cache()
	local tab = api.nvim_get_current_tabpage()
	local buf = api.nvim_get_current_buf()
	state.tab_bufs[tab] = buf
	-- 触发重绘以应用更新
	vim.cmd.redrawtabline()
end

local grp = api.nvim_create_augroup("TablineCore", { clear = true })

-- 核心事件：仅在用户主动操作 (BufEnter/TabEnter) 时更新缓存
api.nvim_create_autocmd({ "BufEnter", "TabEnter" }, {
	group = grp,
	callback = function(args)
		update_current_tab_cache()
		if args.buf then
			debounced_diag_update(args.buf)
		end
	end,
})

api.nvim_create_autocmd("DiagnosticChanged", {
	group = grp,
	callback = function(args)
		debounced_diag_update(args.buf)
	end,
})

api.nvim_create_autocmd("ColorScheme", {
	group = grp,
	callback = function()
		utils.reset_hl_cache()
	end,
})
api.nvim_create_autocmd("BufDelete", {
	group = grp,
	callback = function(args)
		state.diag_cache[args.buf] = nil
	end,
})

return M
