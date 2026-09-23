-- 状态栏、标签栏与终端标题共用的文本处理和重绘调度；不缓存整条渲染结果。
local M = {}

function M.escape(text)
	return (text:gsub("%%", "%%%%"))
end

-- 按显示单元截断，中文/宽字符也计入预算；只在超宽时拆分字符。
function M.truncate(text, width)
	width = math.max(0, width)
	if vim.api.nvim_strwidth(text) <= width then
		return text
	end
	if width == 0 then
		return ""
	end
	local parts, used = {}, 0
	for char in text:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
		local size = vim.api.nvim_strwidth(char)
		if used + size > width - 1 then
			break
		end
		parts[#parts + 1], used = char, used + size
	end
	return table.concat(parts) .. "…"
end

local pending_status, pending_tabs, scheduled = false, false, false
function M.redraw(status, tabs)
	pending_status = pending_status or status
	pending_tabs = pending_tabs or tabs
	if scheduled then
		return
	end
	scheduled = true
	vim.schedule(function()
		local stl, tab = pending_status, pending_tabs
		pending_status, pending_tabs, scheduled = false, false, false
		if stl then
			vim.cmd("redrawstatus!")
		end
		if tab then
			vim.cmd.redrawtabline()
		end
	end)
end

-- 标题的"文件部分"：终端 buffer 直接复用浮窗自己的窗口标题（floatty 设的那个），
-- 普通终端回退到 term_title，其余显示相对路径。
function M.titlestring_file()
	if vim.bo.buftype == "terminal" then
		local t = vim.api.nvim_win_get_config(0).title -- floatty 浮窗标题；普通窗口为 nil
		if type(t) == "table" then
			local parts = {}
			for _, chunk in ipairs(t) do
				parts[#parts + 1] = chunk[1]
			end
			return table.concat(parts)
		end
		return t or vim.b.term_title or "Terminal"
	end
	local path = vim.fn.expand("%:~:.")
	return path ~= "" and path or "[No Name]"
end

return M
