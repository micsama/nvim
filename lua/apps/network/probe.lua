-- 同一出口的多个 Neovim 实例共享结果，由持有 flock 的实例探测。
local M = {}
local uv = vim.uv
local store = require("utils.json_store")
local options = require("config.network")
local ffi = require("ffi")
ffi.cdef("int flock(int fd, int operation);")
local entries = {}
local directory = vim.fn.stdpath("state") .. "/network"
local reasons = {
	[5] = "代理解析失败",
	[6] = "域名解析失败",
	[7] = "连接失败",
	[22] = "HTTP 错误",
	[28] = "超时",
	[35] = "TLS 连接失败",
	[60] = "证书校验失败",
	[124] = "超时",
}

function M.is_probe(pid)
	for _, entry in pairs(entries) do
		if entry.job and entry.job.pid == pid then
			return true
		end
	end
	return false
end

function M.fresh(record)
	return record.checked_at ~= nil and os.time() - record.checked_at <= options.interval_s + options.timeout_s + 5
end

function M.get(exit)
	local entry = entries[exit.id]
	if not entry then
		local key = vim.fn.sha256(exit.proxy .. "\0" .. options.url)
		local path = directory .. "/" .. key
		entry = { path = path, record = store.read(path .. ".json", {}) }
		entries[exit.id] = entry
	end
	return entry.record
end

function M.check(exit, force, changed)
	M.get(exit)
	local entry = entries[exit.id]
	if entry.job then
		return
	end
	entry.record = store.read(entry.path .. ".json", {})
	if not force and os.time() < (entry.record.next_probe_at or 0) then
		return
	end
	local fd = uv.fs_open(entry.path .. ".lock", "a", 384)
	if not fd then
		return
	end
	if ffi.C.flock(fd, 6) ~= 0 then
		uv.fs_close(fd)
		return
	end
	entry.fd = fd
	local previous = entry.record
	local started = uv.hrtime()
	entry.record = vim.tbl_extend("force", previous, { next_probe_at = os.time() + options.timeout_s + 1 })
	store.write(entry.path .. ".json", entry.record)
	local args = {
		"curl",
		"--disable",
		"--silent",
		"--show-error",
		"--fail",
		"--connect-timeout",
		tostring(options.connect_timeout_s),
		"--max-time",
		tostring(options.timeout_s),
		"--proxy",
		exit.proxy,
		"--noproxy",
		exit.proxy == "" and "*" or "",
		options.url,
	}
	entry.job = vim.system(args, { text = true, timeout = (options.timeout_s + 1) * 1000 }, function(result)
		vim.schedule(function()
			if entries[exit.id] ~= entry then
				return
			end
			entry.job = nil
			local country = vim.trim(result.stdout or ""):match("^[A-Z][A-Z]$")
			local ok = result.code == 0 and country ~= nil
			entry.record = {
				status = ok and "ok" or "failed",
				country = ok and country or nil,
				failure = not ok and (reasons[result.code] or "探测失败") or nil,
				offline_since = not ok and (previous.offline_since or os.time()) or nil,
				elapsed_ms = math.floor((uv.hrtime() - started) / 1e6),
				checked_at = os.time(),
				next_probe_at = os.time() + options.interval_s,
			}
			store.write(entry.path .. ".json", entry.record)
			uv.fs_close(entry.fd)
			entry.fd = nil
			changed()
		end)
	end)
end

function M.describe(exit)
	local entry = entries[exit.id]
	local record = M.get(exit)
	if entry and entry.job then
		return "探测中 …"
	end
	if not record.checked_at then
		return "待探测"
	end
	if not M.fresh(record) then
		return "结果已过期"
	end
	if record.status == "ok" then
		return ("✓ %s · %d ms"):format(record.country, record.elapsed_ms)
	end
	return "× " .. record.failure
end

function M.setup()
	vim.fn.mkdir(directory, "p", 448)
end

function M.stop()
	local old = entries
	entries = {}
	for _, entry in pairs(old) do
		if entry.job then
			entry.job:kill(15)
		end
		if entry.fd then
			uv.fs_close(entry.fd)
		end
	end
end

return M
