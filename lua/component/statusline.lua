-- ~/.config/nvim/lua/component/statusline.lua
local M = {}
local api = vim.api
local utils = require("component.utils")
local icons = utils.icons
local p = utils.palette
local data = require("component.stldata")

local capsule_hl_cache = {}

local mode_tone = {
	StatusLineNormal = p.magenta,
	StatusLineInsert = p.green,
	StatusLineVisual = p.yellow,
	StatusLineCmd = p.blue,
	StatusLineReplace = p.red,
}

local function current_mode_group()
	local mode = api.nvim_get_mode().mode
	if mode == "V" or mode == "\22" or mode:sub(1, 1) == "v" then
		return "StatusLineVisual"
	end

	local head = mode:sub(1, 1)
	if head == "i" or head == "t" then
		return "StatusLineInsert"
	end
	if head == "c" then
		return "StatusLineCmd"
	end
	if head == "R" then
		return "StatusLineReplace"
	end
	return "StatusLineNormal"
end

local function get_capsule_hl(mode_hl, is_active)
	local key = is_active and mode_hl or "fixed"
	if capsule_hl_cache[key] then
		return capsule_hl_cache[key]
	end

	local stl_name = is_active and "StatusLine" or "StatusLineNC"
	local stl_bg = api.nvim_get_hl(0, { name = stl_name, link = false }).bg
	local body_name = "StlCapsule_" .. key
	local tail_name = "StlCapsuleTail_" .. key

	if is_active then
		local tone = mode_tone[mode_hl]
		api.nvim_set_hl(0, body_name, { fg = stl_bg, bg = tone, bold = true })
		api.nvim_set_hl(0, tail_name, { fg = tone, bg = stl_bg })
	else
		api.nvim_set_hl(0, body_name, { fg = p.text, bg = p.surface1, bold = true })
		api.nvim_set_hl(0, tail_name, { fg = p.surface1, bg = stl_bg })
	end

	capsule_hl_cache[key] = { body = body_name, tail = tail_name }
	return capsule_hl_cache[key]
end

local C = {}

local function esc_stl(text)
	return text:gsub("%%", "%%%%")
end

local function fold_path(path, max_width)
	if vim.fn.strdisplaywidth(path) <= max_width then
		return path
	end

	local parts = vim.split(path, "/", { plain = true, trimempty = true })
	local first, last = parts[1], parts[#parts]
	if first and last and #parts > 1 then
		local folded = string.format("%s/…/%s", first, last)
		if vim.fn.strdisplaywidth(folded) <= max_width then
			return folded
		end
		folded = string.format("…/%s", last)
		if vim.fn.strdisplaywidth(folded) <= max_width then
			return folded
		end
		return folded
	end

	local keep = math.max(4, max_width - 1)
	local chars = vim.fn.strchars(path)
	return "…" .. vim.fn.strcharpart(path, math.max(0, chars - keep))
end

local function format_file_path(buf, win)
	local path = api.nvim_buf_get_name(buf)
	if path == "" then
		return "[No Name]", ""
	end

	local tab = api.nvim_win_get_tabpage(win)
	local tab_cwd = vim.fn.getcwd(-1, api.nvim_tabpage_get_number(tab))
	local rel = vim.fs.relpath(tab_cwd, path)
	local display = rel and ("./" .. rel) or vim.fn.fnamemodify(path, ":~")
	local file = vim.fn.fnamemodify(display, ":t")
	local dir = vim.fn.fnamemodify(display, ":h")

	if dir == "." then
		dir = ""
	elseif dir ~= "" then
		local max_dir_width = math.max(16, math.min(60, math.floor(vim.o.columns * 0.28)))
		dir = fold_path(dir, max_dir_width)
	end

	return esc_stl(file), esc_stl(dir)
end

function C.file_capsule(buf, win, mode_hl, is_active)
	local file, dir = format_file_path(buf, win)
	local hls = get_capsule_hl(mode_hl, is_active)
	local file_hl = utils.get_compound_hl(hls.body, hls.body, true)
	local readonly = api.nvim_get_option_value("readonly", { buf = buf }) and (" " .. icons.misc.ronly) or ""
	local path_part = string.format("%%#%s#%s", file_hl, file)

	if dir ~= "" then
		path_part = string.format("%s %%#%s#│ %s", path_part, hls.body, dir)
	end

	return string.format("%%#%s# %s%s %%#%s#%s", hls.body, path_part, readonly, hls.tail, icons.R_ROUND)
end

function C.git(buf)
	local info = data.git_info(buf)
	if not info then
		return ""
	end

	local user_hl = (info.user == "micsama") and "Function" or "DiagnosticWarn"
	local user_str = (info.user and info.user ~= false) and string.format(" %%#%s#(%s)", user_hl, info.user) or ""
	local diff_str = ""
	if info.added > 0 then diff_str = diff_str .. " %#MiniDiffSignAdd#" .. icons.git.added .. info.added end
	if info.changed > 0 then diff_str = diff_str .. " %#MiniDiffSignChange#" .. icons.git.changed .. info.changed end
	if info.deleted > 0 then diff_str = diff_str .. " %#MiniDiffSignDelete#" .. icons.git.deleted .. info.deleted end

	return string.format(" %%#String#%s %s%%#Comment#%s%s", icons.git.branch, info.branch, user_str, diff_str)
end

function C.lsp(buf)
	local info = data.lsp_info(buf)
	if not info then
		return ""
	end
	local res = ""
	if info.err > 0 then res = res .. " %#DiagnosticError#" .. icons.diag[1].icon .. info.err end
	if info.warn > 0 then res = res .. " %#DiagnosticWarn#" .. icons.diag[2].icon .. info.warn end
	return res .. " "
end

function C.ruler(buf, mode_hl)
	local ft = api.nvim_get_option_value("filetype", { buf = buf })
	local row = api.nvim_win_get_cursor(vim.g.statusline_winid)[1]
	local total = api.nvim_buf_line_count(buf)
	local progress = (row <= 1)
			and icons.misc.top
		or (row >= total and icons.misc.bottom or string.format("%d%%%%", math.floor((row / total) * 100)))

	local icon, icon_hl = utils.get_file_icon_with_bg(buf, "StatusLine")
	local icon_str = (icon ~= "") and string.format("%%#%s#%s ", icon_hl, icon) or ""

	local hls = get_capsule_hl(mode_hl, true)
	local progress_str = string.format("%%#%s# %s ", hls.body, progress)
	local cursor_str = string.format("%%#%s# %%l:%%c", hls.tail)
	local sep_str = string.format("%%#%s#%s", hls.tail, icons.L_ROUND)

	return string.format("%%#StatusLine# %s%s %s %s%s", icon_str, ft, cursor_str, sep_str, progress_str)
end

function M.render()
	local win = vim.g.statusline_winid
	local buf = api.nvim_win_get_buf(win)

	if win ~= api.nvim_get_current_win() then
		return C.file_capsule(buf, win, "StatusLineNormal", false)
	end

	local mode_hl = current_mode_group()
	return table.concat({
		C.file_capsule(buf, win, mode_hl, true),
		C.git(buf),
		C.lsp(buf),
		"%=",
		C.ruler(buf, mode_hl),
	})
end

function M.setup()
	vim.o.laststatus = 2
	vim.o.statusline = "%!v:lua.require('component.statusline').render()"

	local grp = api.nvim_create_augroup("StlCore", { clear = true })

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

end

return M
