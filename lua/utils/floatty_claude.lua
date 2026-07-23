-- =============================================================================
-- floatty_claude — 把 Claude Code 的 sessions/<pid>.json 元数据映射给浮窗 UI
-- =============================================================================
-- 主要职责：
--   * 生成 UUID & 拼装 `claude --session-id ... -n ...` 启动命令
--   * 在 ~/.claude*/sessions/ 里轮询找到自己的 JSON，然后改用 fs_event 监听
--   * 一旦 .name / .status 发生变化，触发上层注册的 on_change 回调
-- 不负责实际改窗口标题 —— 那是调用方（floatty.lua / statusline）的工作。
-- =============================================================================

local M = {}
local HOME = vim.env.HOME
local json_store = require("utils.json_store")

local POLL_INTERVAL_MS = 120
local POLL_MAX_TRIES = 40 -- 兜底 ~5s 还找不到 json 就放弃

M.STATUS_GLYPHS = {
	busy = { icon = "●", hl = "WarningMsg" }, -- 跑中
	waiting = { icon = "◐", hl = "Question" }, -- 等输入
	idle = { icon = "○", hl = "Function" }, -- 闲置
}

--- @class ClaudeMeta
--- @field dir          string|nil       CLAUDE_CONFIG_DIR；nil → 默认 ~/.claude
--- @field session_id   string           我们生成并通过 --session-id 注入的 UUID
--- @field initial_tag  string           通过 -n 注入的初始展示名（兜底）
--- @field json_path    string|nil       sessions/<pid>.json，发现后填充
--- @field name         string|nil       最新 /rename 名
--- @field status       string|nil       busy|waiting|idle
--- @field watcher      uv_fs_event_t|nil
--- @field poll_timer   uv_timer_t|nil

-- ---------------------------------------------------------------------------
-- 1. 工厂 & 命令拼装
-- ---------------------------------------------------------------------------
local function gen_uuid()
	local out = vim.fn.system("uuidgen"):gsub("%s+", ""):lower()
	if out == "" then
		error("floatty_claude: uuidgen failed; install uuid-runtime or coreutils")
	end
	return out
end

--- @param dir string|nil
--- @return ClaudeMeta
function M.new_meta(dir)
	return {
		dir = dir,
		session_id = gen_uuid(),
		initial_tag = ("nvim-%d-%s"):format(vim.fn.getpid(), os.date("%H%M%S")),
	}
end

--- @param meta ClaudeMeta
function M.build_cmd(meta)
	local prefix = meta.dir and ("env CLAUDE_CONFIG_DIR=%s "):format(vim.fn.shellescape(meta.dir)) or ""
	return ("%sclaude --session-id %s -n %s"):format(
		prefix,
		meta.session_id,
		vim.fn.shellescape(meta.initial_tag)
	)
end

--- 续上一次被打断（未正常关闭）的对话，不生成新 session-id/watcher
--- @param dir string|nil
function M.build_continue_cmd(dir)
	local prefix = dir and ("env CLAUDE_CONFIG_DIR=%s "):format(vim.fn.shellescape(dir)) or ""
	return prefix .. "claude -c"
end

--- 孤儿续接专用 meta：session_id 是从磁盘历史里反查出来的（而非自己生成），
--- 因此不需要 initial_tag —— name/status 会由 attach() 从 sessions/<pid>.json 拉取。
--- @param dir string|nil
--- @param session_id string
--- @return ClaudeMeta
function M.new_meta_resume(dir, session_id)
	return {
		dir = dir,
		session_id = session_id,
	}
end

--- 反查某 cwd 下最近一次会话的 session id。
--- 原理：claude 把每个会话完整落盘到 projects/<slug>/<session-id>.jsonl，
--- 文件名即 session id；slug = realpath(cwd) 里每个非字母数字字符替换成 '-'。
--- 取 mtime 最新的那个，正是 `claude -c` 会续接的会话 —— 二者一致，
--- 因此可用它作为 watcher 的匹配键。找不到则返回 nil（退回无追踪的 -c）。
--- @param dir string|nil        CLAUDE_CONFIG_DIR；nil → 默认 ~/.claude
--- @param cwd string           会话所在工作目录
--- @return string|nil
function M.find_latest_session_id(dir, cwd)
	local real = vim.uv.fs_realpath(cwd) or cwd
	local slug = real:gsub("[^%w]", "-")
	local pdir = (dir or (HOME .. "/.claude")) .. "/projects/" .. slug
	local h = vim.uv.fs_scandir(pdir)
	if not h then
		return nil
	end
	local best_id, best_mtime = nil, -1
	while true do
		local name, kind = vim.uv.fs_scandir_next(h)
		if not name then
			break
		end
		local id = (kind == "file" or kind == nil) and name:match("^(.+)%.jsonl$")
		if id then
			local st = vim.uv.fs_stat(pdir .. "/" .. name)
			local mtime = st and st.mtime and st.mtime.sec or 0
			if mtime > best_mtime then
				best_mtime, best_id = mtime, id
			end
		end
	end
	return best_id
end

-- ---------------------------------------------------------------------------
-- 2. sessions JSON 读取
-- ---------------------------------------------------------------------------
local function read_session_json(path)
	return json_store.read(path, nil)
end

local function find_session_json(dir, session_id)
	local sdir = (dir or (HOME .. "/.claude")) .. "/sessions"
	local h = vim.uv.fs_scandir(sdir)
	if not h then
		return nil
	end
	while true do
		local name, kind = vim.uv.fs_scandir_next(h)
		if not name then
			break
		end
		if (kind == "file" or kind == nil) and name:match("%.json$") then
			local path = sdir .. "/" .. name
			local obj = read_session_json(path)
			if obj and obj.sessionId == session_id then
				return path, obj
			end
		end
	end
end

-- ---------------------------------------------------------------------------
-- 3. Watcher
-- ---------------------------------------------------------------------------
--- @param meta ClaudeMeta|nil
function M.detach(meta)
	if not meta then
		return
	end
	if meta.poll_timer then
		pcall(function()
			meta.poll_timer:stop()
			meta.poll_timer:close()
		end)
		meta.poll_timer = nil
	end
	if meta.watcher then
		pcall(function()
			meta.watcher:stop()
			meta.watcher:close()
		end)
		meta.watcher = nil
	end
end

--- Start watching. on_change is scheduled whenever name/status changes,
--- and also once when JSON is first discovered.
--- @param meta ClaudeMeta
--- @param on_change fun()
function M.attach(meta, on_change)
	if not meta then
		return
	end
	M.detach(meta) -- 复活时确保没残留

	local function pull()
		if not meta.json_path then
			return
		end
		local obj = read_session_json(meta.json_path)
		if not obj then
			return
		end
		if obj.name ~= meta.name or obj.status ~= meta.status then
			meta.name = obj.name
			meta.status = obj.status
			vim.schedule(on_change)
		end
	end

	local function start_fs_event()
		local handle = vim.uv.new_fs_event()
		meta.watcher = handle
		handle:start(meta.json_path, {}, function(err)
			if err then
				return
			end
			vim.schedule(pull)
		end)
		pull()
	end

	local tries = 0
	local timer = vim.uv.new_timer()
	meta.poll_timer = timer
	timer:start(0, POLL_INTERVAL_MS, function()
		tries = tries + 1
		local path, obj = find_session_json(meta.dir, meta.session_id)
		if path then
			meta.json_path = path
			meta.name = obj.name
			meta.status = obj.status
			timer:stop()
			timer:close()
			meta.poll_timer = nil
			vim.schedule(function()
				on_change()
				start_fs_event()
			end)
		elseif tries >= POLL_MAX_TRIES then
			timer:stop()
			timer:close()
			meta.poll_timer = nil
		end
	end)
end

return M
