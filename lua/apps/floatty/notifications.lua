-- 官方 CLI 回调写文件，当前聚焦的 Neovim 领取并显示内部通知。
local M = {}
local uv = vim.uv
local store = require("utils.json_store")
local options = require("config.floatty").notifications
local instance_id = vim.fn.getpid() .. "-" .. uv.hrtime()
local root = vim.fn.stdpath("state") .. "/floatty-notifications"
local timer, focused, current_term
local last_cleanup = 0
local key_ns = vim.api.nvim_create_namespace("floatty.notifications.focus")

function M.is_foreground()
	return focused and store.read(root .. "/foreground.json", {}).instance_id == instance_id
end

local function drain()
	if not M.is_foreground() then
		return
	end
	local events = {}
	local now = os.time()
	for name, kind in vim.fs.dir(root .. "/pending") do
		if kind == "file" and name:match("^[a-f0-9]+%.json$") then
			local path = root .. "/pending/" .. name
			local event = store.read(path, {})
			local claimed = root .. "/claimed/" .. name
			if
				type(event.created_at) ~= "number"
				or type(event.app_name) ~= "string"
				or type(event.cwd) ~= "string"
				or (event.kind ~= "turn_finished" and event.kind ~= "permission_requested")
				or now - event.created_at > options.retention_s
				or uv.fs_stat(claimed)
			then
				uv.fs_unlink(path)
			elseif uv.fs_rename(path, claimed) then
				local same = event.instance_id == instance_id and event.term_id == current_term()
				if not same or event.kind == "permission_requested" then
					events[#events + 1] = event
				end
			end
		end
	end
	-- 已领取文件只用于去重，十分钟清理一次，最多保留一天。
	if now - last_cleanup >= 600 then
		last_cleanup = now
		for name in vim.fs.dir(root .. "/claimed") do
			local path = root .. "/claimed/" .. name
			local stat = uv.fs_stat(path)
			if stat and now - stat.mtime.sec > options.retention_s then
				uv.fs_unlink(path)
			end
		end
	end
	if #events == 0 then
		return
	end
	table.sort(events, function(a, b)
		if a.kind ~= b.kind then
			return a.kind == "permission_requested"
		end
		return a.created_at > b.created_at
	end)
	local lines, level = {}, vim.log.levels.INFO
	for i, event in ipairs(events) do
		local permission = event.kind == "permission_requested"
		if permission then
			level = vim.log.levels.WARN
		end
		if i <= 5 then
			local message = permission and "等待授权" or "本轮结束"
			if permission and type(event.tool) == "string" and event.tool ~= "" then
				message = message .. " · " .. event.tool
			end
			lines[#lines + 1] = ("%s · %s：%s"):format(event.app_name, vim.fn.fnamemodify(event.cwd, ":t"), message)
		end
	end
	if #events > 5 then
		lines[#lines + 1] = ("另有 %d 条提醒"):format(#events - 5)
	end
	vim.notify(table.concat(lines, "\n"), level, { title = "Floatty", timeout = options.timeout_ms })
end

function M.stop()
	focused = false
	if timer then
		timer:stop()
		timer:close()
		timer = nil
	end
	vim.on_key(nil, key_ns)
end

function M.setup(group, get_current_term)
	M.stop()
	if not options.enabled then
		return
	end
	for _, directory in ipairs({ "pending", "claimed" }) do
		vim.fn.mkdir(root .. "/" .. directory, "p", 448)
	end
	current_term = get_current_term
	local function focus()
		focused = true
		store.write(root .. "/foreground.json", { instance_id = instance_id })
	end
	vim.api.nvim_create_autocmd("FocusGained", {
		group = group,
		callback = function()
			focus()
			drain()
		end,
	})
	vim.api.nvim_create_autocmd("FocusLost", {
		group = group,
		callback = function()
			focused = false
		end,
	})
	vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = M.stop })
	-- 启动时若错过 FocusGained，首次真实按键也能确认焦点；通知留给定时器显示。
	vim.on_key(function(_, typed)
		if not focused and typed and typed ~= "" then
			focus()
		end
	end, key_ns)
	timer = uv.new_timer()
	timer:start(
		options.poll_ms,
		options.poll_ms,
		vim.schedule_wrap(function()
			if timer then
				drain()
			end
		end)
	)
end

-- 只给 Floatty 启动的 AI 附加回调，不修改全局 CLI 配置。
function M.wrap(cmd, cfg, term, cwd)
	if not options.enabled or not (cfg.claude or cfg.codex) then
		return cmd
	end
	local python = vim.fn.exepath("python3")
	assert(python ~= "", "Floatty 内部通知需要 python3")
	local script = vim.fn.stdpath("config") .. "/scripts/floatty_event.py"
	local quote = vim.fn.shellescape
	local hook = { type = "command", command = quote(python) .. " " .. quote(script) .. " hook", timeout = 3 }
	if cfg.claude then
		-- permission_prompt 也覆盖网络授权；实际等待约六秒才提醒。
		local hooks = {
			Stop = { { hooks = { hook } } },
			Notification = { { matcher = "permission_prompt", hooks = { hook } } },
			PostToolUse = { { hooks = { hook } } },
		}
		cmd = cmd .. " --settings " .. quote(vim.json.encode({ hooks = hooks }))
	else
		local flags = " --no-daemon -c "
			.. quote("notify=" .. vim.json.encode({ python, script, "codex" }))
			.. " -c "
			.. quote("tui.notifications=false")
		for _, event in ipairs({ "PermissionRequest", "PostToolUse" }) do
			flags = flags
				.. " -c "
				.. quote(
					('hooks.%s=[{hooks=[{type="command",command=%s,timeout=3}]}]'):format(
						event,
						vim.json.encode(hook.command)
					)
				)
		end
		cmd = cmd:gsub("^codex", function()
			return "codex" .. flags
		end, 1)
	end
	term.notification_id = instance_id .. ":" .. term.buf
	return cmd,
		{
			FLOATTY_INSTANCE_ID = instance_id,
			FLOATTY_TERM_ID = term.notification_id,
			FLOATTY_APP_NAME = cfg.name,
			FLOATTY_EVENT_DIR = root,
			FLOATTY_CWD = cwd,
		}
end

return M
