return {
	"tomtom/tcomment_vim",
	event = "BufRead",
	config = function()
		vim.g.tcomment_maps = true
		vim.g.tcomment_textobject_inlinecomment = ''
	end
}