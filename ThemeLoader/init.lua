-----------------
-- ThemeLoader --
-----------------
-- by Bew78LesellB - 2015

local awful = require("awful")
local naughty = require("naughty")
local global = require("global")

confdir = awful.util.getdir("config")
package.path = package.path .. ";" .. confdir .. "/lib/?.lua;"
package.path = package.path .. ";" .. confdir .. "/lib/?/init.lua;"

local confList = {
	{
		name = "Bew v2 - dev",
		path = confdir .. "/bew_v2"
	},
	{
		name = "Bew v1 - stable",
		path = confdir .. "/bew_v1-stable"
	}
}

function loadConf(confpath)
	local rc, err = loadfile(confpath);
	if rc then
	    rc, err = pcall(rc);
	    if rc then
	        return nil;
	    end
	end
	return err
end

local err
for i=1, #confList do
	naughty.notify({ text = "Loading theme '" .. confList[i].name .. "'..." })
	global.confInfos = confList[i]

	local oldPackagePath = package.path
	package.path = package.path .. ";" .. confList[i].path .. "/lib/?.lua;"
	package.path = package.path .. ";" .. confList[i].path .. "/lib/?/init.lua;"

	err = loadConf(confList[i].path .. "/init.lua")

	if not err then
		naughty.notify({ text = "Theme '" .. confList[i].name .. "' loaded !", timeout = 10 })
		return;
	end

	package.path = oldPackagePath
	naughty.notify({
		title = "#> Theme '" .. confList[i].name .. "' crashed during startup on " .. os.date("%d/%m/%Y %T"),
		text = "Theme path: " .. confList[i].path .. "/init.lua\n"
			.. "Error:\n\n" .. err .. "\n",
		timeout = 0
	})
end

-- all themes crashed
assert(false, "\n#### Cannot load themes ####\n\nError:\n" .. err) --trigger error
