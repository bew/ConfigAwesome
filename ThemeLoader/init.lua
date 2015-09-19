-----------------
-- ThemeLoader --
-----------------
-- by Bew78LesellB - 2015

local awful = require("awful")
local naughty = require("naughty")
local global = require("global")

local confdir = awful.util.getdir("config")

local confList = {
	{
		name = "Bew Config",
		path = confdir .. "/bewconfig"
	},
	{
		name = "Stable config",
		path = confdir .. "/stable-config"
	}
}

function addPackagePath(dirPath)
	package.path = package.path .. ";" .. dirPath .. "/?.lua;"
	package.path = package.path .. ";" .. dirPath .. "/?/init.lua;"
end

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


addPackagePath(confdir .. "/lib/")

local err
for i = 1, #confList do
	global.confInfos = confList[i]

	local oldPackagePath = package.path
	addPackagePath(confList[i].path .. "/lib/")
	package.path = package.path .. ";" .. confList[i].path .. "/lib/?/init.lua;"

	err = loadConf(confList[i].path .. "/init.lua")

	if not err then
		-- no error
		naughty.notify({ text = "Theme '" .. confList[i].name .. "' loaded !", timeout = 5 })
		return;
	end

	-- error when loading theme
	package.path = oldPackagePath
	naughty.notify({
		title = "#> ThemeLoader : Theme '" .. confList[i].name .. "' crashed during startup on " .. os.date("%d/%m/%Y %T"),
		text = "Theme path: " .. confList[i].path .. "/init.lua\n"
			.. "Error:\n\n" .. err .. "\n",
		timeout = 0
	})
end

-- all themes crashed
assert(false, "\n#### ThemeLoader : Cannot load themes ####\n\nError:\n" .. err) --trigger error
