require("config.defaults")
require("config.plugins")
require("config.keymaps")
if vim.g.neovide then
	require("config.neovide")
end
