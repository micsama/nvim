local now = MiniDeps.now
now(function()
	require('mini.completion').setup()
	local gen_loader = require('mini.snippets').gen_loader
	require('mini.snippets').setup({
		mappings = {
			jump_next = '<tab>',
			jump_prev = '<s-tab>',
		},
		snippets = {
			gen_loader.from_lang({
				lang_patterns = {
					markdown_inline = { 'markdown.json' },
				}
			}),
		}
	})
	MiniSnippets.start_lsp_server()
end)

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
