local M = {}
local api, fn = vim.api, vim.fn
local state = { terms = {}, last_id = nil, runner_cache = nil }

-- 1. 配置中心：统一管理配色与参数
local runners = { python = "uv run %s", lua = "lua %s", sh = "bash %s", go = "go run %s" }

-- Catppuccin Mocha 配色：Blue(Terminal), Green(Lazygit), Peach(Codex), Mauve(Runner)
local apps = {
	["<D-g>"] = { id = "TERM", name = "Terminal", icon = " ", hl = "Function" },
	["<D-i>"] = { name = "Lazygit", icon = "󰊢 ", cmd = "lazygit", w = 0.98, h = 0.95, hl = "String" },
	["<D-e>"] = { name = "Codex", icon = "󰚩 ", cmd = "codex", w = 0.9, h = 0.95, hl = "Number" },
	["<D-r>"] = { name = "Runner", icon = "󰐊", is_runner = true, w = 0.75, h = 0.6, hl = "Constant" },
}

-- 2. 辅助：元数据解析
local function get_meta()
	local cwd = fn.getcwd()
	return {
		cwd = cwd,
		path = fn.fnamemodify(cwd, ":~"),
		file = fn.expand("%:."),
		ft = vim.bo.filetype,
		is_term = vim.bo.buftype == "terminal",
	}
end

-- 3. 辅助：窗口属性计算
local function apply_win_style(win, cfg, meta, title_override)
	local title = title_override or string.format(" %s %s │ %s ", cfg.icon or "", cfg.name, meta.path)
	local hl = cfg.hl or "FloatBorder"

	api.nvim_win_set_config(win, { title = title, title_pos = "center" })
	vim.wo[win].winhighlight = ("FloatBorder:%s,FloatTitle:%s"):format(hl, hl)
	api.nvim_set_option_value("signcolumn", "no", { win = win })
end

-- 4. 核心 Toggle 逻辑
function M.toggle(cfg)
	local meta = get_meta()

	-- Runner 特殊预处理
	if cfg.is_runner and not meta.is_term then
		local cmd = runners[meta.ft]
		if not cmd then
			return vim.notify("未定义执行器: " .. meta.ft, 2)
		end
		state.runner_cache = vim.tbl_extend("force", cfg, {
			cmd = cmd:format(meta.file),
			path = meta.path,
			id = "RUNNER\0" .. meta.cwd,
		})
	end

	local active_cfg = (cfg.is_runner and state.runner_cache) or cfg
	local cmd = active_cfg.cmd or vim.o.shell
	local id = active_cfg.id or (cmd .. "\0" .. meta.cwd)
	local term = state.terms[id] or {}

	-- 互斥与显隐切换
	if state.last_id and state.last_id ~= id then
		local last = state.terms[state.last_id]
		if last and api.nvim_win_is_valid(last.win or -1) then
			api.nvim_win_close(last.win, true)
		end
	end

	if term.win and api.nvim_win_is_valid(term.win) then
		api.nvim_win_close(term.win, true)
		state.last_id = nil
		return
	end

	-- 准备 Buffer 与 窗口
	if not (term.buf and api.nvim_buf_is_valid(term.buf)) then
		term.buf = api.nvim_create_buf(false, true)
		term.needs_launch = true
	end

	local w, h = active_cfg.w or 0.8, active_cfg.h or 0.8
	local ww, wh = math.floor(vim.o.columns * w), math.floor(vim.o.lines * h)

	term.win = api.nvim_open_win(term.buf, true, {
		relative = "editor",
		width = ww,
		height = wh,
		row = (vim.o.lines - wh) / 2,
		col = (vim.o.columns - ww) / 2,
		style = "minimal",
		border = "rounded",
		zindex = 50,
	})

	apply_win_style(term.win, active_cfg, meta)

	-- 启动进程
	if term.needs_launch then
		local final_cmd = active_cfg.is_runner
				and ([[sh -c '%s; printf "\n✅ Done. Enter to close.\n"; read -r']]):format(cmd:gsub("'", "'\\''"))
			or cmd

		api.nvim_buf_call(term.buf, function()
			fn.jobstart(final_cmd, {
				term = true,
				cwd = meta.cwd,
				on_exit = function()
					if active_cfg.is_runner then
						apply_win_style(term.win, active_cfg, meta, " ✅ Finished ")
					end
					vim.defer_fn(function()
						if api.nvim_buf_is_valid(term.buf) then
							api.nvim_buf_delete(term.buf, { force = true })
						end
						state.terms[id] = nil
					end, 100)
				end,
			})
		end)
		term.needs_launch = nil
	end

	vim.cmd("startinsert")
	term.cfg = active_cfg
	state.terms[id], state.last_id = term, id
end

-- 5. 自动缩放
api.nvim_create_autocmd("VimResized", {
	callback = function()
		local term = state.terms[state.last_id]
		if term and term.cfg and api.nvim_win_is_valid(term.win or -1) then
			local c = term.cfg
			local ww, wh = math.floor(vim.o.columns * (c.w or 0.8)), math.floor(vim.o.lines * (c.h or 0.8))
			api.nvim_win_set_config(term.win, {
				relative = "editor", -- 必须保留此字段，否则会报错
				width = ww,
				height = wh,
				row = (vim.o.lines - wh) / 2,
				col = (vim.o.columns - ww) / 2,
			})
		end
	end,
})

for key, cfg in pairs(apps) do
	vim.keymap.set({ "n", "v", "t" }, key, function()
		M.toggle(cfg)
	end)
end

return M
