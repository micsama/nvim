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

	-- 胶囊背景色映射：
	-- 我们将 StatusLine 的模式状态 Link 到现有的语义高亮组
	-- theme.lua 已经定义了 TabProject (Magenta/Mauve)，我们复用它作为 Normal 模式的颜色
	link("StatusLineNormal", "TabProject") -- Normal: 紫色背景 (与 Tabline Project 一致)
	link("StatusLineInsert", "String") -- Insert: 绿色 (语义: 字符串/新增)
	link("StatusLineVisual", "Statement") -- Visual: 紫色/粉色 (语义: 关键字/选中)
	link("StatusLineCmd", "Function") -- Command: 蓝色 (语义: 函数/操作)
	link("StatusLineReplace", "Error") -- Replace: 红色 (语义: 错误/危险)

	-- Git 状态部分直接使用 MiniDiff 定义好的高亮，无需手动 set_hl
	-- 如果需要微调，可以在 theme.lua 中统一修改 MiniDiffSign*
end

-- 缓存动态生成的胶囊高亮
local capsule_hl_cache = {}

local function get_capsule_hl(mode_hl)
	if capsule_hl_cache[mode_hl] then
		return capsule_hl_cache[mode_hl]
	end

	-- 动态获取颜色 (Level 2: 消费端逻辑)
	-- 我们需要构建一个胶囊：
	-- Body: fg=StatusLineBG, bg=ModeColor
	-- Tail: fg=ModeColor, bg=StatusLineBG

	local mode_def = api.nvim_get_hl(0, { name = mode_hl, link = false })
	local stl_def = api.nvim_get_hl(0, { name = "StatusLine", link = false })

	-- 智能取色逻辑：
	-- 1. ModeColor: 如果是 TabProject 这种 "UI组" (通常定义了bg)，取 bg。如果是 Syntax组 (如 String)，取 fg。
	local mode_color = mode_def.fg
	if mode_hl == "TabProject" or mode_hl == "StatusLineNormal" or mode_def.bg then
		-- 如果有 bg 且不仅仅是默认黑色，优先用 bg
		if mode_def.bg then
			mode_color = mode_def.bg
		end
	end
	-- Fallback
	if not mode_color then
		mode_color = "#89b4fa" -- Blue
	end

	-- 2. StatusLineBG: 必须取 bg
	local stl_bg = stl_def.bg or "#1e1e2e"

	local body_name = "StlCapsule_" .. mode_hl
	local tail_name = "StlCapsuleTail_" .. mode_hl

	api.nvim_set_hl(0, body_name, { fg = stl_bg, bg = mode_color, bold = true })
	api.nvim_set_hl(0, tail_name, { fg = mode_color, bg = stl_bg })

	capsule_hl_cache[mode_hl] = { body = body_name, tail = tail_name }
	return capsule_hl_cache[mode_hl]
end

-- ============================================================================
-- 2. 组件渲染 (Components)
-- ============================================================================

local C = {}

function C.file_capsule(buf, mode_hl, is_active)
	local path = api.nvim_buf_get_name(buf)
	local name = (path == "") and "[No Name]" or vim.fn.fnamemodify(path, ":t")
	local icon = utils.get_icon("file", path)

	if not is_active then
		return string.format("%%#StatusLineNC# %s %s ", icon, name)
	end

	local hls = get_capsule_hl(mode_hl)
	local render_str = string.format("%%#%s# %s %s %%#%s#%s", hls.body, icon, name, hls.tail, icons.R_ROUND)

	if api.nvim_get_option_value("readonly", { buf = buf }) then
		render_str = string.format("%%#%s# %s %s %s %%#%s#%s", hls.body, icon, name, icons.misc.ronly, hls.tail, icons.R_ROUND)
	end

	return render_str
end

function C.git(buf)
	local info = data.git_info(buf)
	if not info then
		return ""
	end

	-- 用户名高亮：如果是自己(micsama)，用 Function(Blue)，否则用 Warn(Yellow)
	local user_hl = (info.user == "micsama") and "Function" or "DiagnosticWarn"
	local user_str = (info.user and info.user ~= false) and (string.format("%%#%s#(%s)", user_hl, info.user)) or ""
	
	local diff_str = ""
	if info.added > 0 then
		diff_str = diff_str .. "%#MiniDiffSignAdd# " .. icons.git.added .. info.added
	end
	if info.changed > 0 then
		diff_str = diff_str .. "%#MiniDiffSignChange# " .. icons.git.changed .. info.changed
	end
	if info.deleted > 0 then
		diff_str = diff_str .. "%#MiniDiffSignDelete# " .. icons.git.deleted .. info.deleted
	end

	return string.format(
		" %%#String#%s %s%%#Comment# %s %s",
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
	
	-- 保护：如果是浮动窗口或无效窗口，光标获取可能会失败
	local success, cursor = pcall(api.nvim_win_get_cursor, win)
	local row = success and cursor[1] or 1
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
			capsule_hl_cache = {}
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