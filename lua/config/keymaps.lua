vim.g.mapleader = " "

local mode_nv = { "n", "v" }
local mode_v = { "v" }
local mode_i = { "i" }

local nmappings = {
	-- quick save and quit
	{ from = "S",            to = ":w<CR>",                                              mode = mode_nv },
	{ from = "Q",            to = ":q<CR>",                                              mode = mode_nv },

	-- bind to quick scollor
	{ from = "J",            to = "5j",                                                  mode = mode_nv },
	{ from = "K",            to = "5k",                                                  mode = mode_nv },
	{ from = "Y",            to = "\"+y",                                                mode = mode_v },

	-- no shift ^_^
	{ from = ";",            to = ":",                                                   mode = mode_nv },
	{ from = "`",            to = "~",                                                   mode = mode_nv },

	-- plugins
	{ from = "R",            to = ":Joshuto<CR>",                                        mode = mode_nv },
	{ from = "<leader>o",    to = "za" },


	-- comment
	{ from = "<c-/>",        to = ":TComment<CR>",                                       mode = { "n", "v", "i" } },
	{ from = "<leader><CR>", to = ":nohlsearch<CR>",                                     mode = mode_nv },


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
	-- { from = "sh",           to = "se", },
	{ from = "<c-k>",        to = ":+tabnext<CR>", },
	{ from = "sh",           to = "<C-w>t<C-w>K", },
	{ from = "sv",           to = "<C-w>t<C-w>H", },
	{ from = "srh",          to = "<C-w>b<C-w>K", },
	{ from = "srv",          to = "<C-w>b<C-w>H", },

	-- Tab management
	-- { from = "<c-t>",        to = ":tabe<CR>", },
	{ from = "<c-T>",        to = ":tab split<CR>", },
	{ from = "<c-j>",        to = ":-tabnext<CR>", },
	{ from = "<c-h>",        to = ":-tabmove<CR>", },
	-- { from = "<c-l>",        to = ":+tabmove<CR>", },






}


vim.keymap.set("n", "q", "<nop>", { noremap = true })
vim.keymap.set("n", ",q", "q", { noremap = true })

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
