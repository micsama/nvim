-- ~/.config/nvim/lua/component/statusline.lua
local M = {}
local api = vim.api
local utils = require("component.utils")
local data = require("component.stldata")

-- ============================================================================
-- 1. 配色映射 (Mode -> Highlight Group)
-- ============================================================================
-- 请确保这些高亮组在你的主题中已定义，或者链接到现有组
-- 这里使用默认的 link 策略作为 Fallback
local mode_map = {
	['n']    = 'StatusLineNormal',
	['i']    = 'StatusLineInsert',
	['v']    = 'StatusLineVisual',
	['V']    = 'StatusLineVisual',
	['\22']  = 'StatusLineVisual', -- CTRL-V
	['c']    = 'StatusLineCmd',
	['R']    = 'StatusLineReplace',
	['t']    = 'StatusLineInsert',
}

local function setup_highlights()
	-- 定义基础高亮，你可以根据你的配色方案修改这里
	local function link(name, target)
		if #api.nvim_get_hl(0, { name = name }) == 0 then
			api.nvim_set_hl(0, name, { link = target })
		end
	end
	
	-- 示例链接 (用户可自定义)
	link('StatusLineNormal', 'String')    -- 绿色/蓝色
	link('StatusLineInsert', 'Function')  -- 蓝色/黄色
	link('StatusLineVisual', 'Statement') -- 紫色
	link('StatusLineCmd',    'Comment')
	link('StatusLineReplace','Error')
end

-- ============================================================================
-- 2. 组件渲染 (Components)
-- ============================================================================

local C = {}

-- 模式指示器
function C.mode(mode_hl)
	local mode_code = api.nvim_get_mode().mode
	local mode_label = mode_code:upper()
	return string.format("%%#%s# ▎ %-3s ", mode_hl, mode_label)
end

-- 文件名 (背景色跟随 Mode)
function C.file_info(buf, mode_hl, is_active)
	local path = api.nvim_buf_get_name(buf)
	local name = (path == "") and "[No Name]" or vim.fn.fnamemodify(path, ":t")
	
	-- 获取文件图标和原始颜色
	local icon, icon_hl_name = utils.get_icon("file", path)
	if not icon_hl_name then icon_hl_name = "StatusLine" end

	-- 魔法：合成图标色与模式背景色
	-- 如果 is_active，我们希望背景是 ModeColor，前景是 IconColor
	-- 如果 inactive，全灰
	
	local render_str = ""
	if is_active then
		-- 这里的逻辑：背景用 Mode 的背景(通常是 statusline 的背景)，或者 Mode 的前景？
		-- 根据需求 "文件名配色和 Mode 配合"：
		-- 方案 A: 文件名背景色 = Mode颜色 (很醒目)
		-- 方案 B: 文件名文字颜色 = Mode颜色 (较优雅)
		
		-- 这里实现方案 A (背景色跟随 Mode，类似 Powerline):
		-- 我们需要创建一个 HL: fg = IconColor, bg = ModeColor
		
		local combined_hl = utils.get_compound_hl(icon_hl_name, mode_hl, { bold = true })
		render_str = string.format("%%#%s# %s %%#%s#%s ", combined_hl, icon, mode_hl, name)
	else
		render_str = string.format("%%#StatusLineNC# %s %s ", icon, name)
	end
	
	-- Modified 标记
	if api.nvim_get_option_value("modified", { buf = buf }) then
		render_str = render_str .. "%#Special# " .. utils.icons.misc.file .. " "
	end
	
	return render_str
end

-- Git (分支 + User + Diff)
function C.git(buf)
	local info = data.git_info(buf) -- 调用 data 层
	if not info then return "" end

	local user_str = (info.user and info.user ~= false) and ("(" .. info.user .. ")") or ""
	
	-- 拼接 Diff 字符串
	local diff_str = ""
	if info.added > 0 then diff_str = diff_str .. "%#GitSignsAdd# " .. utils.icons.git.added .. info.added end
	if info.changed > 0 then diff_str = diff_str .. "%#GitSignsChange# " .. utils.icons.git.changed .. info.changed end
	if info.deleted > 0 then diff_str = diff_str .. "%#GitSignsDelete# " .. utils.icons.git.deleted .. info.deleted end

	return string.format(" %%#GitSignsBranch#%s %s%%#Comment#%s %s", 
		utils.icons.git.branch, info.branch, user_str, diff_str)
end

-- LSP 诊断
function C.lsp(buf)
	local info = data.lsp_info(buf)
	if not info then return "" end
	
	local res = ""
	if info.err > 0 then res = res .. "%#DiagnosticError#" .. utils.icons.diag[1].icon .. info.err end
	if info.warn > 0 then res = res .. "%#DiagnosticWarn#" .. utils.icons.diag[2].icon .. info.warn end
	return res .. " "
end

-- 右侧信息
function C.ruler(buf)
	local ft = api.nvim_get_option_value("filetype", { buf = buf })
	-- 简单的行:列 百分比
	return string.format("%%#StatusLine# %s %%l:%%c %%%%p ", ft)
end

-- ============================================================================
-- 3. 主渲染管线
-- ============================================================================

function M.render()
	local win = vim.g.statusline_winid
	local buf = api.nvim_win_get_buf(win)
	local is_active = win == api.nvim_get_current_win()

	-- 1. 获取当前模式对应的 "基准色"
	local mode = api.nvim_get_mode().mode
	local mode_hl = mode_map[mode] or 'StatusLineNormal'

	if not is_active then
		return table.concat({
			C.file_info(buf, "StatusLineNC", false),
			"%=",
			C.ruler(buf)
		})
	end

	return table.concat({
		C.mode(mode_hl),
		C.file_info(buf, mode_hl, true),
		C.git(buf),
		C.lsp(buf),
		"%=",
		C.ruler(buf)
	})
end

-- ============================================================================
-- 4. Setup
-- ============================================================================

function M.setup()
	setup_highlights()
	
	vim.o.laststatus = 3 -- 推荐全局
	vim.o.statusline = "%!v:lua.require('component.statusline').render()"
	
	local grp = api.nvim_create_augroup("StlCore", { clear = true })
	
	-- 监听配色改变，重置缓存
	api.nvim_create_autocmd("ColorScheme", {
		group = grp,
		callback = function() 
			utils.reset_hl_cache() 
			setup_highlights()
		end
	})
	
	-- 监听 mini.git / diff 更新
	api.nvim_create_autocmd("User", {
		pattern = { "MiniGitUpdated", "MiniDiffUpdated" },
		group = grp,
		callback = function() vim.cmd.redrawstatus() end,
	})
	
	-- 注册 Profiler 命令
	api.nvim_create_user_command("StatusLineStats", function()
		require("component.stldata").profiler.print_stats()
	end, {})
end

return M
