-- 固定出口列表：探测结果原位更新，不移动正在选择的项目。
local M = {}
local api = vim.api
local options = require("config.network")
local probe = require("apps.network.probe")
local ns = api.nvim_create_namespace("network.picker")
local win, buf
local index = 1
local first_row, stride = 2, 3

function M.is_open()
	return win ~= nil and api.nvim_win_is_valid(win)
end

local function row(i)
	return first_row + (i - 1) * stride
end

function M.redraw()
	if not M.is_open() then
		return
	end
	local current = require("apps.network").current()
	local lines, highlights = { "" }, {}
	for i, exit in ipairs(options.exits) do
		local active = exit == current
		local name = exit.proxy == "" and "直连" or ("代理 " .. exit.id)
		local prefix = active and "  ● " or "    "
		local label = prefix .. name
		local padding = string.rep(" ", 22 - vim.fn.strdisplaywidth(label))
		local detail = probe.describe(exit)
		lines[#lines + 1] = label .. padding .. detail
		lines[#lines + 1] = "    " .. (exit.proxy == "" and "不使用代理" or exit.proxy)
		lines[#lines + 1] = ""
		local record = probe.get(exit)
		local tone = "Comment"
		if probe.fresh(record) then
			tone = record.status == "ok" and record.country == "AU" and "DiagnosticOk" or "DiagnosticWarn"
		end
		highlights[#highlights + 1] = { row(i) - 1, 0, #label, active and "Title" or "NormalFloat" }
		highlights[#highlights + 1] = { row(i) - 1, #label + #padding, -1, tone }
		highlights[#highlights + 1] = { row(i), 0, -1, "Comment" }
	end
	vim.bo[buf].modifiable = true
	api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].modifiable = false
	api.nvim_buf_clear_namespace(buf, ns, 0, -1)
	for _, hl in ipairs(highlights) do
		api.nvim_buf_set_extmark(buf, ns, hl[1], hl[2], {
			end_col = hl[3] == -1 and #lines[hl[1] + 1] or hl[3],
			hl_group = hl[4],
		})
	end
	api.nvim_win_set_cursor(win, { row(index), 0 })
end

local function move(delta)
	index = (index - 1 + delta) % #options.exits + 1
	api.nvim_win_set_cursor(win, { row(index), 0 })
end

function M.open()
	if M.is_open() then
		api.nvim_set_current_win(win)
		return
	end
	index = 1
	for i, exit in ipairs(options.exits) do
		if exit == require("apps.network").current() then
			index = i
		end
	end
	buf = api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"
	local width = math.min(58, vim.o.columns - 4)
	local height = 1 + #options.exits * stride
	win = api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
		title = " 󰖟 网络出口 ",
		title_pos = "center",
		footer = " ↵ 切换 · r 重测 · Esc 关闭 ",
		footer_pos = "center",
	})
	vim.wo[win].cursorline = true
	vim.wo[win].wrap = false
	vim.wo[win].scrolloff = 0
	vim.wo[win].winhighlight = "CursorLine:PmenuSel,FloatTitle:Title,FloatFooter:Comment"
	local function close()
		api.nvim_win_close(win, true)
	end
	local function choose(i)
		local exit = options.exits[i]
		close()
		require("apps.network").select(exit)
	end
	local function map(keys, callback)
		for _, key in ipairs(keys) do
			vim.keymap.set("n", key, callback, { buffer = buf, nowait = true })
		end
	end
	map({ "<Esc>", "q" }, close)
	map({ "j", "<Down>", "<Tab>", "<C-n>" }, function()
		move(1)
	end)
	map({ "k", "<Up>", "<S-Tab>", "<C-p>" }, function()
		move(-1)
	end)
	map({ "<CR>" }, function()
		choose(index)
	end)
	for i = 1, #options.exits do
		map({ tostring(i) }, function()
			choose(i)
		end)
	end
	map({ "r" }, function()
		require("apps.network").refresh(true, true)
	end)
	-- 鼠标和其他光标移动也只落在出口主行。
	api.nvim_create_autocmd("CursorMoved", {
		buffer = buf,
		callback = function()
			local cursor_row = api.nvim_win_get_cursor(win)[1]
			index = math.max(1, math.min(#options.exits, math.floor((cursor_row - first_row) / stride + 0.5) + 1))
			if cursor_row ~= row(index) then
				api.nvim_win_set_cursor(win, { row(index), 0 })
			end
		end,
	})
	M.redraw()
	require("apps.network").refresh(true, true)
end

return M
