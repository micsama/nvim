local M = {}
local options = require("config.network")
local probe = require("apps.network.probe")
local store = require("utils.json_store")
local path = vim.fn.stdpath("state") .. "/network/selection.json"
local selected = options.exits[1]
local timer

function M.current()
	return selected
end

function M.refresh(force, all)
	local function changed()
		vim.cmd.redrawstatus()
		require("apps.network.picker").redraw()
	end
	for _, exit in ipairs(all and options.exits or { selected }) do
		probe.check(exit, force, changed)
	end
	changed()
end

function M.select(exit)
	selected = exit
	for _, key in ipairs({ "http_proxy", "https_proxy", "HTTP_PROXY", "HTTPS_PROXY" }) do
		vim.env[key] = exit.proxy ~= "" and exit.proxy or nil
	end
	vim.env.all_proxy, vim.env.ALL_PROXY = nil, nil
	store.write(path, { id = exit.id })
	M.refresh(true)
end

function M.statusline_segment()
	local record = probe.get(selected)
	local label = selected.proxy == "" and "直连" or ("代理 " .. selected.id)
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
	probe.setup()
	local saved = store.read(path, {})
	for _, exit in ipairs(options.exits) do
		if exit.id == saved.id then
			selected = exit
		end
	end
	M.select(selected)
	vim.api.nvim_create_user_command("Proxy", function()
		require("apps.network.picker").open()
	end, {})
	vim.cmd([[cnoreabbrev <expr> proxy getcmdtype() == ':' && getcmdline() ==# 'proxy' ? 'Proxy' : 'proxy']])
	local group = vim.api.nvim_create_augroup("apps.network", { clear = true })
	timer = vim.uv.new_timer()
	timer:start(
		1000,
		1000,
		vim.schedule_wrap(function()
			M.refresh(false, require("apps.network.picker").is_open())
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
