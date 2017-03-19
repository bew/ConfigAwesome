local theme = require("beautiful")
local gears = require("gears")
local ascreen = require("awful.screen")

local function randomWall()
	local walls = theme.wallpapers
	local selectedID = math.random(#walls) or 1
	return walls[selectedID]
end


-- {{{ Wallpaper
if theme.wallpapers then
	ascreen.connect_for_each_screen(function (screen)
		local wall = randomWall()
		gears.wallpaper.maximized(wall, screen, true)
	end)
end
-- }}}
