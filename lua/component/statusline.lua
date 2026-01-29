-- ~/.config/nvim/lua/component/statusline.lua
local M = {}
local api = vim.api
local utils = require("component.utils")
local icons = utils.icons
local data = require("component.stldata")

-- ============================================================================
-- 1. 配色映射 (Mode -> Highlight Group)
-- ============================================================================
local mode_map = {
	["n"] = "StatusLineNormal",
	["i"] = "StatusLineInsert",
	["v"] = "StatusLineVisual",
	["V"] = "StatusLineVisual",
	["\22"] = "StatusLineVisual", -- CTRL-V
	["c"] = "StatusLineCmd",
	["R"] = "StatusLineReplace",
	["t"] = "StatusLineInsert",
}

local function setup_highlights()
	local function link(name, target)
		if #api.nvim_get_hl(0, { name = name }) == 0 then
			api.nvim_set_hl(0, name, { link = target })
		end
	end

	-- 这里的颜色将决定胶囊的背景色
	link("StatusLineNormal", "TabProject") -- 普通模式跟 Tabline CWD 一致 (通常是 mauve/purple)
	link("StatusLineInsert", "String") -- 插入模式 (绿色)
	link("StatusLineVisual", "Statement") -- 可视模式 (紫色/粉色)
	link("StatusLineCmd", "Function") -- 命令模式 (蓝色)
	link("StatusLineReplace", "Error") -- 替换模式 (红色)
end

-- 缓存动态生成的胶囊高亮
local capsule_hl_cache = {}

local function get_capsule_hl(mode_hl)
	if capsule_hl_cache[mode_hl] then
		return capsule_hl_cache[mode_hl]
	end

	-- 获取颜色的真实值
	-- mode_hl (如 String) 通常提供 FG 颜色，我们将其用作胶囊的 BG
	local mode_def = api.nvim_get_hl(0, { name = mode_hl, link = false })
	local stl_def = api.nvim_get_hl(0, { name = "StatusLine", link = false })

	-- 确保能取到颜色，取不到就 fallback
	local mode_fg = mode_def.fg or mode_def.bg -- 优先取 FG，因为大多数 Syntax Group 是 FG
	local stl_bg = stl_def.bg or "#1e1e2e" -- Statusline 背景色

	-- 如果 mode_hl 本身就是 TabProject 这种已经定义好 bg 的，那逻辑可能要反过来
	-- TabProject: fg=Crust, bg=Mauve。这种情况下我们直接用它的 bg。
	if mode_hl == "TabProject" or mode_hl == "StatusLineNormal" then
		mode_fg = mode_def.bg or mode_fg
	end

	local body_name = "StlCapsule_" .. mode_hl
	local tail_name = "StlCapsuleTail_" .. mode_hl

	-- 1. 胶囊主体: bg=模式色, fg=深色(StatusLine背景)
	api.nvim_set_hl(0, body_name, { fg = stl_bg, bg = mode_fg, bold = true })

	-- 2. 胶囊尾部 (半圆): fg=模式色, bg=StatusLine背景
	api.nvim_set_hl(0, tail_name, { fg = mode_fg, bg = stl_bg })

	capsule_hl_cache[mode_hl] = { body = body_name, tail = tail_name }
	return capsule_hl_cache[mode_hl]
end

-- ============================================================================
-- 2. 组件渲染 (Components)
-- ============================================================================

local C = {}

-- 胶囊式文件信息 (替代原有的 mode + file_info)
function C.file_capsule(buf, mode_hl, is_active)
	local path = api.nvim_buf_get_name(buf)
	local name = (path == "") and "[No Name]" or vim.fn.fnamemodify(path, ":t")
	local icon = utils.get_icon("file", path)

	if not is_active then
		return string.format("%%#StatusLineNC# %s %s ", icon, name)
	end

	-- 获取动态胶囊高亮
	local hls = get_capsule_hl(mode_hl)

	-- 构造胶囊: [Icon Name]
	local render_str = string.format("%%#%s# %s %s %%#%s#", hls.body, icon, name, hls.tail)

	-- Readonly 标记 (跟在胶囊后面，或者放在胶囊里面？)
	-- 既然是胶囊，锁最好放在胶囊里面，也就是半圆之前
	if api.nvim_get_option_value("readonly", { buf = buf }) then
		-- 插入到半圆之前，保持 body 高亮
		render_str = string.format("%%#%s# %s %s %s %%#%s#", hls.body, icon, name, icons.misc.ronly, hls.tail)
	end

	return render_str
end

function C.git(buf)
	local info = data.git_info(buf)
	if not info then
		return ""
	end

	local user_str = (info.user and info.user ~= false) and ("(" .. info.user .. ")") or ""
	local diff_str = ""
	if info.added > 0 then
		diff_str = diff_str .. "%#GitSignsAdd# " .. icons.git.added .. info.added
	end
	if info.changed > 0 then
		diff_str = diff_str .. "%#GitSignsChange# " .. icons.git.changed .. info.changed
	end
	if info.deleted > 0 then
		diff_str = diff_str .. "%#GitSignsDelete# " .. icons.git.deleted .. info.deleted
	end

	return string.format(
		" %%#GitSignsBranch#%s %s%%#Comment#%s %s",
		icons.git.branch,
		info.branch,
		user_str,
		diff_str
	)
end

function C.lsp(buf)
	local info = data.lsp_info(buf)
	if not info then
		return ""
	end
	local res = ""
	if info.err > 0 then
		res = res .. "%#DiagnosticError#" .. icons.diag[1].icon .. info.err
	end
	if info.warn > 0 then
		res = res .. "%#DiagnosticWarn#" .. icons.diag[2].icon .. info.warn
	end
	return res .. " "
end

function C.ruler(buf)
	local ft = api.nvim_get_option_value("filetype", { buf = buf })
	local win = vim.g.statusline_winid or 0
	local row = api.nvim_win_get_cursor(win)[1]
	local total = api.nvim_buf_line_count(buf)
	local progress

	if row <= 1 then
		progress = icons.misc.top
	elseif row >= total then
		progress = icons.misc.bottom
	else
		progress = string.format("%d%%%%", math.floor((row / total) * 100))
	end
	return string.format("%%#StatusLine# %s %%l:%%c %s ", ft, progress)
end

-- ============================================================================
-- 3. 主渲染管线
-- ============================================================================

function M.render()
	local win = vim.g.statusline_winid
	local buf = api.nvim_win_get_buf(win)
	local is_active = win == api.nvim_get_current_win()

	local mode = api.nvim_get_mode().mode
	local mode_hl = mode_map[mode] or "StatusLineNormal"

	if not is_active then
		return table.concat({
			C.file_capsule(buf, "StatusLineNC", false),
			"%=",
			C.ruler(buf),
		})
	end

	return table.concat({
		-- 移除单独的 Mode，直接渲染胶囊
		C.file_capsule(buf, mode_hl, true),
		C.git(buf),
		C.lsp(buf),
		"%=",
		C.ruler(buf),
	})
end

-- ============================================================================
-- 4. Setup
-- ============================================================================

function M.setup()
	setup_highlights()

	vim.o.laststatus = 3
	vim.o.statusline = "%!v:lua.require('component.statusline').render()"

	local grp = api.nvim_create_augroup("StlCore", { clear = true })

	api.nvim_create_autocmd("ColorScheme", {
		group = grp,
		callback = function()
			utils.reset_hl_cache()
			capsule_hl_cache = {} -- 清空本地高亮缓存
			setup_highlights()
		end,
	})

	api.nvim_create_autocmd("User", {
		pattern = { "MiniGitUpdated", "MiniDiffUpdated" },
		group = grp,
		callback = function()
			vim.cmd.redrawstatus()
		end,
	})

	api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "WinEnter", "BufEnter" }, {
		group = grp,
		callback = function()
			vim.cmd.redrawstatus()
		end,
	})

	api.nvim_create_user_command("StatusLineStats", function()
		require("component.stldata").profiler.print_stats()
	end, {})
end

return M