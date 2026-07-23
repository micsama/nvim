-- ~/.config/nvim/lua/component/stldata.lua
local M = {}
local api = vim.api
local profiler = require("component.profiler") -- 手搓 statusline 调优用；默认关，:StlProf 开

-- ============================================================================
-- Data Providers (数据源)
-- ============================================================================

-- --- Git User Name (IO Cache) ---
local user_cache = {} -- root -> name

-- 读取文件获取 user.name (毫秒级，带缓存)
local function fetch_git_user(root)
	if not root or root == "" then
		return nil
	end
	if user_cache[root] ~= nil then
		return user_cache[root]
	end

	local function read_config(path)
		local f = io.open(path, "r")
		if not f then
			return nil
		end
		local content = f:read("*a")
		f:close()
		local user_block = content:match("%[user%](.-)%[") or content:match("%[user%](.*)")
		if user_block then
			return user_block:match("name%s*=%s*([^\n]+)")
		end
		return nil
	end

	local name = read_config(root .. "/.git/config")
	if not name then
		local home = os.getenv("HOME")
		if home then
			name = read_config(home .. "/.gitconfig")
		end
	end

	user_cache[root] = name and vim.trim(name) or false
	return user_cache[root]
end

M.git_info = profiler.wrap("git_info", function(buf)
	-- 安全检测：确保 buffer 有效
	if not api.nvim_buf_is_valid(buf) then
		return nil
	end

	local summary = vim.b[buf].minigit_summary
	if not summary or not summary.head_name then
		return nil
	end

	local user = fetch_git_user(summary.root)
	local diff = vim.b[buf].minidiff_summary

	return {
		branch = summary.head_name,
		user = user,
		added = diff and diff.add or 0,
		changed = diff and diff.change or 0,
		deleted = diff and diff.delete or 0,
	}
end)

-- LSP Progress 状态追踪
local lsp_progress_state = {}

api.nvim_create_autocmd("LspProgress", {
	callback = function(ev)
		local key = ev.data.client_id .. "-" .. tostring(ev.data.params.token)
		local val = ev.data.params.value
		if val.kind == "end" then
			lsp_progress_state[key] = nil
		else
			lsp_progress_state[key] = {
				title = val.title or (lsp_progress_state[key] and lsp_progress_state[key].title) or "",
				message = val.message or "",
				percentage = val.percentage,
			}
		end
	end,
})

M.lsp_progress = profiler.wrap("lsp_progress", function()
	local _, task = next(lsp_progress_state)
	if not task then
		return nil
	end
	return task
end)

M.lsp_info = profiler.wrap("lsp_info", function(buf)
	if not api.nvim_buf_is_valid(buf) then
		return nil
	end
	local counts = vim.diagnostic.count(buf)
	local err = counts[vim.diagnostic.severity.ERROR] or 0
	local warn = counts[vim.diagnostic.severity.WARN] or 0
	if err == 0 and warn == 0 then
		return nil
	end
	return { err = err, warn = warn }
end)

return M
