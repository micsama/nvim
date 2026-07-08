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

-- ---------------------------------------------------------------------------
-- 2. sessions JSON 读取
-- ---------------------------------------------------------------------------
local function read_session_json(path)
	local fd = vim.uv.fs_open(path, "r", 438)
	if not fd then
		return nil
	end
	local stat = vim.uv.fs_fstat(fd)
	local data = stat and vim.uv.fs_read(fd, stat.size, 0) or nil
	vim.uv.fs_close(fd)
	if not data or data == "" then
		return nil
	end
	local ok, obj = pcall(vim.json.decode, data)
	return ok and obj or nil
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
