-- ===============================
-- Neovide GUI 客户端设置
-- ===============================

-- 基础 UI / 字体配置
local IS_MACOS = vim.uv.os_uname().sysname == "Darwin"

if IS_MACOS then
	vim.o.guifont = "FantasqueSansM Nerd Font,FiraCode Nerd Font,PingFang SC:h15.5" -- 设置 Neovide 字体及大小
else
	vim.o.guifont = "Microsoft YaHei:h14.5" -- 设置 Neovide 字体及大小
	vim.g.neovide_title_background_color =
		string.format("%x", vim.api.nvim_get_hl(0, { id = vim.api.nvim_get_hl_id_by_name("Normal") }).bg)

	vim.g.neovide_title_text_color = "pink"
end


vim.opt.linespace = 0 -- 消除行间距，使行高更紧凑

-- 窗口效果与行为
vim.g.neovide_window_blurred = true -- 启用窗口模糊效果
vim.g.neovide_floating_blur_amount_x = 1.5 -- 浮动窗口 X 轴模糊量
vim.g.neovide_floating_blur_amount_y = 1.5 -- 浮动窗口 Y 轴模糊量

vim.g.neovide_opacity = 0.86
vim.g.neovide_normal_opacity = 0.83

vim.g.neovide_confirm_quit = true -- 退出时要求确认
-- vim.g.neovide_cursor_animate_command_line = false
-- 输入、鼠标与触控板
vim.g.neovide_has_mouse_grid_detection = true
vim.g.neovide_input_macos_option_key_is_meta = "only_left" -- 仅将左 Option 键映射为 Meta
vim.g.neovide_hide_mouse_when_typing = false -- 打字时自动隐藏鼠标
vim.g.neovide_touch_deadzone = 8.0 -- 设置触摸板死区，防止意外滚动

-- 动画与光标视觉特效 (VFX)
vim.g.neovide_scroll_animation_length = 0.3 -- 滚动动画时长 (秒)
vim.g.neovide_position_animation_length = 0.18 -- 光标位置移动动画时长
vim.g.neovide_cursor_animation_length = 0.07 -- 光标闪烁动画时长
vim.g.neovide_cursor_vfx_mode = "pixiedust" -- 光标视觉特效模式
vim.g.neovide_cursor_animate_in_insert_mode = true -- 插入模式下也启用光标动画
vim.g.neovide_scroll_animation_far_lines = 1 -- 启用快速滚动时的平滑动画
vim.g.neovide_cursor_vfx_particle_density = 15.0 -- 光标特效粒子密度
vim.g.neovide_underline_stroke_scale = 1.0 -- 下划线笔触缩放比例

-- 动态缩放功能与快捷键
vim.g.neovide_scale_factor = 1.0 -- 默认缩放因子
local function scale(delta)
	vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * delta
end
vim.keymap.set("n", "<D-=>", function()
	scale(1.1)
end, { desc = "放大 Neovide 字体/UI" })
vim.keymap.set("n", "<D-->", function()
	scale(1 / 1.1)
end, { desc = "缩小 Neovide 字体/UI" })

local function set_ime(args)
	if args.event:match("Enter$") then
		vim.g.neovide_input_ime = true
	else
		vim.g.neovide_input_ime = false
	end
end

local ime_input = vim.api.nvim_create_augroup("ime_input", { clear = true })

vim.api.nvim_create_autocmd({ "InsertEnter", "InsertLeave" }, {
	group = ime_input,
	pattern = "*",
	callback = set_ime,
})

vim.api.nvim_create_autocmd({ "CmdlineEnter", "CmdlineLeave" }, {
	group = ime_input,
	pattern = "[/\\?]",
	callback = set_ime,
})

-- ✅ 终端模式
vim.api.nvim_create_autocmd({ "TermEnter", "TermLeave" }, {
	group = ime_input,
	pattern = "*",
	callback = set_ime,
})
