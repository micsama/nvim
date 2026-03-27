-- ===========================================================================
-- 键位映射工具
-- ===========================================================================

local M = {}

-- 在文件加载时立即判断系统类型，并缓存结果
local IS_MACOS = vim.uv.os_uname().sysname == "Darwin"

-- =============================================================================
-- 全角字符到半角字符的映射表（Normal 模式）
-- =============================================================================
-- stylua: ignore start
local FULLWIDTH_TO_HALFWIDTH_MAP = {
	-- 命令模式入口
	["："] = { rhs = ":", desc = "全角冒号 -> 命令模式" },
	[";"] = { rhs = ":", desc = "半角分号 -> 命令模式" },
	["；"] = { rhs = ":", desc = "全角分号 -> 命令模式" },

	-- 文本对象/操作符
	["《"] = { rhs = "<", desc = "全角书名号左 -> < (缩进/文本对象)" },
	["》"] = { rhs = ">", desc = "全角书名号右 -> > (缩进/文本对象)" },

	-- 符号/查找
	["‘"] = { rhs = "`", desc = "全角单引号左 -> `" },
	["’"] = { rhs = "'", desc = "全角单引号右 -> '" },
	["“"] = { rhs = '"', desc = '全角双引号左 -> "' },
	["”"] = { rhs = '"', desc = '全角双引号右 -> "' },
	["？"] = { rhs = "?", desc = "全角问号 -> ? (向后查找)" },
	["！"] = { rhs = "!", desc = "全角叹号 -> ! (过滤器)" },

	-- 移动/其他
	["（"] = { rhs = "(", desc = "全角左括号 -> (" },
	["）"] = { rhs = ")", desc = "全角右括号 -> )" },
	["，"] = { rhs = ",", desc = "全角逗号 -> , (重复查找前缀)" },
	["。"] = { rhs = ".", desc = "全角句号 -> . (重复上次操作)" },
}
-- stylua: ignore end

local function smart_zh_period()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2]
	if col <= 0 then
		return "。"
	end

	local prev = line:sub(col, col)
	if prev == "." then
		return "<BS>。"
	end
	if prev:match("%d") then
		return "."
	end

	return "。"
end

--- 创建一个键位映射
--- @param mode string|table: 模式 (如 'n', 'v', 'i', 't', 'nv' 或 {'n', 'v'})
--- @param lhs string: 触发键位 (如 '<leader>w', '<D-g>')
--- @param rhs string|function: 映射目标 (如 '<C-w>w' 或一个 Lua 函数)
--- @param opts_or_desc table|string|nil: 选项表或描述字符串
function M.map(mode, lhs, rhs, opts_or_desc)
	-- 1. 键位转换
	local key_to_use = lhs
	if not IS_MACOS then
		-- 替换 <D-key> 为 <M-key>
		key_to_use = string.gsub(lhs, "<D%-", "<M-")
	end

	-- 2. 选项处理
	local opts = { noremap = true, silent = false }
	if opts_or_desc then
		if type(opts_or_desc) == "string" then
			opts.desc = opts_or_desc
		elseif type(opts_or_desc) == "table" then
			opts = vim.tbl_extend("force", opts, opts_or_desc)
		end
	end

	-- 3. 模式处理
	local modes = mode
	if type(mode) == "string" and #mode > 1 then
		modes = vim.split(mode, "")
	end

	-- 4. 设置映射
	vim.keymap.set(modes, key_to_use, rhs, opts)
end

--- 绑定全角字符到半角字符的 Normal 模式操作
function M.map_fullwidth_to_halfwidth()
	for fullwidth_char, config in pairs(FULLWIDTH_TO_HALFWIDTH_MAP) do
		M.map("nv", fullwidth_char, config.rhs, {
			desc = config.desc,
			silent = false,
		})
	end
end

function M.map_smart_zh_period()
	M.map("it", "。", smart_zh_period, {
		desc = "数字前中文句号 -> 英文点；数字+英文点 -> 中文句号",
		expr = true,
		silent = true,
	})
end

return M
