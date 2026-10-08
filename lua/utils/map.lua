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

-- 终端里的 TUI（Claude Code 等）会隐藏真实光标、自绘输入框，读不到屏幕上的前一个字符，
-- 所以 t 模式改用自己记录的最后一次输入：nil 表示未知（特殊键、刚进入终端模式等）。
local term_last_char

local function smart_zh_period_term()
	local prev = term_last_char
	if prev == "." then
		term_last_char = "。"
		return "<BS>。"
	end
	if prev and prev:match("%d") then
		term_last_char = "."
		return "."
	end
	term_last_char = "。"
	return "。"
end

local function smart_zh_period()
	if vim.api.nvim_get_mode().mode == "t" then
		return smart_zh_period_term()
	end
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

--- 终端里的窗口操作先用真实按键退出 terminal_enter，再运行 Lua。
--- 单独 stopinsert() 只设置标志，不能让当前 C 调用栈立即退场。
local terminal_action_id = 0
function M.map_terminal_action(lhs, callback, desc)
	terminal_action_id = terminal_action_id + 1
	local plug = ("<Plug>(terminal-action-%d)"):format(terminal_action_id)
	vim.keymap.set("n", plug, function()
		callback()
		-- 切回仍在运行的终端时恢复输入；已退出的终端不能重新进入。
		local job = vim.b.terminal_job_id
		local buf, win = vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win()
		if vim.bo.buftype == "terminal" and job and vim.fn.jobwait({ job }, 0)[1] == -1 then
			-- jobwait 可能处理其他退出回调，重新确认焦点还在原来的终端。
			if vim.api.nvim_get_current_buf() == buf and vim.api.nvim_get_current_win() == win then
				vim.cmd.startinsert()
			end
		end
	end, { desc = desc })
	-- <Plug> 即使在 noremap 映射里也会展开。
	M.map("t", lhs, "<C-\\><C-n>" .. plug, desc)
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

	vim.api.nvim_create_autocmd("TermEnter", {
		group = vim.api.nvim_create_augroup("utils.map.zh_period", { clear = true }),
		callback = function()
			term_last_char = nil
		end,
	})
	vim.on_key(function(_, typed)
		-- typed 为空的是映射/feedkeys 产生的键；。 自己在映射里更新状态。
		if typed == "" or typed == "。" or vim.api.nvim_get_mode().mode ~= "t" then
			return
		end
		-- 特殊键（<BS>、方向键等以 0x80 开头）和控制字符都让状态失效。
		-- 注意 0x80 也是 UTF-8 续字节，只能看首字节，不能整串搜。
		if typed:byte(1) == 0x80 or typed:find("[%z\1-\31\127]") then
			term_last_char = nil
		else
			term_last_char = vim.fn.strcharpart(typed, vim.fn.strchars(typed) - 1)
		end
	end, vim.api.nvim_create_namespace("utils.map.zh_period"))
end

return M
