-----------------
-- ThemeLoader --
-----------------
-- by Bew78LesellB - 2015

local naughty = require("naughty")
local global = require("global")

local ThemeLoader = {
	options = {},
	conflist = {},
}
local options = ThemeLoader.options

local function addPackagePath(dirPath)
	package.path = package.path .. ";" .. dirPath .. "/?.lua;"
	package.path = package.path .. ";" .. dirPath .. "/?/init.lua;"
end

local function loadConf(fullpath)
	local save_awesome_conffile = awesome.conffile
	awesome.conffile = fullpath

	local rc, success, load_err, exec_err

	rc, load_err = loadfile(fullpath);
	if rc then
	    success, exec_err = pcall(rc);
	    if success then
	        return
	    end
	end
	awesome.conffile = save_awesome_conffile
	return load_err or exec_err
end

function ThemeLoader.init(args)
	args = args or {}

	options.conf_root = args.conf_root or awesome.conffile:match("(.*/)")

	return true
end

function ThemeLoader.add_config(dir, name)
	local path = options.conf_root .. "/" .. dir

	local conf = {
		name = name,
		path = path,
		fullpath = path .. "/" .. "init.lua"
	}

	-- prepend to conf list
	--table.insert(ThemeLoader.conflist, 1, conf)
	table.insert(ThemeLoader.conflist, conf)
end

function ThemeLoader.run()

	addPackagePath(options.conf_root .. "/lib/")

	local err
	for _, conf in ipairs(ThemeLoader.conflist) do
		global.confInfos = conf

		local oldPackagePath = package.path
		addPackagePath(conf.path .. "/lib/")

		err = loadConf(conf.fullpath)

		if not err then
			-- no error
			naughty.notify({ text = "Theme '" .. conf.name .. "' loaded !", timeout = 5 })
			return true
		end

		-- error when loading theme
		package.path = oldPackagePath
		naughty.notify({
			title = "#> ThemeLoader : Theme '" .. conf.name .. "' crashed during startup on " .. os.date("%d/%m/%Y %T"),
			text = "Theme path: " .. conf.path .. "/init.lua\n"
			.. "Error:\n\n" .. err .. "\n" .. debug.traceback(),
			timeout = 0
		})
	end

	-- all themes crashed
	return false
end

return ThemeLoader

