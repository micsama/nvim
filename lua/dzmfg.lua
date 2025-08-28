-- Put this at the top of 'init.lua'
local path_package = vim.fn.stdpath('data') .. '/site'
local mini_path = path_package .. '/pack/deps/start/mini.nvim'
if not vim.loop.fs_stat(mini_path) then
	vim.cmd('echo "Installing `mini.nvim`" | redraw')
	local clone_cmd = {
		'git', 'clone', '--filter=blob:none',
		-- Uncomment next line to use 'stable' branch
		-- '--branch', 'stable',
		'https://github.com/nvim-mini/mini.nvim', mini_path
	}
	vim.fn.system(clone_cmd)
	vim.cmd('packadd mini.nvim | helptags ALL')
	vim.cmd('echo "Installed `mini.nvim`" | redraw')
end
-- 初始化mini.deps
require('mini.deps').setup({ path = { package = path_package } })
local now, add, later = MiniDeps.now, MiniDeps.add, MiniDeps.later

-- 快捷键 sa sd sr等等，快速更改包围的引号或者括号等等。
now(function()
	require('mini.icons').setup()
	require('mini.notify').setup()
	vim.notify = require('mini.notify').make_notify()
	local gen_loader = require('mini.snippets').gen_loader
	require('mini.snippets').setup({
		snippets = {
			gen_loader.from_lang(),
		},
	})
end)

later(function()
	require('mini.completion').setup(
		{
			mappings = {
				force_twostep = '<C-Space>',
				force_fallback = '<A-Space>',
				scroll_down = '<C-f>',
				scroll_up = '<C-b>',
			},
		}
	)
	require('mini.surround').setup()
	require('mini.diff').setup()
end
)

-- 加载对应的插件
require("plugins.Ui")
require("plugins.lsp")
require("plugins.editor")
require("plugins.filemanager")
require("plugins.dap")
require("plugins.coderunner")

-- TODO: mini.cmp
require("plugins.cmp")
require("plugins.other")
require("plugins.llm")
require("plugins.git")

-- later(function() require('mini.ai').setup() end)
-- later(function() require('mini.comment').setup() end)
-- later(function() require('mini.pick').setup() end)
