-- ~/.config/nvim/lua/utils/json_store.lua
-- 小型 JSON 文件读写：安全读（失败给默认值）+ 安全写（编码失败不落盘）。
-- 消费者：apps/floatty/registry（会话注册表）、apps/recent_repos（frecency 记录）、
--         apps/floatty/claude（读 sessions json，只读、默认 nil）。
-- 语义：文件缺失 / 内容空 / 解析失败 / 结果非 table 一律回落到 default，
--       这些都是"首次运行 / 文件尚未生成"的正常情况，不做 Fail Fast。
local M = {}

--- 读取并解析 JSON 文件。任何失败（不存在/空/解析错/非 table）都返回 default。
--- @param path string
--- @param default any  读取失败时的回落值（floatty/recent_repos 传 {}，claude 传 nil）
--- @return any
function M.read(path, default)
	local f = io.open(path, "r")
	if not f then
		return default
	end
	local content = f:read("*a")
	f:close()
	if not content or content == "" then
		return default
	end
	local ok, data = pcall(vim.json.decode, content)
	if not ok or type(data) ~= "table" then
		return default
	end
	return data
end

--- 编码并写入 JSON 文件。编码失败或文件打不开则放弃（不抛错、不落半截）。
--- 先写临时文件再 rename：多个 nvim 实例共享同一文件时，读方不会读到写了一半的内容。
--- @param path string
--- @param tbl table
--- @return boolean  是否成功写入
function M.write(path, tbl)
	local ok, encoded = pcall(vim.json.encode, tbl)
	if not ok then
		return false
	end
	local tmp = ("%s.%d.tmp"):format(path, vim.uv.os_getpid())
	local f = io.open(tmp, "w")
	if not f then
		return false
	end
	local written = f:write(encoded)
	f:close()
	if not written or not vim.uv.fs_rename(tmp, path) then
		os.remove(tmp)
		return false
	end
	return true
end

return M
