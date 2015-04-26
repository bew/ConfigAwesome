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
	nbLine = nbLine and nbLine or false
end

mod.async = require("bewlib.utils.async")

return mod
