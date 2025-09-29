vim.loader.enable()
-- 先加载不依赖插件的相关配置
require("config.defaults") -- 设置默认的一些配置
require("config.keymaps")  -- 设置快捷键
require("config.mini")     -- 配置mini.nvim

if vim.g.neovide then
	require("config.neovide")
end

vim.pack.add({

	-- 基础依赖插件
	'https://github.com/nvim-lua/plenary.nvim',
	'https://github.com/nvim-telescope/telescope-fzf-native.nvim',
	'https://github.com/kkharji/sqlite.lua',
	'https://github.com/MunifTanjim/nui.nvim',
	{ src = 'https://github.com/nvim-telescope/telescope.nvim',   branch = "0.1.x" },
	{ src = 'https://github.com/nvim-treesitter/nvim-treesitter', branch = "master", build = ":TSUpdate" },

	-- UI插件
	'https://github.com/akinsho/bufferline.nvim',
	'https://github.com/olimorris/onedarkpro.nvim', -- 主题色
	'https://github.com/nvim-lualine/lualine.nvim',
	'https://github.com/dstein64/nvim-scrollview',
	'https://github.com/Bekaboo/dropbar.nvim',
	'https://github.com/nvimdev/dashboard-nvim',
	'https://github.com/folke/which-key.nvim',

	-- 编辑器插件
	'https://github.com/nvim-treesitter/nvim-treesitter-context',
	'https://github.com/shellRaining/hlchunk.nvim',
	'https://github.com/folke/todo-comments.nvim',
	'https://github.com/mbbill/undotree',
	'https://github.com/rachartier/tiny-inline-diagnostic.nvim',
	'https://github.com/AckslD/nvim-neoclip.lua',

	'https://github.com/windwp/nvim-autopairs',
	'https://github.com/folke/trouble.nvim',
	'https://github.com/keaising/im-select.nvim',

	-- 文件管理相关
	'https://github.com/nvim-neo-tree/neo-tree.nvim',
	'https://github.com/mikavilpas/yazi.nvim',
	'https://github.com/pteroctopus/faster.nvim', --TODO: 在大文件中禁用部分功能，替代bigfile.nvim
	'https://github.com/natecraddock/workspaces.nvim',

	-- 第三方工具相关插件
	'https://github.com/akinsho/toggleterm.nvim',
	'https://github.com/kdheepak/lazygit.nvim',
	'https://github.com/lewis6991/gitsigns.nvim',
	'https://github.com/olimorris/codecompanion.nvim',

	-- Dap插件
	'https://github.com/nvim-telescope/telescope-dap.nvim',
	'https://github.com/nvim-neotest/nvim-nio',
	'https://github.com/mfussenegger/nvim-dap',
	'https://github.com/mfussenegger/nvim-dap-python',
	'https://github.com/jay-babu/mason-nvim-dap.nvim',
	'https://github.com/williamboman/mason.nvim',
	'https://github.com/theHamsta/nvim-dap-virtual-text',
	'https://github.com/rcarriga/nvim-dap-ui',

	-- 娱乐插件
	'https://github.com/seandewar/actually-doom.nvim',

	-- 不同文件的独特插件
	'https://github.com/kaymmm/bullets.nvim', -- markdown列表
	'https://github.com/MeanderingProgrammer/render-markdown.nvim',
	'https://github.com/folke/which-key.nvim',

})

require("dzmfg") -- 加载对应的插件配置
