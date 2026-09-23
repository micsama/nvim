-- =============================================================================
-- 呼吸边框（Claude busy 时，边框颜色随时间明暗律动）
-- 全局同一时刻只有一个浮窗在呼吸；窗口失效时自动停止。
-- =============================================================================
local M = {}
local options = require("config.floatty").pulse

local pulse = { timer = nil, win = nil, start_ns = nil }

local function hex_from_hl(name, field, fallback)
	local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
	if ok and hl and hl[field] then
		return hl[field]
	end
	return fallback
end

--- 优先用 Catppuccin 当前 flavour 的 peach，取不到再退回 WarningMsg 前景色
local function base_color()
	local ok, palettes = pcall(require, "catppuccin.palettes")
	if ok then
		local p = palettes.get_palette()
		if p and p.peach then
			return p.peach
		end
	end
	return hex_from_hl("WarningMsg", "fg", 0xfab387)
end

--- c1/c2 接受数字色值（0xRRGGBB）或 "#rrggbb" 字符串，返回 "#rrggbb"
local function blend(c1, c2, t)
	if type(c1) == "string" then
		c1 = tonumber(c1:sub(2), 16)
	end
	if type(c2) == "string" then
		c2 = tonumber(c2:sub(2), 16)
	end
	local r1, g1, b1 = math.floor(c1 / 65536) % 256, math.floor(c1 / 256) % 256, c1 % 256
	local r2, g2, b2 = math.floor(c2 / 65536) % 256, math.floor(c2 / 256) % 256, c2 % 256
	local r = math.floor(r1 + (r2 - r1) * t + 0.5)
	local g = math.floor(g1 + (g2 - g1) * t + 0.5)
	local b = math.floor(b1 + (b2 - b1) * t + 0.5)
	return string.format("#%02x%02x%02x", r, g, b)
end

function M.enabled()
	return options.enabled
end

--- 当前正在呼吸的窗口（没有则 nil）
function M.win()
	return pulse.win
end

function M.stop()
	if pulse.timer then
		pcall(function()
			pulse.timer:stop()
			pulse.timer:close()
		end)
		pulse.timer = nil
	end
	pulse.win = nil
end

--- 让 win 的边框随时间呼吸，直到窗口失效或被其他状态打断
function M.start(win)
	if pulse.win == win and pulse.timer then
		return -- 已经在跑了
	end
	M.stop()
	pulse.win = win
	pulse.start_ns = vim.uv.hrtime()

	local base = base_color()
	local bg = hex_from_hl("NormalFloat", "bg", hex_from_hl("Normal", "bg", 0x1e1e2e))
	local white = 0xffffff
	-- 暗端往窗口背景色混，亮端只轻微提亮，全程保持同一色相，像光在呼吸而不是变脏变白
	local dark_end = blend(base, bg, 0.6)
	local bright_end = blend(base, white, 0.2)

	local timer = vim.uv.new_timer()
	pulse.timer = timer
	-- 动画频率和周期由 config.floatty 控制。
	timer:start(0, options.interval_ms, function()
		local elapsed = (vim.uv.hrtime() - pulse.start_ns) / 1e9
		local phase = (elapsed % options.period_s) / options.period_s
		local t = (math.sin(phase * math.pi * 2) + 1) / 2 -- 0..1
		local color = blend(dark_end, bright_end, t) -- 在暗/亮两端之间明暗律动
		vim.schedule(function()
			if not (pulse.win and vim.api.nvim_win_is_valid(pulse.win)) then
				M.stop()
				return
			end
			vim.api.nvim_set_hl(0, "FloattyPulseBusy", { fg = color })
			vim.wo[pulse.win].winhighlight = "FloatBorder:FloattyPulseBusy,FloatTitle:FloattyPulseBusy"
		end)
	end)
end

return M
