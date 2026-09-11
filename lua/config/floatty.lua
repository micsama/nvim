-- Floatty 常用配置：快捷键、应用、Claude 目录、窗口比例、Runner 和动画。
-- 修改后重启 Neovim；应用运行状态由 apps.floatty 单独维护。
local HOME = vim.env.HOME
local runners = { python = "uv run %s", lua = "lua %s", sh = "bash %s", go = "go run %s", rust = "cargo run" }
local autoclose_ms = 100 -- on_exit 后多久自动关窗（留时间瞥一眼结果）

local apps = {
	-- [Type 1: 直达型]
	{ key = "<D-g>", name = "Terminal", icon = " ", hl = "Function" },
	{
		key = "<D-i>",
		name = "Lazygit",
		icon = "󰊢  ",
		cmd = "lazygit",
		w = 0.98,
		h = 0.95,
		hl = "String",
		idle_ttl_ms = 60000, -- 隐藏超过 1 分钟未重新打开则自动关闭，省待机 CPU
	},

	-- [Type 2: 菜单型] (只有这种需要 choices)
	{
		key = "<D-e>",
		pick_key = "<M-e>",
		name = "AI",
		icon = "󰚩  ",
		w = 0.9,
		h = 0.95,
		hl = "Number",
		shell = "zsh",
		choices = {
			{ name = "Codex", cmd = "codex", codex = true },
			{ name = "😭[Claude]😭", claude = { dir = nil } },
			{ name = "Claude", claude = { dir = HOME .. "/.claude1" } },
			{ name = "Shell", cmd = vim.o.shell },
		},
	},

	-- [Type 3: 动态型]
	{ key = "<D-r>", name = "Runner", icon = "󰐊 ", is_runner = true, w = 0.75, h = 0.6, hl = "Constant" },
}

return {
	apps = apps,
	runners = runners,
	autoclose_ms = autoclose_ms,
	window = { w = 0.8, h = 0.8, border = "rounded", zindex = 50 },
	pulse = { enabled = true, period_s = 4.8, interval_ms = 80 },
}
