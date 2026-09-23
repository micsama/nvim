-- =============================================================================
-- Floatty：浮动终端 / Lazygit / AI 会话 / Runner
--   controller.lua  终端生命周期（toggle / pick / idle 关闭）
--   registry.lua    持久会话注册表（孤儿会话续接）
--   claude.lua      Claude Code 会话元数据 watcher
--   pulse.lua       busy 时的呼吸边框
-- 用户可调选项在 lua/config/floatty.lua。
-- =============================================================================
local M = {}
local controller = require("apps.floatty.controller")
local claude = require("apps.floatty.claude")

M.toggle = controller.toggle
M.pick = controller.pick

--- statusline 片段：AI 菜单里后台存活的会话（带 Claude 状态图标）+ 上次未正常关闭的孤儿会话。
--- 返回已带高亮的 statusline 字符串，无内容时返回 ""。
function M.statusline_segment()
	local items = controller.active_menu_indices()
	local orphan_idx = controller.orphan_menu_indices()
	if #items == 0 and #orphan_idx == 0 then
		return ""
	end
	local s = ""
	if #items > 0 then
		local parts = {}
		for _, it in ipairs(items) do
			if it.status then
				local g = claude.STATUS_GLYPHS[it.status] or claude.STATUS_GLYPHS.idle
				parts[#parts + 1] = string.format("%%#%s#%d%s", g.hl, it.idx, g.icon)
			else
				parts[#parts + 1] = string.format("%%#Function#%d", it.idx)
			end
		end
		s = s .. string.format(" %%#Function#󰚩 [%s%%#Function#]", table.concat(parts, "%#Comment#,"))
	end
	if #orphan_idx > 0 then
		s = s .. string.format(" %%#FloattyOrphan#󰊠 [%s]", table.concat(orphan_idx, ","))
	end
	return s
end

-- Comment 默认斜体，孤儿角标只想要灰色不想要斜体，单独开一个不带 italic 的组
local function set_hl()
	local comment = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
	vim.api.nvim_set_hl(0, "FloattyOrphan", { fg = comment.fg, italic = false })
end

function M.setup()
	local map = require("utils.map")
	local group = vim.api.nvim_create_augroup("apps.floatty", { clear = true })

	set_hl()
	vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_hl })
	vim.api.nvim_create_autocmd("VimResized", { group = group, callback = controller.on_resized })
	vim.api.nvim_create_autocmd("WinClosed", {
		group = group,
		desc = "Start float terminal idle timeout",
		callback = function(ev)
			controller.on_win_closed(tonumber(ev.match))
		end,
	})
	-- 注册表只在显式读取/更新和目录、焦点变化时刷新，状态栏只读内存。
	vim.api.nvim_create_autocmd({ "FocusGained", "DirChanged" }, {
		group = group,
		callback = function()
			require("apps.floatty.registry").refresh()
			vim.cmd.redrawstatus()
		end,
	})

	for _, x in ipairs(controller.APPS) do
		local function toggle()
			controller.toggle(x)
		end
		map.map("nvi", x.key, toggle, x.name)
		map.map_terminal_action(x.key, toggle, x.name)
		-- 菜单型再绑一个变体用于 picker（可由 pick_key 显式指定，否则用 Shift 变体）
		if x.choices then
			local pick_key = x.pick_key or x.key:gsub("<D%-(%a)>", "<D-S-%1>")
			local function pick()
				controller.pick(x)
			end
			map.map("nvi", pick_key, pick, x.name .. " picker")
			map.map_terminal_action(pick_key, pick, x.name .. " picker")
		end
	end
end

return M
