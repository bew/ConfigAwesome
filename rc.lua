-- failsafe mode
-- if all configs fail, load the default rc.lua


local cwd = debug.getinfo(1).source:match("@?(.*/)")

-- Init randomness
math.randomseed(os.time())

local ThemeLoader
local function loadLoader()
	ThemeLoader = require("ThemeLoader")
	print("ThemeLoader loaded at", ThemeLoader)
end

if pcall(loadLoader) and ThemeLoader.init({confdir = cwd}) then
	-- ThemeLoader found, adding configs & run them !

	ThemeLoader.add_config("/bewconfig", "Bew config")
	ThemeLoader.add_config("/stable-config", "Very old config")

	if ThemeLoader.run() then
		return
	end

	-- TODO: add error handler
	-- ThemeLoader.on_error(function(err, is_last) --[[ do something ]] end)
end

-- Load defaut theme when all others fail
print("#### ThemeLoader : Cannot load themes ####")
dofile("/etc/xdg/awesome/rc.lua");
