local M = {}
local map = require("utils.map").map

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
		name = "AI",
		icon = "󰚩 ",
		w = 0.9,
		h = 0.95,
		hl = "Number",
		choices = {
			{ name = "Codex", cmd = "codex" },
			{ name = "Gemini", cmd = "gemini" },
			{ name = "Claude", cmd = ("CLAUDE_CONFIG_DIR='%s/.claude1' claude"):format(HOME) },
			{ name = "🐶Claude🐶", cmd = ("CLAUDE_CONFIG_DIR='%s/.claude2' claude"):format(HOME) },
			{ name = "[😭Claude😭]", cmd = ("claude"):format(HOME) },
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
	return cfg.id or ((cfg.cmd or cfg.name) .. "::" .. cwd)
end

local function kill_term(id)
	local t = state.terms[id]
	if not t then
		return
	end
	if t.win and vim.api.nvim_win_is_valid(t.win) then
		vim.api.nvim_win_close(t.win, true)
	end
	if t.buf and vim.api.nvim_buf_is_valid(t.buf) then
		vim.api.nvim_buf_delete(t.buf, { force = true })
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
			vim.api.nvim_win_close(active.win, true)
			state.last_id = nil
			if same_tab then
				vim.schedule(function()
					vim.cmd("checktime")
				end)
				return
			end
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
	local is_new = not (term.buf and vim.api.nvim_buf_is_valid(term.buf))

	raw.active_id = target_id
	term.raw_source = raw
	term.cfg = target_cfg

	if is_new then
		term.buf = vim.api.nvim_create_buf(false, true)
	end

	term.win = vim.api.nvim_open_win(term.buf, true, get_win_opts(target_cfg))
	local hl = target_cfg.hl or "FloatBorder"
	vim.wo[term.win].winhighlight = ("FloatBorder:%s,FloatTitle:%s"):format(hl, hl)

	if is_new then
		local start_time = vim.uv.hrtime()
		local cmd = target_cfg.cmd or vim.o.shell
		local final_cmd = target_cfg.is_runner
				and ("sh -c %s"):format(vim.fn.shellescape(cmd .. '; printf "\\n✅ Done. Enter to close."; read -r'))
			or cmd

		vim.api.nvim_buf_call(term.buf, function()
			vim.fn.jobstart(final_cmd, {
				term = true,
				cwd = target_cfg.cwd or ctx.cwd,
				on_exit = function(_, code)
					vim.schedule(function()
						if vim.api.nvim_win_is_valid(term.win) then
							local icon = code == 0 and "✅" or "❌"
							local exit_hl = code == 0 and "String" or "Error"
							local duration = string.format("%.1fs", (vim.uv.hrtime() - start_time) / 1e9)
							vim.api.nvim_win_set_config(term.win, {
								title = make_title(icon .. " " .. duration, target_cfg.file or target_cfg.name),
							})
							vim.wo[term.win].winhighlight = ("FloatBorder:%s,FloatTitle:%s"):format(exit_hl, exit_hl)
						end
						vim.defer_fn(function()
							kill_term(target_id)
						end, AUTOCLOSE_MS)
					end)
				end,
			})
		end)
	else
		vim.cmd("startinsert")
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
	local items = {}
	for _, c in ipairs(raw.choices) do
		local merged = vim.tbl_deep_extend("force", vim.deepcopy(raw), c)
		local id = compute_id(merged, ctx.cwd)
		local term = state.terms[id]
		local buf_alive = term and term.buf and vim.api.nvim_buf_is_valid(term.buf)
		local visible = buf_alive and term.win and vim.api.nvim_win_is_valid(term.win)

		local marker
		if visible then
			marker = "" -- nf-fa-check_circle
		elseif buf_alive then
			marker = "" -- nf-fa-circle (solid)
		else
			marker = "" -- nf-fa-circle_o (outline)
		end

		table.insert(items, {
			choice = c,
			visible = visible,
			label = ("%s  %s"):format(marker, c.name),
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
		end
	end,
})

for _, x in ipairs(APPS) do
	map("nvit", x.key, function()
		M.toggle(x)
	end, x.name)
	-- 菜单型再绑一个 Shift 变体用于 picker
	if x.choices then
		local shift_key = x.key:gsub("<D%-(%a)>", "<D-S-%1>")
		map("nvit", shift_key, function()
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
