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
vim.keymap.set("i", "<C-9>", ctrlu, { silent = true })

return {
	{
		"RRethy/vim-illuminate",
		-- 设置为在进入插入模式或光标移动时加载
		event = { "InsertEnter", "CursorMoved" },
		config = function()
			require('illuminate').configure({
				providers = {
					-- 'lsp', -- 可根据需要启用
					'treesitter',
					'regex',
				},
				delay = 250, -- 延迟时间，单位为毫秒
			})

			-- 设置高亮样式
			vim.api.nvim_set_hl(0, "IlluminatedWordText", { bg = "#393E4D", underline = true })
		end,
	},
	{
		"dkarter/bullets.vim",
		lazy = false,
		ft = { "markdown", "txt" },
	},
	-- TODO:研究下面这个插件,平滑滚动
	-- {
	-- 	"karb94/neoscroll.nvim",
	-- 	config = function()
	-- 		require('neoscroll').setup({})
	-- 	end
	-- }
	-- {
	-- 	"psliwka/vim-smoothie",
	-- 	init = function()
	-- 		vim.cmd([[nnoremap <unique> <C-e> <cmd>call smoothie#do("\<C-D>") <CR>]])
	-- 		vim.cmd([[nnoremap <unique> <C-u> <cmd>call smoothie#do("\<C-U>") <CR>]])
	-- 	end
	-- },
	{
		"NvChad/nvim-colorizer.lua",
		opts = {
			filetypes = { "*" },
			user_default_options = {
				RGB = true,       -- #RGB hex codes
				RRGGBB = true,    -- #RRGGBB hex codes
				names = true,     -- "Name" codes like Blue or blue
				RRGGBBAA = false, -- #RRGGBBAA hex codes
				AARRGGBB = true,  -- 0xAARRGGBB hex codes
				rgb_fn = false,   -- CSS rgb() and rgba() functions
				hsl_fn = false,   -- CSS hsl() and hsla() functions
				css = false,      -- Enable all CSS features: rgb_fn, hsl_fn, names, RGB, RRGGBB
				css_fn = false,   -- Enable all CSS *functions*: rgb_fn, hsl_fn
				-- Available modes for `mode`: foreground, background,  virtualtext
				mode = "virtualtext", -- Set the display mode.
				-- Available methods are false / true / "normal" / "lsp" / "both"
				-- True is same as normal
				tailwind = true,
				sass = { enable = false },
				virtualtext = "■",
			},
			-- all the sub-options of filetypes apply to buftypes
			buftypes = {},
		}
	},
	{
		"fedepujol/move.nvim",
		config = function()
			require('move').setup({
				line = {
					enable = true,
					indent = true
				},
				block = {
					enable = true,
					indent = true
				},
				word = {
					enable = false,
				},
				char = {
					enable = false
				}
			})
			local opts = { noremap = true, silent = true }
			-- Normal-mode commands
			vim.keymap.set('n', '<c-s-j>', ':MoveLine(1)<CR>', opts)
			vim.keymap.set('n', '<c-j>', ':MoveLine(-1)<CR>', opts)

			-- Visual-mode commands
			vim.keymap.set('v', '<c-j>', ':MoveBlock(1)<CR>', opts)
			vim.keymap.set('v', '<c-s-j>', ':MoveBlock(-1)<CR>', opts)
		end
	},
	{
		-- TODO 不会用
		"gbprod/substitute.nvim",
		config = function()
			local substitute = require("substitute")
			substitute.setup({
				-- on_substitute = require("yanky.integration").substitute(),
				highlight_substituted_text = {
					enabled = true,
					timer = 200,
				},
			})
			vim.keymap.set("n", "s", substitute.operator, { noremap = true })
			vim.keymap.set("n", "sh", function() substitute.operator({ motion = "e" }) end, { noremap = true })
			vim.keymap.set("x", "s", require('substitute.range').visual, { noremap = true })
			vim.keymap.set("n", "ss", substitute.line, { noremap = true })
			vim.keymap.set("n", "sI", substitute.eol, { noremap = true })
			vim.keymap.set("x", "s", substitute.visual, { noremap = true })
		end
	},
	-- TODO: 继续研究
	{
		'kevinhwang91/nvim-ufo',
		dependencies = { 'kevinhwang91/promise-async' },
		-- 通过键绑定来实现懒加载
		keys = {
			{ 'zR', function() require('ufo').openAllFolds() end,  desc = 'Open all folds' },
			{ 'zM', function() require('ufo').closeAllFolds() end, desc = 'Close all folds' },
		},
		config = function()
			-- 设置折叠相关选项
			vim.o.foldcolumn = '1' -- 显示折叠列
			vim.o.foldlevel = 99 -- 高折叠层级，用于 ufo 提供者
			vim.o.foldlevelstart = 99
			vim.o.foldenable = true

			-- 使用 ufo 的默认设置，可以选择不同的提供者
			require('ufo').setup({
				provider_selector = function(bufnr, filetype, buftype)
					return { 'treesitter', 'indent' } -- 使用 treesitter 和 indent 作为默认提供者
				end,
			})
		end,
	},
	{
		"keaising/im-select.nvim",
		config = function()
			require("im_select").setup({})
		end,
	},
	{
		-- TODO 继续研究
		"windwp/nvim-autopairs",
		config = function()
			require("nvim-autopairs").setup({})
		end
	},
}
