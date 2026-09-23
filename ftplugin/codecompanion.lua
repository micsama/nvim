-- ===========================================================================
-- ftplugin: codecompanion
-- ===========================================================================

vim.cmd("runtime! ftplugin/markdown.lua")

-- # @ \ 随时触发补全；/ 只在行首触发（斜杠命令）
local triggers = { ["#"] = true, ["@"] = true, ["\\"] = true }
local buf = vim.api.nvim_get_current_buf()

vim.api.nvim_create_autocmd("InsertCharPre", {
	group = vim.api.nvim_create_augroup("CodeCompanionTrigger_" .. buf, { clear = true }),
	buffer = buf,
	callback = function()
		local char = vim.v.char
		if not (triggers[char] or char == "/") then
			return
		end
		-- 使用 schedule 确保字符先落盘（进入缓冲区），再触发补全
		vim.schedule(function()
			if char == "/" and vim.fn.col(".") > 2 then
				return
			end
			vim.api.nvim_feedkeys(vim.keycode("<C-x><C-o>"), "n", true)
		end)
	end,
})
