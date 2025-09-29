require('mini.notify').setup()
require('mini.surround').setup()
require('mini.diff').setup()
require('mini.icons').setup({
	style = 'glyph',
})
vim.notify = require('mini.notify').make_notify()
-- TODO:
MiniIcons.mock_nvim_web_devicons()
MiniIcons.tweak_lsp_kind()
