local mode_nv = { "n", "v" }
local mode_it = { "i", "t" }
local nmappings = {
	-- quick save and quit
	{ from = "<D-s>",        to = "<CMD>up<CR>",                                             mode = mode_nv },
	{ from = "<M-s>",        to = "<CMD>up<CR>",                                             mode = mode_nv },
	{ from = "<S>",          to = "<CMD>up<CR>",                                             mode = mode_nv },
	{ from = "<D-w>",        to = "<CMD>q<CR>",                                              mode = mode_nv },

	-- bind to quick scollor and copy2system clipboard
	{ from = "J",            to = "5j",                                                      mode = mode_nv },
	{ from = "K",            to = "5k",                                                      mode = mode_nv },
	{ from = "Y",            to = "\"+y",                                                    mode = "v" },
	{ from = "<D-c>",        to = "\"+y",                                                    mode = "v" },
	{ from = "<D-v>",        to = "\"+P",                                                    mode = mode_nv },
	{ from = "<D-v>",        to = "<C-R>+",                                                  mode = { "i", "c" } },
	{ from = "<D-v>",        to = [[<C-\><C-N>"+pa]],                                        mode = "t" },

	-- no shift ^_^
	{ from = ";",            to = ":",                                                       mode = mode_nv },
	{ from = "`",            to = "~",                                                       mode = mode_nv },

	-- 设置自动换行
	{ from = "<M-z>",        to = "<CMD>set wrap!<CR>",                                      mode = mode_nv },

	-- 设置插入模式下的cmd+方向键
	{ from = "<D-left>",     to = "<C-o>0",                                                  mode = mode_it },
	{ from = "<D-right>",    to = "<C-o>$",                                                  mode = mode_it },
	{ from = "<D-left>",     to = "<C-o>0",                                                  mode = mode_it },
	{ from = "<D-left>",     to = "<C-o>0",                                                  mode = mode_it },



	-- file manager & tab manager
	{ from = "<D-t>",        to = "<CMD>tab new<CR>:Yazi<CR>",                               mode = mode_nv },
	{ from = "<D-j>",        to = "<CMD>-tabnext<CR>",                                       mode = mode_nv },
	{ from = "<D-k>",        to = "<CMD>+tabnext<CR>",                                       mode = mode_nv },
	{ from = "<D-s-j>",      to = "<CMD>-tabmove<CR>", },
	{ from = "<D-s-k>",      to = "<CMD>+tabmove<CR>", },
	{ from = "<D-j>",        to = "<C-\\><C-n>:-tabnext<CR>",                                mode = mode_it },
	{ from = "<D-k>",        to = "<C-\\><C-n>:+tabnext<CR>",                                mode = mode_it },
	{ from = "<D-t>",        to = "<C-\\><C-n>:tab new<CR>:Yazi<CR>",                        mode = mode_it },

	-- no_highlight search
	{ from = "<leader><CR>", to = "<CMD>nohlsearch<CR>", },

	-- quick open nvim config
	{ from = "<leader>rc",   to = "<CMD>edit ~/.config/nvim/init.lua<CR>:chdir ./<CR>", },

	-- Window & splits
	{ from = "<leader>w",    to = "<CMD>wincmd w<CR>", },
	{ from = "<leader>k",    to = "<C-w>k", },
	{ from = "<leader>j",    to = "<C-w>j", },
	{ from = "<leader>h",    to = "<C-w>h", },
	{ from = "<leader>l",    to = "<C-w>l", },
	{ from = "qf",           to = "<C-w>o", },
	{ from = "s",            to = "<nop>", },
	{ from = "sk",           to = "<CMD>set nosplitbelow<CR>:split<CR>:set splitbelow<CR>", },
	{ from = "sj",           to = "<CMD>set splitbelow<CR>:split<CR>", },
	{ from = "sh",           to = "<CMD>set nosplitright<CR>:vsplit<CR>:set splitright<CR>", },
	{ from = "sl",           to = "<CMD>set splitright<CR>:vsplit<CR>", },
	{ from = "<up>",         to = "<CMD>res +5<CR>", },
	{ from = "<down>",       to = "<CMD>res -5<CR>", },
	{ from = "<left>",       to = "<CMD>vertical resize-5<CR>", },
	{ from = "<right>",      to = "<CMD>vertical resize+5<CR>", },
	{ from = "sh",           to = "<C-w>t<C-w>K", },
	{ from = "sv",           to = "<C-w>t<C-w>H", },
	{ from = "srh",          to = "<C-w>b<C-w>K", },
	{ from = "srv",          to = "<C-w>b<C-w>H", },
}

for i = 1, 9 do
	vim.keymap.set("n", "<D-" .. i .. ">", function()
		local tab_count = vim.fn.tabpagenr('$') -- 获取当前标签页总数
		if i <= tab_count then
			vim.cmd("tabnext " .. i) -- 切换到第 i 个标签页
		else
			vim.notify("现在没有标签页: " .. i, vim.log.levels.WARN) -- 通知用户标签页不存在
		end
	end, { desc = "Switch to tab " .. i })
end

vim.keymap.del('n', 'grr')
vim.keymap.del('x', 'gra')
vim.keymap.del('n', 'gra')
vim.keymap.del('n', 'grn')
vim.keymap.set("n", "q", "<nop>", { noremap = true })
vim.keymap.set("n", ",q", "q", { noremap = true })

-- 终端模式下启用esc
-- vim.api.nvim_set_keymap('t', '<Esc><ESC>', [[<C-\><C-n>]], { noremap = true, silent = true })


for _, mapping in ipairs(nmappings) do
	vim.keymap.set(mapping.mode or "n", mapping.from, mapping.to, { noremap = true })
end



local function run_vim_shortcut(shortcut)
	local escaped_shortcut = vim.api.nvim_replace_termcodes(shortcut, true, false, true)
	vim.api.nvim_feedkeys(escaped_shortcut, 'n', true)
end


-- close win below
vim.keymap.set("n", "<leader>q", function()
	-- Safely require "trouble" and call close if it's loaded
	local trouble_exists, trouble = pcall(require, "trouble")
	if trouble_exists then
		trouble.close()
	end

	-- Check the number of windows and execute shortcut if there are more than one
	local wins = vim.api.nvim_tabpage_list_wins(0)
	if #wins > 1 then
		run_vim_shortcut([[<C-w>j:q<CR>]])
	end
end, { noremap = true, silent = true })
