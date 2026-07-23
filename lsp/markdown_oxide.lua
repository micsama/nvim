-- ===========================================================================
-- LSP: markdown_oxide
-- ===========================================================================

---@param client vim.lsp.Client
---@param bufnr integer
---@param cmd string
local function command_factory(client, bufnr, cmd)
	return client:exec_cmd({
		title = ("Markdown-Oxide-%s"):format(cmd),
		command = "jump",
		arguments = { cmd },
	}, { bufnr = bufnr })
end

-- markdown-oxide 上报的 workspace/fileOperations 过滤器里，`pattern.matches`/`scheme`
-- 字段常以 JSON null 形式出现，被 Neovim 解码成 vim.NIL（userdata）而非 Lua nil。
-- mini.files 的 lsp_fs_hook 直接假定这些字段是 nil 或 string，遇到 vim.NIL 会在
-- `scheme .. ':'` 处报 E5108（attempt to concatenate userdata）。上游拒绝在
-- mini.files 里做兼容处理，故在此处对 server_capabilities 做一次净化。
---@param client vim.lsp.Client
local function sanitize_file_operation_filters(client)
	local file_ops = ((client.server_capabilities or {}).workspace or {}).fileOperations
	if not file_ops then return end
	for _, op in pairs(file_ops) do
		for _, filter in ipairs(op.filters or {}) do
			if filter.scheme == vim.NIL then filter.scheme = nil end
			local pattern = filter.pattern
			if pattern then
				if pattern.matches == vim.NIL then pattern.matches = nil end
				if pattern.options == vim.NIL then pattern.options = nil end
			end
		end
	end
end

---@type vim.lsp.Config
return {
	root_markers = { ".git", ".obsidian", ".moxide.toml" },
	filetypes = { "markdown", "codecompanion" },
	cmd = { "markdown-oxide" },
	on_attach = function(client, bufnr)
		sanitize_file_operation_filters(client)
		for _, cmd in ipairs({ "today", "tomorrow", "yesterday" }) do
			vim.api.nvim_buf_create_user_command(
				bufnr,
				"Lsp" .. ("%s"):format(cmd:gsub("^%l", string.upper)),
				function()
					command_factory(client, bufnr, cmd)
				end,
				{
					desc = ("Open %s daily note"):format(cmd),
				}
			)
		end
	end,
}
