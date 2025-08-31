-- Configuration for the JSON language server in Neovim
-- Sets up the server with specified filetypes, initialization options, and root detection markers
return {
    cmd = { '/opt/homebrew/bin/vscode-json-languageserver', '--stdio' },
    filetypes = { 'json', 'jsonc' },
    init_options = {
      provideFormatter = true,
    },
    root_markers = { '.git' },
  }
