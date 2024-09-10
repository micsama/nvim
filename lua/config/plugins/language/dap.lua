return {
	{
		'mfussenegger/nvim-dap',
		config = function()
			local dap = require('dap')
			dap.adapters.python = {
				type = 'executable',
				command = "python",
				args = { '-m'
				, 'debugpy. adapter' },
			}
		end
	}
}
