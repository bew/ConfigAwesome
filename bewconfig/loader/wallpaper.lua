local gears = require("gears")
local ascreen = require("awful.screen")
local beautiful = require("beautiful")

local WallCache = require("bewlib.wallpapers.cache")
local WallSelector = require("bewlib.wallpapers.selector")

local global_wall_cache = WallCache.new({
    where = beautiful.wallpaper_dir,
})
global_wall_cache:scan()

ascreen.connect_for_each_screen(function(screen)

    screen.wallpaper_selector = WallSelector.new({
        cache = global_wall_cache,

        -- TODO: when global wallpaper filter change, this selector should use it
        -- follow_filter_of = wall_filter,

        on_select = function(wall_path)
            gears.wallpaper.maximized(wall_path, screen, true)
        end,
    })

    --global_wall_cache:on("scan::complete", function()
        screen.wallpaper_selector:next()
    --end)

end)
