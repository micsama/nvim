-- ===========================================================================
-- ftplugin: codecompanion
-- ===========================================================================

require("render-markdown").setup({
	file_types = { "markdown", "codecompanion", "vimwiki" },
	completions = { lsp = { enabled = true } },
})

vim.api.nvim_create_autocmd("InsertCharPre", {
	buffer = 0, -- 仅对当前 CodeCompanion 缓冲区生效
	callback = function()
		-- 定义触发补全的关键符号
		local triggers = { ["#"] = true, ["@"] = true, ["\\"] = true }

		if triggers[vim.v.char] then
			-- 使用 schedule 确保字符先落盘（进入缓冲区），再触发补全
			vim.schedule(function()
				local keys = vim.api.nvim_replace_termcodes("<C-x><C-o>", true, true, true)
				vim.api.nvim_feedkeys(keys, "n", true)
			end)
		end
	end,
})

vim.api.nvim_create_autocmd("InsertCharPre", {
	buffer = 0,
	callback = function()
		if vim.v.char == "/" then
			vim.schedule(function()
				local col = vim.fn.col(".")
				if col <= 2 then
					local keys = vim.api.nvim_replace_termcodes("<C-x><C-o>", true, true, true)
					vim.api.nvim_feedkeys(keys, "n", true)
				end
			end)
		end
	end,
})
