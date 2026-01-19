-- ===========================================================================
-- 浮窗终端与工具入口
-- ===========================================================================

local M = {}
local api, fn = vim.api, vim.fn
local map = require("utils.map").map

local ID_SEP = "\0"
local state = { terms = {}, last_id = nil }

-- =============================================================================
-- 配置中心
-- =============================================================================
-- stylua: ignore start
local runners = {
	python = "uv run %s", lua = "lua %s", sh = "bash %s", go = "go run %s", rust = "cargo run",
}

local apps = {
	{ key = "<D-g>", id = "TERM", name = "Terminal", icon = " ", hl = "Function" },
	{ key = "<D-i>", name = "Lazygit", icon = "󰊢 ", cmd = "lazygit", w = 0.98, h = 0.95, hl = "String" },
	{ key = "<D-e>", name = "Codex", icon = "󰚩 ", cmd = "codex", w = 0.9, h = 0.95, hl = "Number" },
	{ key = "<D-r>", name = "Runner", icon = "󰐊 ", is_runner = true, w = 0.75, h = 0.6, hl = "Constant" },
}
-- stylua: ignore end

-- =============================================================================
-- 辅助函数
-- =============================================================================
local function make_id(key, cwd)
	return key .. ID_SEP .. cwd
end

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

local function apply_win_style(win, hl, title)
	if not api.nvim_win_is_valid(win) then
		return
	end
	api.nvim_win_set_config(win, { title = title, title_pos = "center" })
	vim.wo[win].winhighlight = ("FloatBorder:%s,FloatTitle:%s"):format(hl, hl)
	vim.wo[win].signcolumn = "no"
end

local function format_duration(start_time)
	return string.format("%.1fs", vim.uv.hrtime() / 1e9 - start_time)
end

local function build_runner_cfg(base_cfg, meta)
	local cmd_tpl = runners[meta.ft]
	if not cmd_tpl then
		vim.notify("未定义执行器: " .. meta.ft, vim.log.levels.WARN)
		return nil
	end
	return vim.tbl_extend("force", base_cfg, {
		cmd = cmd_tpl:format(meta.file),
		id = make_id("RUNNER", meta.file), -- 按文件区分，避免缓存污染
	})
end

-- =============================================================================
-- 核心 Toggle 逻辑
-- =============================================================================
function M.toggle(cfg)
	local meta = get_meta()

	-- Runner 预处理
	if cfg.is_runner and not meta.is_term then
		cfg = build_runner_cfg(cfg, meta)
		if not cfg then
			return
		end
	end

	local cmd = cfg.cmd or vim.o.shell
	local id = cfg.id or make_id(cmd, meta.cwd)
	local term = state.terms[id] or {}

	-- 互斥：关闭其他浮窗
	if state.last_id and state.last_id ~= id then
		local last = state.terms[state.last_id]
		if last and api.nvim_win_is_valid(last.win or -1) then
			api.nvim_win_close(last.win, true)
		end
	end

	-- 切换显隐
	if term.win and api.nvim_win_is_valid(term.win) then
		api.nvim_win_close(term.win, true)
		state.last_id = nil
		return
	end

	-- 创建 Buffer
	local needs_launch = not (term.buf and api.nvim_buf_is_valid(term.buf))
	if needs_launch then
		term.buf = api.nvim_create_buf(false, true)
	end

	-- 计算窗口尺寸
	local w, h = cfg.w or 0.8, cfg.h or 0.8
	local ww, wh = math.floor(vim.o.columns * w), math.floor(vim.o.lines * h)

	-- 创建浮窗
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

	local default_title = (" %s%s │ %s "):format(cfg.icon or "", cfg.name, meta.path)
	apply_win_style(term.win, cfg.hl or "FloatBorder", default_title)

	-- 启动进程
	if needs_launch then
		local start_time = vim.uv.hrtime() / 1e9
		local final_cmd = cfg.is_runner
				and ("sh -c %s"):format(fn.shellescape(cmd .. '; printf "\\n✅ Done. Enter to close."; read -r'))
			or cmd

		api.nvim_buf_call(term.buf, function()
			fn.jobstart(final_cmd, {
				term = true,
				cwd = meta.cwd,
				on_exit = function(_, code)
					vim.schedule(function()
						local ok = code == 0
						local hl = ok and "String" or "DiagnosticError"
						local icon = ok and "✅" or "❌"
						local title = (" %s %s │ %s "):format(icon, format_duration(start_time), meta.path)
						apply_win_style(term.win, hl, title)

						vim.defer_fn(function()
							if term.buf and api.nvim_buf_is_valid(term.buf) then
								api.nvim_buf_delete(term.buf, { force = true })
							end
							state.terms[id] = nil
						end, 100)
					end)
				end,
			})
		end)
	end

	vim.cmd.startinsert()
	term.cfg, state.terms[id], state.last_id = cfg, term, id
end

-- =============================================================================
-- 自动缩放
-- =============================================================================
api.nvim_create_autocmd("VimResized", {
	callback = function()
		local term = state.terms[state.last_id]
		if not (term and term.cfg and api.nvim_win_is_valid(term.win or -1)) then
			return
		end

		local c = term.cfg
		local ww = math.floor(vim.o.columns * (c.w or 0.8))
		local wh = math.floor(vim.o.lines * (c.h or 0.8))

		api.nvim_win_set_config(term.win, {
			relative = "editor",
			width = ww,
			height = wh,
			row = (vim.o.lines - wh) / 2,
			col = (vim.o.columns - ww) / 2,
		})
	end,
})

-- =============================================================================
-- 键位绑定
-- =============================================================================
vim.iter(apps):each(function(cfg)
	map("nvt", cfg.key, function()
		M.toggle(cfg)
	end, cfg.name)
end)

return M
