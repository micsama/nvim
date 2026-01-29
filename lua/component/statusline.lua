-- ~/.config/nvim/lua/component/statusline.lua
local M = {}
local api = vim.api
local utils = require("component.utils")
local icons = utils.icons
local data = require("component.stldata")

-- ============================================================================
-- 1. 配置
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

-- 缓存动态生成的胶囊高亮组 (Body & Tail)
local capsule_hl_cache = {}

---根据当前模式高亮组，合成胶囊专用的 Body 和 Tail 高亮
---@param mode_hl string 基础高亮组名 (如 "StatusLineInsert")
---@return table { body: string, tail: string }
local function get_capsule_hl(mode_hl)
	if capsule_hl_cache[mode_hl] then
		return capsule_hl_cache[mode_hl]
	end

	-- 获取基础高亮定义
	local mode_def = api.nvim_get_hl(0, { name = mode_hl, link = false })
	local stl_def = api.nvim_get_hl(0, { name = "StatusLine", link = false })

	-- 1. 模式主色: 优先取 bg (针对 TabProject 类)，否则取 fg (针对 String 类)
	local mode_color = mode_def.bg or mode_def.fg or "#89b4fa"
	-- 2. 状态栏背景色
	local stl_bg = stl_def.bg or "#1e1e2e"

	local body_name = "StlCapsule_" .. mode_hl
	local tail_name = "StlCapsuleTail_" .. mode_hl

	-- 合成：Body(fg=背景, bg=主色) | Tail(fg=主色, bg=背景)
	api.nvim_set_hl(0, body_name, { fg = stl_bg, bg = mode_color, bold = true })
	api.nvim_set_hl(0, tail_name, { fg = mode_color, bg = stl_bg })

	capsule_hl_cache[mode_hl] = { body = body_name, tail = tail_name }
	return capsule_hl_cache[mode_hl]
end

-- ============================================================================
-- 2. 组件渲染 (Components)
-- ============================================================================

local C = {}

-- 胶囊式文件信息: [ Name ] (移除 Icon)
function C.file_capsule(buf, mode_hl, is_active)
	local path = api.nvim_buf_get_name(buf)
	local name = (path == "") and "[No Name]" or vim.fn.fnamemodify(path, ":t")
	
	if not is_active then
		return string.format("%%#StatusLineNC# %s ", name)
	end

	local hls = get_capsule_hl(mode_hl)
	local readonly = api.nvim_get_option_value("readonly", { buf = buf }) and (" " .. icons.misc.ronly) or ""

	return string.format("%%#%s# %s%s %%#%s#%s", hls.body, name, readonly, hls.tail, icons.R_ROUND)
end

function C.git(buf)
	local info = data.git_info(buf)
	if not info then return "" end

	local user_hl = (info.user == "micsama") and "Function" or "DiagnosticWarn"
	local user_str = (info.user and info.user ~= false) and (string.format(" %%#%s#(%s)", user_hl, info.user)) or ""
	
	local diff_str = ""
	if info.added > 0 then diff_str = diff_str .. " %#MiniDiffSignAdd#" .. icons.git.added .. info.added end
	if info.changed > 0 then diff_str = diff_str .. " %#MiniDiffSignChange#" .. icons.git.changed .. info.changed end
	if info.deleted > 0 then diff_str = diff_str .. " %#MiniDiffSignDelete#" .. icons.git.deleted .. info.deleted end

	return string.format(" %%#String#%s %s%%#Comment#%s%s", icons.git.branch, info.branch, user_str, diff_str)
end

function C.lsp(buf)
	local info = data.lsp_info(buf)
	if not info then return "" end
	local res = ""
	if info.err > 0 then res = res .. " %#DiagnosticError#" .. icons.diag[1].icon .. info.err end
	if info.warn > 0 then res = res .. " %#DiagnosticWarn#" .. icons.diag[2].icon .. info.warn end
	return res .. " "
end

function C.ruler(buf, is_active, mode_hl)
	local ft = api.nvim_get_option_value("filetype", { buf = buf })
	local win = vim.g.statusline_winid or 0
	local success, cursor = pcall(api.nvim_win_get_cursor, win)
	local row = success and cursor[1] or 1
	local total = api.nvim_buf_line_count(buf)
	
	local progress = (row <= 1) and icons.misc.top or (row >= total and icons.misc.bottom or string.format("%d%%%%", math.floor((row / total) * 100)))
	
	-- Icon 逻辑: 使用 utils 统一处理
	local base_bg = is_active and "StatusLine" or "StatusLineNC"
	local icon, icon_hl = utils.get_file_icon_with_bg(buf, base_bg)
	local icon_str = (icon ~= "") and string.format("%%#%s#%s ", icon_hl, icon) or ""

	local capsule_mode_hl = is_active and (mode_hl or "StatusLineNormal") or "StatusLineNC"
	local hls = get_capsule_hl(capsule_mode_hl)
	local progress_str = string.format("%%#%s# %s ", hls.body, progress)
	local cursor_str = string.format("%%#%s# %%l:%%c", hls.tail)
	local sep_str = string.format("%%#%s#%s", hls.tail, icons.L_ROUND)

	return string.format("%%#%s# %s%s %s %s%s", base_bg, icon_str, ft, cursor_str, sep_str, progress_str)
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
		return table.concat({ C.file_capsule(buf, "StatusLineNC", false), "%=", C.ruler(buf, false, "StatusLineNC") })
	end

	return table.concat({
		C.file_capsule(buf, mode_hl, true),
		C.git(buf),
		C.lsp(buf),
		"%=",
		C.ruler(buf, true, mode_hl),
	})
end

-- ============================================================================
-- 4. Setup
-- ============================================================================

function M.setup()
	vim.o.laststatus = 3
	vim.o.statusline = "%!v:lua.require('component.statusline').render()"

	local grp = api.nvim_create_augroup("StlCore", { clear = true })

	-- 主题切换时，只需清空本地的高亮缓存即可
	api.nvim_create_autocmd("ColorScheme", {
		group = grp,
		callback = function()
			utils.reset_hl_cache()
			capsule_hl_cache = {}
		end,
	})

	api.nvim_create_autocmd("User", {
		pattern = { "MiniGitUpdated", "MiniDiffUpdated" },
		group = grp,
		callback = function() vim.cmd.redrawstatus() end,
	})

	api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "WinEnter", "BufEnter" }, {
		group = grp,
		callback = function() vim.cmd.redrawstatus() end,
	})

	api.nvim_create_user_command("StatusLineStats", function()
		require("component.stldata").profiler.print_stats()
	end, {})
end

return M
