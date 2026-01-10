-- filepath: lua/dzmfg.lua
--  ██████╗ ███████╗███╗   ███╗███████╗ ██████╗
-- ██╔════╝ ██╔════╝████╗ ████║██╔════╝██╔════╝
-- ██║  ███╗█████╗  ██╔████╔██║█████╗  ██║  ███╗
-- ██║   ██║██╔══╝  ██║╚██╔╝██║██╔══╝  ██║   ██║
-- ╚██████╔╝███████╗██║ ╚═╝ ██║███████╗╚██████╔╝
--  ╚═════╝ ╚══════╝╚═╝     ╚═╝╚══════╝ ╚═════╝
-- Neovim Configuration by dzmfg
-- 🚀 Powered by LunarVim-inspired setup
-- 🎨 Themes, LSP, DAP, and AI companions ready!
-- 📅 Last updated: 2025-10-16

-- 加载功能模块配置 (Loading Functional Plugin Configurations)
require("plugins.Ui") -- 用户界面和外观
require("plugins.editor") -- 编辑器增强功能
require("plugins.llm.codecompanion") -- 大型语言模型相关插件
-- require('plugins.dap')       -- 调试适配器协议 (DAP)


local function diag_line_summary()
	local bufnr = vim.api.nvim_get_current_buf()
	local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
	local diags = vim.diagnostic.get(bufnr, { lnum = lnum })

	if #diags == 0 then
		vim.api.nvim_echo({ { "No diagnostics on this line", "DiagnosticHint" } }, false, {})
		return
	end

	local sev_name = {
		[1] = "ERROR",
		[2] = "WARN",
		[3] = "INFO",
		[4] = "HINT",
	}
	local sev_hl = {
		[1] = "DiagnosticError",
		[2] = "DiagnosticWarn",
		[3] = "DiagnosticInfo",
		[4] = "DiagnosticHint",
	}

	-- group by source
	local by_source = {}
	for _, d in ipairs(diags) do
		local src = d.source or "unknown"
		by_source[src] = by_source[src] or {}
		table.insert(by_source[src], d)
	end

	-- header
	local header = {
		{ ("Line %d: %d diagnostic(s)  "):format(lnum + 1, #diags), "Title" },
	}

	for src, list in pairs(by_source) do
		local max_sev = 4
		for _, d in ipairs(list) do
			if d.severity < max_sev then
				max_sev = d.severity
			end
		end
		table.insert(header, { src, "Identifier" })
		table.insert(header, { "(", "Comment" })
		table.insert(header, { sev_name[max_sev], sev_hl[max_sev] })
		table.insert(header, { ":" .. #list .. ")  ", "Comment" })
	end

	vim.api.nvim_echo(header, false, {})

	-- details
	for src, list in pairs(by_source) do
		vim.api.nvim_echo({
			{ "─ ", "Comment" },
			{ src, "Identifier" },
			{ " (" .. #list .. ")", "Comment" },
		}, false, {})

		table.sort(list, function(a, b)
			return a.severity < b.severity
		end)

		for i, d in ipairs(list) do
			local code = d.code and (" [" .. d.code .. "]") or ""
			vim.api.nvim_echo({
				{ "  " .. i .. ") ", "Comment" },
				{ sev_name[d.severity], sev_hl[d.severity] },
				{ code .. " ", "Comment" },
				{ d.message, "Normal" },
			}, false, {})
		end
	end
end

vim.api.nvim_create_user_command("DiagLine", diag_line_summary, {})
