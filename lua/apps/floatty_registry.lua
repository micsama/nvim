-- Floatty 会话注册表。渲染阶段只读缓存；写入前重新读取以减少覆盖旧数据。
-- 仍沿用原有共享文件格式；不提供多实例事务或精确 session ID 恢复。
local M = {}
local store = require("utils.json_store")
local path = vim.fn.stdpath("state") .. "/floatty_sessions.json"
local cached = store.read(path, {})

function M.get()
	return cached
end

function M.refresh()
	cached = store.read(path, {})
	return cached
end

function M.add(id, entry)
	M.refresh()[id] = entry
	store.write(path, cached)
end

function M.remove(id)
	local data = M.refresh()
	if data[id] ~= nil then
		data[id] = nil
		store.write(path, data)
	end
end

vim.api.nvim_create_autocmd({ "FocusGained", "DirChanged" }, {
	group = vim.api.nvim_create_augroup("FloattyRegistry", { clear = true }),
	callback = function()
		M.refresh()
		vim.cmd.redrawstatus()
	end,
})

return M
