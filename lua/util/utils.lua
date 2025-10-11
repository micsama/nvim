-- util/utils.lua

local M = {}

-- 在文件加载时立即判断系统类型，并缓存结果
local IS_MACOS = vim.uv.os_uname().sysname == 'Darwin'

--- 创建一个键位映射
--- @param mode string|table: 模式 (如 'n', 'v', 'i', 't', 'nv' 或 {'n', 'v'})
--- @param lhs string: 触发键位 (如 '<leader>w', '<D-g>')
--- @param rhs string|function: 映射目标 (如 '<C-w>w' 或一个 Lua 函数)
--- @param opts_or_desc table|string|nil: 选项表或描述字符串
function M.map(mode, lhs, rhs, opts_or_desc)
	-- 1. 键位转换
	local key_to_use = lhs
	if not IS_MACOS then
		key_to_use = string.gsub(lhs, '<D-([a-zA-Z0-9-][^>]-)>', '<M-%1>')
	end

	-- 2. 选项处理
	local opts = { noremap = true, silent = false }
	if opts_or_desc then
		if type(opts_or_desc) == 'string' then
			opts.desc = opts_or_desc
		elseif type(opts_or_desc) == 'table' then
			opts = vim.tbl_extend('force', opts, opts_or_desc)
		end
	end

	-- 3. 模式处理
	local modes = mode
	if type(mode) == 'string' and #mode > 1 then
		modes = vim.split(mode, '')
	end

	-- 4. 设置映射
	vim.keymap.set(modes, key_to_use, rhs, opts)
end

return M
