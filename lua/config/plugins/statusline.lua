-- local current_signature = function()
-- 	if not pcall(require, 'lsp_signature') then return end
-- 	local sig = require("lsp_signature").status_line(50)
-- 	return sig.label .. "🐼" .. sig.hint
-- end

return {

	"nvim-lualine/lualine.nvim",
	dependencies = { 'nvim-tree/nvim-web-devicons' },
	lazy = false,
	config = function()
		require('lualine').setup {
			options = {
				icons_enabled = true,
				theme = 'autO',
				component_separators = { left = '', right = '' },
				section_separators = { left = '', right = '' },
				disabled_filetypes = {
					statusline = {},
					winbar = {},
				},
				ignore_focus = {},
				always_divide_middle = true,
				globalstatus = true,
				refresh = {
					statusline = 1000,
					tabline = 1000,
					winbar = 1000,
				}
			},
			sections = {
				lualine_a = { 'filename' },
				lualine_b = { 'branch', 'diff', 'diagnostics' },
				lualine_c = { 'overseer' },
				lualine_x = { {
					"swenv",
					cond = function()
						-- 检查文件类型是否为 Python 或 buf 类型是命令行
						local ft = vim.bo.filetype
						local buftype = vim.bo.buftype
						return ft == "python" or buftype == "terminal" or buftype == "prompt"
					end,
					icon=""
				} },
				lualine_y = { 'filesize', 'filetype' },
				lualine_z = { 'location' }
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { 'filename' },
				lualine_x = { 'location' },
				lualine_y = {},
				lualine_z = {}
			},
			tabline = {},
			winbar = {},
			inactive_winbar = {},
			extensions = {}
		}
	end
}
