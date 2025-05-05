-- 非默认值的有效设置（这些会改变默认行为）
vim.o.termguicolors = true             -- 启用真彩色支持，提供更丰富的颜色显示
vim.o.number = true                    -- 显示绝对行号
vim.o.relativenumber = true            -- 显示相对行号（与其他行的距离）
vim.o.cursorline = true                -- 高亮光标所在行，便于定位
vim.o.colorcolumn = '100'              -- 在第100列显示标尺线，帮助保持代码宽度
vim.o.showmode = false                 -- 隐藏模式提示（如INSERT/NORMAL等）
vim.o.scrolloff = 4                    -- 光标距离窗口顶部/底部保留4行缓冲
vim.o.signcolumn = "yes"               -- 始终显示标记列（用于git/diagnostic等标记）
vim.o.exrc = true                      -- 允许加载项目本地.nvimrc配置文件
vim.o.secure = false                   -- 允许本地.nvimrc执行命令（有安全风险，请确保信任项目）
vim.o.viewoptions = 'cursor,folds,slash,unix' -- 保存/恢复视图时记住光标位置、折叠状态等
vim.o.tabstop = 2                      -- 每个Tab显示为2个空格宽度
vim.o.shiftwidth = 2                   -- 自动缩进使用2个空格
vim.o.softtabstop = 2                  -- 退格键删除缩进时一次删除2个空格
vim.o.list = true                      -- 显示不可见字符（如Tab/空格等）
vim.o.listchars = 'tab:|\\ ,trail:▫'   -- 设置Tab显示为|，行尾空格显示为▫
vim.opt.foldlevel = 99                 -- 默认展开所有折叠（99是最高级别）
vim.opt.foldmethod = "expr"            -- 使用表达式计算折叠（需要自定义foldexpr）
vim.o.splitright = true                -- 垂直分割时新窗口出现在右侧
vim.o.splitbelow = true                -- 水平分割时新窗口出现在下方
vim.o.ignorecase = true                -- 搜索时忽略大小写
vim.o.smartcase = true                 -- 如果搜索包含大写字母，则启用大小写敏感
vim.o.inccommand = 'split'             -- 实时预览命令效果（如替换命令）
vim.o.completeopt = 'menuone,noinsert,noselect,preview' -- 补全菜单行为：总是显示菜单，不自动插入，不自动选择，显示预览
vim.o.shortmess = vim.o.shortmess .. 'c' -- 缩短某些消息显示（如补全菜单）
vim.o.updatetime = 100                 -- 触发CursorHold等事件的时间间隔（毫秒）
vim.o.formatoptions = vim.o.formatoptions:gsub('tc', '') -- 禁用自动换行(t)和文本注释自动换行(c)
vim.o.virtualedit = 'block'            -- 允许在块选择模式下移动到空位置

-- 与默认值相同的设置（可以安全移除）
vim.o.autochdir = false             -- 不自动切换工作目录（默认关闭）
vim.o.expandtab = false             -- 不将Tab转换为空格（默认使用真实Tab）
vim.o.smarttab = true               -- 在行首按Tab使用shiftwidth（默认开启）
vim.o.autoindent = true             -- 新行自动保持与前一行相同的缩进（默认开启）
vim.o.indentexpr = ''               -- 不使用表达式缩进（默认空字符串）
vim.o.visualbell = true             -- 使用视觉铃声而非声音提示（默认开启）
vim.o.wrap = true                   -- 自动换行（默认开启）
vim.o.ttimeoutlen = 0               -- 键码超时时间（默认0毫秒）
vim.o.timeout = false               -- 不启用键入超时（默认关闭）
vim.o.ttyfast = true                -- 优化终端重绘（现代终端默认开启）

-- Python配置
-- 设置Python3宿主程序路径，优先使用虚拟环境中的Python
vim.g.python3_host_prog = (os.getenv("VIRTUAL_ENV") or "/Users/dzmfg/.uv/base") .. "/bin/python"

-- 禁用不需要的语言提供程序
vim.g.loaded_perl_provider = 0         -- 禁用Perl支持（减少启动开销）
vim.g.loaded_ruby_provider = 0         -- 禁用Ruby支持（减少启动开销）

-- 自动命令组
-- 自动切换工作目录到项目根目录（当检测到特定文件时）
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function(ctx)
    local root = vim.fs.root(ctx.buf, { 
      ".git",       -- Git仓库根目录
      "Makefile",   -- Makefile所在目录
      ".venv",      -- Python虚拟环境目录
      "Cargo.toml", -- Rust项目文件
      "package.json" -- Node.js项目文件
    })
    if root and root ~= "." and root ~= vim.fn.getcwd() then
      vim.cmd.tcd(root)  -- 切换工作目录但不影响其他窗口
      vim.notify("Change CWD to " .. root)  -- 显示通知
    end
  end,
  desc = "Auto change working directory to project root"  -- 自动命令描述
})

-- 恢复上次打开文件时的光标位置
vim.api.nvim_create_autocmd("BufReadPost", {
  pattern = "*",
  callback = function()
    if vim.fn.line("'\"") > 1 and vim.fn.line("'\"") <= vim.fn.line("$") then
      vim.cmd.normal({ 'g\'"', bang = true })  -- 跳转到上次光标位置
    end
  end,
  desc = "Restore cursor position when reopening files"
})

-- 终端打开时自动进入插入模式
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "term://*",
  command = "startinsert",
  desc = "Automatically enter insert mode when opening terminal"
})

-- 自动重新加载init.lua当它被修改时
vim.api.nvim_create_augroup("NVIMRC", { clear = true })
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "init.lua",
  group = "NVIMRC",
  command = "source %",
  desc = "Auto reload init.lua when modified"
})

-- 终端颜色配置（使用Dracula配色方案的近似值）
local terminal_colors = {
  '#000000', -- 黑色
  '#FF5555', -- 红色
  '#50FA7B', -- 绿色
  '#F1FA8C', -- 黄色
  '#BD93F9', -- 蓝色
  '#FF79C6', -- 品红
  '#8BE9FD', -- 青色
  '#BFBFBF', -- 白色
  '#4D4D4D', -- 亮黑色
  '#FF6E67', -- 亮红色
  '#5AF78E', -- 亮绿色
  '#F4F99D', -- 亮黄色
  '#CAA9FA', -- 亮蓝色
  '#FF92D0', -- 亮品红
  '#9AEDFE'  -- 亮青色
}

-- 将homebrew的内容加进来
vim.env.PATH = "/opt/homebrew/bin:"..vim.env.PATH

-- 应用终端颜色配置
for i, color in ipairs(terminal_colors) do
  vim.g['terminal_color_' .. (i-1)] = color
end

-- 终端模式下的键位映射
vim.keymap.set('t', '<C-N>', '<C-\\><C-N>', { desc = "Exit terminal insert mode" })  -- 退出终端插入模式
vim.keymap.set('t', '<C-O>', '<C-\\><C-N><C-O>', { desc = "Exit terminal insert mode and open fold" })  -- 退出并打开折叠

-- 高亮组配置
vim.cmd([[hi NonText ctermfg=gray guifg=grey10]])  -- 设置非文本（如行尾）的颜色

-- 文件和备份配置
local config_dir = vim.fn.stdpath('config') .. '/tmp'  -- 获取配置目录下的tmp子目录
vim.o.backupdir = config_dir .. '/backup,.'  -- 备份文件保存位置
vim.o.directory = config_dir .. '/backup,.'  -- 交换文件保存位置
vim.o.undofile = true                       -- 启用撤销历史持久化
vim.o.undodir = config_dir .. '/undo,.'     -- 撤销历史文件保存位置
