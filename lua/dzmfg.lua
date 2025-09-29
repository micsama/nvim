require("onedarkpro").setup({
	colors = {
		cursorline = "#303442" -- This is optional. The default cursorline color is based on the background
	},
	options = {
		cursorline = true
	}
})
vim.cmd.colorscheme('onedark')
require('Bullets').setup({})

local now, add, later = MiniDeps.now, MiniDeps.add, MiniDeps.later

now(function()
	require('mini.notify').setup()
	vim.notify = require('mini.notify').make_notify()
	require('mini.icons').setup({
		style = 'glyph',
	})
end)

later(function()
	require('mini.surround').setup()
	require('mini.diff').setup()
end
)

MiniIcons.mock_nvim_web_devicons()
later(MiniIcons.tweak_lsp_kind, "prepend")

-- 加载对应的插件
require("plugins.Ui")
require("plugins.lsp")
require("plugins.editor")
require("plugins.filemanager")
require("plugins.dap")

-- TODO: mini.cmp
require("plugins.cmp")
require("plugins.other")
require("plugins.llm")
require("plugins.git")
