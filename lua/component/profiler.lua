-- ~/.config/nvim/lua/component/profiler.lua
-- statusline 组件渲染耗时采样器（手搓 statusline 调优时用）。
-- 默认关闭 —— 热路径上只多一次布尔判断，零采样开销。
-- 用 :StlProf on 开启、:StlProf 打印、:StlProf off 关闭（命令在 statusline.lua 注册）。
local M = { enabled = false, stats = {} }
local uv = vim.uv
local RING_SIZE = 100 -- 每个组件保留最近 N 次采样求平均

local function ensure(name)
	if not M.stats[name] then
		M.stats[name] = { calls = 0, samples = {}, head = 1 }
	end
	return M.stats[name]
end

--- 包裹 fn 做计时。始终返回 wrapper，采样与否在调用时按 M.enabled 决定，
--- 因此开关可随时切换、无需重载模块。关闭时仅多一次布尔判断 + 一层调用。
--- @param name string  组件名（打印时显示）
--- @param fn fun(...): any
function M.wrap(name, fn)
	local stat = ensure(name)
	return function(...)
		if not M.enabled then
			return fn(...)
		end
		local t0 = uv.hrtime()
		local res = { fn(...) }
		stat.samples[stat.head] = uv.hrtime() - t0 -- 纳秒
		stat.head = (stat.head % RING_SIZE) + 1
		stat.calls = stat.calls + 1
		return unpack(res)
	end
end

--- 打印各组件的累计调用数与近 RING_SIZE 次平均耗时（ms）
function M.print_stats()
	print(string.format("%-16s | %-8s | %-10s", "Component", "Calls", "Avg(ms)"))
	print(string.rep("-", 40))
	for name, s in pairs(M.stats) do
		local total, n = 0, 0
		for _, v in ipairs(s.samples) do
			total, n = total + v, n + 1
		end
		local avg_ms = (n > 0) and (total / n / 1e6) or 0
		print(string.format("%-16s | %-8d | %.4f", name, s.calls, avg_ms))
	end
end

return M
