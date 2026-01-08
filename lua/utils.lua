-- utils.lua

local M = { markers = { "pyproject.toml", ".git", ".venv", "Cargo.toml", "go.mod" } }

-- 在文件加载时立即判断系统类型，并缓存结果
local IS_MACOS = vim.uv.os_uname().sysname == "Darwin"

--- 全角字符到半角字符的映射表（Normal 模式）
-- 键是全角字符，值是对应的半角字符或命令
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
		-- vim.notify(key_to_use)
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

local _last_path = nil

M.get_root = function(buf)
	return vim.fs.root(buf or 0, M.markers)
end

M.sync_venv = function(config, root)
	local path = vim.fs.joinpath(root, ".venv", "bin", "python")
	vim.notify(path, 2, { title = "Python Venv" })
	if vim.uv.fs_stat(path) and path ~= _last_path then
		_last_path = path
		config.settings.python.pythonPath = path
		vim.schedule(function()
			vim.notify(path, 2, { title = "Python Venv" })
		end)
	end
end

return M
