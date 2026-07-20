-- ===========================================================================
-- Mini.nvim 插件集合
-- ===========================================================================

local map = require("utils.map").map

-- =============================================================================
-- 1) 编辑器核心功能增强
-- =============================================================================
require("mini.completion").setup({ fallback_action = "<C-x><C-f>" })

require("mini.pairs").setup()
require("mini.surround").setup()

-- =============================================================================
-- 2) 工作流与版本控制工具
-- =============================================================================

-- require('mini.extra').setup() -- 暂时注释，功能复杂，后续处理
local mini_diff = require("mini.diff")
mini_diff.setup({
	source = {
		mini_diff.gen_source.git(),
		mini_diff.gen_source.save(),
	},
	view = { style = "sign", signs = { add = "▎", change = "░", delete = "█" } },
})

-- =============================================================================
-- 3) MiniFiles 复制辅助
-- =============================================================================
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
	options = {
		permanent_delete = false,
	},
})

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

-- =============================================================================
-- 4) UI/美化/显示
-- =============================================================================

require("mini.icons").setup({
	style = "glyph",
	directory = {
		workspace = { glyph = "󰉋", hl = "MiniIconsYellow" },
	},
})
MiniIcons.mock_nvim_web_devicons()
MiniIcons.tweak_lsp_kind()

require("mini.cursorword").setup()

-- =============================================================================
-- 5) 代码高亮与辅助
-- =============================================================================
local hipatterns = require("mini.hipatterns")
hipatterns.setup({ -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
	highlighters = {
		fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
		hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
		todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
		note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
		hex_color = hipatterns.gen_highlighter.hex_color(), -- Highlight hex color codes
	},
})

map("nti", "<D-f>", function()
	require("utils.zoom").toggle()
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
			"pmenu_next",
			"increase_indent",
			"minisnippets_expand",
			"jump_after_close",
		})
		map_multistep("i", "<S-Tab>", { "minisnippets_prev", "pmenu_prev", "decrease_indent", "jump_before_open" })
		map_multistep("i", "<CR>", { "pmenu_accept", "minipairs_cr" })
		map_multistep("i", "<BS>", { "minipairs_bs", "hungry_bs" })
		map_multistep("s", "<Tab>", { "minisnippets_next" })
		map_multistep("s", "<S-Tab>", { "minisnippets_prev" })
	end,
})
