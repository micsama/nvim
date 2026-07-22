local M = {}
local map = require("utils.map").map
local fclaude = require("utils.floatty_claude")

-- =============================================================================
-- 0. 全局状态中心
-- =============================================================================
-- terms: 存储所有活着的终端实例 { id = { win, buf, cfg, raw_source } }
-- last_id: 当前屏幕上那个浮动窗口的 ID (用于判断 Toggle)
-- ctx_cache: 缓存文件上下文，防止在 Terminal 里获取不到文件类型
local state = { terms = {}, last_id = nil, ctx_cache = nil }

-- =============================================================================
-- 0b. 持久化会话注册表
-- =============================================================================
-- 用于记录"当前存活的 claude 后台会话"，跨 Neovim 重启存活。
-- 按 cwd 区分（不做 pid 隔离）：每个 nvim 实例通常只盯一个项目目录，
-- 不同实例的 cwd 天然不重叠，孤儿检测按 cwd 过滤即可避免误判。
-- 正常 spawn 时写入一条记录；进程退出(on_exit)或用户手动 kill_term 时移除。
-- 如果 nvim 被直接关闭（子进程随之被杀），on_exit 的 vim.schedule 回调
-- 来不及执行，记录就会遗留在文件里 —— 下次启动时读到的就是"未正常关闭"的孤儿。
local REGISTRY_PATH = vim.fn.stdpath("state") .. "/floatty_sessions.json"

local function load_registry()
	local f = io.open(REGISTRY_PATH, "r")
	if not f then
		return {}
	end
	local content = f:read("*a")
	f:close()
	local ok, data = pcall(vim.json.decode, content)
	if not ok or type(data) ~= "table" then
		return {}
	end
	return data
end

local function save_registry(reg)
	local ok, encoded = pcall(vim.json.encode, reg)
	if not ok then
		return
	end
	local f = io.open(REGISTRY_PATH, "w")
	if not f then
		return
	end
	f:write(encoded)
	f:close()
end

local function registry_add(id, entry)
	local reg = load_registry()
	reg[id] = entry
	save_registry(reg)
end

local function registry_remove(id)
	local reg = load_registry()
	if reg[id] ~= nil then
		reg[id] = nil
		save_registry(reg)
	end
end

-- =============================================================================
-- 1. 配置定义 (Data)
-- =============================================================================
local HOME = vim.env.HOME
local RUNNERS = { python = "uv run %s", lua = "lua %s", sh = "bash %s", go = "go run %s", rust = "cargo run" }
local AUTOCLOSE_MS = 100 -- on_exit 后多久自动关窗（留时间瞥一眼结果）

local APPS = {
	-- [Type 1: 直达型]
	{ key = "<D-g>", name = "Terminal", icon = " ", hl = "Function" },
	{ key = "<D-i>", name = "Lazygit", icon = "󰊢 ", cmd = "lazygit", w = 0.98, h = 0.95, hl = "String" },

	-- [Type 2: 菜单型] (只有这种需要 choices)
	{
		key = "<D-e>",
		pick_key = "<M-e>",
		name = "AI",
		icon = "󰚩 ",
		w = 0.9,
		h = 0.95,
		hl = "Number",
		shell = "zsh",
		choices = {
			{ name = "Codex", cmd = "codex" },
			{ name = "Codex-YesCode", cmd = "CODEX_HOME=/Users/dzmfg/.codex1 codex" },
			{ name = "Claude", claude = { dir = HOME .. "/.claude1" } },
			{ name = "🐶Claude🐶", claude = { dir = HOME .. "/.claude2" } },
			{ name = "[😭Claude😭]", claude = { dir = nil } },
			{ name = "Shell", cmd = vim.o.shell },
		},
	},

	-- [Type 3: 动态型]
	{ key = "<D-r>", name = "Runner", icon = "󰐊 ", is_runner = true, w = 0.75, h = 0.6, hl = "Constant" },
}

-- =============================================================================
-- 2. 辅助函数 (Helpers)
-- =============================================================================
local function make_title(prefix, body)
	return (" %s │ %s "):format(prefix, body)
end

local function get_win_opts(cfg)
	local w, h = cfg.w or 0.8, cfg.h or 0.8
	local cols, lines = vim.o.columns, vim.o.lines
	local width, height = math.floor(cols * w), math.floor(lines * h)
	return {
		relative = "editor",
		width = width,
		height = height,
		row = (lines - height) / 2,
		col = (cols - width) / 2,
		style = "minimal",
		border = "rounded",
		zindex = 50,
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

--- 给 statusline 用：返回 APPS 菜单里当前后台存活的选项
--- （idx = 在 picker 列表里的位置，1-based；status = busy|waiting|idle，非 claude 项为 nil）。
--- @return { idx: integer, status: string|nil }[]
function M.active_menu_indices()
	local cwd = vim.uv.cwd() or vim.fn.getcwd()
	local items = {}
	for _, app in ipairs(APPS) do
		if app.choices then
			for i, c in ipairs(app.choices) do
				local id = compute_id(c, cwd)
				local term = state.terms[id]
				if term and term.exited == nil and term.buf and vim.api.nvim_buf_is_valid(term.buf) then
					items[#items + 1] = { idx = i, status = term.claude and term.claude.status }
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
	local reg = load_registry()
	local indices = {}
	for _, app in ipairs(APPS) do
		if app.choices then
			for i, c in ipairs(app.choices) do
				if c.claude then
					local id = compute_id(c, cwd)
					local term = state.terms[id]
					local alive = term and term.exited == nil and term.buf and vim.api.nvim_buf_is_valid(term.buf)
					if not alive and reg[id] then
						indices[#indices + 1] = i
					end
				end
			end
		end
	end
	return indices
end

-- =============================================================================
-- 2b. 呼吸边框（Claude busy 时，边框颜色随时间明暗律动）
-- =============================================================================
local pulse = { timer = nil, win = nil, start_ns = nil }

local function hex_from_hl(name, field, fallback)
	local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
	if ok and hl and hl[field] then
		return hl[field]
	end
	return fallback
end

--- 优先用 Catppuccin 当前 flavour 的 peach，取不到再退回 WarningMsg 前景色
local function pulse_base_color()
	local ok, palettes = pcall(require, "catppuccin.palettes")
	if ok then
		local p = palettes.get_palette()
		if p and p.peach then
			return p.peach
		end
	end
	return hex_from_hl("WarningMsg", "fg", 0xfab387)
end

--- c1/c2 接受数字色值（0xRRGGBB）或 "#rrggbb" 字符串，返回 "#rrggbb"
local function blend(c1, c2, t)
	if type(c1) == "string" then
		c1 = tonumber(c1:sub(2), 16)
	end
	if type(c2) == "string" then
		c2 = tonumber(c2:sub(2), 16)
	end
	local r1, g1, b1 = math.floor(c1 / 65536) % 256, math.floor(c1 / 256) % 256, c1 % 256
	local r2, g2, b2 = math.floor(c2 / 65536) % 256, math.floor(c2 / 256) % 256, c2 % 256
	local r = math.floor(r1 + (r2 - r1) * t + 0.5)
	local g = math.floor(g1 + (g2 - g1) * t + 0.5)
	local b = math.floor(b1 + (b2 - b1) * t + 0.5)
	return string.format("#%02x%02x%02x", r, g, b)
end

local PULSE_PERIOD_S = 1.6 -- 一次呼吸的周期

local function stop_pulse()
	if pulse.timer then
		pcall(function()
			pulse.timer:stop()
			pulse.timer:close()
		end)
		pulse.timer = nil
	end
	pulse.win = nil
end

--- 让 win 的边框随时间呼吸，直到窗口失效或被其他状态打断
local function start_pulse(win)
	if pulse.win == win and pulse.timer then
		return -- 已经在跑了
	end
	stop_pulse()
	pulse.win = win
	pulse.start_ns = vim.uv.hrtime()

	local base = pulse_base_color()
	local bg = hex_from_hl("NormalFloat", "bg", hex_from_hl("Normal", "bg", 0x1e1e2e))
	local white = 0xffffff
	-- 暗端往窗口背景色混，亮端只轻微提亮，全程保持同一色相，像光在呼吸而不是变脏变白
	local dark_end = blend(base, bg, 0.6)
	local bright_end = blend(base, white, 0.2)

	local timer = vim.uv.new_timer()
	pulse.timer = timer
	-- 呼吸周期 1.6s，属于慢速律动，80ms(~12.5fps) 已经足够顺滑，没必要按 UI 帧率(50ms+)去刷
	timer:start(0, 80, function()
		local elapsed = (vim.uv.hrtime() - pulse.start_ns) / 1e9
		local phase = (elapsed % PULSE_PERIOD_S) / PULSE_PERIOD_S
		local t = (math.sin(phase * math.pi * 2) + 1) / 2 -- 0..1
		local color = blend(dark_end, bright_end, t) -- 在暗/亮两端之间明暗律动
		vim.schedule(function()
			if not (pulse.win and vim.api.nvim_win_is_valid(pulse.win)) then
				stop_pulse()
				return
			end
			vim.api.nvim_set_hl(0, "FloattyPulseBusy", { fg = color })
			vim.wo[pulse.win].winhighlight = "FloatBorder:FloattyPulseBusy,FloatTitle:FloattyPulseBusy"
		end)
	end)
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
	local g = fclaude.STATUS_GLYPHS[status] or fclaude.STATUS_GLYPHS.idle
	local prefix = ("%s%s %s"):format(cfg.icon or "", cfg.name, g.icon)
	local body = meta.name or cfg.file or "Term"
	vim.api.nvim_win_set_config(term.win, { title = make_title(prefix, body) })

	if status == "busy" then
		start_pulse(term.win)
	else
		if pulse.win == term.win then
			stop_pulse()
		end
		vim.wo[term.win].winhighlight = ("FloatBorder:%s,FloatTitle:%s"):format(g.hl, g.hl)
	end

	vim.cmd("redrawstatus!")
end

local function kill_term(id)
	local t = state.terms[id]
	if not t then
		return
	end
	if pulse.win == t.win then
		stop_pulse()
	end
	fclaude.detach(t.claude)
	if t.win and vim.api.nvim_win_is_valid(t.win) then
		vim.api.nvim_win_close(t.win, true)
	end
	if t.buf and vim.api.nvim_buf_is_valid(t.buf) then
		vim.api.nvim_buf_delete(t.buf, { force = true })
	end
	if t.cfg and t.cfg.claude then
		registry_remove(id)
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

-- =============================================================================
-- 3. 核心控制器 (Controller)
-- =============================================================================
function M.toggle(raw, choice)
	local ctx = get_ctx()

	-- ============================================================
	-- 阶段 1: 解析目标 (target_cfg, target_id)
	--   - choice 显式传入 → 用 choice
	--   - 否则有 active_id 且 buf 健在 → 复活
	--   - 否则是菜单型 → 走 picker
	--   - 否则 → 用 raw 本体
	-- ============================================================
	local target_id, target_cfg

	if choice then
		target_cfg = vim.tbl_deep_extend("force", vim.deepcopy(raw), choice)
	elseif raw.active_id and state.terms[raw.active_id] and vim.api.nvim_buf_is_valid(state.terms[raw.active_id].buf) then
		target_id = raw.active_id
		target_cfg = state.terms[target_id].cfg
	elseif raw.choices then
		return M.pick(raw)
	else
		target_cfg = vim.deepcopy(raw)
		if raw.active_id then
			raw.active_id = nil -- 记忆已失效
		end
	end

	-- Runner 特殊处理 (仅在新启动路径，复活时保持原 cfg)
	if target_cfg.is_runner and not target_id then
		if not (ctx.ft and RUNNERS[ctx.ft]) then
			return vim.notify("⚠️ No runner for " .. (ctx.ft or "nil"), 3)
		end
		target_cfg = vim.tbl_extend("force", target_cfg, {
			cmd = RUNNERS[ctx.ft]:format(ctx.file),
			id = "RUN::" .. ctx.cwd,
			file = ctx.path .. "/" .. ctx.file,
		})
	end

	target_id = target_id or compute_id(target_cfg, ctx.cwd)

	-- ============================================================
	-- 阶段 2: Toggle Hide
	-- 如果屏幕上正显示的就是 target，且在当前 tab → 藏起来收工
	-- ============================================================
	if state.last_id == target_id then
		local active = state.terms[target_id]
		if active and active.win and vim.api.nvim_win_is_valid(active.win) then
			local same_tab = vim.api.nvim_win_get_tabpage(active.win) == vim.api.nvim_get_current_tabpage()
			if same_tab then
				if active.exited ~= nil then
					kill_term(target_id)
				else
					vim.api.nvim_win_close(active.win, true)
					state.last_id = nil
				end
				vim.schedule(function()
					vim.cmd("checktime")
				end)
				return
			end
			vim.api.nvim_win_close(active.win, true)
			state.last_id = nil
			-- 跨 tab：关掉旧窗，下面在当前 tab 重开
		end
	end

	-- ============================================================
	-- 阶段 3: 互斥关窗
	-- 屏幕上若有别的浮动窗，关窗保留 buf
	-- ============================================================
	if state.last_id and state.last_id ~= target_id then
		local last = state.terms[state.last_id]
		if last and last.win and vim.api.nvim_win_is_valid(last.win) then
			vim.api.nvim_win_close(last.win, true)
		end
	end

	-- ============================================================
	-- 阶段 4: Spawn or Show
	-- ============================================================
	local term = state.terms[target_id] or {}
	if term.exited ~= nil and not (term.win and vim.api.nvim_win_is_valid(term.win)) then
		kill_term(target_id)
		term = {}
	end
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
		local start_time = vim.uv.hrtime()
		local cmd
		if target_cfg.claude then
			-- 注册表里还留着这个 id → 上次是被 nvim 陪葬关闭的孤儿，用 -c 续上那次对话；
			-- 否则是全新会话，走原来的 --session-id 流程（供 status 轮询/标题联动用）。
			local was_orphan = load_registry()[target_id] ~= nil
			if was_orphan then
				cmd = fclaude.build_continue_cmd(target_cfg.claude.dir)
				-- -c 会续接 cwd 下最近一次会话；反查它的 session id，
				-- 让 watcher 重新挂上（找不到则退化为无状态图标，行为同旧版）。
				local sid = fclaude.find_latest_session_id(target_cfg.claude.dir, ctx.cwd)
				if sid then
					term.claude = fclaude.new_meta_resume(target_cfg.claude.dir, sid)
				end
			else
				term.claude = fclaude.new_meta(target_cfg.claude.dir)
				cmd = fclaude.build_cmd(term.claude)
			end
			registry_add(target_id, { ts = os.time() })
		end
		cmd = cmd or target_cfg.cmd or vim.o.shell
		local final_cmd
		if target_cfg.is_runner then
			final_cmd = ("sh -c %s"):format(vim.fn.shellescape(cmd .. '; printf "\\n✅ Done. Enter to close."; read -r'))
		elseif target_cfg.shell then
			final_cmd = { target_cfg.shell, "-c", "exec " .. cmd }
		else
			final_cmd = cmd
		end

		vim.api.nvim_buf_call(term.buf, function()
			vim.fn.jobstart(final_cmd, {
				term = true,
				cwd = target_cfg.cwd or ctx.cwd,
				on_exit = function(_, code)
					vim.schedule(function()
						term.exited = code
						fclaude.detach(term.claude)
						if target_cfg.claude then
							registry_remove(target_id)
						end
						if term.win and vim.api.nvim_win_is_valid(term.win) then
							local icon = code == 0 and "✅" or "❌"
							local exit_hl = code == 0 and "String" or "Error"
							local duration = string.format("%.1fs", (vim.uv.hrtime() - start_time) / 1e9)
							local body = (term.claude and term.claude.name)
								or target_cfg.file
								or target_cfg.name
							vim.api.nvim_win_set_config(term.win, {
								title = make_title(("%s exit %d · %s"):format(icon, code, duration), body),
							})
							vim.wo[term.win].winhighlight = ("FloatBorder:%s,FloatTitle:%s"):format(exit_hl, exit_hl)
						end
						if code == 0 then
							vim.defer_fn(function()
								kill_term(target_id)
							end, AUTOCLOSE_MS)
						end
					end)
				end,
			})
		end)
		if term.claude then
			fclaude.attach(term.claude, function()
				refresh_claude_title(term)
			end)
		end
	else
		vim.cmd("startinsert")
	end

	if term.claude then
		refresh_claude_title(term)
	end

	state.terms[target_id] = term
	state.last_id = target_id
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
	local reg = load_registry()
	local items = {}
	for _, c in ipairs(raw.choices) do
		local merged = vim.tbl_deep_extend("force", vim.deepcopy(raw), c)
		local id = compute_id(merged, ctx.cwd)
		local term = state.terms[id]
		local buf_alive = term and term.buf and vim.api.nvim_buf_is_valid(term.buf)
		local visible = buf_alive and term.win and vim.api.nvim_win_is_valid(term.win)
		local exited = buf_alive and term.exited ~= nil
		local orphan = merged.claude and not buf_alive and reg[id]

		-- Claude 已活：用 status glyph 表"后台存活+状态"，前台用 ▶；二者择一，避免重复
		local is_claude_alive = buf_alive and not exited and merged.claude
		local name_suffix = ""
		if is_claude_alive and term.claude and term.claude.name then
			name_suffix = (" · %s"):format(term.claude.name)
		end

		local marker
		if visible then
			marker = "▶ " -- 前台显示中（Claude 的 status 已在浮窗标题里，不再叠）
		elseif exited then
			marker = "✖ " -- 已退出，选中时会清理后重启
		elseif is_claude_alive and term.claude then
			local g = fclaude.STATUS_GLYPHS[term.claude.status or "idle"] or fclaude.STATUS_GLYPHS.idle
			marker = g.icon .. " " -- 后台 Claude：用 status glyph 单独表示
		elseif buf_alive then
			marker = "○ " -- 后台运行（非 Claude）
		elseif orphan then
			marker = "󰊠 " -- 上次未正常关闭的孤儿会话，选中会用 -c 续上
		else
			marker = "- " -- 未启动
		end
		local status_icon = ""
		if orphan then
			name_suffix = (" (%s 未正常关闭)"):format(os.date("%H:%M", reg[id].ts))
		end

		table.insert(items, {
			choice = c,
			visible = visible,
			label = ("%s%s%s%s"):format(marker, status_icon, c.name, name_suffix),
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
		if i.visible then
			return -- 已经在屏幕上，无事可做
		end
		M.toggle(raw, i.choice)
	end)
end

-- =============================================================================
-- 4. 自动化与按键绑定
-- =============================================================================
vim.api.nvim_create_autocmd("VimResized", {
	callback = function()
		local t = state.terms[state.last_id]
		if t and vim.api.nvim_win_is_valid(t.win) then
			vim.api.nvim_win_set_config(t.win, get_win_opts(t.cfg))
			if t.claude then
				refresh_claude_title(t)
			end
		end
	end,
})

for _, x in ipairs(APPS) do
	map("nvit", x.key, function()
		M.toggle(x)
	end, x.name)
	-- 菜单型再绑一个变体用于 picker（可由 pick_key 显式指定，否则用 Shift 变体）
	if x.choices then
		local pick_key = x.pick_key or x.key:gsub("<D%-(%a)>", "<D-S-%1>")
		map("nvit", pick_key, function()
			M.pick(x)
		end, x.name .. " picker")
	end
end

vim.api.nvim_create_autocmd("TermOpen", {
	callback = function()
		vim.wo.wrap = true
	end,
})

return M
