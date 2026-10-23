-- 单次 HTTPS 请求查询代理出口国家；状态栏只读内存。
local M = {}
local uv = vim.uv
local store = require("utils.json_store")
local ffi = require("ffi")
ffi.cdef("int flock(int fd, int operation);")
local timer, job
local lease, shared_path
local generation = 0
local checking = false
local status = "unknown"
local country, failure, offline_since
local updated_at

local function now()
	local seconds, microseconds = uv.gettimeofday()
	return seconds + microseconds / 1e6
end

function M.statusline_segment()
	local options = require("config.floatty").network
	if updated_at and now() - updated_at > options.timeout_s + options.interval_ms / 1000 + 5 then
		return " %#DiagnosticWarn#网络 …（结果已过期）"
	end
	if status == "ok" then
		if country then
			local flag = vim.fn.nr2char(0x1F1E6 + country:byte(1) - 65)
				.. vim.fn.nr2char(0x1F1E6 + country:byte(2) - 65)
			local hl = country == "AU" and "DiagnosticOk" or "DiagnosticWarn"
			return (" %%#%s#网络 %s %s"):format(hl, flag, country)
		end
		return " %#DiagnosticWarn#网络 ✓ 地区未知"
	elseif status == "failed" then
		local seconds = math.max(0, math.floor(now() - offline_since))
		local elapsed = seconds .. "秒"
		if seconds >= 3600 then
			elapsed = ("%d时%02d分"):format(math.floor(seconds / 3600), math.floor(seconds / 60) % 60)
		elseif seconds >= 60 then
			elapsed = ("%d分%02d秒"):format(math.floor(seconds / 60), seconds % 60)
		end
		return (" %%#DiagnosticWarn#网络 ? %s（探测失败 %s）"):format(failure, elapsed)
	end
	return " %#Comment#网络 …"
end

function M.stop()
	generation = generation + 1
	if timer then
		timer:stop()
		timer:close()
		timer = nil
	end
	if job then
		M.probe_pid = nil
		job:kill(15)
		job = nil
	end
	if lease then
		uv.fs_close(lease)
	end -- 关闭 fd / 进程退出都会释放内核锁
	lease = nil
	checking = false
end

function M.setup(group)
	M.stop()
	status = "unknown"
	country, failure, offline_since, updated_at = nil, nil, nil, nil
	local current = generation
	local options = require("config.floatty").network
	local interval = options.interval_ms / 1000
	-- 相同代理与探测配置共享；不同出口配置互不覆盖。不落盘代理 URL。
	local proxy = vim.env.https_proxy or vim.env.HTTPS_PROXY or ""
	local key = vim.fn.sha256(
		table.concat({ options.url, proxy, tostring(options.connect_timeout_s), tostring(options.timeout_s) }, "\0")
	)
	local directory = vim.fn.stdpath("state") .. "/floatty-network/" .. key
	vim.fn.mkdir(directory, "p", 448)
	shared_path = directory .. "/status.json"
	local function accept(record)
		if
			type(record) ~= "table"
			or record.version ~= 1
			or type(record.checked_at) ~= "number"
			or (record.status ~= "ok" and record.status ~= "failed")
		then
			return
		end
		local previous = status
		status = record.status
		country = type(record.country) == "string" and record.country:match("^[A-Z][A-Z]$") or nil
		failure = type(record.failure) == "string" and record.failure or "探测失败"
		offline_since = type(record.offline_since) == "number" and record.offline_since or record.checked_at
		updated_at = record.checked_at
		if status == "failed" and previous ~= "failed" and require("apps.floatty.notifications").is_foreground() then
			vim.notify("网络检查失败：" .. failure, vim.log.levels.WARN)
		end
		vim.cmd.redrawstatus()
	end
	local function tick()
		if current ~= generation then
			return
		end
		local record = store.read(shared_path, {})
		accept(record)
		if not lease then
			local fd = uv.fs_open(directory .. "/leader.lock", "a", 384)
			if fd then
				if ffi.C.flock(fd, 6) == 0 then
					lease = fd
				else
					uv.fs_close(fd)
				end -- LOCK_EX | LOCK_NB
			end
		end
		if not lease or checking or now() < (tonumber(record.next_probe_at) or 0) then
			return
		end
		checking = true
		local started_at = now()
		-- 退出时其他实例会接替；即使正在中止 curl，也先等本次请求的超时边界。
		record.next_probe_at = started_at + options.timeout_s + 1
		store.write(shared_path, record)
		local function complete(ok, message, region)
			if current ~= generation then
				return
			end
			M.probe_pid = nil
			job = nil
			checking = false
			local finished_at = now()
			local result = {
				version = 1,
				status = ok and "ok" or "failed",
				country = ok and region or nil,
				failure = not ok and message or nil,
				offline_since = not ok and (record.offline_since or finished_at) or nil,
				checked_at = finished_at,
				next_probe_at = math.max(started_at + interval, finished_at),
			}
			store.write(shared_path, result)
			accept(result)
		end
		if proxy == "" then
			complete(false, "未配置代理")
			return
		end

		local ok, process = pcall(vim.system, {
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
			proxy,
			"--noproxy",
			"",
			options.url,
		}, { text = true, timeout = (options.timeout_s + 1) * 1000 }, function(result)
			vim.schedule(function()
				if current ~= generation then
					return
				end
				if result.code ~= 0 then
					local reasons = {
						[5] = "代理解析失败",
						[6] = "域名解析失败",
						[7] = "代理连接失败",
						[22] = "HTTP 错误",
						[28] = "超时",
						[35] = "TLS 连接失败",
						[60] = "证书校验失败",
						[124] = "超时",
					}
					complete(false, reasons[result.code] or ("请求失败 " .. result.code))
				else
					local region = vim.trim(result.stdout or ""):match("^[A-Z][A-Z]$")
					complete(true, nil, region)
				end
			end)
		end)
		job = ok and process or nil
		M.probe_pid = job and job.pid
		if not ok then
			complete(false, "无法启动探测")
		end
	end
	timer = vim.uv.new_timer()
	timer:start(0, options.poll_ms or 1000, vim.schedule_wrap(tick))
	vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = M.stop })
end

return M
