-- ============================================================================
-- Neovim 配置: Mini.nvim 插件集合
-- ============================================================================

-- 获取通用工具函数（如：map）
local map = require("utils.map").map

-- ----------------------------------------------------------------------------
-- 1. 编辑器核心功能增强 (mini.pairs, mini.surround, mini.completion)
-- ----------------------------------------------------------------------------

require("mini.completion").setup({ fallback_action = "<C-x><C-f>" })

require("mini.pairs").setup()
require("mini.surround").setup()

-- ----------------------------------------------------------------------------
-- 2. 工作流与版本控制工具 (mini.diff, mini.files, mini.git)
-- ----------------------------------------------------------------------------

-- require('mini.extra').setup() -- 暂时注释，功能复杂，后续处理
require("mini.diff").setup({
	source = {
		require("mini.diff").gen_source.git(),
		require("mini.diff").gen_source.save(),
	},
	view = { style = "sign", signs = { add = "▎", change = "░", delete = "█" } },
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
	directory = {
		workspace = { glyph = "󰉋", hl = "MiniIconsYellow" },
	},
})
MiniIcons.mock_nvim_web_devicons()
MiniIcons.tweak_lsp_kind()

-- require("mini.notify").setup({
-- 	lsp_progress = {
-- 		enable = false,
-- 	},
-- })

require("mini.cursorword").setup()
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

require("hlchunk").setup({ chunk = { enable = true } })

require("mini.misc").setup()
map("n", "<D-f>", function()
	require("mini.misc").zoom()
end, "放大当前窗口")

vim.api.nvim_create_autocmd("InsertEnter", {
	group = vim.api.nvim_create_augroup("DzmfgMiniSnippets", { clear = true }),
	once = true,
	callback = function()
		local ms = require("mini.snippets")
		local gen_loader = ms.gen_loader
		ms.setup({
			mappings = {
				jump_next = "<tab>",
				jump_prev = "<s-tab>",
			},
			snippets = { gen_loader.from_lang({ lang_patterns = {
				markdown_inline = { "markdown.json" },
			} }) },
		})
		ms.start_lsp_server() -- 这里比较奇怪 开了会报错

		local map_multistep = require("mini.keymap").map_multistep
		map_multistep("i", "<Tab>", {
			"minisnippets_next",
			"minisnippets_expand",
			"pmenu_next",
			"increase_indent",
			"jump_after_close",
		})
		map_multistep("i", "<S-Tab>", { "minisnippets_prev", "pmenu_prev", "decrease_indent", "jump_before_open" })
		map_multistep("i", "<CR>", { "pmenu_accept", "minipairs_cr" })
		map_multistep("i", "<BS>", { "minipairs_bs", "hungry_bs" })
		map_multistep("s", "<Tab>", { "minisnippets_next" })
		map_multistep("s", "<S-Tab>", { "minisnippets_prev" })
	end,
})
