local nv = { "n", "v" }
local it = { "i", "t" }
-- TODO: 重写 keymaps
local nmappings = {
	-- 文件操作
	{ "<D-s>",        "<CMD>up<CR>",                                            mode = nv }, -- 保存文件
	{ "<M-s>",        "<CMD>up<CR>",                                            mode = nv }, -- 保存文件（替代）
	{ "<S>",          "<CMD>up<CR>",                                            mode = nv }, -- 保存文件（替代）
	{ "<D-w>",        "<CMD>q<CR>",                                             mode = nv }, -- 关闭窗口

	-- 导航与编辑
	{ "J",            "5j",                                                     mode = nv }, -- 向下快速移动5行
	{ "K",            "5k",                                                     mode = nv }, -- 向上快速移动5行
	{ ";",            ":",                                                      mode = nv }, -- 快速进入命令模式
	{ "`",            "~",                                                      mode = nv }, -- 切换大小写

	-- 剪贴板操作
	{ "Y",            "\"+y",                                                   mode = "v" },         -- 复制到系统剪贴板
	{ "<D-c>",        "\"+y",                                                   mode = "v" },         -- 系统复制
	{ "<D-v>",        "\"+P",                                                   mode = nv },          -- 系统粘贴
	{ "<D-v>",        "<C-R>+",                                                 mode = { "i", "c" } }, -- 插入/命令模式下粘贴
	{ "<D-v>",        [[<C-\><C-N>"+pa]],                                       mode = "t" },         -- 终端模式下粘贴

	-- 窗口管理
	{ "<leader>w",    "<CMD>wincmd w<CR>" },         -- 切换到下一个窗口
	{ "<leader>k",    "<C-w>k" },                    -- 上方窗口
	{ "<leader>j",    "<C-w>j" },                    -- 下方窗口
	{ "<leader>h",    "<C-w>h" },                    -- 左边窗口
	{ "<leader>l",    "<C-w>l" },                    -- 右边窗口
	{ "qf",           "<C-w>o" },                    -- 关闭除当前外的其他窗口
	{ "<up>",         "<CMD>res +5<CR>" },           -- 增加窗口高度
	{ "<down>",       "<CMD>res -5<CR>" },           -- 减小窗口高度
	{ "<left>",       "<CMD>vertical resize-5<CR>" }, -- 减小窗口宽度
	{ "<right>",      "<CMD>vertical resize+5<CR>" }, -- 增加窗口宽度

	-- 分屏管理
	{ "s",            "<nop>" },                                                  -- 禁用默认 s
	{ "sk",           "<CMD>set nosplitbelow<CR>:split<CR>:set splitbelow<CR>" }, -- 上方分屏
	{ "sj",           "<CMD>set splitbelow<CR>:split<CR>" },                      -- 下方分屏
	{ "sh",           "<CMD>set nosplitright<CR>:vsplit<CR>:set splitright<CR>" }, -- 左侧分屏
	{ "sl",           "<CMD>set splitright<CR>:vsplit<CR>" },                     -- 右侧分屏
	{ "sh",           "<C-w>t<C-w>K" },                                           -- 转为水平布局
	{ "sv",           "<C-w>t<C-w>H" },                                           -- 转为垂直布局
	{ "srh",          "<C-w>b<C-w>K" },                                           -- 分屏水平旋转
	{ "srv",          "<C-w>b<C-w>H" },                                           -- 分屏垂直旋转

	-- 标签页管理
	{ "<D-t>",        "<CMD>tab new<CR>:Yazi<CR>",                              mode = nv }, -- 新建标签并打开文件管理器
	{ "<D-j>",        "<CMD>-tabnext<CR>",                                      mode = nv }, -- 上一个标签页
	{ "<D-k>",        "<CMD>+tabnext<CR>",                                      mode = nv }, -- 下一个标签页
	{ "<D-s-j>",      "<CMD>-tabmove<CR>" },                                                -- 标签左移
	{ "<D-s-k>",      "<CMD>+tabmove<CR>" },                                                -- 标签右移
	{ "<D-j>",        "<C-\\><C-n>:-tabnext<CR>",                               mode = it }, -- 插入模式：上一个标签页
	{ "<D-k>",        "<C-\\><C-n>:+tabnext<CR>",                               mode = it }, -- 插入模式：下一个标签页
	{ "<D-t>",        "<C-\\><C-n>:tab new<CR>:Yazi<CR>",                       mode = it }, -- 插入模式：新建标签并打开 Yazi

	-- 其他杂项
	{ "<M-z>",        "<CMD>set wrap!<CR>",                                     mode = nv }, -- 切换自动换行
	{ "<D-left>",     "<C-o>0",                                                 mode = it }, -- 插入模式：移动到行首
	{ "<D-right>",    "<C-o>$",                                                 mode = it }, -- 插入模式：移动到行尾
	{ "<leader><CR>", "<CMD>nohlsearch<CR>" },                                              -- 清除搜索高亮
	{ "<leader>rc",   "<CMD>edit ~/.config/nvim/init.lua<CR>:chdir ./<CR>" },               -- 打开配置文件

	-- Git 相关终端
	{ "<D-g>",        ":ToggleTerm dir=git_dir<CR>",                            mode = nv,                          desc = "打开终端 (Git 目录)" },
	{ "<D-g>",        "<C-\\><C-n>:ToggleTerm dir=git_dir<CR>",                 mode = it,                          desc = "打开终端 (Git 目录)" },

	-- LSP 相关
	{ '<leader>h',    function() vim.lsp.buf.hover() end,                       desc = "悬浮提示" },
	{ 'gd',           function() vim.lsp.buf.definition() end,                  desc = "跳转到定义" },
	{ 'gD',           '<cmd>tab split | lua vim.lsp.buf.definition()<CR>',      desc = "在新标签中打开定义" },
	{ 'gi',           function() vim.lsp.buf.implementation() end,              desc = "跳转到实现" },
	{ 'go',           function() vim.lsp.buf.type_definition() end,             desc = "跳转到类型定义" },
	{ 'gr',           function() vim.lsp.buf.references() end,                  desc = "查看引用" },
	{ '<leader>rn',   function() vim.lsp.buf.rename() end,                      desc = "重命名符号" },
	{ '<leader>,',    function() vim.lsp.buf.code_action() end,                 desc = "代码操作" },
	{ '<leader>t',    '<cmd>Trouble<CR>',                                       desc = "打开 Trouble" },
	{
		'<leader>-',
		function()
			vim.diagnostic.jump({
				count = -1,                       -- 上一个诊断
				float = true,                     -- 显示浮动窗口
				pos = vim.api.nvim_win_get_cursor(0), -- 当前光标位置
			})
		end,
		desc = "上一个诊断"
	},
	{
		'<leader>=',
		function()
			vim.diagnostic.jump({
				count = 1,                        -- 下一个诊断
				float = true,
				pos = vim.api.nvim_win_get_cursor(0),
			})
		end,
		desc = "下一个诊断"
	},
	-- 插入模式快捷键
	{ '<c-f>', function() vim.lsp.buf.signature_help() end, mode = 'i', desc = "函数签名帮助" },
	{ 'U',     ':UndotreeToggle<CR>',                        mode = nv }, -- 打开撤销树
	{ "<leader>y", "<CMD>lua require('telescope').extensions.neoclip.default()<CR>",mode = nv , desc = "打开 neoclip" },
	{ "<D-b>", "<CMD>Neotree toggle reveal=true source=filesystem dir=./<CR>" }, -- 文件树
	{ "<D-y>", "<cmd>Yazi<cr>", desc = "在当前文件位置打开 Yazi", },
	{
		"<leader>?",
		function()
			require("which-key").show({ global = false })
		end,
		desc = "查看 buffer 内快捷键 (which-key)",
	},
}

