vim.g.mapleader = " "       -- 将<Leader>键设置为空格键
vim.g.maplocalleader = "\\" -- 将本地<Leader>键设置为反斜杠
require("config.defaults")  -- 设置默认的一些配置
require("config.keymaps")   -- 设置快捷键
if vim.g.neovide then
	require("config.neovide")
end
require("dzmfg") -- 基础mini设置配置

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
    vim.pack.add{"https://github.com/kdheepak/lazygit.nvim"}
    vim.g.lazygit_floating_window_scaling_factor = 1.0
    vim.g.lazygit_floating_window_winblend = 0
    vim.g.lazygit_use_neovim_remote = true

local uname = vim.uv.os_uname()
-- -- 检查系统类型
if uname.sysname == "Darwin" then
	vim.notify("macOS Loading...")
	-- vim.o.shell = "/opt/homebrew/bin/fish"
	vim.o.shell = "/opt/homebrew/bin/nu"
else
	vim.notify("Linux Loading...")
	vim.o.shell = "/usr/bin/bash"
end
