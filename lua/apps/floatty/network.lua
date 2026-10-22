-- 单个国外诊断接口同时提供连通性与出口地区；状态栏只读内存。
local M = {}
local timer, job
local generation = 0
local checking = false
local status = "unknown"
local country, failure, offline_since

local function now()
	return vim.uv.hrtime() / 1e9
end

function M.check(callback)
	local proxy = vim.env.https_proxy or vim.env.HTTPS_PROXY
	if not proxy or proxy == "" then
		callback(false, "未配置代理")
		return
	end
	local options = require("config.floatty").network
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
				local reason = reasons[result.code] or ("请求失败 " .. result.code)
				callback(false, reason)
				return
			end
			local region = ("\n" .. (result.stdout or "") .. "\n"):match("\nloc=([A-Z][A-Z])[\r\n]")
			callback(true, region and ("出口地区 " .. region) or "地区未知", region)
		end)
	end)
	if not ok then
		callback(false, "无法启动探测")
	end
	return ok and process or nil
end

local function duration(seconds)
	seconds = math.max(0, math.floor(seconds))
	if seconds >= 3600 then
		return ("%d时%02d分%02d秒"):format(math.floor(seconds / 3600), math.floor(seconds / 60) % 60, seconds % 60)
	elseif seconds >= 60 then
		return ("%d分%02d秒"):format(math.floor(seconds / 60), seconds % 60)
	end
	return seconds .. "秒"
end

function M.statusline_segment()
	if status == "ok" then
		if country then
			local flag = vim.fn.nr2char(0x1F1E6 + country:byte(1) - 65)
				.. vim.fn.nr2char(0x1F1E6 + country:byte(2) - 65)
			local hl = country == "AU" and "DiagnosticOk" or "DiagnosticWarn"
			return (" %%#%s#网络 %s %s"):format(hl, flag, country)
		end
		return " %#DiagnosticWarn#网络 ✓ 地区未知"
	elseif status == "failed" then
		return (" %%#DiagnosticError#网络 × %s（已离线 %s）"):format(failure, duration(now() - offline_since))
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
		job:kill(15)
		job = nil
	end
	checking = false
end

function M.setup(group)
	M.stop()
	status = "unknown"
	country, failure, offline_since = nil, nil, nil
	local current = generation
	local next_probe = 0
	local interval = require("config.floatty").network.interval_ms / 1000
	local function tick()
		if current ~= generation then
			return
		end
		if status == "failed" then
			vim.cmd.redrawstatus()
		end
		if checking or now() < next_probe then
			return
		end
		next_probe = now() + interval
		checking = true
		job = M.check(function(ok, message, region)
			if current ~= generation then
				return
			end
			job = nil
			checking = false
			local previous = status
			status = ok and "ok" or "failed"
			country = ok and region or nil
			if ok then
				failure, offline_since = nil, nil
			else
				failure = message
				offline_since = offline_since or now()
				if previous ~= "failed" then
					vim.notify("网络检查失败：" .. message, vim.log.levels.WARN)
				end
			end
			vim.cmd.redrawstatus()
		end)
	end
	timer = vim.uv.new_timer()
	timer:start(0, 1000, vim.schedule_wrap(tick))
	vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = M.stop })
end

return M
