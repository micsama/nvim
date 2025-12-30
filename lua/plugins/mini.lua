-- ============================================================================
-- Neovim 配置: Mini.nvim 插件集合
--
-- ============================================================================

-- 获取通用工具函数（如：map）
local map = require("util.utils").map
local hipatterns = require("mini.hipatterns")
local map_multistep = require("mini.keymap").map_multistep

-- ----------------------------------------------------------------------------
-- 1. 编辑器核心功能增强 (mini.pairs, mini.surround, mini.completion, mini.snippets)
-- ----------------------------------------------------------------------------

require("mini.completion").setup()
require("mini.pairs").setup()
require("mini.surround").setup()

-- mini.snippets 配置
local ms = require("mini.snippets")
local gen_loader = ms.gen_loader
ms.setup({
	mappings = {
		jump_next = "<tab>",
		jump_prev = "<s-tab>",
	},
	snippets = {
		gen_loader.from_lang({
			lang_patterns = {
				markdown_inline = { "markdown.json" },
			},
		}),
	},
})
-- 这里比较奇怪 开了会报错
ms.start_lsp_server()

-- keymap 多步映射 (与 mini.snippets/completion 配合)
-- 统一处理 <Tab>, <S-Tab>, <CR>, <BS> 在插入模式下的行为
map_multistep("i", "<Tab>", { "pmenu_next" }) -- 补全菜单：下一个
map_multistep("i", "<S-Tab>", { "pmenu_prev" }) -- 补全菜单：上一个
map_multistep("i", "<CR>", { "pmenu_accept", "minipairs_cr" }) -- 接受补全或 mini.pairs 回车
map_multistep("i", "<BS>", { "minipairs_bs" }) -- mini.pairs 退格

-- ----------------------------------------------------------------------------
-- 2. 工作流与版本控制工具 (mini.diff, mini.files, mini.git)
-- ----------------------------------------------------------------------------

-- require('mini.extra').setup() -- 暂时注释，功能复杂，后续处理
require("mini.diff").setup({
	view = {
		style = "sign",
		signs = { add = "▎", change = "░", delete = "▒" },
	},
})

require("mini.files").setup({
	mappings = { go_in_plus = "<CR>" },
	content = {
		filter = function(fs_entry)
			-- 隐藏以 '.' 开头的文件或目录
			if vim.startswith(fs_entry.name, ".DS") then
				return false
			end
			return true
		end,
	},
	use_as_default_explorer = true,
	permanent_delete = false,
})

local function yank_relative_path()
	local p = vim.fn.fnamemodify(MiniFiles.get_fs_entry().path, ":.")
	vim.fn.setreg("+", p)
	vim.notify(p)
end

vim.api.nvim_create_autocmd("User", {
	pattern = "MiniFilesBufferCreate",
	callback = function(a)
		vim.keymap.set("n", "yp", yank_relative_path, { buffer = a.data.buf_id })
	end,
})

require("mini.git").setup()

-- ----------------------------------------------------------------------------
-- 3. UI/美化/显示 (mini.icons, mini.notify, mini.starter, mini.cursorword)
-- ----------------------------------------------------------------------------

require("mini.icons").setup({
	style = "glyph",
	default = {},
	directory = {},
})
MiniIcons.mock_nvim_web_devicons()
MiniIcons.tweak_lsp_kind()

-- require('mini.notify').setup()
require("mini.starter").setup()
require("mini.cursorword").setup()
-- require('mini.base16').setup({}) -- 颜色主题，保持原样注释

-- mini.snippets LSP Server 启动 (方便与其他LSP集成)

-- ----------------------------------------------------------------------------
-- 4. 代码高亮与辅助 (mini.hipatterns, hlchunk, mini.misc)
-- ----------------------------------------------------------------------------

-- mini.hipatterns 配置
hipatterns.setup({
	highlighters = {
		-- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
		fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
		hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
		todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
		note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
		-- Highlight hex color codes
		hex_color = hipatterns.gen_highlighter.hex_color(),
	},
})

-- hlchunk 代替 mini.indentscope，因为mini.indentscope只有默认的缩进显示
-- require('mini.indentscope').setup()
require("hlchunk").setup({
	chunk = {
		enable = true,
	},
})

-- mini.misc 配置及映射
require("mini.misc").setup()
-- 映射：放大当前窗口
map("n", "<D-f>", function()
	require("mini.misc").zoom()
end, "放大当前窗口")
-- 启用终端背景色同步功能
require("mini.misc").setup_termbg_sync()
-- require('mini.misc').setup_auto_root()
-- 暴露全局函数 (put/put_text)
require("mini.misc").setup({ make_global = { "put", "put_text" } })
