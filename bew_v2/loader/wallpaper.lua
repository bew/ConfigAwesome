local theme = require("beautiful")
local gears = require("gears")


-- {{{ Wallpaper
if theme.wallpaper then
	for s = 1, screen.count() do
		gears.wallpaper.maximized(theme.wallpaper, s, true)
	end
end
-- }}}
