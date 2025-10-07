-- util/utils.lua

local M = {}

--- 创建一个键位映射
--- @param mode string|table: 模式 (如 'n', 'v', 'i', 't', 'nv' 或 {'n', 'v'})
--- @param lhs string: 触发键位 (如 '<leader>w')
--- @param rhs string|function: 映射目标 (如 '<C-w>w' 或一个 Lua 函数)
--- @param opts_or_desc table|string|nil: 选项表或描述字符串
function M.map(mode, lhs, rhs, opts_or_desc)
	local opts = {
		noremap = true,
		silent = false,
	}

	if opts_or_desc then
		if type(opts_or_desc) == 'string' then
			opts.desc = opts_or_desc
		elseif type(opts_or_desc) == 'table' then
			opts = vim.tbl_extend('force', opts, opts_or_desc)
		end
	end

	local modes = mode
	if type(mode) == 'string' and #mode > 1 then
		-- 如果 mode 是多字符字符串，将其拆分成表格
		modes = vim.split(mode, '')
	end

	vim.keymap.set(modes, lhs, rhs, opts)
end

return M
