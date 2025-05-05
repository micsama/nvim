return {
    cmd = { 'rust-analyzer' },
    filetypes = { 'rust' },
    settings = {
        ["rust-analyzer"] = {
            completion = { autoimport = { enable = false } },
            inlayHints = { typeHints = true },
            cargo = { allFeatures = true },
            checkOnSave = { command = "clippy" },
            hover = {
                actions = {
                    run = { enable = true },
                    enable = true,
                }
            },
        }
    },
}
