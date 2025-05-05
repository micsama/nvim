return {
    cmd = { 'ruff', 'server' },
    filetypes = { 'python' },
    root_markers = { 'pyproject.toml', 'ruff.toml', '.ruff.toml', '.git' },
	settings = {
		logLevel = 'debug',
		configuration = "~/.config/nvim/ruff.toml",
		configurationPreference = "filesystemFirst",
		lineLength = 100,
		fixAll = true,
		organizeImports = true,
		showSyntaxErrors = true,
	},
  }