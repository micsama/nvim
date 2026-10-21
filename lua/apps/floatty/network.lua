-- 定时通过现有代理探测 Google 连通性；状态缓存在内存中供 statusline 使用。
local M = {}
local timer, job
local generation = 0
local checking = false
local status = "unknown"

function M.check(callback)
	local proxy = vim.env.https_proxy or vim.env.HTTPS_PROXY
	if not proxy or proxy == "" then
		callback(false, "未配置 HTTPS 代理（https_proxy / HTTPS_PROXY）")
		return
	end
	local ok, process = pcall(vim.system, {
		"curl",
		"--disable",
		"--silent",
		"--show-error",
		"--fail",
		"--connect-timeout",
		"4",
		"--max-time",
		"10",
		"--proxy",
		proxy,
		"--noproxy",
		"",
		"--output",
		"/dev/null",
		"https://www.google.com/generate_204",
	}, { text = true, timeout = 11000 }, function(result)
		vim.schedule(function()
			if result.code ~= 0 then
				callback(false, "代理网络探测失败或超时（curl " .. result.code .. "）")
				return
			end
			callback(true, "Google 连接正常")
		end)
	end)
	if not ok then
		callback(false, "无法启动网络探测：" .. tostring(process))
	end
	return ok and process or nil
end

-- 状态栏只读内存，渲染时不产生网络请求。
function M.statusline_segment()
	if status == "ok" then
		return " %#DiagnosticOk#Google ✓"
	elseif status == "failed" then
		return " %#DiagnosticWarn#Google ×"
	end
	return " %#Comment#Google …"
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
	local current = generation
	local function probe()
		if current ~= generation or checking then
			return
		end
		checking = true
		job = M.check(function(ok, message)
			if current ~= generation then
				return
			end
			job = nil
			checking = false
			local previous = status
			status = ok and "ok" or "failed"
			if not ok and previous ~= "failed" then
				vim.notify("Google 网络检查失败：" .. message, vim.log.levels.WARN)
			end
			vim.cmd.redrawstatus()
		end)
	end
	timer = vim.uv.new_timer()
	timer:start(0, require("config.floatty").network.interval_ms, vim.schedule_wrap(probe))
	vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = M.stop })
end

return M
