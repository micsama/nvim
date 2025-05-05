vim.o.guifont = "FantasqueSansM Nerd Font Propo,FiraCode Nerd Font,PingFang SC:h17.5"
vim.opt.linespace = 0

-- 窗口模糊
vim.g.neovide_window_blurred = true
vim.g.neovide_floating_blur_amount_x = 2.0
vim.g.neovide_floating_blur_amount_y = 2.0

-- 窗口阴影
vim.g.neovide_confirm_quit = true

-- 输入的option键绑定
vim.g.neovide_input_macos_option_key_is_meta = 'only_left'

-- 动画
vim.g.neovide_scroll_animation_length = 0.3
vim.g.neovide_position_animation_length = 0.15
vim.g.neovide_cursor_animation_length = 0.07
vim.g.neovide_cursor_vfx_mode = "pixiedust"

vim.g.neovide_cursor_animate_in_insert_mode = true
vim.g.neovide_scroll_animation_far_lines = 1
vim.g.neovide_cursor_vfx_particle_density = 10.0

-- 自动隐藏鼠标
vim.g.neovide_hide_mouse_when_typing = false

-- 触摸板死区
vim.g.neovide_touch_deadzone = 8.0



-- 其他画面设置
vim.g.neovide_underline_stroke_scale = 1.0

-- 刷新率 有vsync所以不需要
-- vim.g.neovide_refresh_rate = 60
-- vim.g.neovide_refresh_rate_idle = 5

-- 绑定 D-1 到 D-9 用于切换到对应的标签页




-- 动态窗口比例设置
vim.g.neovide_scale_factor = 1.0

-- 调整缩放因子
local function scale(delta)
    vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * delta
end

-- 快捷键映射
vim.keymap.set("n", "<D-=>", function() scale(1.1) end)
vim.keymap.set("n", "<D-->", function() scale(1 / 1.1) end)




--  TODO: 后续看看需不需要替代im-select

-- local function set_ime(args)
--     if args.event:match("Enter$") then
--         vim.g.neovide_input_ime = true
--     else
--         vim.g.neovide_input_ime = false
--     end
-- end
--
-- local ime_input = vim.api.nvim_create_augroup("ime_input", { clear = true })
--
-- vim.api.nvim_create_autocmd({ "InsertEnter", "InsertLeave" }, {
--     group = ime_input,
--     pattern = "*",
--     callback = set_ime
-- })
--
-- vim.api.nvim_create_autocmd({ "CmdlineEnter", "CmdlineLeave" }, {
--     group = ime_input,
--     pattern = "[/\\?]",
--     callback = set_ime
-- })
--
