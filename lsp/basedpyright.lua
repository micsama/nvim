-- ===========================================================================
-- LSP: basedpyright
-- ===========================================================================

---@type vim.lsp.Config
return {
	cmd = { "basedpyright-langserver", "--stdio" },
	filetypes = { "python" },
	root_markers = {
		"pyrightconfig.json",
		"pyproject.toml",
		"setup.py",
		"setup.cfg",
		"requirements.txt",
		"Pipfile",
		".git",
	},

	settings = {
		basedpyright = {
			analysis = {
				typeCheckingMode = "basic", -- 开启基础类型检查（平衡准确性与干扰）
				autoSearchPaths = true, -- 自动搜索第三方库路径
				useLibraryCodeForTypes = true, -- 从库代码推断类型（在无 type hints 时很有用）
				diagnosticMode = "openFilesOnly", -- 仅分析已打开的文件，避免全量扫描消耗资源
				reportMissingTypeStubs = "none", -- 不报告缺失类型存根（减少无意义的波浪线）
			},
		},
	},

	on_attach = function(client, _)
		local caps = client.server_capabilities
		caps.completionProvider = nil -- 补全建议
		caps.definitionProvider = nil -- 跳转到定义 (Go to Definition)
		caps.declarationProvider = nil -- 跳转到声明 (Go to Declaration)
		caps.typeDefinitionProvider = nil -- 跳转到类型定义 (Go to Type Definition)
		caps.referencesProvider = nil -- 查找引用 (Find References)
		caps.renameProvider = nil -- 变量重命名 (Rename)
		caps.signatureHelpProvider = nil -- 函数签名提示（输入括号时的参数提醒）
		caps.codeActionProvider = nil -- 代码修复建议 (Code Actions)
		caps.executeCommandProvider = nil -- 执行特定的 LSP 命令
	end,
}
