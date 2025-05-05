-- 加载mini.nvim
local path_package = vim.fn.stdpath('data') .. '/site/'
local mini_path = path_package .. 'pack/deps/start/mini.nvim'
if not vim.loop.fs_stat(mini_path) then
	vim.cmd('echo "Installing `mini.nvim`" | redraw')
			local clone_cmd = { 'git', 'clone', '--filter=blob:none', 'https://github.com/echasnovski/mini.nvim', mini_path }
	vim.fn.system(clone_cmd)
	vim.cmd('packadd mini.nvim | helptags ALL')
	vim.cmd('echo "Installed `mini.nvim`" | redraw')
end

require('mini.deps').setup({ path = { package = path_package } })

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

-- Safely execute later
-- later(function() require('mini.ai').setup() end)
-- later(function() require('mini.comment').setup() end)
-- later(function() require('mini.pick').setup() end)
-- later(function() require('mini.surround').setup() end)
