-- ~/.config/nvim/lua/component/stldata.lua
local M = {}
local api = vim.api
local uv = vim.uv

-- ============================================================================
-- 1. Profiler (性能监控 - 装饰器模式)
-- ============================================================================
M.profiler = {
	enabled = true, -- 全局开关
	stats = {},     -- 存储统计数据
}

-- 环形缓冲区大小
local RING_SIZE = 100

function M.profiler.wrap(name, fn)
	if not M.profiler.enabled then return fn end

	-- 初始化该组件的统计数据
	if not M.profiler.stats[name] then
		-- FIX: 使用 vim.split 替代不存在的 vim.tbl_split
		local empty_samples = vim.split(string.rep("0,", RING_SIZE), ",")
		-- vim.split 可能会在最后多产生一个空字符串，处理一下
		if empty_samples[#empty_samples] == "" then
			table.remove(empty_samples)
		end
		
		M.profiler.stats[name] = {
			count_5s = 0,
			samples = empty_samples, 
			head = 1,
			last_check = uv.hrtime()
		}
	end

	local stat = M.profiler.stats[name]

	return function(...)
		local start_t = uv.hrtime()
		local res = { fn(...) } -- 捕获返回值
		local end_t = uv.hrtime()
		local dur = end_t - start_t -- 纳秒

		-- 记录样本 (Ring Buffer)
		stat.samples[stat.head] = dur
		stat.head = (stat.head % RING_SIZE) + 1

		-- 统计频率
		stat.count_5s = stat.count_5s + 1

		return unpack(res)
	end
end

-- 打印统计信息的命令接口
function M.profiler.print_stats()
	print(string.format("%-20s | %-8s | %-10s", "Component", "Calls", "Avg(ms)"))
	print(string.rep("-", 45))
	for name, data in pairs(M.profiler.stats) do
		local total = 0
		local active_samples = 0
		for _, v in ipairs(data.samples) do
			local n = tonumber(v)
			if n and n > 0 then
				total = total + n
				active_samples = active_samples + 1
			end
		end
		local avg_ms = (active_samples > 0) and (total / active_samples / 1e6) or 0
		print(string.format("%-20s | %-8d | %.4f", name, data.count_5s, avg_ms))
	end
end

-- ============================================================================
-- 2. Data Providers (数据源)
-- ============================================================================

-- --- Git User Name (IO Cache) ---
local user_cache = {} -- root -> name

-- 读取文件获取 user.name (毫秒级，带缓存)
local function fetch_git_user(root)
	if not root or root == "" then return nil end
	if user_cache[root] ~= nil then return user_cache[root] end

	local function read_config(path)
		local f = io.open(path, "r")
		if not f then return nil end
		local content = f:read("*a")
		f:close()
		local user_block = content:match('%[user%](.-)%[') or content:match('%[user%](.*)')
		if user_block then
			return user_block:match('name%s*=%s*([^\n]+)')
		end
		return nil
	end

	local name = read_config(root .. "/.git/config")
	if not name then
		local home = os.getenv("HOME")
		if home then name = read_config(home .. "/.gitconfig") end
	end

	user_cache[root] = name and vim.trim(name) or false
	return user_cache[root]
end

M.git_info = M.profiler.wrap("git_info", function(buf)
	-- 安全检测：确保 buffer 有效
	if not api.nvim_buf_is_valid(buf) then return nil end

	local summary = vim.b[buf].minigit_summary
	if not summary or not summary.head_name then return nil end

	local user = fetch_git_user(summary.root)
	local diff = vim.b[buf].minidiff_summary

	return {
		branch = summary.head_name,
		user = user,
		added = diff and diff.add or 0,
		changed = diff and diff.change or 0,
		deleted = diff and diff.delete or 0,
	}
end)

M.lsp_info = M.profiler.wrap("lsp_info", function(buf)
	if not api.nvim_buf_is_valid(buf) then return nil end
	local counts = vim.diagnostic.count(buf)
	local err = counts[vim.diagnostic.severity.ERROR] or 0
	local warn = counts[vim.diagnostic.severity.WARN] or 0
	if err == 0 and warn == 0 then return nil end
	return { err = err, warn = warn }
end)

return M
