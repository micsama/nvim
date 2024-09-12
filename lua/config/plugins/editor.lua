-- Neovim 插件配置文件

-- 自定义函数与按键映射
vim.cmd([[
fun! s:MakePair()
    let line = getline('.')
    let len = strlen(line)
    if line[len - 1] == ";" || line[len - 1] == ","
        normal! lx$P
    else
        normal! lx$p
    endif
endfun
inoremap <c-u> <ESC>:call <SID>MakePair()<CR>
]])
local ctrlu = require("plugin.ctrlu").ctrlu

-- 插件配置
return {
	-- 高亮当前光标下的词
	{
		"RRethy/vim-illuminate",
		event = { "InsertEnter", "CursorMoved" }, -- 插入模式进入或光标移动时加载
		config = function()
			require('illuminate').configure({
				providers = { 'treesitter', 'regex' }, -- 可以根据需要启用 LSP
				delay = 250,
			})
			vim.api.nvim_set_hl(0, "IlluminatedWordText", { bg = "#393E4D", underline = true })
		end,
	},

	-- Markdown 和 txt 文件的项目符号插件
	{
		"dkarter/bullets.vim",
		ft = { "markdown", "txt" }, -- 文件类型匹配时加载
	},

	-- 颜色显示插件
	{
		"NvChad/nvim-colorizer.lua",
		event = "BufReadPost", -- 打开文件后加载
		opts = {
			filetypes = { "*" },
			user_default_options = {
				RGB = true,
				RRGGBB = true,
				names = true,
				RRGGBBAA = false,
				AARRGGBB = true,
				rgb_fn = false,
				hsl_fn = false,
				css = false,
				css_fn = false,
				mode = "virtualtext",
				tailwind = true,
				sass = { enable = false },
				virtualtext = "■",
			},
			buftypes = {},
		}
	},

	-- 移动文本插件
	{
		"fedepujol/move.nvim",
		keys = { -- 设置快捷键以实现懒加载
			{ "<C-s-j>", ":MoveLine(1)<CR>",   mode = "n", desc = "Move line down" },
			{ "<C-j>",   ":MoveLine(-1)<CR>",  mode = "n", desc = "Move line up" },
			{ "<C-j>",   ":MoveBlock(1)<CR>",  mode = "v", desc = "Move block down" },
			{ "<C-s-j>", ":MoveBlock(-1)<CR>", mode = "v", desc = "Move block up" },
		},
		config = function()
			require('move').setup({
				line = { enable = true, indent = true },
				block = { enable = true, indent = true },
				word = { enable = false },
				char = { enable = false },
			})
		end
	},

	-- -- 替换插件
	-- {
	-- 	"gbprod/substitute.nvim",
	-- 	keys = { -- 配置按键映射进行懒加载
	-- 		{ "n", "s",  function() require('substitute').operator() end,                 desc = "Substitute operator" },
	-- 		{ "n", "sh", function() require('substitute').operator({ motion = "e" }) end, desc = "Substitute till end" },
	-- 		{ "x", "s",  function() require('substitute.range').visual() end,             desc = "Substitute in visual mode" },
	-- 		{ "n", "ss", function() require('substitute').line() end,                     desc = "Substitute line" },
	-- 		{ "n", "sI", function() require('substitute').eol() end,                      desc = "Substitute to end of line" },
	-- 	},
	-- 	config = function()
	-- 		require("substitute").setup({
	-- 			highlight_substituted_text = { enabled = true, timer = 200 },
	-- 		})
	-- 	end
	-- },
	--
	-- -- 折叠插件
	-- {
	-- 	'kevinhwang91/nvim-ufo',
	-- 	dependencies = { 'kevinhwang91/promise-async' },
	-- 	keys = {
	-- 		{ 'zR', function() require('ufo').openAllFolds() end,  desc = 'Open all folds' },
	-- 		{ 'zM', function() require('ufo').closeAllFolds() end, desc = 'Close all folds' },
	-- 	},
	-- 	config = function()
	-- 		vim.o.foldcolumn = '1'
	-- 		vim.o.foldlevel = 99
	-- 		vim.o.foldlevelstart = 99
	-- 		vim.o.foldenable = true
	-- 		require('ufo').setup({
	-- 			provider_selector = function(bufnr, filetype, buftype)
	-- 				return { 'treesitter', 'indent' }
	-- 			end,
	-- 		})
	-- 	end,
	-- },

	-- 输入法切换插件
	{
		"keaising/im-select.nvim",
		event = "InsertEnter", -- 进入插入模式时加载
		config = function()
			require("im_select").setup({})
		end,
	},

	-- 自动括号补全插件
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter", -- 插入模式进入时加载
		config = function()
			require("nvim-autopairs").setup({})
		end
	},
}
