-- 界面相关设置
vim.o.termguicolors = true             -- 启用真彩色支持
vim.env.NVIM_TUI_ENABLE_TRUE_COLOR = 1 -- 启用终端的真彩色
vim.o.number = true                    -- 显示行号
vim.o.relativenumber = true            -- 显示相对行号
vim.o.cursorline = true                -- 高亮光标所在行
vim.o.colorcolumn = '100'              -- 设置列标尺
vim.o.showmode = false                 -- 隐藏模式提示
vim.o.scrolloff = 4                    -- 光标上下保留行数
vim.o.wrap = false                     -- 不自动换行
vim.o.visualbell = true                -- 使用视觉提示而非声音提示
vim.o.signcolumn = "yes"

-- 文件和目录相关设置
vim.o.autochdir = true                        -- 自动切换当前工作目录
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

-- 折叠相关设置
vim.o.foldmethod = 'indent' -- 使用缩进作为折叠依据
vim.o.foldlevel = 99        -- 默认展开所有折叠
vim.o.foldenable = true     -- 启用折叠
vim.o.foldlevelstart = 99   -- 打开文件时默认展开所有折叠

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
vim.o.ttyfast = true        -- 提升终端性能
vim.o.virtualedit = 'block' -- 允许块状选择模式的虚拟编辑
vim.g.mapleader = " "
vim.o.shell = "/opt/homebrew/bin/fish"



vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, { pattern = "*.md", command = "setlocal spell", })
vim.api.nvim_create_autocmd("BufEnter", { pattern = "*", command = "silent! lcd %:p:h", })

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
    autocmd BufWritePost .vim.lua exec ":so %"
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
-- NOTE:只在第一次加载。很耗时
-- local function ensure_directory(path)
-- 	if vim.fn.isdirectory(path) == 0 then
-- 		vim.fn.mkdir(path, "p")
-- 	end
-- end
--
-- -- 创建目录的部分
-- ensure_directory(vim.fn.expand("$HOME/.config/nvim/tmp/backup"))
-- ensure_directory(vim.fn.expand("$HOME/.config/nvim/tmp/undo"))
-- local config_path = vim.fn.stdpath("config")
-- local current_config_path = config_path .. "/lua/config/machine_specific.lua"
--
-- if not vim.loop.fs_stat(current_config_path) then
-- 	local default_config_path = config_path .. "/default_config/_machine_specific_default.lua"
-- 	local default_config_file = io.open(default_config_path, "rb")
-- 	if default_config_file then
-- 		local current_config_file = io.open(current_config_path, "wb")
-- 		if current_config_file then
-- 			current_config_file:write(default_config_file:read("*all"))
-- 			io.close(current_config_file)
-- 		end
-- 		io.close(default_config_file)
-- 	end
-- end
