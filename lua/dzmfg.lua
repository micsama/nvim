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
	require('mini.notify').setup()
	vim.notify = require('mini.notify').make_notify()
	require('mini.icons').setup({
		style = 'glyph',
	})
	local gen_loader = require('mini.snippets').gen_loader
	require('mini.snippets').setup({
		mappings = {
			jump_next = '<tab>',
			jump_prev = '<s-tab>',
		},
		snippets = {
			gen_loader.from_lang(),
		},
	})
end)

later(function()
	require('mini.completion').setup()
	require('mini.surround').setup()
	require('mini.diff').setup()
	-- 设置自动补全相关的键位绑定
	local keys = {
		['cr']        = vim.api.nvim_replace_termcodes('<CR>', true, true, true),
		['ctrl-y']    = vim.api.nvim_replace_termcodes('<C-y>', true, true, true),
		['ctrl-y_cr'] = vim.api.nvim_replace_termcodes('<C-y><CR>', true, true, true),
	}
	_G.cr_action = function()
		if vim.fn.pumvisible() ~= 0 then
			local item_selected = vim.fn.complete_info()['selected'] ~= -1
			return item_selected and keys['ctrl-y'] or keys['ctrl-y_cr']
		else
			return keys['cr']
		end
	end
	vim.api.nvim_set_keymap('i', '<CR>', 'v:lua._G.cr_action()', { noremap = true, expr = true })
	vim.api.nvim_set_keymap('i', '<Tab>', [[pumvisible() ? "\<C-n>" : "\<Tab>"]], { noremap = true, expr = true })
	vim.api.nvim_set_keymap('i', '<S-Tab>', [[pumvisible() ? "\<C-p>" : "\<S-Tab>"]], { noremap = true, expr = true })
end
)

MiniSnippets.start_lsp_server()
MiniIcons.mock_nvim_web_devicons()
later(MiniIcons.tweak_lsp_kind, "prepend")

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
