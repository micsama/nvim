require("config.defaults")
-- 获取系统信息
local uname = vim.uv.os_uname()

-- 检查系统类型
if uname.sysname == "Linux" then
	vim.o.shell = "/usr/bin/bash"
elseif uname.sysname == "Darwin" then
	vim.o.shell = "/opt/homebrew/bin/fish"
else
	vim.o.shell = "/usr/bin/bash"
end

require("config.keymaps")
require("config.plugins")
if vim.g.neovide then
	require("config.neovide")
end
