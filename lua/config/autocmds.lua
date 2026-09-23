-- ===========================================================================
-- 自动命令 (AuCommands)
-- ===========================================================================

-- 创建 AutoCommand Group 并清除之前的命令
vim.api.nvim_create_augroup("CustomSetupGroup", { clear = true })
local custom_group = "CustomSetupGroup"

-- 自动切换工作目录到项目根目录
-- 优先找 .git（worktree/submodule 里 .git 是文件，同样命中），回退到其他项目标记；结果按 buffer 缓存
vim.api.nvim_create_autocmd("BufEnter", {
	group = custom_group,
	callback = function(ctx)
		local name = vim.api.nvim_buf_get_name(ctx.buf)
		if vim.bo[ctx.buf].buftype ~= "" or name == "" then
			return
		end

		-- 缓存：每个 buffer 只计算一次
		local root = vim.b[ctx.buf].project_root
		if root == nil then
			local root_markers = { "pyproject.toml", ".luarc.json", "Makefile", "Cargo.toml", "package.json", "go.mod" }
			root = vim.fs.root(ctx.buf, ".git") or vim.fs.root(ctx.buf, root_markers) or false
			vim.b[ctx.buf].project_root = root
		end

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
	callback = function()
		vim.wo.wrap = true
		vim.cmd.startinsert()
	end,
	desc = "Terminal: wrap long lines and enter insert mode",
})

-- 配置修改后重启 Neovim，避免 source 与 require 缓存造成部分重载。

vim.filetype.add({
	extension = {
		log = "log",
	},
})
