local nv = { "n", "v" }
local it = { "i", "t" }
-- TODO: 重写 keymaps
local nmappings = {
	-- File operations
	{ "<D-s>",        "<CMD>up<CR>",                                            mode = nv }, -- Save file
	{ "<M-s>",        "<CMD>up<CR>",                                            mode = nv }, -- Save file (alternative)
	{ "<S>",          "<CMD>up<CR>",                                            mode = nv }, -- Save file (alternative)
	{ "<D-w>",        "<CMD>q<CR>",                                             mode = nv }, -- Close window

	-- Navigation & editing
	{ "J",            "5j",                                                     mode = nv }, -- Fast scroll down
	{ "K",            "5k",                                                     mode = nv }, -- Fast scroll up
	{ ";",            ":",                                                      mode = nv }, -- Quick command mode
	{ "`",            "~",                                                      mode = nv }, -- Toggle case

	-- Clipboard operations
	{ "Y",            "\"+y",                                                   mode = "v" },         -- Yank to system clipboard
	{ "<D-c>",        "\"+y",                                                   mode = "v" },         -- Copy to system clipboard
	{ "<D-v>",        "\"+P",                                                   mode = nv },          -- Paste from system clipboard
	{ "<D-v>",        "<C-R>+",                                                 mode = { "i", "c" } }, -- Paste in insert/command mode
	{ "<D-v>",        [[<C-\><C-N>"+pa]],                                       mode = "t" },         -- Paste in terminal mode

	-- Window management
	{ "<leader>w",    "<CMD>wincmd w<CR>" },         -- Focus next window
	{ "<leader>k",    "<C-w>k" },                    -- Move to window above
	{ "<leader>j",    "<C-w>j" },                    -- Move to window below
	{ "<leader>h",    "<C-w>h" },                    -- Move to left window
	{ "<leader>l",    "<C-w>l" },                    -- Move to right window
	{ "qf",           "<C-w>o" },                    -- Close other windows
	{ "<up>",         "<CMD>res +5<CR>" },           -- Increase window height
	{ "<down>",       "<CMD>res -5<CR>" },           -- Decrease window height
	{ "<left>",       "<CMD>vertical resize-5<CR>" }, -- Decrease window width
	{ "<right>",      "<CMD>vertical resize+5<CR>" }, -- Increase window width

	-- Split management
	{ "s",            "<nop>" },                                                  -- Disable default 's'
	{ "sk",           "<CMD>set nosplitbelow<CR>:split<CR>:set splitbelow<CR>" }, -- Split above
	{ "sj",           "<CMD>set splitbelow<CR>:split<CR>" },                      -- Split below
	{ "sh",           "<CMD>set nosplitright<CR>:vsplit<CR>:set splitright<CR>" }, -- Split left
	{ "sl",           "<CMD>set splitright<CR>:vsplit<CR>" },                     -- Split right
	{ "sh",           "<C-w>t<C-w>K" },                                           -- Horizontal split layout
	{ "sv",           "<C-w>t<C-w>H" },                                           -- Vertical split layout
	{ "srh",          "<C-w>b<C-w>K" },                                           -- Rotate splits horizontally
	{ "srv",          "<C-w>b<C-w>H" },                                           -- Rotate splits vertically

	-- Tab management
	{ "<D-t>",        "<CMD>tab new<CR>:Yazi<CR>",                              mode = nv }, -- New tab with file explorer
	{ "<D-j>",        "<CMD>-tabnext<CR>",                                      mode = nv }, -- Previous tab
	{ "<D-k>",        "<CMD>+tabnext<CR>",                                      mode = nv }, -- Next tab
	{ "<D-s-j>",      "<CMD>-tabmove<CR>" },                                                -- Move tab left
	{ "<D-s-k>",      "<CMD>+tabmove<CR>" },                                                -- Move tab right
	{ "<D-j>",        "<C-\\><C-n>:-tabnext<CR>",                               mode = it }, -- Previous tab (insert mode)
	{ "<D-k>",        "<C-\\><C-n>:+tabnext<CR>",                               mode = it }, -- Next tab (insert mode)
	{ "<D-t>",        "<C-\\><C-n>:tab new<CR>:Yazi<CR>",                       mode = it }, -- New tab (insert mode)

	-- Miscellaneous
	{ "<M-z>",        "<CMD>set wrap!<CR>",                                     mode = nv }, -- Toggle line wrap
	{ "<D-left>",     "<C-o>0",                                                 mode = it }, -- Move to line start (insert mode)
	{ "<D-right>",    "<C-o>$",                                                 mode = it }, -- Move to line end (insert mode)
	{ "<leader><CR>", "<CMD>nohlsearch<CR>" },                                              -- Clear search highlights
	{ "<leader>rc",   "<CMD>edit ~/.config/nvim/init.lua<CR>:chdir ./<CR>" },               -- Open Neovim config

	{ "<D-g>",        ":ToggleTerm dir=git_dir<CR>",                            mode = nv,                          desc = "Toggle terminal" },
	{ "<D-g>",        "<C-\\><C-n>:ToggleTerm dir=git_dir<CR>",                 mode = it,                          desc = "Toggle terminal" },
	{ '<leader>h',    function() vim.lsp.buf.hover() end,                       desc = "LSP Hover" },
	{ 'gd',           function() vim.lsp.buf.definition() end,                  desc = "Go to Definition" },
	{ 'gD',           '<cmd>tab split | lua vim.lsp.buf.definition()<CR>',      desc = "Open Definition in New Tab" },
	{ 'gi',           function() vim.lsp.buf.implementation() end,              desc = "Go to Implementation" },
	{ 'go',           function() vim.lsp.buf.type_definition() end,             desc = "Go to Type Definition" },
	{ 'gr',           function() vim.lsp.buf.references() end,                  desc = "Go to References" },
	{ '<leader>rn',   function() vim.lsp.buf.rename() end,                      desc = "Rename Symbol" },
	{ '<leader>,',    function() vim.lsp.buf.code_action() end,                 desc = "Code Action" },
	{ '<leader>t',    '<cmd>Trouble<CR>',                                       desc = "Open Trouble" },
	{
		'<leader>-',
		function()
			vim.diagnostic.jump({
				count = -1,                       -- 指定跳转到上一个
				float = true,                     -- 显示浮动窗口
				pos = vim.api.nvim_win_get_cursor(0), -- 当前光标位置
			})
		end,
		desc = "Previous Diagnostic"
	},
	-- 跳转到下一个诊断信息
	{
		'<leader>=',
		function()
			vim.diagnostic.jump({
				count = 1,                        -- 指定跳转到下一个
				float = true,                     -- 显示浮动窗口
				pos = vim.api.nvim_win_get_cursor(0), -- 当前光标位置
			})
		end,
		desc = "Next Diagnostic"
	},
	-- Insert mode keymap
	{ '<c-f>', function() vim.lsp.buf.signature_help() end, mode = 'i', desc = "Signature Help" },
	{ 'U',     ':UndotreeToggle<CR>',                        mode = nv },
	{ "<leader>y", "<CMD>lua require('telescope').extensions.neoclip.default()<CR>",mode = nv , desc = "Open neoclip" },
	{ "<D-b>", "<CMD>Neotree toggle reveal=true source=filesystem dir=./<CR>" },
	{ "<D-y>", "<cmd>Yazi<cr>", desc = "Open yazi at the current file", },
	{
		"<leader>?",
		function()
			require("which-key").show({ global = false })
		end,
		desc = "Buffer Local Keymaps (which-key)",
	},
}


-- Apply all mappings
for _, mapping in ipairs(nmappings) do
	vim.keymap.set(mapping.mode or "n", mapping[1], mapping[2], { noremap = true })
end

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
