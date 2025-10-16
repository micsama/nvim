---@brief Pyright LSP 配置
---
--- https://github.com/microsoft/pyright
---
--- `pyright`, a static type checker and language server for python
local function set_python_path(command)
	local user_path_valid = command.args and string.len(command.args) > 0
	local path = user_path_valid and command.args or "./.venv/bin/python"
	local clients = vim.lsp.get_clients {
		bufnr = vim.api.nvim_get_current_buf(),
		name = 'pyright',
	}
	for _, client in ipairs(clients) do
		if client.settings then
			client.settings.python = vim.tbl_deep_extend('force', client.settings.python, { pythonPath = path })
		else
			client.config.settings = vim.tbl_deep_extend('force', client.config.settings, { python = { pythonPath = path } })
		end
		client:notify('workspace/didChangeConfiguration', { settings = nil })
	end
	vim.notify('Pyright pythonPath set to: ' .. path, vim.log.levels.INFO, { title = 'Pyright Config' })
end

---@type vim.lsp.Config
return {
	cmd = { 'pyright-langserver', '--stdio' },
	filetypes = { 'python' },
	root_markers = {
		'pyproject.toml',
		'setup.py',
		'setup.cfg',
		'requirements.txt',
		'Pipfile',
		'pyrightconfig.json',
		'.git',
	},
	settings = {
		python = {
			analysis = {
				typeCheckingMode = "off",
				autoSearchPaths = true,
				diagnosticMode = 'openFilesOnly',
			},
		},
	},
	on_attach = function(client, bufnr)
		vim.api.nvim_buf_create_user_command(bufnr, 'LspPyrightOrganizeImports', function()
			local params = {
				command = 'pyright.organizeimports',
				arguments = { vim.uri_from_bufnr(bufnr) },
			}
			client.request('workspace/executeCommand', params, nil, bufnr)
		end, {
			desc = 'Organize Imports',
		})
		vim.api.nvim_buf_create_user_command(bufnr, 'LspPyrightSetPythonPath', set_python_path, {
			desc = 'Reconfigure pyright with the provided python path (default: .venv/bin/python)',
			nargs = '?',
			complete = 'file',
		})
	end,
}
