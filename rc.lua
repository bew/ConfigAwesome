-- failsafe mode
-- if the current config fail, load the default rc.lua

-- package.path = package.path .. ";./lib/?.lua;"

local awful = require("awful")
local naughty = require("naughty")
local global = require("global")

local themeLoader = true
local loadError= nil

local rc;
if themeLoader then
	rc, global_err = loadfile(awful.util.getdir("config") .. "/ThemeLoader/init.lua");
	if rc then
		rc, global_err = pcall(rc);
		if rc then
			return;
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
