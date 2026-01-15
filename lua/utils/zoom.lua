local M = {}
local winid, group

local function get_opts()
	local name = vim.api.nvim_buf_get_name(0)
	name = (name ~= "") and vim.fn.fnamemodify(name, ":t") or "[No Name]"

	return {
		relative = "editor",
		row = 0,
		col = 0,
		width = math.max(vim.o.columns - 2, 1),
		height = math.max(vim.o.lines - vim.o.cmdheight - 2, 1),
		border = "rounded",
		title = (" %s "):format(name),
		title_pos = "center",
	}
end

function M.toggle()
	-- 1. 主动关闭逻辑
	if winid and vim.api.nvim_win_is_valid(winid) then
		vim.api.nvim_win_close(winid, true)
		return -- 触发 WinClosed 自动清理，此处无需额外操作
	end

	-- 2. 开启逻辑
	winid = vim.api.nvim_open_win(0, true, get_opts())
	vim.cmd.normal("zz")

	-- 3. 响应式与清理逻辑
	group = vim.api.nvim_create_augroup("UserZoom", { clear = true })

	-- 窗口调整：仅监听关键变量
	vim.api.nvim_create_autocmd({ "VimResized", "OptionSet" }, {
		group = group,
		pattern = "cmdheight", -- 仅监听 cmdheight 变化
		callback = function()
			if vim.api.nvim_win_is_valid(winid) then
				vim.api.nvim_win_set_config(winid, get_opts())
			end
		end,
	})

	-- 自动清理：解决“手动关闭窗口导致残留”的问题
	vim.api.nvim_create_autocmd("WinClosed", {
		group = group,
		pattern = tostring(winid),
		callback = function()
			if group then
				vim.api.nvim_del_augroup_by_id(group)
			end
			winid, group = nil, nil
		end,
	})
end

return M
