--
-- editor
--
require('mini.completion').setup()
require('mini.pairs').setup()
require('mini.surround').setup()
local gen_loader = require('mini.snippets').gen_loader
require('mini.snippets').setup({
	mappings = {
		jump_next = '<tab>',
		jump_prev = '<s-tab>',
	},
	snippets = {
		gen_loader.from_lang({
			lang_patterns = {
				markdown_inline = { 'markdown.json' },
			}
		}),
	}
})

local map_multistep = require('mini.keymap').map_multistep
map_multistep('i', '<Tab>', { 'pmenu_next' })
map_multistep('i', '<S-Tab>', { 'pmenu_prev' })
map_multistep('i', '<CR>', { 'pmenu_accept', 'minipairs_cr' })
map_multistep('i', '<BS>', { 'minipairs_bs' })

--
-- workflow
--

-- 这个插件功能很复杂 慢慢看
-- require('mini.extra').setup()
require('mini.diff').setup()
require('mini.files').setup()



require('mini.icons').setup({ style = 'glyph' })
MiniIcons.mock_nvim_web_devicons()
MiniIcons.tweak_lsp_kind()
MiniSnippets.start_lsp_server()
require('mini.notify').setup()
require('mini.git').setup()
