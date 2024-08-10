-- TODO 等待修改
local m = { noremap = true, nowait = true }
local config = {
	'nvim-telescope/telescope.nvim', tag = '0.1.8',
	-- or                              , branch = '0.1.x',
		  dependencies = { 'nvim-lua/plenary.nvim' }
}
return config