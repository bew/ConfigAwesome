-- failsafe mode
-- if the current config fail, load the default rc.lua

-- package.path = package.path .. ";./lib/?.lua;"

local naughty = require("naughty")

local themeLoader = true
local loadError = nil

local cwd = debug.getinfo(1).source:match("@?(.*/)")

-- Init randomness
math.randomseed(os.time())

local _
if themeLoader then
	local f, err = loadfile(cwd .. "/ThemeLoader/init.lua")
	if not err then
		_, err = pcall(f)
		if not err then
			return
		end
	end
end

-- Load defaut theme when all others fail
dofile("/etc/xdg/awesome/rc.lua");

if loadError then
	naughty.notify({
		title = "#> Awesome crashed during startup on " .. os.date("%d/%m/%Y %T"),
		text = "Error:\n\n" .. loadError .. "\n",
		timeout = 0
	})
end
