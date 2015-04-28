--[[ bewlib.utils ]]--


-- Grab environement
local capi = {
	timer = timer
}

-- Module dependencies
local naughty = require("naughty")

-- Module environement
local mod = {}

function mod.toast(text, options)
	local options = options or {}
	options.text = text
	return naughty.notify(options)
end

function mod.setTimeout(callback, timeout)
	local theTimer = capi.timer({ timeout = timeout })
	theTimer:connect_signal("timeout", function()
		theTimer:stop()
		callback()
	end)
	theTimer:start()
	return theTimer
end

function mod.setInterval(callback, interval)
	local theTimer = capi.timer({ timeout = interval })
	theTimer:connect_signal("timeout", callback)
	theTimer:start()
	return theTimer
end

function mod.readFile(path, nbLine)
	nbLine = type(nbLine) == "number" and nbLine or false
	local f = io.open(path)
	if not f then return nil end
	local tab = {}
	if not nbLine then
		for line in f:lines() do
			table.insert(tab, line)
		end
	else
		local i = 1
		for line in f:lines() do
			table.insert(tab, line)
			if nbLine == i then
				break
			end
			i = i + 1
		end
	end
	return tab
end

mod.async = require("bewlib.utils.async")

return mod
