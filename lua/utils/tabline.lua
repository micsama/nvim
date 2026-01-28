local M = {}
local api = vim.api

-- 1. 外部依赖检测 (mini.icons)
local has_icons, mini_icons = pcall(require, "mini.icons")
local get_icon = has_icons and mini_icons.get or function(_, _) return "", "" end

-- 2. 视觉常量 (Unicode 安全)
local ICONS = {
	SELECTED   = "󰄲 ",
	UNSELECTED = "󰄱 ",
	MODIFIED   = " 󰷫▕",
	SEPARATOR  = " ▕",
	CWD        = " ",
	DIAG = {
		[vim.diagnostic.severity.ERROR] = { icon = " ✘", hl = "DiagnosticError" },
		[vim.diagnostic.severity.WARN]  = { icon = " 󱓈", hl = "DiagnosticWarn" },
		[vim.diagnostic.severity.INFO]  = { icon = " 󰋽", hl = "DiagnosticInfo" },
		[vim.diagnostic.severity.HINT]  = { icon = " 󰛩", hl = "DiagnosticHint" },
	},
}

-- 3. 状态管理 (M4 Mac 优化：最小化内存分配)
local state = {
	hl_cache   = {},
	diag_cache = {},
	scroll_off = 0,
	timer      = vim.uv.new_timer(),
	cwd_cache  = { raw = nil, render = "", width = 0 },
}

-- --- 核心引擎 ---

-- 高亮合成器：修复了 link 解析，确保颜色从 Catppuccin 正确继承
local function get_compound_hl(fg_name, bg_name, is_bold)
	local key = fg_name .. (bg_name or "") .. (is_bold and "_B" or "")
	if state.hl_cache[key] then return state.hl_cache[key] end

	local name = "TabHL_" .. key:gsub("[^%w_]", "_")
	local fg_def = api.nvim_get_hl(0, { name = fg_name, link = false })
	local bg_def = api.nvim_get_hl(0, { name = bg_name, link = false })

	api.nvim_set_hl(0, name, {
		fg = fg_def.fg,
		bg = bg_def.bg,
		bold = is_bold,
	})

	state.hl_cache[key] = name
	return name
end

-- CWD 组件：生成亮底黑字色块 (Pill Style)
local function get_cwd_component(max_chars)
	local current_raw = vim.fn.getcwd()
	if state.cwd_cache.raw == current_raw then
		return state.cwd_cache.render, state.cwd_cache.width
	end

	local name = vim.fn.fnamemodify(current_raw, ":t")
	if name == "" then name = "/" end

	-- Unicode 安全截断
	if api.nvim_strwidth(name) > max_chars then
		name = vim.fn.strcharpart(name, 0, max_chars - 1) .. "…"
	end

	-- 这里的空格构成了亮色块的内边距 (Padding)
	local text = " " .. ICONS.CWD .. name .. " "
	state.cwd_cache.raw = current_raw
	state.cwd_cache.render = text
	state.cwd_cache.width = api.nvim_strwidth(text)

	return text, state.cwd_cache.width
end

-- Tab 项工厂
local function make_tab_item(tabid, idx, is_sel, name_counts)
	local win = api.nvim_tabpage_get_win(tabid)
	local buf = api.nvim_win_get_buf(win)
	local path = api.nvim_buf_get_name(buf)

	local base_hl = is_sel and "TabLineSel" or "TabLine"
	local diag = state.diag_cache[buf]

	-- 文件名处理与重名消解 (Ambiguity Resolution)
	local filename = (path == "") and "[No Name]" or vim.fn.fnamemodify(path, ":t")
	if path ~= "" and (name_counts[filename] or 0) > 1 then
		local parent = vim.fn.fnamemodify(path, ":p:h:t")
		if parent ~= "" and parent ~= "." then filename = parent .. "/" .. filename end
	end

	if api.nvim_strwidth(filename) > 20 then
		filename = vim.fn.strcharpart(filename, 0, 19) .. "…"
	end
	local label = filename:gsub("%%", "%%%%")

	local icon_txt, icon_hl = get_icon("file", path)
	if not icon_hl then icon_hl = base_hl end
	local mod_txt = api.nvim_get_option_value("modified", { buf = buf }) and ICONS.MODIFIED or ICONS.SEPARATOR

	-- 动态高亮计算
	local diag_icon = diag and diag.icon or ""
	local diag_hl = diag and diag.hl or base_hl
	local final_icon_hl = get_compound_hl(icon_hl, base_hl, is_sel)
	local final_name_hl = is_sel and base_hl or (diag and get_compound_hl(diag_hl, base_hl, false) or base_hl)
	local final_diag_hl = diag and get_compound_hl(diag_hl, base_hl, is_sel) or base_hl
	local final_mod_hl = get_compound_hl("DiagnosticOk", base_hl, is_sel)

	local width = 4 + (idx >= 10 and 2 or 1) + api.nvim_strwidth(icon_txt) +
	              api.nvim_strwidth(filename) + api.nvim_strwidth(diag_icon) + api.nvim_strwidth(mod_txt)

	local render_str = string.format(
		"%%%dT%%#%s# %s%d %%#%s#%s %%#%s#%s%%#%s#%s%%#%s#%s",
		tabid, base_hl, is_sel and ICONS.SELECTED or ICONS.UNSELECTED, idx,
		final_icon_hl, icon_txt, final_name_hl, label, final_diag_hl, diag_icon, final_mod_hl, mod_txt
	)

	return { width = width, render_str = render_str }
end

-- --- Main Render Pipeline ---

function M.render()
	local tabs = api.nvim_list_tabpages()
	local cur_tab = api.nvim_get_current_tabpage()
	local cur_idx = 1

	-- 1. 组件准备
	local cwd_str, cwd_w = get_cwd_component(15)

	-- 2. 预分析 (Pass 1)
	local name_stats = {}
	for i, t in ipairs(tabs) do
		if t == cur_tab then cur_idx = i end
		local win = api.nvim_tabpage_get_win(t)
		local buf = api.nvim_win_get_buf(win)
		local path = api.nvim_buf_get_name(buf)
		local name = (path == "") and "[No Name]" or vim.fn.fnamemodify(path, ":t")
		name_stats[name] = (name_stats[name] or 0) + 1
	end

	-- 3. 布局项生成 (Pass 2)
	local items = {}
	for i, t in ipairs(tabs) do
		items[i] = make_tab_item(t, i, t == cur_tab, name_stats)
	end

	-- 4. 滑动窗口计算 (Pass 3)
	-- 这里的 4 代表装饰符宽度 "▌ "，+1 用于间隙
	local avail_width = vim.o.columns - 4 - cwd_w - 1

	local start_idx = state.scroll_off + 1
	if cur_idx < start_idx then start_idx = cur_idx end

	local end_idx = start_idx
	local current_w = 0
	for i = start_idx, #items do
		current_w = current_w + items[i].width
		if current_w > avail_width then break end
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

	-- 5. 拼接渲染 (Pass 4)
	local res = {
		"%#Special#▌ ",       -- 1. 装饰
		"%#TabProject#" .. cwd_str, -- 2. 项目名 (亮底黑字)
		"%#TabLine# ",             -- 3. 过渡空隙
	}
	for i = start_idx, end_idx do
		if items[i] then table.insert(res, items[i].render_str) end
	end
	table.insert(res, "%#TabLineFill#%T")

	return table.concat(res)
end

-- --- 异步与事件监听 ---

local function update_diag(buf)
	if not api.nvim_buf_is_valid(buf) then return end
	local counts = vim.diagnostic.count(buf)
	local new_data = nil
	if (counts[vim.diagnostic.severity.ERROR] or 0) > 0 then new_data = ICONS.DIAG[vim.diagnostic.severity.ERROR]
	elseif (counts[vim.diagnostic.severity.WARN] or 0) > 0 then new_data = ICONS.DIAG[vim.diagnostic.severity.WARN]
	elseif (counts[vim.diagnostic.severity.INFO] or 0) > 0 then new_data = ICONS.DIAG[vim.diagnostic.severity.INFO]
	elseif (counts[vim.diagnostic.severity.HINT] or 0) > 0 then new_data = ICONS.DIAG[vim.diagnostic.severity.HINT] end

	if state.diag_cache[buf] ~= new_data then
		state.diag_cache[buf] = new_data
		vim.cmd.redrawtabline()
	end
end

local function debounced_diag_update(buf)
	state.timer:stop()
	state.timer:start(50, 0, vim.schedule_wrap(function() update_diag(buf) end))
end

local grp = api.nvim_create_augroup("TablineCore", { clear = true })
api.nvim_create_autocmd({ "DiagnosticChanged", "BufEnter" }, {
	group = grp,
	callback = function(args) debounced_diag_update(args.buf) end,
})
-- 当颜色方案改变时清空合成高亮缓存
api.nvim_create_autocmd("ColorScheme", {
	group = grp,
	callback = function() state.hl_cache = {} end,
})
-- 清理缓存防止内存泄漏
api.nvim_create_autocmd("BufDelete", {
	group = grp,
	callback = function(args) state.diag_cache[args.buf] = nil end,
})

return M
