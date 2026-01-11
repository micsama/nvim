local M = {}
local map = require("utils").map

local state = { terms = {}, last_id = nil }

local runners = {
	python = "uv run %s",
	lua = "lua %s",
	sh = "bash %s",
}

local function get_meta()
	local cwd = vim.fn.getcwd()
	return {
		cwd = cwd,
		display_path = vim.fn.fnamemodify(cwd, ":~"),
		rel_file = vim.fn.expand("%:."),
		ft = vim.bo.filetype,
	}
end

local function get_win_opts(cfg)
	local meta = get_meta()
	local w, h = cfg.width or 0.8, cfg.height or 0.8
	local width = math.floor(vim.o.columns * (w > 1 and w / vim.o.columns or w))
	local height = math.floor(vim.o.lines * (h > 1 and h / vim.o.lines or h))
	return {
		relative = "editor",
		width = width,
		height = height,
		row = math.floor((vim.o.lines - height) / 2),
		col = math.floor((vim.o.columns - width) / 2),
		style = "minimal",
		border = "rounded",
		zindex = 50,
		title = string.format(" %s %s │ %s ", cfg.icon or "", cfg.name or "Term", meta.display_path),
		title_pos = "center",
	}
end

function M.toggle(cfg)
	cfg = type(cfg) == "string" and { cmd = cfg } or cfg or {}
	local meta = get_meta()
	local cmd = type(cfg.cmd) == "function" and cfg.cmd() or cfg.cmd or vim.o.shell
	local id = cmd .. "\0" .. meta.cwd
	local term = state.terms[id] or {}

	if state.last_id and state.last_id ~= id then
		local last = state.terms[state.last_id]
		if last and vim.api.nvim_win_is_valid(last.win or -1) then
			vim.api.nvim_win_close(last.win, true)
		end
	end

	if term.win and vim.api.nvim_win_is_valid(term.win) then
		vim.api.nvim_win_close(term.win, true)
		state.last_id = nil
		return
	end

	local is_new = not (term.buf and vim.api.nvim_buf_is_valid(term.buf))
	if is_new then
		term.buf = vim.api.nvim_create_buf(false, true)
	end
	term.win = vim.api.nvim_open_win(term.buf, true, get_win_opts(cfg))

	if is_new then
		local shell_wrap = cfg.keep and string.format("%s; exec $SHELL", cmd) or cmd
		vim.api.nvim_buf_call(term.buf, function()
			vim.fn.jobstart(shell_wrap, {
				term = true,
				cwd = meta.cwd,
				on_exit = function()
					vim.api.nvim_buf_delete(term.buf, { force = true })
					state.terms[id] = nil
				end,
			})
		end)
	end

	vim.wo[term.win].wrap = cfg.wrap or false
	vim.cmd("startinsert")
	term.cfg = cfg
	state.terms[id], state.last_id = term, id
end

vim.api.nvim_create_autocmd("VimResized", {
	callback = function()
		local term = state.terms[state.last_id]
		if term and vim.api.nvim_win_is_valid(term.win or -1) then
			vim.api.nvim_win_set_config(term.win, get_win_opts(term.cfg))
		end
	end,
})

local keymaps = {
	{ "nvt", "<D-g>", { name = "Terminal", wrap = true } },
	{ "nvt", "<D-i>", { cmd = "lazygit", name = "Lazygit", icon = "󰊢", width = 0.98, height = 0.98 } },
	{ "nvt", "<D-e>", { cmd = "codex", name = "Codex", icon = "󰚩", width = 0.9, height = 0.95 } },
}

for _, k in ipairs(keymaps) do
	map(k[1], k[2], function()
		M.toggle(k[3])
	end)
end

map("n", "<D-r>", function()
	local meta = get_meta()
	local pattern = runners[meta.ft]
	if not pattern then
		return vim.notify("未定义执行器: " .. meta.ft, vim.log.levels.WARN)
	end
	M.toggle({
		cmd = string.format(pattern, meta.rel_file),
		name = "Runner",
		icon = "󰐊",
		width = 0.5,
		height = 0.4,
		keep = true,
	})
end)

return M
