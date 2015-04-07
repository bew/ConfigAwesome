-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")


local lain = require("lain")
local utils = require("bewlib").utils

local global = require("global")


local debug = require("gears.debug").dump_return


-----------------------------------------------------
-- Simple function to load additional LUA files from rc/ or lib/
function loadrc(name, mod)
	local success
	local result

	-- Which file? In rc/ or in lib/?
	local path = global.confInfos.path .. "/" .. (mod and "lib" or "rc") .. "/" .. name .. ".lua"

	-- If the module is already loaded, don't load it again
	if mod and package.loaded[mod] then
		return package.loaded[mod]
	end

	-- Execute the RC/module file
	success, result = pcall(function() return dofile(path) end)
	if not success then
		naughty.notify({
			title = "Error while loading an RC file",
			text = "When loading `" .. name .. "`, got the following error:\n" .. result,
			preset = naughty.config.presets.critical
		})
		return print("E: error loading RC file '" .. name .. "': " .. result)
	end

	-- Is it a module?
	if mod then
		return package.loaded[mod]
	end

	return result
end
-----------------------------------------------------


loadrc("vars")
local config = global.config

loadrc("wallpaper")


-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
	-- Each screen has its own tag table.
	-- tags[s] = awful.tag({ "Web", "Divers", 3, 4, 5, "Code", "Code", 8, "Misc" }, s, layouts[1])
	tags[s] = awful.tag({ "Web", "Web2", "Web3", "				  ", "Divers", "Divers", "				  ", "Code", "CODE", "Code", "				  ", "Misc", "Misc" }, s, global.layouts[1])
end
-- }}}













-- {{{ Menu
-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
menubar.geometry = {
	x = 0,
	y = 0,
	width = 1500
}
-- }}}











-- {{{ Wibox
-- Create a textclock widget
wClock = awful.widget.textclock()

-- Create a wibox for each screen and add it
topbar = {}
bottombar = {}

wLayoutSwitcher = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
	awful.button({			}, 1, awful.tag.viewonly),
	awful.button({ modkey 	}, 1, awful.client.movetotag),
	awful.button({ 			}, 3, awful.tag.viewtoggle),
	awful.button({ modkey	}, 3, awful.client.toggletag),
	awful.button({ 			}, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
	awful.button({ 			}, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
)

-- Battery widget
wBattery = lain.widgets.bat({
    settings = function()
        widget:set_markup(" | " .. bat_now.status .. " | " .. bat_now.perc .. "% | ")
    end
})

wEmergencyReload = wibox.widget.textbox("  Reload RC  ")
wEmergencyReload:buttons(awful.util.table.join(
	awful.button({}, 1, function ()
		awesome.restart()
	end)
))

wEmergencyEdit = wibox.widget.textbox("  Edit RC  ")
wEmergencyEdit:buttons(awful.util.table.join(
	awful.button({}, 1, function ()
		awful.util.spawn("/home/lesell_b/soft-portable/subl3" .. awful.util.getdir("config"))
	end)
))

function foreachScreen(callback)
	if callback == nil then
		return
	end

	local s
	for s = 1, screen.count() do
		callback(s)
	end
end

foreachScreen(function (s)
	-- Create an imagebox widget which will contains an icon indicating which layout we're using.
	wLayoutSwitcher[s] = awful.widget.layoutbox(s)
	wLayoutSwitcher[s]:buttons(awful.util.table.join(
		awful.button({ }, 1, function () awful.layout.inc(global.layouts,  1) end),
		awful.button({ }, 3, function () awful.layout.inc(global.layouts, -1) end)
	))

	-- Create a taglist widget
	mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

	-- Create the wibox
	topbar[s] = awful.wibox({ position = "top", screen = s })

	-- Emergency widgets
	local layEmergency = wibox.layout.fixed.horizontal()
	layEmergency:add(wEmergencyReload)
	layEmergency:add(wEmergencyEdit)

	-- Widgets that are aligned to the left
	local tagsLayout = wibox.layout.fixed.horizontal()
	tagsLayout:add(mytaglist[s])

	-- Widgets that are aligned to the right
	local right_layout = wibox.layout.fixed.horizontal()
	if s == 1 then
		right_layout:add(wibox.widget.systray())
	end
	right_layout:add(wClock)
	right_layout:add(wBattery)
	right_layout:add(wLayoutSwitcher[s])

	-- Now bring it all together (with the tasklist in the middle)
	local layTopbar = wibox.layout.align.horizontal()
	layTopbar:set_middle(tagsLayout)
	layTopbar:set_right(right_layout)
	layTopbar:set_left(layEmergency)

	topbar[s]:set_widget(layTopbar)
end)
-- }}}


--[[ {{{ Mouse bindings
root.buttons(awful.util.table.join(
	awful.button({ }, 4, awful.tag.viewnext),
	awful.button({ }, 5, awful.tag.viewprev)
))
-- }}} ]]




local wibox = require("wibox")

local w = wibox({
	width = 200,
	height = 300,
	x = 300,
	y = 100,
	ontop = true,
	opacity = 1
})
w:set_bg("#03A9F4")

function toggle_w()
	w.visible = not w.visible
end






-- for ping:
local async        = require("lain.asyncshell")




-- {{{ Key bindings
globalkeys = awful.util.table.join(


	-- Show/Hide test Wibox
	awful.key({ modkey }, "b", toggle_w),




	awful.key({ modkey,			}, "Left",	awful.tag.viewprev		 ),
	awful.key({ modkey,			}, "Right",  awful.tag.viewnext		 ),
	awful.key({ modkey,			}, "Escape", awful.tag.history.restore),
	awful.key({ modkey, altkey	}, "j", awful.tag.viewprev ),
	awful.key({ modkey, altkey	}, "k", awful.tag.viewnext ),

	awful.key({ modkey, "Shift" }, "Left",
		function ()
			if not client.focus then return; end
			local c = client.focus
			local idx = awful.tag.getidx()
			local new_idx = (idx == 1 and #tags[c.screen] or idx - 1)
			awful.client.movetotag(tags[c.screen][new_idx])
			awful.tag.viewonly(tags[c.screen][new_idx])
			client.focus = c
		end
	),
	awful.key({ modkey, "Shift" }, "Right",
		function ()
			if not client.focus then return; end
			local c = client.focus
			local idx = awful.tag.getidx()
			local new_idx = (idx == #tags[c.screen] and 1 or idx + 1)
			awful.client.movetotag(tags[c.screen][new_idx])
			awful.tag.viewonly(tags[c.screen][new_idx])
			client.focus = c
		end
	),


	-- awesome management
	awful.key({ modkey, "Control" }, "r", awesome.restart),
	awful.key({ modkey, "Shift"	}, "q", awesome.quit),

	-- client selection
	awful.key({ modkey,			  }, "j",
		function ()
			awful.client.focus.byidx( 1)
			if client.focus then client.focus:raise() end
		end
	),
	awful.key({ modkey,			  }, "k",
		function ()
			awful.client.focus.byidx(-1)
			if client.focus then client.focus:raise() end
		end
	),



	-- Layout manipulation
	awful.key({ modkey, "Shift"		}, "j",	function () awful.client.swap.byidx( 1) end),
	awful.key({ modkey, "Shift"		}, "k",	function () awful.client.swap.byidx(-1) end),

	awful.key({ modkey, "Control"	}, "j",	function () awful.screen.focus_relative( 1) end),
	awful.key({ modkey, "Control"	}, "k",	function () awful.screen.focus_relative(-1) end),

	awful.key({ modkey }, "u",
		awful.client.urgent.jumpto
	),

	awful.key({ modkey }, "Tab",
		function ()
			awful.client.focus.history.previous()
			if client.focus then
				client.focus:raise()
			end
		end
	),



	-- Apps spawning
	awful.key({ modkey,				}, "t", function () awful.util.spawn(global.config.apps.term) end),
	awful.key({ modkey, altkey		}, "t", function () awful.util.spawn(global.config.apps.term2) end),



	-- Standard program
	awful.key({ modkey,			  }, "l",	  function () awful.tag.incmwfact( 0.05) end),
	awful.key({ modkey,			  }, "h",	  function () awful.tag.incmwfact(-0.05) end),

	awful.key({ modkey, "Shift"	}, "h",	  function () awful.tag.incnmaster( 1) end),
	awful.key({ modkey, "Shift"	}, "l",	  function () awful.tag.incnmaster(-1) end),

	awful.key({ modkey, "Control" }, "h",	  function () awful.tag.incncol( 1) end),
	awful.key({ modkey, "Control" }, "l",	  function () awful.tag.incncol(-1) end),
	awful.key({ modkey, "Control" }, "n",
		awful.client.restore
	),



	-- switch layout
	awful.key({ modkey,			  }, "space", function () awful.layout.inc(global.layouts,  1) end),
	awful.key({ modkey, "Shift"	}, "space", function () awful.layout.inc(global.layouts, -1) end),



	-- Menubar
	awful.key({ modkey }, "x", function() menubar.show() end),



	awful.key({ modkey }, "g", function ()
		utils.toast("Sending 1 packet to google.fr")
		async.request("ping google.fr -c 1 -w 1", function (file_out)
			local out = file_out:read("*all")

			utils.toast(out, { title = "===== Ping google.fr result =====" })
			file_out:close()
		end)
	end),

	----------------------------------------------------------------------
	------------------ functions keys ------------------------------------
	----------------------------------------------------------------------
	-- ALSA volume control
	awful.key({  }, "XF86AudioRaiseVolume",
		function ()
			awful.util.spawn("amixer -q set Master 1%+")
			--widget_volume.update()
			naughty.notify({
				text = "Increasing volume",
				timeout = 0.5
			})
		end
	),
	awful.key({  }, "XF86AudioLowerVolume",
		function ()
			awful.util.spawn("amixer -q set Master 1%-")
			--widget_volume.update()
			naughty.notify({
				text = "Decreasing Volume",
				timeout = 0.5
			})
		end
	),
	awful.key({  }, "XF86AudioMute",
		function ()
			awful.util.spawn("amixer -q set Master playback toggle")
			--widget_volume.update()
			naughty.notify({
				text = "Mute / Unmute",
				timeout = 0.5
			})
		end
	),



	-- Brightness control
	awful.key({  }, "XF86MonBrightnessDown",
		function ()
			awful.util.spawn("xbacklight -10")
			naughty.notify({
				text = "Decreasing Brightness",
				timeout = 0.5
			})
		end
	),
	awful.key({  }, "XF86MonBrightnessUp",
		function ()
			awful.util.spawn("xbacklight +10")
			naughty.notify({
				text = "Increasing Brightness",
				timeout = 0.5
			})
		end
	),



	-- Lock screen control
	awful.key({  }, "XF86Sleep",
		function ()
			awful.util.spawn("/home/lesell_b/.bin/my_i3lock")
			naughty.notify({
				text = "Locking...",
				timeout = 0.5
			})
		end
	),
	awful.key({  }, "Pause",
		function ()
			awful.util.spawn("/home/lesell_b/.bin/my_i3lock")
			naughty.notify({
				text = "Locking...",
				timeout = 0.5
			})
		end
	)
)




clientkeys = awful.util.table.join(
	awful.key({ modkey, "Shift"	}, "c",		function (c) c:kill()								 end),
	awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle							),
	awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
	awful.key({ modkey,			  }, "o",		awful.client.movetoscreen								),
	awful.key({ modkey,			  }, "a",		function (c) c.ontop = not c.ontop				end),
	-- awful.key({ modkey,			  }, "n",
	-- 	function (c)
	-- 		-- The client currently has the input focus, so it cannot be
	-- 		-- minimized, since minimized clients can't have the focus.
	-- 		c.minimized = true
	-- 	end
	-- ),
	awful.key({ modkey,			  }, "m",
		function (c)
			c.maximized_horizontal = not c.maximized_horizontal
			c.maximized_vertical	= not c.maximized_vertical
		end
	)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
	globalkeys = awful.util.table.join(globalkeys,
		-- View tag only.
		awful.key({ modkey }, "#" .. i + 9,
					function ()
						local screen = mouse.screen
						local tag = awful.tag.gettags(screen)[i]
						if tag then
							awful.tag.viewonly(tag)
						end
					end),
		-- Toggle tag.
		awful.key({ modkey, "Control" }, "#" .. i + 9,
					function ()
						local screen = mouse.screen
						local tag = awful.tag.gettags(screen)[i]
						if tag then
							awful.tag.viewtoggle(tag)
						end
					end),
		-- Move client to tag.
		awful.key({ modkey, "Shift" }, "#" .. i + 9,
					function ()
						if client.focus then
							local tag = awful.tag.gettags(client.focus.screen)[i]
							if tag then
								awful.client.movetotag(tag)
							end
						end
					end),
		-- Toggle tag.
		awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
					function ()
						if client.focus then
							local tag = awful.tag.gettags(client.focus.screen)[i]
							if tag then
								awful.client.toggletag(tag)
							end
						end
					end)
	)
end

clientbuttons = awful.util.table.join(
	awful.button({			}, 1, function (c)
		client.focus = c; c:raise()
	end),
	awful.button({ modkey	}, 1, awful.mouse.client.move),
	awful.button({ modkey	}, 3, awful.mouse.client.resize)
)

-- Set keys
root.keys(globalkeys)
-- }}}












loadrc("rules")














-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
	-- Enable sloppy focus
	c:connect_signal("mouse::enter", function(c)
		if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
			and awful.client.focus.filter(c) then
			client.focus = c
		end
	end)

	if not startup then
		-- Set the windows at the slave,
		-- i.e. put it at the end of others instead of setting it master.
		-- awful.client.setslave(c)

		-- Put windows in a smart way, only if they does not set an initial position.
		if not c.size_hints.user_position and not c.size_hints.program_position then
			awful.placement.no_overlap(c)
			awful.placement.no_offscreen(c)
		end
	end

	-- if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
	if c.type == "normal" or c.type == "dialog" then
		-- buttons for the titlebar
		local buttons = awful.util.table.join(
			awful.button({ }, 1, function()
				client.focus = c
				c:raise()
				awful.mouse.client.move(c)
			end),
			awful.button({ }, 3, function()
				client.focus = c
				c:raise()
				awful.mouse.client.resize(c)
			end)
		)

		-- Widgets that are aligned to the left
		local left_layout = wibox.layout.fixed.horizontal()
		left_layout:add(awful.titlebar.widget.iconwidget(c))
		left_layout:buttons(buttons)

		-- Widgets that are aligned to the right
		local right_layout = wibox.layout.fixed.horizontal()
		-- right_layout:add(awful.titlebar.widget.floatingbutton(c))
		right_layout:add(awful.titlebar.widget.maximizedbutton(c))
		right_layout:add(awful.titlebar.widget.stickybutton(c))
		right_layout:add(awful.titlebar.widget.ontopbutton(c))
		right_layout:add(awful.titlebar.widget.closebutton(c))

		-- The title goes in the middle
		local middle_layout = wibox.layout.flex.horizontal()
		local title = awful.titlebar.widget.titlewidget(c)
		title:set_align("center")
		middle_layout:add(title)
		middle_layout:buttons(buttons)

		-- Now bring it all together
		local layout = wibox.layout.align.horizontal()
		layout:set_left(left_layout)
		layout:set_right(right_layout)
		layout:set_middle(middle_layout)

		awful.titlebar(c):set_widget(layout)
		if (global.config.default.titlebar.show == false) then
			awful.titlebar.hide(c)
		end
	end
end)

client.connect_signal("focus", function(c)
	c.border_color = beautiful.border_focus
end)
client.connect_signal("unfocus", function(c)
	c.border_color = beautiful.border_normal
end)
-- }}}


loadrc("run_once")
