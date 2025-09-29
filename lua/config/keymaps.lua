-- ===========================================================================
-- 键盘映射 (Keymaps)
-- 这个文件使用表格来集中定义所有快捷键，并使用 `utils.lua` 中的 `map` 函数来应用映射。
-- ===========================================================================
-- 导入键位映射工具函数
local map = require("util.utils").map

vim.g.mapleader = " "       -- 将<Leader>键设置为空格键
vim.g.maplocalleader = "\\" -- 将本地<Leader>键设置为反斜杠

-- 定义一个包含所有快捷键映射的表格
local mappings = {
	-- =======================================================================
	-- 核心操作
	-- =======================================================================
	{ "n", "<D-s>", "<CMD>up<CR>", "保存文件" },
	{ "n", "<D-w>", "<CMD>q<CR>", "关闭窗口" },
	{ "n", "J", "5j", "向下快速移动5行" },
	{ "n", "K", "5k", "向上快速移动5行" },
	{ "n", ";", ":", "快速进入命令模式" },
	{ "n", "`", "~", "切换大小写" },
	{ "v", "Y", '"+y', "复制到系统剪贴板" },
	{ "v", "<D-c>", '"+y', "系统复制" },
	{ "nv", "<D-v>", '"+P', "系统粘贴" },
	{ { "i", "c" }, "<D-v>", "<C-R>+", "插入/命令模式下粘贴" },
	{ "t", "<D-v>", [[<C-\><C-N>"+pa]], "终端模式下粘贴" },

	-- =======================================================================
	-- 窗口、分屏与标签页管理
	-- =======================================================================
	{ "n", "<leader>w", "<CMD>wincmd w<CR>", "切换到下一个窗口" },
	{ "n", "<leader>k", "<C-w>k", "切换到上方窗口" },
	{ "n", "<leader>j", "<C-w>j", "切换到下方窗口" },
	{ "n", "<leader>h", "<C-w>h", "切换到左方窗口" },
	{ "n", "<leader>l", "<C-w>l", "切换到右方窗口" },
	{ "n", "<up>", "<CMD>res +5<CR>", "增加窗口高度" },
	{ "n", "<down>", "<CMD>res -5<CR>", "减小窗口高度" },
	{ "n", "<left>", "<CMD>vertical resize-5<CR>", "减小窗口宽度" },
	{ "n", "<right>", "<CMD>vertical resize+5<CR>", "增加窗口宽度" },
	{ "n", "s", "<nop>", "禁用默认s" },
	{ "n", "sk", "<CMD>split<CR>", "上方水平分屏" },
	{ "n", "sj", "<CMD>split<CR>", "下方水平分屏" },
	{ "n", "sh", "<CMD>vsplit<CR>", "左侧垂直分屏" },
	{ "n", "sl", "<CMD>vsplit<CR>", "右侧垂直分屏" },
	{ "n", "sq", "<C-w>o", "关闭除当前外的其他窗口" },
	{ "nv", "<D-t>", "<CMD>tab new<CR>:Yazi<CR>", "新建标签页并打开Yazi" },
	{ "nv", "<D-k>", "<CMD>tabnext<CR>", "下一个标签页" },
	{ "nv", "<D-j>", "<CMD>tabprevious<CR>", "上一个标签页" },
	{ "n", "<D-s-j>", "<CMD>tabmove -1<CR>", "标签页左移" },
	{ "n", "<D-s-k>", "<CMD>tabmove +1<CR>", "标签页右移" },
	{ "it", "<D-j>", "<C-\\><C-n>:-tabnext<CR>", "插入模式：上一个标签页" },
	{ "it", "<D-k>", "<C-\\><C-n>:+tabnext<CR>", "插入模式：下一个标签页" },
	{ "it", "<D-t>", "<C-\\><C-n>:tab new<CR>:Yazi<CR>", "插入模式：新建标签并打开 Yazi" },

	-- =======================================================================
	-- LSP (Language Server Protocol)
	-- =======================================================================
	{ "n", '<leader>h', function() vim.lsp.buf.hover() end, "悬浮提示" },
	{ "n", "gd", function() vim.lsp.buf.definition() end, "跳转到定义" },
	{ "n", "gD", '<cmd>tab split | lua vim.lsp.buf.definition()<CR>', "在新标签中打开定义" },
	{ "n", "gi", function() vim.lsp.buf.implementation() end, "跳转到实现" },
	{ "n", "go", function() vim.lsp.buf.type_definition() end, "跳转到类型定义" },
	{ "n", "gr", function() vim.lsp.buf.references() end, "查看引用" },
	{ "n", "<leader>rn", function() vim.lsp.buf.rename() end, "重命名符号" },
	{ "n", "<leader>,", function() vim.lsp.buf.code_action() end, "代码操作" },
	{ "n", '<leader>-', vim.diagnostic.goto_prev, "上一个诊断" },
	{ "n", '<leader>=', vim.diagnostic.goto_next, "下一个诊断" },
	{ "i", '<c-f>', function() vim.lsp.buf.signature_help() end, "函数签名帮助" },

	-- =======================================================================
	-- 插件与杂项（类VsCode改键～）
	-- =======================================================================
	{ "nv", "<M-z>", "<CMD>set wrap!<CR>", "切换自动换行" },
	{ "it", "<D-left>", "<C-o>0", "插入模式：移动到行首" },
	{ "it", "<D-right>", "<C-o>$", "插入模式：移动到行尾" },
	{ "n", "<leader><CR>", "<CMD>nohlsearch<CR>", "清除搜索高亮" },
	{ "n", "<leader>rc", "<CMD>edit ~/.config/nvim/init.lua<CR>", "打开配置文件" },
	{ "nv", "<D-g>", ":ToggleTerm dir=git_dir<CR>", "打开Git目录终端" },
	{ "it", "<D-g>", "<C-\\><C-n>:ToggleTerm dir=git_dir<CR>", "打开Git目录终端" },
	{ "nv", 'U', ':UndotreeToggle<CR>', "打开撤销树" },
	{ "nv", "<leader>y", "<CMD>lua require('telescope').extensions.neoclip.default()<CR>", "打开剪贴板历史" },
	{ "n", "<D-b>", "<CMD>Neotree toggle reveal=true source=filesystem dir=./<CR>", "打开文件树" },
	{ "n", "<D-y>", "<cmd>Yazi<cr>", "在当前文件位置打开Yazi" },
	{ "n", "<leader>t", '<cmd>Trouble<CR>', "打开 Trouble" },
	{ "n", "<leader>gg", '<cmd>LazyGit<CR>', "打开 Lazygit" },
}

for _, mapping in ipairs(mappings) do
	-- 使用 Lua 的解构赋值来简化代码
	local mode, lhs, rhs, desc = unpack(mapping)
	map(mode, lhs, rhs, { desc = desc })
end


-- 关闭下方窗口
map("n", "<leader>q", function()
	local wins = vim.api.nvim_tabpage_list_wins(0)
	if #wins > 1 then
		vim.cmd("wincmd j | q")
	end
end, "关闭下方窗口")

-- 特殊处理：标签页数字切换 (这里因为逻辑复杂，不适合用表格)
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

-- 特殊处理：终端模式退出
map('t', '<Esc><Esc>', [[<C-\><C-n>]], "退出终端模式")

vim.keymap.del('n', 'grr')
vim.keymap.del('x', 'gra')
vim.keymap.del('n', 'gra')
vim.keymap.del('n', 'grn')

-- 使用 `map` 禁用默认的 'q'
map("n", "q", "<nop>", "禁用默认q")
map("n", ",q", "q", "使用,q来退出")
