local path_package = vim.fn.stdpath('data') .. '/site'
local mini_path = path_package .. '/pack/deps/start/mini.nvim'
if not vim.loop.fs_stat(mini_path) then
	vim.cmd('echo "Installing `mini.nvim`" | redraw')
	local clone_cmd = {
		'git', 'clone', '--filter=blob:none',
		'https://github.com/nvim-mini/mini.nvim', mini_path
	}
	vim.fn.system(clone_cmd)
	vim.cmd('packadd mini.nvim | helptags ALL')
	vim.cmd('echo "Installed `mini.nvim`" | redraw')
end

require('mini.deps').setup({ path = { package = path_package } })

local later = MiniDeps.later
require('mini.notify').setup()
vim.notify = require('mini.notify').make_notify()
require('mini.icons').setup({
	style = 'glyph',
})

later(function()
	require('mini.surround').setup()
	require('mini.diff').setup()
end
)

MiniIcons.mock_nvim_web_devicons()
later(MiniIcons.tweak_lsp_kind, "prepend")
