-- =============================================================================
-- Floatty 控制器：终端实例生命周期（toggle / pick / kill / idle 定时关闭）
-- 本模块 require 时无副作用；keymap 与 autocmd 由 apps.floatty.setup() 注册。
-- =============================================================================
local M = {}
local claude = require("apps.floatty.claude")
local registry = require("apps.floatty.registry")
local pulse = require("apps.floatty.pulse")

-- =============================================================================
-- 0. 全局状态中心
-- =============================================================================
-- terms: 存储所有活着的终端实例 { id = { win, buf, cfg, raw_source } }
-- last_id: 当前屏幕上那个浮动窗口的 ID (用于判断 Toggle)
-- ctx_cache: 缓存文件上下文，防止在 Terminal 里获取不到文件类型
local state = { terms = {}, last_id = nil, ctx_cache = nil }

-- =============================================================================
-- 1. 配置定义 (Data)
-- =============================================================================
local options = require("config.floatty")
M.APPS = vim.deepcopy(options.apps)
local APPS = M.APPS
local RUNNERS = options.runners
local AUTOCLOSE_MS = options.autoclose_ms

-- =============================================================================
-- 2. 辅助函数 (Helpers)
-- =============================================================================
local function make_title(prefix, body)
	return (" %s │ %s "):format(prefix, body)
end

local function get_win_opts(cfg)
	local w, h = cfg.w or options.window.w, cfg.h or options.window.h
	local cols, lines = vim.o.columns, vim.o.lines
	local width, height = math.floor(cols * w), math.floor(lines * h)
	return {
		relative = "editor",
		width = width,
		height = height,
		row = (lines - height) / 2,
		col = (cols - width) / 2,
		style = "minimal",
		border = options.window.border,
		zindex = options.window.zindex,
		title = make_title((cfg.icon or "") .. cfg.name, cfg.file or "Term"),
		title_pos = "center",
	}
end

local function get_ctx()
	local cwd, ft = vim.uv.cwd() or vim.fn.getcwd(), vim.bo.filetype
	if vim.bo.buftype ~= "terminal" and ft ~= "" then
		state.ctx_cache = { file = vim.fn.expand("%:."), path = vim.fn.fnamemodify(cwd, ":~"), ft = ft }
	end
	return vim.tbl_extend("keep", { cwd = cwd }, state.ctx_cache or {})
end

local function compute_id(cfg, cwd)
	if cfg.claude then
		return ("claude::%s::%s"):format(cfg.claude.dir or "default", cwd)
	end
	return cfg.id or ((cfg.cmd or cfg.name) .. "::" .. cwd)
end

local function is_persistent_app(cfg)
	return cfg and (cfg.claude or cfg.codex)
end

--- 某个 claude 型 choice 指定了自定义 dir，但该目录在本机不存在
--- （比如多台电脑共用同一份配置，只有部分机器装了对应的 claude 配置）。
--- 只用于 picker 里把这类选项标成"不可选"，不影响其它 choice。
--- @param c table
--- @return boolean
local function claude_dir_missing(c)
	if not (c.claude and c.claude.dir) then
		return false
	end
	local stat = vim.uv.fs_stat(c.claude.dir)
	return not (stat and stat.type == "directory")
end

--- 从 state.terms[id] 读出一组存活状态布尔量，作为 "alive/exited/visible 各自什么含义"
--- 的唯一定义。三个调用点（active_menu_indices / orphan_menu_indices / pick）都以此为准，
--- 避免各自手写判断导致语义漂移。轻量：只查表 + 校验句柄，无 deepcopy，可放心用在热路径。
--- @param id string
--- @return table|nil term, table status  status = { buf_alive, alive, exited, visible }
local function term_status(id)
	local term = state.terms[id]
	local buf_alive = (term and term.buf and vim.api.nvim_buf_is_valid(term.buf)) and true or false
	return term,
		{
			buf_alive = buf_alive,
			alive = buf_alive and term.exited == nil,
			exited = buf_alive and term.exited ~= nil,
			visible = buf_alive and term.win ~= nil and vim.api.nvim_win_is_valid(term.win),
		}
end

--- 给 statusline 用：返回 APPS 菜单里当前后台存活的选项
--- （idx = 在 picker 列表里的位置，1-based；status = busy|waiting|idle，非 claude 项为 nil）。
--- @return { idx: integer, status: string|nil }[]
function M.active_menu_indices()
	local cwd = vim.uv.cwd() or vim.fn.getcwd()
	local items = {}
	for _, app in ipairs(APPS) do
		if app.choices then
			for i, c in ipairs(app.choices) do
				local term, st = term_status(compute_id(c, cwd))
				if st.alive then
					items[#items + 1] = { idx = i, status = term and term.claude and term.claude.status }
				end
			end
		end
	end
	return items
end

--- 给 statusline 用：返回 APPS 菜单里当前 cwd 下"曾经存活但未正常关闭"的选项序号
--- （即注册表里还有记录、但本次 nvim 里没有对应活体终端 —— 上次的孤儿会话）。
--- @return integer[]
function M.orphan_menu_indices()
	local cwd = vim.uv.cwd() or vim.fn.getcwd()
	local reg = registry.get()
	local indices = {}
	for _, app in ipairs(APPS) do
		if app.choices then
			for i, c in ipairs(app.choices) do
				if is_persistent_app(c) then
					local id = compute_id(c, cwd)
					local _, st = term_status(id)
					if not st.alive and reg[id] then
						indices[#indices + 1] = i
					end
				end
			end
		end
	end
	return indices
end

local function refresh_claude_title(term)
	if not (term and term.win and vim.api.nvim_win_is_valid(term.win)) then
		return
	end
	local cfg, meta = term.cfg, term.claude
	if not (meta and cfg) then
		return
	end
	local status = meta.status or "idle"
	local g = claude.STATUS_GLYPHS[status] or claude.STATUS_GLYPHS.idle
	local prefix = ("%s%s %s"):format(cfg.icon or "", cfg.name, g.icon)
	local body = meta.name or cfg.file or "Term"
	vim.api.nvim_win_set_config(term.win, { title = make_title(prefix, body) })

	if status == "busy" and pulse.enabled() then
		pulse.start(term.win)
	else
		if pulse.win() == term.win then
			pulse.stop()
		end
		vim.wo[term.win].winhighlight = ("FloatBorder:%s,FloatTitle:%s"):format(g.hl, g.hl)
	end

	vim.cmd("redrawstatus!")
end

local function cancel_idle_timer(term)
	local timer = term.idle_timer
	if not timer then
		return
	end
	term.idle_timer = nil
	if not timer:is_closing() then
		timer:close()
	end
end

local function kill_term(id, expected)
	local t = state.terms[id]
	if not t or (expected and t ~= expected) then
		return
	end
	cancel_idle_timer(t)
	local win = t.win
	t.win = nil -- 避免 WinClosed 把主动销毁误判为隐藏
	if pulse.win() == win then
		pulse.stop()
	end
	claude.detach(t.claude)
	if win and vim.api.nvim_win_is_valid(win) then
		vim.api.nvim_win_close(win, true)
	end
	if t.buf and vim.api.nvim_buf_is_valid(t.buf) then
		vim.api.nvim_buf_delete(t.buf, { force = true })
	end
	if is_persistent_app(t.cfg) then
		registry.remove(id)
	end

	-- [重要] 清理记忆指针：如果这个死掉的终端是某组配置的"现任"，则将其废黜
	if t.raw_source and t.raw_source.active_id == id then
		t.raw_source.active_id = nil
	end

	state.terms[id] = nil
	if state.last_id == id then
		state.last_id = nil
	end
end

--- 隐藏超过配置的时限后关闭终端；timer 身份校验可拦截已经入队的旧回调。
local function schedule_idle_close(id, term)
	local ttl = term.cfg.idle_ttl_ms
	if not ttl then
		return
	end
	cancel_idle_timer(term)
	local timer
	timer = vim.defer_fn(function()
		local current = state.terms[id]
		if not current or current.idle_timer ~= timer then
			return
		end
		current.idle_timer = nil
		if not (current.win and vim.api.nvim_win_is_valid(current.win)) then
			kill_term(id)
		end
	end, ttl)
	term.idle_timer = timer
end

-- =============================================================================
-- 3. 核心控制器 (Controller)
-- toggle = resolve_target → hide_if_shown → 互斥关窗 → show_term（→ spawn_job）
-- =============================================================================

--- 阶段 1: 解析目标。
---   - choice 显式传入 → 用 choice
---   - 否则有 active_id 且 buf 健在 → 复活
---   - 否则是菜单型 → 返回 nil，由调用方走 picker
---   - 否则 → 用 raw 本体
--- Runner 只在新启动路径按文件类型拼命令，复活时保持原 cfg。
--- @return table|nil cfg, string|nil id
local function resolve_target(raw, choice, ctx)
	local target_id, target_cfg
	if choice then
		target_cfg = vim.tbl_deep_extend("force", vim.deepcopy(raw), choice)
	elseif
		raw.active_id
		and state.terms[raw.active_id]
		and vim.api.nvim_buf_is_valid(state.terms[raw.active_id].buf)
	then
		target_id = raw.active_id
		target_cfg = state.terms[target_id].cfg
	elseif raw.choices then
		return nil
	else
		target_cfg = vim.deepcopy(raw)
		raw.active_id = nil -- 记忆已失效
	end

	if target_cfg.is_runner and not target_id then
		if not (ctx.ft and RUNNERS[ctx.ft]) then
			vim.notify("⚠️ No runner for " .. (ctx.ft or "nil"), 3)
			return nil
		end
		target_cfg = vim.tbl_extend("force", target_cfg, {
			cmd = RUNNERS[ctx.ft]:format(vim.fn.shellescape(ctx.file)),
			id = "RUN::" .. ctx.cwd,
			file = ctx.path .. "/" .. ctx.file,
		})
	end

	return target_cfg, target_id or compute_id(target_cfg, ctx.cwd)
end

--- 阶段 2: 屏幕上正显示的就是 target 且在当前 tab → 藏起来（已退出则销毁），返回 true 收工。
--- 在别的 tab 显示 → 关掉旧窗，由后续流程在当前 tab 重开。
local function hide_if_shown(target_id)
	if state.last_id ~= target_id then
		return false
	end
	local active = state.terms[target_id]
	if not (active and active.win and vim.api.nvim_win_is_valid(active.win)) then
		return false
	end
	if vim.api.nvim_win_get_tabpage(active.win) ~= vim.api.nvim_get_current_tabpage() then
		vim.api.nvim_win_close(active.win, true)
		return false
	end
	if active.exited ~= nil then
		kill_term(target_id)
	else
		vim.api.nvim_win_close(active.win, true)
	end
	vim.schedule(function()
		vim.cmd("checktime")
	end)
	return true
end

--- 按应用类型拼出最终命令；claude/codex 会根据注册表判断是否续接孤儿会话。
local function build_cmd(term, target_cfg, target_id, ctx)
	local cmd
	if target_cfg.claude then
		-- 注册表里还留着这个 id → 上次是被 nvim 陪葬关闭的孤儿，用 -c 续上那次对话；
		-- 否则是全新会话，走原来的 --session-id 流程（供 status 轮询/标题联动用）。
		local was_orphan = registry.refresh()[target_id] ~= nil
		if was_orphan then
			cmd = claude.build_continue_cmd(target_cfg.claude.dir)
			-- -c 会续接 cwd 下最近一次会话；反查它的 session id，
			-- 让 watcher 重新挂上（找不到则退化为无状态图标，行为同旧版）。
			local sid = claude.find_latest_session_id(target_cfg.claude.dir, ctx.cwd)
			if sid then
				term.claude = claude.new_meta_resume(target_cfg.claude.dir, sid)
			end
		else
			term.claude = claude.new_meta(target_cfg.claude.dir)
			cmd = claude.build_cmd(term.claude)
		end
	elseif target_cfg.codex then
		-- Codex 没有 Claude 那样可监听的实时状态文件；只记录会话是否
		-- 在 Neovim 正常存活期间被托管，异常重启时用 --last 恢复。
		cmd = registry.refresh()[target_id] ~= nil and "codex resume --last" or "codex"
	end
	cmd = cmd or target_cfg.cmd or vim.o.shell

	if target_cfg.is_runner then
		return ("sh -c %s"):format(vim.fn.shellescape(cmd .. '; printf "\\n✅ Done. Enter to close."; read -r'))
	elseif target_cfg.shell then
		return { target_cfg.shell, "-c", "exec " .. cmd }
	end
	return cmd
end

--- 在 term.buf 里启动 job；退出时更新标题/边框，成功退出的延迟自动关闭。
local function spawn_job(term, target_cfg, target_id, ctx)
	local start_time = vim.uv.hrtime()
	local final_cmd = build_cmd(term, target_cfg, target_id, ctx)
	if is_persistent_app(target_cfg) then
		registry.add(target_id, { ts = os.time() })
	end

	local spawned_buf = term.buf
	vim.api.nvim_buf_call(spawned_buf, function()
		vim.fn.jobstart(final_cmd, {
			term = true,
			cwd = target_cfg.cwd or ctx.cwd,
			on_exit = function(_, code)
				vim.schedule(function()
					if state.terms[target_id] ~= term or term.buf ~= spawned_buf then
						return -- 旧 job 的退出事件不能修改新实例或它的注册记录。
					end
					term.exited = code
					claude.detach(term.claude)
					if is_persistent_app(target_cfg) then
						registry.remove(target_id)
					end
					if term.win and vim.api.nvim_win_is_valid(term.win) then
						local icon = code == 0 and "✅" or "❌"
						local exit_hl = code == 0 and "String" or "Error"
						local duration = string.format("%.1fs", (vim.uv.hrtime() - start_time) / 1e9)
						local body = (term.claude and term.claude.name) or target_cfg.file or target_cfg.name
						vim.api.nvim_win_set_config(term.win, {
							title = make_title(("%s exit %d · %s"):format(icon, code, duration), body),
						})
						vim.wo[term.win].winhighlight = ("FloatBorder:%s,FloatTitle:%s"):format(exit_hl, exit_hl)
					end
					if code == 0 then
						vim.defer_fn(function()
							if term.buf == spawned_buf then
								kill_term(target_id, term)
							end
						end, AUTOCLOSE_MS)
					end
				end)
			end,
		})
	end)
	if term.claude then
		claude.attach(term.claude, function()
			refresh_claude_title(term)
		end)
	end
end

--- 阶段 4: 复用或新建终端 buffer，打开浮窗；新 buffer 才启动 job。
local function show_term(raw, target_cfg, target_id, ctx)
	local term = state.terms[target_id] or {}
	if term.exited ~= nil and not (term.win and vim.api.nvim_win_is_valid(term.win)) then
		kill_term(target_id)
		term = {}
	end
	cancel_idle_timer(term) -- 重新显示：撤销之前排的空闲自动关闭
	local is_new = not (term.buf and vim.api.nvim_buf_is_valid(term.buf))

	raw.active_id = target_id
	term.raw_source = raw
	term.cfg = target_cfg
	term.exited = nil

	if is_new then
		term.buf = vim.api.nvim_create_buf(false, true)
	end

	term.win = vim.api.nvim_open_win(term.buf, true, get_win_opts(target_cfg))
	local hl = target_cfg.hl or "FloatBorder"
	vim.wo[term.win].winhighlight = ("FloatBorder:%s,FloatTitle:%s"):format(hl, hl)

	if is_new then
		spawn_job(term, target_cfg, target_id, ctx)
	else
		vim.cmd("startinsert")
	end

	if term.claude then
		refresh_claude_title(term)
	end

	state.terms[target_id] = term
	state.last_id = target_id
end

function M.toggle(raw, choice)
	local ctx = get_ctx()
	local target_cfg, target_id = resolve_target(raw, choice, ctx)
	if not target_cfg then
		if raw.choices and not choice then
			M.pick(raw)
		end
		return
	end

	if hide_if_shown(target_id) then
		return
	end

	-- 阶段 3: 互斥关窗 —— 屏幕上若有别的浮动窗，关窗保留 buf
	if state.last_id and state.last_id ~= target_id then
		local last = state.terms[state.last_id]
		if last and last.win and vim.api.nvim_win_is_valid(last.win) then
			vim.api.nvim_win_close(last.win, true)
		end
	end

	show_term(raw, target_cfg, target_id, ctx)
end

-- =============================================================================
-- 3b. Picker (Shift 变体)
-- 列出 raw.choices 所有项及当前运行状态
-- =============================================================================
function M.pick(raw)
	if not raw.choices then
		return M.toggle(raw)
	end

	local ctx = get_ctx()
	local reg = registry.refresh()
	local items = {}
	for _, c in ipairs(raw.choices) do
		local disabled = claude_dir_missing(c)
		local merged = vim.tbl_deep_extend("force", vim.deepcopy(raw), c)
		local id = compute_id(merged, ctx.cwd)
		local term, st = term_status(id)
		local buf_alive = st.buf_alive
		local visible = st.visible
		local exited = st.exited
		local orphan = is_persistent_app(merged) and not buf_alive and reg[id]

		-- Claude 已活：用 status glyph 表"后台存活+状态"，前台用 ▶；二者择一，避免重复
		local is_claude_alive = buf_alive and not exited and merged.claude
		local name_suffix = ""
		if is_claude_alive and term and term.claude and term.claude.name then
			name_suffix = (" · %s"):format(term.claude.name)
		end

		local marker
		if disabled then
			marker = "  " -- 目录不存在，本机不可用
		elseif visible then
			marker = "▶ " -- 前台显示中（Claude 的 status 已在浮窗标题里，不再叠）
		elseif exited then
			marker = "✖ " -- 已退出，选中时会清理后重启
		elseif is_claude_alive and term and term.claude then
			local g = claude.STATUS_GLYPHS[term.claude.status or "idle"] or claude.STATUS_GLYPHS.idle
			marker = g.icon .. " " -- 后台 Claude：用 status glyph 单独表示
		elseif buf_alive then
			marker = "○ " -- 后台运行（非 Claude）
		elseif orphan then
			marker = "󰊠 " -- 上次未正常关闭的孤儿会话，选中会用 -c 续上
		else
			marker = "- " -- 未启动
		end
		if orphan then
			name_suffix = (" (%s 未正常关闭)"):format(os.date("%H:%M", reg[id].ts))
		elseif disabled then
			name_suffix = " (目录不存在)"
		end

		table.insert(items, {
			choice = c,
			visible = visible,
			disabled = disabled,
			label = ("%s%s%s"):format(marker, c.name, name_suffix),
		})
	end

	vim.ui.select(items, {
		prompt = (raw.icon or "") .. raw.name .. ":",
		format_item = function(i)
			return i.label
		end,
	}, function(i)
		if not i then
			return
		end
		if i.disabled then
			return vim.notify(("⚠️ %s 目录不存在，跳过"):format(i.choice.name), 3)
		end
		if i.visible then
			return -- 已经在屏幕上，无事可做
		end
		M.toggle(raw, i.choice)
	end)
end

-- =============================================================================
-- 4. 事件处理（由 apps.floatty.setup() 挂到 autocmd 上）
-- =============================================================================
function M.on_resized()
	local t = state.terms[state.last_id]
	if t and t.win and vim.api.nvim_win_is_valid(t.win) then
		vim.api.nvim_win_set_config(t.win, get_win_opts(t.cfg))
		if t.claude then
			refresh_claude_title(t)
		end
	end
end

--- 处理 :close、<C-w>c 等外部关窗：窗口消失后仍保留终端，按配置启动 idle TTL。
function M.on_win_closed(win)
	for id, term in pairs(state.terms) do
		if term.win == win then
			term.win = nil
			if state.last_id == id then
				state.last_id = nil
			end
			schedule_idle_close(id, term)
			break
		end
	end
end

return M
