-- 键盘映射 (Keymaps)
-- 集中管理所有快捷键。依赖 `util.utils` 中的 `map` 函数应用映射。
local map = require("util.utils").map

vim.g.mapleader = " "       -- <Leader>键设置为空格键。
vim.g.maplocalleader = "\\" -- 本地<Leader>键设置为反斜杠。

-- 定义一个包含所有快捷键映射的表格
local mappings = {
	-- 核心操作 (Core Operations)
	{ "nvi", "<D-s>", "<CMD>up<CR>", "保存当前文件 (Save file)" },
	{ "nv", "<D-w>", "<CMD>q<CR>", "关闭当前窗口 (Quit window)" },
	{ "nv", ";", ":", "快速进入命令行模式 (Command mode)" },
	{ "nv", "`", "~", "切换光标下字符大小写 (Toggle case)" },
	{ "nv", "J", "5j", "向下快速移动5行" },
	{ "nv", "K", "5k", "向上快速移动5行" },

	-- 剪贴板 (Clipboard)
	{ "v", "Y", '"+y', "复制到系统剪贴板" },
	{ "v", "<D-c>", '"+y', "系统复制" },
	{ "nv", "<D-v>", '"+P', "系统粘贴 (普通/可视模式)" },
	{ "ic", "<D-v>", "<C-R>+", "插入/命令模式下粘贴" },
	{ "t", "<D-v>", [[<C-\><C-N>"+pa]], "终端模式下粘贴" },

	-- 窗口、分屏与标签页管理 (Window & Tab Management)
	{ "n", "<leader>w", "<CMD>wincmd w<CR>", "切换到下一个窗口" },

	-- 窗口大小调整
	{ "n", "<up>", "<CMD>res +5<CR>", "增加窗口高度" },
	{ "n", "<down>", "<CMD>res -5<CR>", "减小窗口高度" },
	{ "n", "<left>", "<CMD>vertical resize-5<CR>", "减小窗口宽度" },
	{ "n", "<right>", "<CMD>vertical resize+5<CR>", "增加窗口宽度" },

	-- 分屏操作 (命令为默认行为)
	{ "n", "s", "<nop>", "禁用默认s，作为分屏前缀" },
	{ "n", "sj", "<CMD>split<CR>", "上下分屏" },
	{ "n", "sv", "<CMD>vsplit<CR>", "左右垂直分屏" },
	{ "n", "sq", "<C-w>o", "关闭除当前外的其他窗口" },

	-- 标签页操作
	{ "nv", "<D-t>", "<CMD>tab new<CR>:Yazi<CR>", "新建标签页并打开Yazi" },
	{ "nv", "<D-k>", "<CMD>tabnext<CR>", "下一个标签页" },
	{ "nv", "<D-j>", "<CMD>tabprevious<CR>", "上一个标签页" },
	{ "n", "<D-s-j>", "<CMD>tabmove -1<CR>", "标签页左移" },
	{ "n", "<D-s-k>", "<CMD>tabmove +1<CR>", "标签页右移" },
	{ "it", "<D-j>", "<C-\\><C-n>:-tabnext<CR>", "插入模式：上一个标签页" },
	{ "it", "<D-k>", "<C-\\><C-n>:+tabnext<CR>", "插入模式：下一个标签页" },
	{ "it", "<D-t>", "<C-\\><C-n>:tab new<CR>:Yazi<CR>", "插入模式：新建标签并打开 Yazi" },

	-- LSP (Language Server Protocol)
	{ "n", "<leader>h", function() vim.lsp.buf.hover() end, "悬浮提示" },
	{ "n", "gd", function() vim.lsp.buf.definition() end, "跳转到定义" },
	{ "n", "gD", function() vim.cmd('tab split | lua vim.lsp.buf.definition()') end, "在新标签中打开定义" },
	{ "n", "gi", function() vim.lsp.buf.implementation() end, "跳转到实现" },
	{ "n", "go", function() vim.lsp.buf.type_definition() end, "跳转到类型定义" },
	{ "n", "gr", function() vim.lsp.buf.references() end, "查看引用" },
	{ "n", "<leader>rn", function() vim.lsp.buf.rename() end, "重命名符号" },
	{ "n", "<leader>,", function() vim.lsp.buf.code_action() end, "代码操作" },
	{ "n", '<leader>-', vim.diagnostic.goto_prev, "上一个诊断信息" },
	{ "n", '<leader>=', vim.diagnostic.goto_next, "下一个诊断信息" },
	{ "i", '<c-f>', function() vim.lsp.buf.signature_help() end, "函数签名帮助 (插入模式)" },

	-- 插件与杂项 (Plugins & Utilities)
	{ "nv", "<M-z>", "<CMD>set wrap!<CR>", "切换自动换行" },
	{ "it", "<D-left>", "<C-o>0", "插入模式：移动到行首" },
	{ "it", "<D-right>", "<C-o>$", "插入模式：移动到行尾" },
	{ "n", "<leader><CR>", "<CMD>nohlsearch<CR>", "清除搜索高亮" },
	{ "n", "<leader>rc", "<CMD>edit ~/.config/nvim/init.lua<CR>", "打开配置文件" },
	{ "nv", "<D-g>", ":ToggleTerm dir=git_dir<CR>", "打开Git目录终端" },
	{ "it", "<D-g>", "<C-\\><C-n>:ToggleTerm dir=git_dir<CR>", "插入模式：打开Git目录终端" },
	{ "nv", 'U', ':UndotreeToggle<CR>', "打开撤销树" },
	{ "nv", "<leader>y", "<CMD>lua require('telescope').extensions.neoclip.default()<CR>", "打开剪贴板历史" },
	{ "n", "<D-b>", "<CMD>Neotree toggle reveal=true source=filesystem dir=./<CR>", "打开文件树" },
	{ "n", "<D-y>", "<cmd>Yazi<cr>", "在当前文件位置打开Yazi" },
	{ "n", "<leader>t", '<cmd>Trouble<CR>', "打开 Trouble 诊断面板" },
	{ "n", "<leader>gg", '<cmd>LazyGit<CR>', "打开 Lazygit" },
	{"nv","tt","<cmd>Translate zh<CR>","翻译光标下内容为中文"}
	-- { "t", "<Esc><Esc>", [[<C-\><C-n>]], "退出终端模式 (Exit terminal mode)" }
}

-- 应用所有表格中的快捷键映射
for _, mapping in ipairs(mappings) do
	local mode, lhs, rhs, desc = unpack(mapping)
	map(mode, lhs, rhs, { desc = desc })
end

-- 特殊函数映射 (需要复杂逻辑的映射)
-- 关闭下方窗口
map("n", "<leader>q", function()
	local wins = vim.api.nvim_tabpage_list_wins(0)
	if #wins > 1 then vim.cmd("wincmd j | q") end
end, "关闭下方窗口 (Close lower window)")

-- 标签页数字切换
for i = 1, 9 do
	map("n", "<D-" .. i .. ">", function()
		local tab_count = vim.fn.tabpagenr('$')
		if i <= tab_count then
			vim.cmd("tabnext " .. i)
		else
			vim.notify("标签页 " .. i .. " 不存在。", vim.log.levels.WARN)
		end
	end, "切换到标签页 " .. i)
end

-- 清理未使用的或冲突的默认映射
vim.keymap.del('n', 'grr')
vim.keymap.del('x', 'gra')
vim.keymap.del('n', 'gra')
vim.keymap.del('n', 'grn')
