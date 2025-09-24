-- ~/.config/nvim/lua/plugins/lsp.lua or similar
---@brief
--- https://github.com/microsoft/pyright
--- `pyright`, a static type checker and language server for python

local function set_python_path(path)
	local clients = vim.lsp.get_clients({
		bufnr = vim.api.nvim_get_current_buf(),
		name = 'pyright',
	})
	for _, client in ipairs(clients) do
		if client.settings then
			client.settings.python = vim.tbl_deep_extend('force', client.settings.python, { pythonPath = path })
		else
			client.config.settings = vim.tbl_deep_extend('force', client.config.settings, { python = { pythonPath = path } })
		end
		client.notify('workspace/didChangeConfiguration', { settings = nil })
	end
end

return {
	cmd = { 'pyright-langserver', '--stdio' },
	filetypes = { 'python' },
	-- 自动识别项目根目录的标记文件
	root_markers = {
		'pyproject.toml',
		'setup.py',
		'setup.cfg',
		'requirements.txt',
		'Pipfile',
		'pyrightconfig.json',
		'.git',
		'main.py',
	},
	settings = {
		python = {
			analysis = {
				autoSearchPaths = true,
				useLibraryCodeForTypes = true,
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

		-- 新增命令: 使用当前目录下的虚拟环境
		vim.api.nvim_buf_create_user_command(bufnr, 'LspUseVenv', function()
			local root_dir = vim.fs.dirname(vim.fs.find({ '.git', 'pyproject.toml', '.venv' },
				{ upward = true, stop = vim.env.HOME })[1] or vim.fn.getcwd())
			if not root_dir then
				print('Could not find project root.')
				return
			end

			local venv_path = vim.fn.glob(root_dir .. '/.venv/bin/python')
			if venv_path == '' then
				print('Virtual environment .venv/bin/python not found.')
				return
			end

			-- 如果找到虚拟环境，则设置 Python 路径并重启 LSP
			set_python_path(venv_path)
			print('Pyright using virtual environment: ' .. venv_path)
		end, {
			desc = 'Use the virtual environment in the current directory',
		})
	end,
}
