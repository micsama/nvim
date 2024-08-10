local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

local lazy_cmd = require("lazy.view.config").commands
local lazy_keys = {
    { cmd = "install", key = "i" },
    { cmd = "update",  key = "u" },
    { cmd = "sync",    key = "s" },
    { cmd = "clean",   key = "cl" },
    { cmd = "check",   key = "ch" },
    { cmd = "log",     key = "l" },
    { cmd = "restore", key = "rs" },
    { cmd = "profile", key = "p" },
    { cmd = "profile", key = "p" },
}
for _, v in ipairs(lazy_keys) do
    lazy_cmd[v.cmd].key = "<SPC>" .. v.key
    lazy_cmd[v.cmd].key_plugin = "<leader>" .. v.key
end

vim.keymap.set("n", "<leader>pl", ":Lazy<CR>", { noremap = true })

require("lazy").setup({
    require("config.plugins.telescope"),
    require("config.plugins.treesitter"),
    require("config.plugins.colorscheme"),
    require("config.plugins.joshuto"),
    -- 滚动条
    require("config.plugins.scrollbar"),
    require("config.plugins.snippets"),

    require("config.plugins.git"),

    require("config.plugins.winbar"),
    require("config.plugins.notify"),

    require("config.plugins.statusline"),
    require("config.plugins.editor"),

    require("config.plugins.comment"),
    require("config.plugins.project"),

    require("config.plugins.window-management"),
    require("config.plugins.yank"),

    require("config.plugins.tex"),
    { "dstein64/vim-startuptime" },

    -- 等待继续配置
    require("config.plugins.autocomplete").config,
    require("config.plugins.lspconfig").config,

    require("config.plugins.wilder"),
    require("config.plugins.indent"),


    require("config.plugins.search"),
    require("config.plugins.undo"),

    require("config.plugins.tabline"),
    require("config.plugins.surround"),
    require("config.plugins.copilot"),

    require("config.plugins.markdown"),
    require("config.plugins.fun"),
    require("config.plugins.debugger"),


})
