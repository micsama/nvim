-- ~/.config/nvim/lua/utils/lazy.lua
-- 按需加载：先注册占位命令，首次执行（或 Tab 补全）时才调用 load()，
-- 再把原命令（范围 / ! / 参数 / 修饰符）原样转发给插件注册的真实命令。
-- 消费者：plugins/telescope、plugins/editor（mason）、plugins/llm/codecompanion
local M = {}

--- 返回只执行一次的 load 函数
--- @param fn fun()
--- @return fun()
function M.once(fn)
	local done = false
	return function()
		if not done then
			done = true
			fn()
		end
	end
end

--- @param names string[] 占位命令名；load() 之后应由插件重新定义
--- @param load fun()     幂等的加载函数（建议用 M.once 包一层）
function M.on_cmd(names, load)
	local function real_load()
		-- 先删占位，避免插件没定义同名命令时转发回自己造成死循环
		for _, name in ipairs(names) do
			pcall(vim.api.nvim_del_user_command, name)
		end
		load()
	end
	for _, name in ipairs(names) do
		vim.api.nvim_create_user_command(name, function(o)
			real_load()
			local range = o.range == 2 and ("%d,%d"):format(o.line1, o.line2) or o.range == 1 and tostring(o.line1) or ""
			vim.cmd(("%s %s%s%s %s"):format(o.mods, range, name, o.bang and "!" or "", o.args))
		end, {
			nargs = "*",
			range = true,
			bang = true,
			complete = function(_, line)
				real_load()
				return vim.fn.getcompletion(line, "cmdline")
			end,
		})
	end
end

return M
