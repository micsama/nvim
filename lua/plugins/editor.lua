require('trouble').setup({})

-- 展示代码缩进
require('hlchunk').setup({
	line_num = {
		enable = true
	},
	chunk = {
		enable = true
	},
	indent = {
		enable = true
	}
})


-- FIX:
-- TODO:
-- HACK:
-- WARN:
-- PERF:
-- NOTE:
-- TEST:
require('todo-comments').setup(
	{
		keywords = {
			MODIFIED = {
				icon = ' ',
				color = 'hint',
				alt = { 'CHANGED', 'UPDATED', 'MOD' }
			},
		}
	})

vim.g.undotree_DiffAutoOpen = 1
vim.g.undotree_SetFocusWhenToggle = 1
vim.g.undotree_ShortIndicators = 1
vim.g.undotree_WindowLayout = 2
vim.g.undotree_DiffpanelHeight = 8
vim.g.undotree_SplitWidth = 24

vim.cmd([[
function! g:Undotree_CustomMap()
    nmap <buffer> k <plug>UndotreeNextState
    nmap <buffer> j <plug>UndotreePreviousState
    nmap <buffer> K 5<plug>UndotreeNextState
    nmap <buffer> J 5<plug>UndotreePreviousState
endfunction
]])

require('tiny-inline-diagnostic').setup()
vim.diagnostic.config({ virtual_text = false })

require('Bullets').setup({})

-- leader+y 可以搜索的 剪贴板历史记录
require('neoclip').setup({
	history = 1000,
	enable_persistent_history = true,
	keys = {
		telescope = {
			i = {
				select = '<c-y>',
				paste = '<cr>',
				paste_behind = '<c-g>',
				replay = '<c-q>', -- replay a macro
				delete = '<c-d>', -- delete an entry
				edit = '<c-k>', -- edit an entry
				custom = {},
			},
		},
	},
})
