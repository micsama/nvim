vim.opt.signcolumn = 'yes'    -- 始终显示标记列（用于LSP诊断、Git Gutter等）。
vim.opt.cursorline = true     -- 始终高亮光标所在行，便于定位。
vim.opt.colorcolumn = '100'   -- 在第100列显示辅助标尺线，帮助控制代码宽度。
vim.opt.scrolloff = 5         -- 光标距离窗口顶部/底部保留5行缓冲。
vim.opt.showmode = false      -- 隐藏模式提示（如INSERT/NORMAL等），通常由状态栏插件处理。
vim.opt.virtualedit = 'block' -- 允许在块选择模式下移动到空位置。
-- vim.opt.splitright = true             -- 垂直分割时新窗口出现在右侧。
-- vim.opt.splitbelow = true             -- 水平分割时新窗口出现在下方。
vim.cmd([[hi NonText ctermfg=gray guifg=grey10]]) -- 设置非文本元素（如文件末尾的~）的颜色。
vim.opt.number = true -- 显示文件的绝对行号。
vim.opt.relativenumber = true -- 显示相对于光标的相对行号，启用混合行号。
vim.opt.foldlevel = 99 -- 默认展开所有折叠（99是最高级别，即不折叠）。
vim.opt.foldmethod = 'expr' -- 使用表达式计算折叠（通常由LSP或插件接管）。
vim.opt.viewoptions = 'cursor,folds,slash,unix' -- 保存/恢复视图时记住光标位置、折叠状态等。
vim.opt.tabstop = 2 -- 设置一个Tab键的宽度为2个空格。
vim.opt.shiftwidth = 2 -- 自动缩进时使用的空格数。
vim.opt.softtabstop = 2 -- 退格键删除缩进时一次删除2个空格。
vim.opt.autoindent = true -- 启用新行自动保持与前一行相同的缩进。
vim.opt.smartindent = false -- 禁用智能缩进（通常由LSP或插件提供更精确的缩进）。
vim.opt.ignorecase = true -- 搜索时忽略大小写。
vim.opt.smartcase = true -- 如果搜索包含大写字母，则启用大小写敏感。
vim.opt.completeopt = 'menuone,noselect' -- 补全菜单：总是显示菜单，但不自动选择/插入。
vim.opt.updatetime = 100 -- 触发LSP和CursorHold事件的时间间隔（毫秒）。
vim.opt.inccommand = 'split' -- 实时预览命令效果（如替换命令）到分割窗口。
vim.opt.shortmess:append('c') -- 缩短某些消息显示（如补全菜单）。
vim.o.formatoptions = vim.o.formatoptions:gsub('tc', '') -- 禁用自动换行(t)和文本注释自动换行(c)。
vim.opt.list = true -- 显示不可见字符（如Tab/空格等）。
vim.opt.listchars = { tab = '|\\ ', trail = '▫' } -- 设置不可见字符的显示样式: Tab为|和空格，行尾空格为▫。
vim.opt.exrc = true -- 允许加载项目本地.nvimrc配置文件（请确保信任项目）。

-- 文件和备份配置
local config_dir = vim.fn.stdpath('config') .. '/tmp' -- 获取配置目录下的tmp子目录
vim.o.backupdir = config_dir .. '/backup,.'           -- 备份文件保存位置
vim.o.directory = config_dir .. '/backup,.'           -- 交换文件保存位置
vim.o.undofile = true                                 -- 启用撤销历史持久化
vim.o.undodir = config_dir .. '/undo,.'               -- 撤销历史文件保存位置

-- =============================== 环境 ================================
vim.g.python3_host_prog = (os.getenv('VIRTUAL_ENV') or '/Users/dzmfg/.venvs/base') .. '/bin/python' -- 优先使用虚拟环境中的 Python。

-- 禁用不必要的提供程序，减少启动开销。
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- 环境变量配置（macOS 优化）。
vim.env.PATH = '/opt/homebrew/bin:' .. vim.env.PATH -- 将 Homebrew 的 bin 目录添加到 PATH。

-- 根据系统设置默认终端 Shell。
local uname = vim.uv.os_uname()
if uname.sysname == 'Darwin' then
	vim.notify('macOS Loading...')
	vim.opt.shell = '/opt/homebrew/bin/nu' -- 优先使用 nu shell。
else
	vim.notify('Linux Loading...')
	vim.opt.shell = '/usr/bin/bash'
end

-- 终端颜色配置 (Dracula 近似值)
local terminal_colors = {
	'#000000', '#FF5555', '#50FA7B', '#F1FA8C', -- 0-3 (黑色, 红色, 绿色, 黄色)
	'#BD93F9', '#FF79C6', '#8BE9FD', '#BFBFBF', -- 4-7 (蓝色, 品红, 青色, 白色)
	'#4D4D4D', '#FF6E67', '#5AF78E', '#F4F99D', -- 8-11 (亮黑, 亮红, 亮绿, 亮黄)
	'#CAA9FA', '#FF92D0', '#9AEDFE'            -- 12-14 (亮蓝, 亮品红, 亮青色)
}

for i, color in ipairs(terminal_colors) do
	vim.g['terminal_color_' .. (i - 1)] = color -- 设置 terminal_color_0 到 terminal_color_14。
end

-- =============================== 自动命令 (AuCommands) ================================

-- 创建 AutoCommand Group 并清除之前的命令
vim.api.nvim_create_augroup('CustomSetupGroup', { clear = true })
local custom_group = 'CustomSetupGroup'

-- 自动切换工作目录到项目根目录 (使用 vim.fs.root 现代 API)
vim.api.nvim_create_autocmd('BufEnter', {
	group = custom_group,
	callback = function(ctx)
		-- 定义寻找项目根目录的标识文件/目录
		local root_markers = { 'pyproject.toml', '.luarc.json', '.git', 'Makefile', '.venv', 'Cargo.toml', 'package.json',
			'go.mod' }
		local root = vim.fs.root(ctx.buf, root_markers)
		-- 如果找到根目录，且它不是当前目录，则切换当前窗口的目录
		if root and root ~= '.' and root ~= vim.fn.getcwd() then
			vim.cmd.tcd(root)
			vim.notify('CWD changed to ' .. root, vim.log.levels.INFO, { title = '项目根目录' })
		end
	end,
	desc = 'Auto change working directory to project root'
})

-- 恢复上次打开文件时的光标位置
vim.api.nvim_create_autocmd('BufReadPost', {
	group = custom_group,
	pattern = '*',
	callback = function()
		-- 检查上次光标位置是否有效（行号大于1且小于文件总行数）
		if vim.fn.line('\'"') > 1 and vim.fn.line('\'"') <= vim.fn.line("$") then
			-- 跳转到上次光标位置 (''')
			vim.cmd.normal({ 'g`\"', bang = true })
		end
	end,
	desc = 'Restore cursor position when reopening files'
})

-- 终端打开时自动进入插入模式
vim.api.nvim_create_autocmd('TermOpen', {
	group = custom_group,
	pattern = 'term://*',
	command = 'startinsert',
	desc = 'Automatically enter insert mode when opening terminal'
})

-- 自动重新加载配置文件
vim.api.nvim_create_augroup('NVIMRC', { clear = true })
vim.api.nvim_create_autocmd('BufWritePost', {
	pattern = 'init.lua,*/default.lua', -- 匹配 init.lua 或当前的 default.lua
	group = 'NVIMRC',
	command = 'source %',
	desc = 'Auto reload config file when modified'
})
