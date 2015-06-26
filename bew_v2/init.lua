--[[

		Awesome WM config

	- by Bew78LesellB alias bew -

	Starting date ~ 2015-01
	Last update Wed Apr 15 16:00:29 CEST 2015

--]]

--[[ Grab environnement ]]--
local capi = {
	timer = timer
}

-- load modif (widget, etc) from radical
require("radical")

-- Standard awesome library
local awful = require("awful")
awful.rules = require("awful.rules")

-- Widget and layout library
local wibox = require("wibox")

-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")

local lain = require("lain")
local debug = require("gears.debug").dump_return
local gears = require("gears")


-- Autofocus (when changing tag/screen/etc or add/delete client/tag)
require("awful.autofocus")

local global = require("global")

--[[ My lib ]]--
local utils = require("bewlib.utils")
local battery = require("bewlib.computer.battery")
battery.init({update = 2})
--[[
TODO:
battery.init({
	update = {
		status = 2,
		other = 30
	}
})

TODO:
battery.setUpdate({
	perc = 15,
})
--]]
battery:on("percentage::changed", function(self, perc)
	utils.toast("percentage changed !!")
end)

battery:on("timeLeft::changed", function(self, time)
	local msg = self.infos.status == "Charging" and "full" or "empty"
	utils.toast("time to " .. msg .. ": " .. string.gsub(time, "(%d%d):(%d%d)", "%1h %2m"))
end)

battery:on("status::changed", function(self, status)
	utils.toast("Status changed !!\n"
			 .. "==> " .. status)
end)

function loadFile(path)
	local success
	local result

	-- Which file? In rc/ or in lib/?
	local path = global.confInfos.path .. "/" .. path .. ".lua"

	-- Execute the file
	success, result = pcall(function() return dofile(path) end)
	if not success then
		naughty.notify({
			title = "Error while loading file",
			text = "When loading `" .. path .. "`, got the following error:\n" .. result,
			preset = naughty.config.presets.critical
		})
		return print("E: error loading RC file '" .. path .. "': " .. result)
	end

	return result
end

loadFile("loader/vars")
local theme = global.theme
local config = global.config

loadFile("loader/wallpaper")


-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
	-- Each screen has its own tag table.
	-- tags[s] = awful.tag({ "Web", "Divers", 3, 4, 5, "Code", "Code", 8, "Misc" }, s, layouts[1])
	tags[s] = awful.tag({
		"Web", "Web2", "Web3", "				  ",
		"Divers", "Divers", "				  ",
		"Code", "CODE", "Code", "				  ",
		"Misc", "Misc" }, s, global.layouts[1])
end
-- }}}



-- Edit the config file
awesome_edit = function ()
	awful.util.spawn(run_in_term_cmd .. "'cd " .. awful.util.getdir("config") .. " && " .. termEditor .. " " .. "rc.lua" .. "'")
end




-- {{{ Menu
-- Menubar configuration
menubar.utils.terminal = terminal -- Set the terminal for applications that require it
menubar.geometry = {
	x = 0,
	y = 0,
	width = 1500
}
-- }}}


local lockAndSleeping = false
function lockAndSleep()
	if not lockAndSleeping then
		async.request("my_i3lock", function(file_out)
			lockAndSleeping = false
		end)
		utils.setTimeout(function()
			awful.util.spawn("systemctl hybrid-sleep")
		end, 3)
		lockAndSleeping = true
	end
end

utils.setInterval(function()
	local battery = "BAT0"
	async.request("cat /sys/class/power_supply/" .. battery .. "/capacity", function(file_out)
		local stdout = file_out:read("*line")
		file_out:close()

		local perc = tonumber(stdout)
		if perc < 15 then
			utils.toast("perc: " .. perc, { title = "Checking battery infos" })
		end
		if perc < 5 then
			async.request("cat /sys/class/power_supply/" .. battery .. "/status", function(file_out)
				local status = file_out:read("*line")
				file_out:close()

				if status == "Charging" then return end
				utils.toast("need lock and sleep !!!", { title = "Battery status is " .. status })
				--lockAndSleep()
			end)
		end
	end)
end, 10)



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

wEmergencyReload = wibox.widget.imagebox( theme.getIcon( "emergency", "rcReload" ), true)
wEmergencyReload:buttons(awful.util.table.join(
	awful.button({}, 1, function ()
		awesome.restart()
	end)
))

wEmergencyEdit = wibox.widget.imagebox( theme.getIcon( "emergency", "rcEdit" ), true)
wEmergencyEdit:buttons(awful.util.table.join(
	awful.button({}, 1, function ()
		awesome_edit()
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

	wLayoutSwitcher[s] = awful.widget.layoutbox(s)
	wLayoutSwitcher[s]:buttons(awful.util.table.join(
		awful.button({ }, 1, function () awful.layout.inc(global.layouts,  1) end),
		awful.button({ }, 3, function () awful.layout.inc(global.layouts, -1) end)
	))

	mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

	-- Emergency widgets
	local layEmergency = wibox.layout.fixed.horizontal()
	layEmergency:add( wibox.widget.textbox("RC: ") )
	layEmergency:add( wEmergencyReload )
	layEmergency:add( wEmergencyEdit )

	-- Tags layout
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

	topbar[s] = awful.wibox({ position = "top", screen = s })
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




-- Load radical tests functions
--loadFile("tests/radical_1") -- have weird bugs





-- for ping:
local async = require("lain.asyncshell")


local notif_id = {}



-- Network management
local wpa_cli = {
	cmd = "wpa_cli -i wlo1 "
}

local wallpaper_toggle = {
	state = false,
	id_notif = nil
}




-- {{{ Key bindings
globalkeys = awful.util.table.join(


	-- Show/Hide test Wibox
	awful.key({ modkey }, "b", toggle_w),

	awful.key({ modkey }, "Left", awful.tag.viewprev),
	awful.key({ modkey }, "Right",  awful.tag.viewnext),
	awful.key({ modkey }, "Escape", awful.tag.history.restore),
	awful.key({ modkey, altkey	}, "j", awful.tag.viewprev ),
	awful.key({ modkey, altkey	}, "k", awful.tag.viewnext ),

	awful.key({ modkey, "Shift" }, "Left", function ()
		if not client.focus then return; end
		local c = client.focus
		local idx = awful.tag.getidx()
		local new_idx = (idx == 1 and #tags[c.screen] or idx - 1)
		awful.client.movetotag(tags[c.screen][new_idx])
		awful.tag.viewonly(tags[c.screen][new_idx])
		client.focus = c
	end),
	awful.key({ modkey, "Shift" }, "Right", function ()
		if not client.focus then return; end
		local c = client.focus
		local idx = awful.tag.getidx()
		local new_idx = (idx == #tags[c.screen] and 1 or idx + 1)
		awful.client.movetotag(tags[c.screen][new_idx])
		awful.tag.viewonly(tags[c.screen][new_idx])
		client.focus = c
	end),


	-- awesome management
	awful.key({ modkey, "Control" }, "r", awesome.restart),
	awful.key({ modkey, "Shift"	}, "q", awesome.quit),

	-- client selection
	awful.key({ modkey,			  }, "j", function ()
		awful.client.focus.byidx( 1)
		if client.focus then client.focus:raise() end
	end),
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
	awful.key({ modkey			}, "space", function () awful.layout.inc(global.layouts,  1) end),
	awful.key({ modkey, "Shift"	}, "space", function () awful.layout.inc(global.layouts, -1) end),



	-- Menubar
	awful.key({ modkey }, "x", function() menubar.show() end),



	awful.key({ modkey }, "g", function ()
		notif_id.ping = utils.toast("Sending 1 packet to google.fr", {
			position = "bottom_right",
			replaces_id = notif_id.ping
		}).id
		async.request("ping google.fr -c 1 -w 1", function (file_out)
			local out = file_out:read("*all")
			file_out:close()

			notif_id.ping = utils.toast(out, {
				title = "===== Ping google.fr result =====",
				position = "bottom_right",
				replaces_id = notif_id.ping 
			}).id
		end)
	end),

	-- Wallpaper managment
	awful.key({ modkey }, "w", function()
		if wallpaper_toggle.state then
			wallpaper_toggle.id_notif = utils.toast("Resetting wallpaper", { replaces_id = wallpaper_toggle.id_notif }).id
			gears.wallpaper.maximized(theme.wallpaper, 1, true)
		else
			wallpaper_toggle.id_notif = utils.toast("Changing wallpaper", { replaces_id = wallpaper_toggle.id_notif }).id
			gears.wallpaper.maximized(theme.wallpaper_dir .. "powered_by_archlinux__yellow_on_black.png", 1, true)
		end
		wallpaper_toggle.state = not wallpaper_toggle.state
	end),

	-- Computer managment
	awful.key({ modkey }, "p", lockAndSleep),

	-- Network management
	--- network infos
	awful.key({ modkey }, "n", function()
		async.request(wpa_cli.cmd .. "status", function(file_out)
			local stdout = file_out:read("*all")
			file_out:close()

			if stdout == "" then
				utils.toast("Please run 'wifi' in a terminal", { title = "Wifi is not ACTIVATED" })
			end


			--utils.toast("[debug] before match")
			local net_now = {
				status = string.match(stdout, "wpa_state=([%a_]*)"),
				ip_addr = string.match(stdout, "ip_address=([%d]+%.[%d]+%.[%d]+%.[%d]+)")
			}
			--utils.toast("[debug] after match")
			notif_id.net_info = utils.toast("\n" .. stdout, {
				title = net_now.status .. "  -  " .. (net_now.ip_addr and net_now.ip_addr or "NO IP"),
				--title = "Volume " .. vol_now.perc .. "% [" .. string.upper(vol_now.status) .. "]",
				--position = "bottom_right",
				replaces_id = notif_id.net_info
			}).id
		end)
	end),

	--- network change (intra / bew's gs4)
	awful.key({ modkey, "Control" }, "n", function()
		-- info on networks
		local networks = {
			-- keybind is i
			i = {
				name = "Intra Epitech",
				id = 0
			},
			-- keybind is b
			b = {
				name = "Bew's GS4",
				id = 2
			},
			s = {
				name = "Schol@Net",
				id = 1
			}
		}

		-- display help
		local help_str = "\n"
		for key, net in pairs(networks) do
			help_str = help_str .. "[ " .. key .. " ] (id=" .. net.id .. ") - " .. net.name .. "\n"
		end
		help_str = help_str .. "\nPress ESCAPE to cancel"
		local help_notif = utils.toast(help_str, {
			title = "===== Select network =====",
			timeout = 0,
			replaces_id = notif_id.net_selector
		})
		notif_id.net_selector = help_notif.id

		-- grab keys
		keygrabber.run(function(mod, key, event)
			if event == "release" then return true end
			keygrabber.stop()
			naughty.destroy(help_notif)
			if networks[key] then
				async.request(wpa_cli.cmd .. "select_network " .. networks[key].id, function(file_out)
					file_out:close()
					notif_id.net_selector = utils.toast("Trying to connect...", {
						title = "Network '" .. networks[key].name .. "' selected",
						replaces_id = notif_id.net_selector
					}).id
				end)
			end
			return true
		end)
	end),

	--- network saved list
	awful.key({ modkey, "Shift" }, "n", function()
		async.request(wpa_cli.cmd .. "list_networks", function(file_out)
			local stdout = file_out:read("*all")
			file_out:close()
			notif_id.net_list = utils.toast(stdout, {
				title = "===== Networks saved list =====",
				replaces_id = notif_id.net_list
			}).id
		end)
	end),

	---------------------------------------------------------------
	------------------ FN keys ------------------------------------
	---------------------------------------------------------------
	-- ALSA volume control
	awful.key({  }, "XF86AudioRaiseVolume",
		function ()
			awful.util.spawn("amixer -q set Master 1%+")

			async.request('amixer get Master', function(file_out)
				local stdout = file_out:read("*all")
				file_out:close()

				local vol_now = {}
				vol_now.perc, vol_now.status = string.match(stdout, "([%d]+)%%.*%[([%l]*)")
				notif_id.volume = utils.toast("Increase", {
					title = "Volume " .. vol_now.perc .. "% [" .. string.upper(vol_now.status) .. "]",
					position = "bottom_right",
					replaces_id = notif_id.volume
				}).id
			end)
		end),
	awful.key({  }, "XF86AudioLowerVolume",
		function ()
			awful.util.spawn("amixer -q set Master 1%-")

			async.request('amixer get Master', function(file_out)
				local stdout = file_out:read("*all")
				file_out:close()

				local vol_now = {}
				vol_now.perc, vol_now.status = string.match(stdout, "([%d]+)%%.*%[([%l]*)")
				notif_id.volume = utils.toast("Decrease", {
					title = "Volume " .. vol_now.perc .. "% [" .. string.upper(vol_now.status) .. "]",
					position = "bottom_right",
					replaces_id = notif_id.volume
				}).id
			end)
		end),
	awful.key({  }, "XF86AudioMute",
		function ()
			awful.util.spawn("amixer -q set Master playback toggle")

			async.request('amixer get Master', function(file_out)
				local stdout = file_out:read("*all")
				file_out:close()

				local vol_now = {}
				vol_now.perc, vol_now.status = string.match(stdout, "([%d]+)%%.*%[([%l]*)")
				notif_id.volume = utils.toast( vol_now.status == "on" and "Unmute" or "Mute", {
					title = "Volume " .. vol_now.perc .. "% [" .. string.upper(vol_now.status) .. "]",
					position = "bottom_right",
					replaces_id = notif_id.volume
				}).id
			end)
		end),



	-- Brightness control
	awful.key({  }, "XF86MonBrightnessDown",
		function ()
			awful.util.spawn("xbacklight -dec 5 -time 1")

			async.request('xbacklight -get', function(file_out)
				local perc = file_out:read("*line")
				file_out:close()

				perc = string.match(perc, "(%d+)%..*")
				notif_id.brightness = utils.toast("Decrease", {
					title = "Brightness " .. perc .. "%",
					position = "bottom_right",
					replaces_id = notif_id.brightness
				}).id
			end)
		end),
	awful.key({  }, "XF86MonBrightnessUp",
		function ()
			awful.util.spawn("xbacklight -inc 5 -time 1")

			async.request('xbacklight -get', function(file_out)
				local perc = file_out:read("*line")
				file_out:close()

				perc = string.match(perc, "(%d+)%..*")
				notif_id.brightness = utils.toast("Increase", {
					title = "Brightness " .. perc .. "%",
					position = "bottom_right",
					replaces_id = notif_id.brightness
				}).id
			end)
		end),



	-- Lock screen control
	awful.key({  }, "XF86Sleep",
		function ()
			awful.util.spawn("/home/lesell_b/.bin/my_i3lock")
			naughty.notify({
				text = "Locking...",
				timeout = 0.5
			})
		end),
	awful.key({  }, "Pause",
		function ()
			awful.util.spawn("/home/lesell_b/.bin/my_i3lock")
			naughty.notify({
				text = "Locking...",
				timeout = 0.5
			})
		end)
)




clientkeys = awful.util.table.join(
	awful.key({ modkey, "Shift"	}, "c",		function (c) c:kill()								end),
	awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle						),
	awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster())	end),
	awful.key({ modkey,			  }, "a",		function (c) c.ontop = not c.ontop				end),
	awful.key({ modkey,			  }, "n",
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
		awful.key({ modkey }, "#" .. i + 9, function ()
			local screen = mouse.screen
			local tag = awful.tag.gettags(screen)[i]
			if tag then
				awful.tag.viewonly(tag)
			end
		end),
		-- Toggle tag.
		awful.key({ modkey, "Control" }, "#" .. i + 9, function ()
			local screen = mouse.screen
			local tag = awful.tag.gettags(screen)[i]
			if tag then
				awful.tag.viewtoggle(tag)
			end
		end),
		-- Move client to tag.
		awful.key({ modkey, "Shift" }, "#" .. i + 9, function ()
			if client.focus then
				local tag = awful.tag.gettags(client.focus.screen)[i]
				if tag then
					awful.client.movetotag(tag)
				end
			end
		end),
		-- Toggle tag.
		awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9, function ()
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
	awful.button({ modkey }, 1, awful.mouse.client.move),
	awful.button({ modkey }, 3, awful.mouse.client.resize)
)

-- Set keys
root.keys(globalkeys)
-- }}}












loadFile("rc/rules")














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

		--[[ Titlebar definition ]]
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
	c.border_color = theme.border_focus
end)
client.connect_signal("unfocus", function(c)
	c.border_color = theme.border_normal
end)
-- }}}

-- make awesome to crash....
--utils.toast(debug(topbar[1]))

loadFile("rc/run_once")
