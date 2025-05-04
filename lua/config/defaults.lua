-- 界面相关设置
vim.o.termguicolors = true             -- 启用真彩色支持
vim.env.NVIM_TUI_ENABLE_TRUE_COLOR = 1 -- 启用终端的真彩色
vim.o.number = true                    -- 显示行号
vim.o.relativenumber = true            -- 显示相对行号
vim.o.cursorline = true                -- 高亮光标所在行
vim.o.colorcolumn = '100'              -- 设置列标尺
vim.o.showmode = false                 -- 隐藏模式提示
vim.o.scrolloff = 4                    -- 光标上下保留行数
vim.o.wrap = true                      -- 自动换行
vim.o.visualbell = true                -- 使用视觉提示而非声音提示
vim.o.signcolumn = "yes"

-- 文件和目录相关设置
vim.o.autochdir = false                        -- 自动切换当前工作目录
vim.o.exrc = true                             -- 允许在本地目录使用 .nvimrc 文件
vim.o.secure = false                          -- 允许执行本地 .nvimrc 中的命令
vim.o.viewoptions = 'cursor,folds,slash,unix' -- 保存/恢复视图的选项

-- 缩进和制表符相关设置
vim.o.expandtab = false -- 使用制表符而不是空格
vim.o.tabstop = 2 -- 设置制表符宽度为 2 个空格
vim.o.smarttab = true -- 插入 Tab 时更智能
vim.o.shiftwidth = 2 -- 缩进宽度为 2 个空格
vim.o.softtabstop = 2 -- 回退时使用 2 个空格
vim.o.autoindent = true -- 自动缩进
vim.o.indentexpr = '' -- 不使用表达式缩进
vim.o.list = true -- 显示不可见字符
vim.o.listchars = 'tab:|\\ ,trail:▫' -- 设置不可见字符显示格式

-- 设置 fold 相关的选项
-- TODO:修复这里的设置方案
vim.opt.foldlevel = 99
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.require'utils/fold'.foldexpr()"


-- 分割窗口相关设置
vim.o.splitright = true -- 垂直分割窗口时，新窗口在右边
vim.o.splitbelow = true -- 水平分割窗口时，新窗口在下方

-- 搜索相关设置
vim.o.ignorecase = true -- 搜索时忽略大小写
vim.o.smartcase = true  -- 搜索时智能区分大小写

-- 命令和补全相关设置
vim.o.inccommand = 'split'                              -- 实时显示命令效果
vim.o.completeopt = 'menuone,noinsert,noselect,preview' -- 自动补全选项
vim.o.shortmess = vim.o.shortmess .. 'c'                -- 缩短消息显示
-- 性能和延迟相关设置
vim.o.ttimeoutlen = 0                                   -- 设置终端超时时间
vim.o.timeout = false                                   -- 禁用键入超时
vim.o.updatetime = 100                                  -- 设置更新时间为 100 毫秒

-- 格式化选项
vim.o.formatoptions = vim.o.formatoptions:gsub('tc', '') -- 禁用自动换行和文本注释

-- 其他设置
vim.o.ttyfast = true                                        -- 提升终端性能
vim.o.virtualedit = 'block'                                 -- 允许块状选择模式的虚拟编辑
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.python3_host_prog = (os.getenv("VIRTUAL_ENV") or "/Users/dzmfg/.uv/base") .. "/bin/python"

-- auto change root
vim.api.nvim_create_autocmd("BufEnter", {
	callback = function(ctx)
		local root = vim.fs.root(ctx.buf, { ".git", "Makefile", ".venv", "Cargo.toml", "package.json" })
		if root and root ~= "." and root ~= vim.fn.getcwd() then
			vim.cmd.tcd(root)
			vim.notify("Change CWD to " .. root)
		end
	end,
})

vim.cmd([[au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif]])

vim.g.terminal_color_0     = '#000000'
vim.g.terminal_color_1     = '#FF5555'
vim.g.terminal_color_2     = '#50FA7B'
vim.g.terminal_color_3     = '#F1FA8C'
vim.g.terminal_color_4     = '#BD93F9'
vim.g.terminal_color_5     = '#FF79C6'
vim.g.terminal_color_6     = '#8BE9FD'
vim.g.terminal_color_7     = '#BFBFBF'
vim.g.terminal_color_8     = '#4D4D4D'
vim.g.terminal_color_9     = '#FF6E67'
vim.g.terminal_color_10    = '#5AF78E'
vim.g.terminal_color_11    = '#F4F99D'
vim.g.terminal_color_12    = '#CAA9FA'
vim.g.terminal_color_13    = '#FF92D0'
vim.g.terminal_color_14    = '#9AEDFE'

vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

vim.cmd([[autocmd TermOpen term://* startinsert]])
vim.cmd([[
augroup NVIMRC
    autocmd!
    autocmd BufWritePost init.lua exec ":so %"
augroup END
tnoremap <C-N> <C-\><C-N>
tnoremap <C-O> <C-\><C-N><C-O>
]])


vim.cmd([[hi NonText ctermfg=gray guifg=grey10]])

vim.cmd([[
    set backupdir=$HOME/.config/nvim/tmp/backup,.
    set directory=$HOME/.config/nvim/tmp/backup,.
    if has('persistent_undo')
        set undofile
        set undodir=$HOME/.config/nvim/tmp/undo,.
    endif
]])

-- 获取系统信息
local uname = vim.uv.os_uname()
-- 检查系统类型
if uname.sysname == "Linux" then
	vim.o.shell = "/usr/bin/bash"
elseif uname.sysname == "Darwin" then
	vim.o.shell = "/opt/homebrew/bin/fish"
	-- vim.o.shell = "/opt/homebrew/bin/nu"
else
	vim.o.shell = "/usr/bin/bash"
end

vim.env.PATH = "/opt/homebrew/bin:"..vim.env.PATH
if vim.g.neovide then
	require("config.neovide")
end
