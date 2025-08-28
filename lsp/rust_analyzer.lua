return {
	cmd = { 'rust-analyzer' },
	filetypes = { 'rust' },

	on_attach = function(client, bufnr)
		-- 启用 inlay hints
		if client.server_capabilities.inlayHintProvider then
			vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
		end
		if client.supports_method("textDocument/inlayHint", { bufnr = bufnr }) then
			vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
		end

		-- 设置诊断配置
		vim.diagnostic.config({
			severity_sort = true,
			underline = true,
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = '✘',
					[vim.diagnostic.severity.WARN] = '▲',
					[vim.diagnostic.severity.HINT] = '⚑',
					[vim.diagnostic.severity.INFO] = '»',
				},
				linehl = {
					[vim.diagnostic.severity.ERROR] = 'ErrorMsg',
				},
				numhl = {
					[vim.diagnostic.severity.WARN] = 'WarningMsg',
				},
			},
			virtual_text = false,
			update_in_insert = false,
			float = true,
		})

	end,
	settings = {
		["rust-analyzer"] = {
			completion = { autoimport = { enable = false } },
			inlayHints = { typeHints = true },
			cargo = { allFeatures = true },
			checkOnSave = true,
			hover = {
				actions = {
					run = { enable = true },
					enable = true,
				}
			},
		}
	},
}
