-- ============================================================================
-- Neovim 配置: Mini.nvim 插件集合
-- ============================================================================

-- 获取通用工具函数（如：map）
local map = require("utils").map

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
ms.start_lsp_server() -- 这里比较奇怪 开了会报错

local map_multistep = require("mini.keymap").map_multistep

-- 【Tab 逻辑链】：代码片段跳转 -> 片段展开 -> 补全菜单 -> 增加缩进 -> 跳出括号
map_multistep("i", "<Tab>", {
	"minisnippets_next",
	"minisnippets_expand",
	"pmenu_next",
	"increase_indent",
	"jump_after_close",
})

-- 【Shift-Tab 逻辑链】：代码片段回跳 -> 补全菜单 -> 减少缩进 -> 跳到左括号前
map_multistep("i", "<S-Tab>", { "minisnippets_prev", "pmenu_prev", "decrease_indent", "jump_before_open" })

-- 【回车键 逻辑链】：确认补全项 -> 自动配对换行
map_multistep("i", "<CR>", { "pmenu_accept", "minipairs_cr" })

-- 【退格键 逻辑链】：成对删除括号 -> 贪婪删除空格
map_multistep("i", "<BS>", { "minipairs_bs", "hungry_bs" })

-- 【选择模式】：确保在填写代码片段时 Tab 依然能跳转
map_multistep("s", "<Tab>", { "minisnippets_next" })
map_multistep("s", "<S-Tab>", { "minisnippets_prev" })

-- ----------------------------------------------------------------------------
-- 2. 工作流与版本控制工具 (mini.diff, mini.files, mini.git)
-- ----------------------------------------------------------------------------

-- require('mini.extra').setup() -- 暂时注释，功能复杂，后续处理
require("mini.diff").setup({
	source = {
		require("mini.diff").gen_source.git(),
		require("mini.diff").gen_source.save(),
	},
	view = {
		style = "sign",
		signs = { add = "▎", change = "░", delete = "█" },
	},
})

require("mini.files").setup({
	mappings = { go_in_plus = "<CR>" },
	content = {
		filter = function(fs_entry)
			if vim.startswith(fs_entry.name, ".DS") then
				return false
			end
			return true
		end,
	},
	permanent_delete = false,
})

-- ----------------------------------------------------------------------------
-- 2. yp, yP 来复制选择目标的
-- ----------------------------------------------------------------------------
local function yank(mod)
	local p = vim.fn.fnamemodify(MiniFiles.get_fs_entry().path, mod)
	vim.fn.setreg("+", p)
	vim.notify("Copied: " .. p, nil, { title = "MiniFiles", icon = "📂" })
end

vim.api.nvim_create_autocmd("User", {
	pattern = "MiniFilesBufferCreate",
	callback = function(ev)
		map("n", "yp", function()
			yank(":.")
		end, { buffer = ev.data.buf_id })
		map("n", "yP", function()
			yank(":p")
		end, { buffer = ev.data.buf_id })
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

-- require("mini.notify").setup({
-- 	lsp_progress = {
-- 		enable = false,
-- 	},
-- })
require("mini.starter").setup()
require("mini.cursorword").setup()
-- require('mini.base16').setup({}) -- 颜色主题，保持原样注释

-- mini.snippets LSP Server 启动 (方便与其他LSP集成)

-- ----------------------------------------------------------------------------
-- 4. 代码高亮与辅助 (mini.hipatterns, hlchunk, mini.misc)
-- ----------------------------------------------------------------------------
-- mini.hipatterns 配置
local hipatterns = require("mini.hipatterns")
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
