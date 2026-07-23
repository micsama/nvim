-- ~/.config/nvim/lua/utils/json_store.lua
-- 小型 JSON 文件读写：安全读（失败给默认值）+ 安全写（编码失败不落盘）。
-- 消费者：apps/floatty（会话注册表）、apps/recent_repos（frecency 记录）、
--         utils/floatty_claude（读 sessions json，只读、默认 nil）。
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
--- @param path string
--- @param tbl table
--- @return boolean  是否成功写入
function M.write(path, tbl)
	local ok, encoded = pcall(vim.json.encode, tbl)
	if not ok then
		return false
	end
	local f = io.open(path, "w")
	if not f then
		return false
	end
	f:write(encoded)
	f:close()
	return true
end

return M
