local theme = require("beautiful")
local gears = require("gears")

local function randomWall()
	local walls = theme.wallpapers
	local selectedID = math.random(#walls) or 1
	return walls[selectedID]
end


-- {{{ Wallpaper
if theme.wallpapers then
	for s = 1, screen.count() do
		local wall = randomWall()
		gears.wallpaper.maximized(wall, s, true)
	end
end
-- }}}
