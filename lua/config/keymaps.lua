local mode_nv = { "n", "v" }
local mode_v = { "v" }

local nmappings = {
	-- quick save and quit
	{ from = "<a-s>",        to = ":w<CR>",                                              mode = { "n", "i", "v" } },
	{ from = "<S>",          to = ":w<CR>",                                              mode = mode_nv },
	{ from = "<a-q>",        to = ":q<CR>",                                              mode = mode_nv },
	{ from = "<a-q>",        to = "<esc>:q<CR>",                                         mode = "i" },

	-- bind to quick scollor and copy2system clipboard
	{ from = "J",            to = "5j",                                                  mode = mode_nv },
	{ from = "K",            to = "5k",                                                  mode = mode_nv },
	{ from = "Y",            to = "\"+y",                                                mode = mode_v },

	-- no shift ^_^
	{ from = ";",            to = ":",                                                   mode = mode_nv },
	{ from = "`",            to = "~",                                                   mode = mode_nv },

	-- 设置自动换行
	{ from = "<a-z>",        to = ":set wrap!<CR>",                                      mode = mode_nv },



	{ from = "<leader>or",   to = ":OverseerRun<CR>" },
	{ from = "<leader>oo",   to = ":OverseerToggle<CR>" },
	{ from = "<c-k>",        to = ":ToggleTerm<CR>",                                     mode = { "n", "i" } },
	{ from = "<c-k>",        to = "<c-\\><c-n>:ToggleTerm<CR>",                          mode = { "t" } },


	-- file manager & tab manager
	{ from = "<a-t>",        to = ":tab new<CR>:Joshuto<CR>",                            mode = mode_nv },
	{ from = "<a-j>",        to = ":-tabnext<CR>", },
	{ from = "<a-k>",        to = ":+tabnext<CR>", },
	{ from = "<a-h>",        to = ":-tabmove<CR>", },
	{ from = "<a-l>",        to = ":+tabmove<CR>", },
	{ from = "<a-b>",        to = ":Neotree toggle<CR>", },

	-- no_highlight search
	{ from = "<leader><CR>", to = ":nohlsearch<CR>",                                     mode = mode_nv },

	-- quick open nvim config
	{ from = "<leader>rc",   to = ":edit ~/.config/nvim/init.lua<CR>:chdir ./<CR>",      mode = "n" },

	-- Window & splits
	{ from = "<leader>w",    to = "<C-w>w", },
	{ from = "<leader>k",    to = "<C-w>k", },
	{ from = "<leader>j",    to = "<C-w>j", },
	{ from = "<leader>h",    to = "<C-w>h", },
	{ from = "<leader>l",    to = "<C-w>l", },
	{ from = "qf",           to = "<C-w>o", },
	{ from = "s",            to = "<nop>", },
	{ from = "sj",           to = ":set nosplitbelow<CR>:split<CR>:set splitbelow<CR>", },
	{ from = "sk",           to = ":set splitbelow<CR>:split<CR>", },
	{ from = "sl",           to = ":set nosplitright<CR>:vsplit<CR>:set splitright<CR>", },
	{ from = "sh",           to = ":set splitright<CR>:vsplit<CR>", },
	{ from = "<up>",         to = ":res +5<CR>", },
	{ from = "<down>",       to = ":res -5<CR>", },
	{ from = "<left>",       to = ":vertical resize-5<CR>", },
	{ from = "<right>",      to = ":vertical resize+5<CR>", },
	{ from = "sh",           to = "<C-w>t<C-w>K", },
	{ from = "sv",           to = "<C-w>t<C-w>H", },
	{ from = "srh",          to = "<C-w>b<C-w>K", },
	{ from = "srv",          to = "<C-w>b<C-w>H", },
}


vim.keymap.set("n", "q", "<nop>", { noremap = true })
vim.keymap.set("n", ",q", "q", { noremap = true })

-- 终端模式下启用esc
vim.api.nvim_set_keymap('t', '<Esc><ESC>', [[<C-\><C-n>]], { noremap = true, silent = true })


for _, mapping in ipairs(nmappings) do
	vim.keymap.set(mapping.mode or "n", mapping.from, mapping.to, { noremap = true })
end



local function run_vim_shortcut(shortcut)
	local escaped_shortcut = vim.api.nvim_replace_termcodes(shortcut, true, false, true)
	vim.api.nvim_feedkeys(escaped_shortcut, 'n', true)
end


-- close win below
vim.keymap.set("n", "<leader>q", function()
	require("trouble").close()
	local wins = vim.api.nvim_tabpage_list_wins(0)
	if #wins > 1 then
		run_vim_shortcut([[<C-w>j:q<CR>]])
	end
end, { noremap = true, silent = true })
local builtin = require('telescope.builtin')
-- TODO
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
