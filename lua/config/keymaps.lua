-- ===========================================================================
-- 键盘映射 (Keymaps)
-- ===========================================================================
local map = require("utils.map").map
require("utils.map").map_fullwidth_to_halfwidth()

M = {}
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- stylua: ignore start
local static_maps = {
    -- 核心 & 剪贴板
    { "nvi", "<D-s>",       "<CMD>up<CR>",                       "保存当前文件" },
    { "nv",  "<D-w>",       "<CMD>q<CR>",                        "关闭当前窗口" },
    { "nv",  "`",           "~",                                 "切换大小写" },
    { "nv",  "J",           "5j",                                "向下快移 5 行" },
    { "nv",  "K",           "5k",                                "向上快移 5 行" },
    { "n",   "<C-j>",       "J",                                 "拼接两行" },
    { "v",   "Y",           '"+y',                               "复制到系统剪贴板" },
    { "v",   "<D-c>",       '"+y',                               "复制到系统剪贴板" },
    { "nv",  "<D-v>",       '"+p',                               "粘贴自系统剪贴板" },
    { "ic",  "<D-v>",       "<C-R>+",                            "插入模式粘贴" },
    { "t",   "<D-v>",       [[<C-\><C-N>"+pa]],                  "终端模式粘贴" },
    { "it",  "<D-left>",    "<C-o>0",                            "移动到行首" },
    { "it",  "<D-right>",   "<C-o>$",                            "移动到行尾" },

    -- 窗口 & 标签页
    { "n",   "<leader>w",   "<CMD>wincmd w<CR>",                 "切换到下一窗口" },
    { "n",   "s",           "<nop>",                             "分屏前缀" },
    { "n",   "sj",          "<CMD>split<CR>",                    "上下分屏" },
    { "n",   "sv",          "<CMD>vsplit<CR>",                   "左右分屏" },
    { "n",   "sq",          "<C-w>o",                            "关闭其他窗口" },
    { "n",   "<up>",        "<CMD>res +5<CR>",                   "增加窗口高度" },
    { "n",   "<down>",      "<CMD>res -5<CR>",                   "减小窗口高度" },
    { "n",   "<left>",      "<CMD>vertical resize-5<CR>",        "减小窗口宽度" },
    { "n",   "<right>",     "<CMD>vertical resize+5<CR>",        "增加窗口宽度" },
    { "nv",  "<D-t>",       "<CMD>tab new<CR>",                  "新标签页" },
    { "nv",  "<D-k>",       "<CMD>tabnext<CR>",                  "下一个标签页" },
    { "nv",  "<D-j>",       "<CMD>tabprevious<CR>",              "上一个标签页" },
    { "n",   "<D-s-j>",     "<CMD>tabmove -1<CR>", "标签页左移" },
    { "n",   "<D-s-k>",     "<CMD>tabmove +1<CR>", "标签页右移" },
    { "it",  "<D-j>",       "<C-\\><C-n>:-tabnext<CR>",          "插入: 上个标签" },
    { "it",  "<D-k>",       "<C-\\><C-n>:+tabnext<CR>",          "插入: 下个标签" },
    { "it",  "<D-t>",       "<C-\\><C-n>:tab new<CR>",           "插入: 新标签" },
    { "n",   "<leader>ss",  "<CMD>mksession!<CR>",               "Save Session" },
    { "n",   "<leader>sl",  "<CMD>source Session.vim<Cr>",       "Load Session" },
    -- 插件简短指令
    { "nv",  "<D-z>",       "<CMD>set wrap!<CR>",                "切换自动换行" },
    { "n",   "<leader><CR>","<CMD>nohlsearch<CR>",               "清除搜索高亮" },
    { "nv",  "U",           ":UndotreeToggle<CR>",               "撤销树" },
    { "nv",  "<D-o>",       "<CMD>CodeCompanionChat Toggle<CR>", "AI 聊天" },
}

local function_maps = {
    { "n",   "<c-g>",      function() MiniGit.show_at_cursor() end,          "查看当前行git历史" },
    { "n",   "H",          function() MiniDiff.toggle_overlay() end,         "切换 Hunk 预览" },
    { "n",   "<D-b>",      function() _G.ToggleMiniFilesAtCurrentFile() end, "打开侧边文件树" },
    { "n",   "<leader>rc", "<CMD>source ~/.config/nvim/Session.vim<CR>",     "加载 Session" },
    { "n",   "<leader>q",  function() local wins = vim.api.nvim_tabpage_list_wins(0) if #wins > 1 then vim.cmd("wincmd j | q") end end, "关闭下方窗口" },
}

M.lsp_maps = {
    { "n",   "<leader>h",  vim.lsp.buf.hover,           "悬浮提示" },
    { "n",   "gd",         vim.lsp.buf.definition,      "跳转定义" },
    { "n",   "gi",         vim.lsp.buf.implementation,  "跳转实现" },
    { "n",   "go",         vim.lsp.buf.type_definition, "跳转类型定义" },
    { "n",   "gr",         vim.lsp.buf.references,      "查看引用" },
    { "n",   "<leader>rn", vim.lsp.buf.rename,          "变量重命名" },
    { "n",   "<leader>,",  vim.lsp.buf.code_action,     "代码操作" },
    { "i",   "<c-f>",      vim.lsp.buf.signature_help,  "函数签名帮助" },
    { "n",   "gD",         function() vim.cmd('tab split | lua vim.lsp.buf.definition()') end, "新标签打开定义" },
}
-- stylua: ignore end

vim.iter({ static_maps, function_maps }):flatten():each(function(m)
	map(unpack(m))
end)

vim.iter(vim.fn.range(1, 9)):each(function(i)
	map("nit", "<D-" .. i .. ">", function()
		if i <= vim.fn.tabpagenr("$") then
			vim.cmd("tabnext " .. i)
		else
			vim.notify("标签页[" .. i .. "]不存在", vim.log.levels.WARN, { title = "󰓩  Tabs" })
		end
	end, "切换到标签页 " .. i)
end)

function ToggleMiniFilesAtCurrentFile()
	if not MiniFiles.close() then
		local current_file = vim.api.nvim_buf_get_name(0)
		local is_valid_file = current_file and current_file ~= "" and vim.fn.filereadable(current_file) == 1
		MiniFiles.open(is_valid_file and current_file or nil)
	end
end

-- 清理未使用的或冲突的默认映射
-- vim.keymap.del("n", "grr")
-- vim.keymap.del("x", "gra")
-- vim.keymap.del("n", "gra")
-- vim.keymap.del("n", "grn")
return M
