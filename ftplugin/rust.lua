-- ===========================================================================
-- ftplugin: rust
-- ===========================================================================

local pairs = require("mini.pairs")
vim.lsp.inlay_hint.enable(true)

vim.lsp.codelens.enable(true, { bufnr = 0 })

-- 1. 泛型 <> 补全方案
-- 逻辑：仅在字母后敲击 < 才会自动补全 <>（如 Vec<T>）
-- 这样不会干扰普通的算术比较 1 < 2
pairs.map_buf(0, "i", "<", {
	action = "open",
	pair = "<>",
	neigh_pattern = "%a.",
})

pairs.map_buf(0, "i", ">", {
	action = "close",
	pair = "<>",
})
