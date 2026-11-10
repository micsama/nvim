local M = {}
local options = require("config.network")
local probe = require("apps.network.probe")
local store = require("utils.json_store")
local path = probe.directory .. "/selection.json"
local selected = options.exits[1]
local timer

--- 探测出口（默认全部）；未到 next_probe_at 的会跳过，force 则立即重测。
function M.refresh(force, exits)
	for _, exit in ipairs(exits or options.exits) do
		probe.check(exit, force, vim.cmd.redrawstatus)
	end
end

local function apply(exit)
	selected = exit
	for _, key in ipairs({ "http_proxy", "https_proxy", "HTTP_PROXY", "HTTPS_PROXY" }) do
		vim.env[key] = exit.proxy ~= "" and exit.proxy or nil
	end
	vim.env.all_proxy, vim.env.ALL_PROXY = nil, nil
end

--- 启动最早期调用：只把上次选择的出口写进环境变量，不落盘、不探测。
function M.apply_saved()
	local saved = store.read(path, {})
	for _, exit in ipairs(options.exits) do
		if exit.id == saved.id then
			return apply(exit)
		end
	end
	apply(selected)
end

--- 用户主动切换：应用、记住，并立即重测该出口。
function M.select(exit)
	apply(exit)
	store.write(path, { id = exit.id })
	M.refresh(true, { exit })
end

--- 选择出口：只展示后台缓存的探测结果，不等待；末项“重测”在后台强制重测全部出口。
function M.pick()
	local retry = { name = "重测全部出口" }
	local items = vim.list_extend(vim.list_slice(options.exits), { retry })
	vim.ui.select(items, {
		prompt = "网络出口",
		format_item = function(item)
			if item == retry then
				return item.name
			end
			local mark = item == selected and "● " or "  "
			local name = item.name .. string.rep(" ", 10 - vim.fn.strdisplaywidth(item.name))
			return mark .. name .. probe.describe(item)
		end,
	}, function(item)
		if item == retry then
			M.refresh(true)
			vim.notify("正在后台重测网络出口…")
		elseif item then
			M.select(item)
		end
	end)
end

function M.statusline_segment()
	local record = probe.get(selected)
	local label = selected.name
	if not probe.fresh(record) then
		return " %#DiagnosticWarn#" .. label .. " …"
	end
	if record.status == "ok" then
		local country = record.country
		local flag = vim.fn.nr2char(0x1F1E6 + country:byte(1) - 65) .. vim.fn.nr2char(0x1F1E6 + country:byte(2) - 65)
		return (" %%#%s#%s %s %s"):format(country == "AU" and "DiagnosticOk" or "DiagnosticWarn", label, flag, country)
	end
	local seconds = math.max(0, os.time() - record.offline_since)
	local elapsed = seconds < 60 and (seconds .. "秒")
		or ("%d分%02d秒"):format(math.floor(seconds / 60), seconds % 60)
	return (" %%#DiagnosticWarn#%s × %s（%s）"):format(label, record.failure, elapsed)
end

function M.setup()
	vim.fn.mkdir(probe.directory, "p", 448)
	vim.api.nvim_create_user_command("Proxy", M.pick, {})
	vim.cmd([[cnoreabbrev <expr> proxy getcmdtype() == ':' && getcmdline() ==# 'proxy' ? 'Proxy' : 'proxy']])
	local group = vim.api.nvim_create_augroup("apps.network", { clear = true })
	timer = vim.uv.new_timer()
	timer:start(
		1000,
		1000,
		vim.schedule_wrap(function()
			M.refresh(false)
			-- 结果变化由探测回调重绘；只有失败时状态栏的持续秒数需要逐秒走动。
			if probe.get(selected).status == "failed" then
				vim.cmd.redrawstatus()
			end
		end)
	)
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			timer:stop()
			timer:close()
			probe.stop()
		end,
	})
end

return M
