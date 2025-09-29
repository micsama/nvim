-- 先加载不依赖插件的相关配置
require("config.defaults") -- 设置默认的一些配置
require("config.keymaps")  -- 设置快捷键
require("config.mini")     -- 配置mini.nvim

if vim.g.neovide then
	require("config.neovide")
end

vim.pack.add({
	-- 基础插件
	-- UI相关插件
	'https://github.com/olimorris/onedarkpro.nvim', -- 主题色
	-- 第三方工具嵌入插件
	"https://github.com/kdheepak/lazygit.nvim",
	-- 编辑器插件
	-- 娱乐插件
	"https://github.com/seandewar/actually-doom.nvim",
	-- 不同文件的独特插件
	'https://github.com/kaymmm/bullets.nvim',      -- markdown列表
})

require("dzmfg") -- 基础mini设置配置

