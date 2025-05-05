vim.g.mapleader = " "       -- 将<Leader>键设置为空格键
vim.g.maplocalleader = "\\" -- 将本地<Leader>键设置为反斜杠
require("config.defaults")  -- 设置默认的一些配置
require("config.keymaps")   -- 设置快捷键
if vim.g.neovide then
	require("config.neovide")
end
require("dzmfg") -- 基础mini设置配置

local uname = vim.uv.os_uname()
-- -- 检查系统类型
if uname.sysname == "Darwin" then
	vim.notify("macOS Loading...")
	vim.o.shell = "/opt/homebrew/bin/fish"
	-- vim.o.shell = "/opt/homebrew/bin/nu"
else
	vim.notify("Linux Loading...")
	vim.o.shell = "/usr/bin/bash"
end
