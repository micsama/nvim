-- Helper function for transparency formatting
-- local alpha = function()
-- 	return string.format("%x", math.floor(255 * vim.g.transparency or 0.8))
-- end
-- -- g:neovide_transparency should be 0 if you want to unify transparency of content and title bar.
-- vim.g.neovide_transparency = 0.0
-- vim.g.transparency = 0.8
-- vim.g.neovide_background_color = "#0f1117" .. alpha()

-- 字体
-- vim.o.guifont = "FiraCode Nerd Font:h15"
vim.o.guifont = "FantasqueSansM Nerd Font Propo,FiraCode Nerd Font,PingFang SC:h18"
vim.opt.linespace = 0

-- 窗口模糊
vim.g.neovide_window_blurred = true
vim.g.neovide_floating_blur_amount_x = 2.0
vim.g.neovide_floating_blur_amount_y = 2.0


-- 窗口阴影
-- vim.g.neovide_floating_shadow = true
-- vim.g.neovide_floating_z_height = 10
-- vim.g.neovide_light_angle_degrees = 45
-- vim.g.neovide_light_radius = 5
-- vim.g.neovide_profiler = true
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

-- 自动隐藏鼠标
vim.g.neovide_hide_mouse_when_typing = true

-- 触摸板死区
vim.g.neovide_touch_deadzone = 8.0



-- 其他画面设置
vim.g.neovide_underline_stroke_scale = 1.0

-- 刷新率 有vsync所以不需要
-- vim.g.neovide_refresh_rate = 60
-- vim.g.neovide_refresh_rate_idle = 5
-- 复制粘贴
vim.keymap.set('v', '<D-c>', '"+y')              -- Copy
vim.keymap.set('n', '<D-v>', '"+P')              -- Paste normal mode
vim.keymap.set('v', '<D-v>', '"+P')              -- Paste visual mode
vim.keymap.set('c', '<D-v>', '<C-R>+')           -- Paste command mode
vim.keymap.set('i', '<D-v>', '<C-R>+')           -- Paste insert mode
vim.keymap.set('t', '<D-v>', [[<C-\><C-N>"+pa]]) -- Paste insert mode

-- 绑定 D-1 到 D-9 用于切换到对应的标签页
for i = 1, 9 do
	vim.keymap.set("n", "<D-" .. i .. ">", function()
		local tab_count = vim.fn.tabpagenr('$') -- 获取当前标签页总数
		if i <= tab_count then
			vim.cmd("tabnext " .. i) -- 切换到第 i 个标签页
		else
			vim.notify("现在没有标签页: " .. i, vim.log.levels.WARN) -- 通知用户标签页不存在
		end
	end, { desc = "Switch to tab " .. i })
end




-- 动态窗口比例：
vim.g.neovide_scale_factor = 1.0
local change_scale_factor = function(delta)
	vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * delta
end
vim.keymap.set("n", "<D-=>", function()
	change_scale_factor(1.1)
end)
vim.keymap.set("n", "<D-->", function()
	change_scale_factor(1 / 1.1)
end)



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
