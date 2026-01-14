-- ===========================================================================
-- 自动命令 (AuCommands)
-- ===========================================================================

-- 创建 AutoCommand Group 并清除之前的命令
vim.api.nvim_create_augroup("CustomSetupGroup", { clear = true })
local custom_group = "CustomSetupGroup"

-- 自动切换工作目录到项目根目录 (使用 vim.fs.root 现代 API)
vim.api.nvim_create_autocmd("BufEnter", {
	group = custom_group,
	callback = function(ctx)
		-- 定义寻找项目根目录的标识文件/目录
		local root_markers =
			{ "pyproject.toml", ".luarc.json", ".git", "Makefile", ".venv", "Cargo.toml", "package.json", "go.mod" }
		local root = vim.fs.root(ctx.buf, root_markers)
		-- 如果找到根目录，且它不是当前目录，则切换当前窗口的目录
		if root and root ~= "." and root ~= vim.fn.getcwd() then
			vim.cmd.tcd(root)
			vim.notify(root, nil, { title = "Workspace ->", icon = "󱉭" })
		end
	end,
	desc = "Auto change working directory to project root",
})

-- 恢复上次打开文件时的光标位置
vim.api.nvim_create_autocmd("BufReadPost", {
	group = custom_group,
	pattern = "*",
	callback = function()
		-- 检查上次光标位置是否有效（行号大于1且小于文件总行数）
		if vim.fn.line("'\"") > 1 and vim.fn.line("'\"") <= vim.fn.line("$") then
			-- 跳转到上次光标位置 (''')
			vim.cmd.normal({ 'g`"', bang = true })
		end
	end,
	desc = "Restore cursor position when reopening files",
})

-- 终端打开时自动进入插入模式
vim.api.nvim_create_autocmd("TermOpen", {
	group = custom_group,
	pattern = "term://*",
	command = "startinsert",
	desc = "Automatically enter insert mode when opening terminal",
})

-- 自动重新加载配置文件
vim.api.nvim_create_augroup("NVIMRC", { clear = true })

vim.api.nvim_create_autocmd("BufWritePost", {
	pattern = "init.lua,*/base.lua", -- 匹配 init.lua 或当前的 base.lua
	group = "NVIMRC",
	command = "source %",
	desc = "Auto reload config file when modified",
})
