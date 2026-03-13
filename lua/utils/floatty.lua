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
local RUNNERS = { python = "uv run %s", lua = "lua %s", sh = "bash %s", go = "go run %s", rust = "cargo run" }

local APPS = {
	-- [Type 1: 直达型]
	{ key = "<D-g>", name = "Terminal", icon = " ", hl = "Function" },
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
			{ name = "Claude", cmd = "claude" },
			{ name = "Shell", cmd = vim.o.shell },
		},
	},

	-- [Type 3: 动态型]
	{ key = "<D-r>", name = "Runner", icon = "󰐊 ", is_runner = true, w = 0.75, h = 0.6, hl = "Constant" },
}

-- =============================================================================
-- 2. 辅助函数 (Helpers)
-- =============================================================================
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
		title = (" %s%s │ %s "):format(cfg.icon or "", cfg.name, cfg.file or "Term"),
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

	-- [重要] 清理记忆指针：如果这个死掉的终端是某组配置的“现任”，则将其废黜
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
	-- ============================================================
	-- 阶段 1: 闭嘴 (Toggle Hide)
	-- 如果当前打开的窗口就是“这组配置”里的，直接关掉
	-- ============================================================
	if state.last_id then
		local active_term = state.terms[state.last_id]
		-- 判断内存地址相等，说明是同一个 raw 配置组
		if active_term and active_term.raw_source == raw then
			vim.api.nvim_win_close(active_term.win, true)
			state.last_id = nil
			-- 关闭浮窗后检查外部改动，刷新底层 buffer
			vim.schedule(function()
				vim.cmd("checktime")
			end)
			return -- 结束，不做任何事
		end
	end

	-- ============================================================
	-- 阶段 2: 复活 (Resume)
	-- 只有在没指定 choice 的情况下才尝试复活（防止用户想强制开新的）
	-- ============================================================
	local target_id = nil
	local target_cfg = nil

	if not choice and raw.active_id then
		local saved = state.terms[raw.active_id]
		-- 检查记忆中的进程是否还健在
		if saved and vim.api.nvim_buf_is_valid(saved.buf) then
			target_id = raw.active_id
			target_cfg = saved.cfg
			-- 这里不递归！直接拿着找到的 ID 去阶段 4 执行显示逻辑
		else
			raw.active_id = nil -- 记忆已失效，清除
		end
	end

	-- ============================================================
	-- 阶段 3: 点菜 (Selection)
	-- 如果没能复活，且需要选择，就弹窗
	-- ============================================================
	if not target_id and raw.choices and not choice then
		return vim.ui.select(raw.choices, {
			prompt = "Tool:",
			format_item = function(i)
				return i.name
			end,
		}, function(c)
			if c then
				M.toggle(raw, c)
			end -- 只有这里需要递归，因为用户产生了新的输入
		end)
	end

	-- ============================================================
	-- 阶段 4: 执行 (Execute - Spawn or Show)
	-- 此时我们必然已经有了足够的信息来开启窗口
	-- ============================================================

	-- 4.1 准备配置 (如果不是复活的，需要重新计算配置)
	local ctx = get_ctx()
	if not target_cfg then
		-- 合并 raw 和 user choice
		target_cfg = vim.deepcopy(choice and vim.tbl_deep_extend("force", raw, choice) or raw)

		-- 特殊处理 Runner
		if target_cfg.is_runner then
			if not (ctx.ft and RUNNERS[ctx.ft]) then
				return vim.notify("⚠️ No runner for " .. (ctx.ft or "nil"), 3)
			end
			target_cfg = vim.tbl_extend("force", target_cfg, {
				cmd = RUNNERS[ctx.ft]:format(ctx.file),
				id = "RUN::" .. ctx.cwd, -- Runner ID 格式
				file = ctx.path .. "/" .. ctx.file,
			})
		end
	end

	-- 4.2 计算最终 ID (复活的直接用，新算的生成)
	target_id = target_id or (target_cfg.id or (target_cfg.cmd or target_cfg.name) .. "::" .. ctx.cwd)
	local term = state.terms[target_id] or {}

	-- 4.3 互斥逻辑 (Switch) - 如果有别的窗口开着，关掉它
	if state.last_id and state.last_id ~= target_id then
		local last = state.terms[state.last_id]
		if last and vim.api.nvim_win_is_valid(last.win) then
			vim.api.nvim_win_close(last.win, true)
		end
	end

	-- 4.4 启动或显示
	local is_new = not (term.buf and vim.api.nvim_buf_is_valid(term.buf))

	-- [重要] 更新记忆：无论这是新的还是复活的，它现在就是这组配置的“现任”
	raw.active_id = target_id
	term.raw_source = raw
	term.cfg = target_cfg -- 确保 term 上始终有最新的 cfg

	if is_new then
		term.buf = vim.api.nvim_create_buf(false, true)
	end

	-- 创建窗口
	term.win = vim.api.nvim_open_win(term.buf, true, get_win_opts(target_cfg))
	vim.api.nvim_set_option_value(
		"winhighlight",
		"FloatBorder:" .. (target_cfg.hl or "FloatBorder") .. ",FloatTitle:" .. (target_cfg.hl or "FloatBorder"),
		{ win = term.win }
	)

	-- 如果是新的，启动进程
	if is_new then
		local start_time = vim.uv.hrtime()
		-- 构建命令
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
						-- 更新窗口标题显示结果
						if vim.api.nvim_win_is_valid(term.win) then
							local icon = code == 0 and "✅" or "❌"
							local hl = code == 0 and "String" or "Error"
							local duration = string.format("%.1fs", (vim.uv.hrtime() - start_time) / 1e9)
							local title = (" %s %s │ %s "):format(icon, duration, target_cfg.file or target_cfg.name)
							vim.api.nvim_win_set_config(term.win, { title = title })
							vim.api.nvim_set_option_value(
								"winhighlight",
								"FloatBorder:" .. hl .. ",FloatTitle:" .. hl,
								{ win = term.win }
							)
						end
						-- 延时自动销毁
						vim.defer_fn(function()
							kill_term(target_id)
						end, 100)
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

vim.iter(APPS):each(function(x)
	map("nvt", x.key, function()
		M.toggle(x)
	end, x.name)
end)

return M
