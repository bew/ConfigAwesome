--[[

Awesome WM config

- by Bew78LesellB alias bew -

Starting date ~ 2015-01
Last update Wed Apr 15 16:00:29 CEST 2015

--]]

--assert(false, "testing")

--[[ Grab environnement ]]--
local capi = {
	timer = timer,
	client = client
}

-- Standard awesome library
local awful = require("awful")

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

local scratch = require("scratch")

local global = require("global")

--[[ My lib ]]--
local utils = require("bewlib.utils")
local Keymap = require("bewlib.keymap")
local Const = require("bewlib.const")


function loadFile(path)
	local success
	local result

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


--[[ === BEWLIB === ]]--

--[[ BATTERY ]]--
local Battery = require("bewlib.computer.battery")
Battery.init({update = 2})
Battery:on("percentage::changed", function(self, perc)
	--utils.toast("percentage changed !!")
end)

Battery:on("timeLeft::changed", function(self, time)
	local msg = self.infos.status == "Charging" and "full" or "empty"
	utils.toast("time to " .. msg .. ": " .. string.gsub(time, "(%d%d):(%d%d)", "%1h %2m"))
end)

Battery:on("status::changed", function(self, status)
	utils.toast("Status changed !!\n"
	.. "==> " .. status)
end)

--[[ COMMAND ]]--
local Command = require("bewlib.command")

--Command.test()
-- Load some commands
loadFile("cmds/goto")



-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
-- Each screen has its own tag table.
-- tags[s] = awful.tag({ "Web", "Divers", 3, 4, 5, "Code", "Code", 8, "Misc" }, s, layouts[1])
tags[1] = awful.tag({
	"| no name |",
	"| no name |",
	"| no name |",
	"| no name |",
}, s, global.layouts[1])
-- }}}



-- Edit the config file
awesome_edit = function ()
	local function spawnInTerm(cmd)
		awful.util.spawn(run_in_term_cmd .. "'" .. cmd .. "'")
	end

	spawnInTerm("cd " .. awful.util.getdir("config") .. " && " .. config.apps.termEditor .. " " .. "rc.lua")
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


--TODO: refactor, put it in bewlib managment system, and setup it here
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



-- {{{ Wibox
-- Create a textclock widget
wClock = awful.widget.textclock()

-- Create a wibox for each screen and add it
topbar = {}
bottombar = {}

wLayoutSwitcher = {}




-- Tag list config
mytaglist = {}
mytaglist.buttons = {
	awful.button({			}, 1, awful.tag.viewonly),
}




-- Battery widget
wBattery = wibox.widget.textbox()

Command.register("widget.updateBatteryStatus", function()
	wBattery:set_text(" | " .. Battery.infos.status .. " | " .. Battery.infos.perc .. "% | ")
end)

Battery:on("percentage::changed", Command.getFunction("widget.updateBatteryStatus"))
Battery:on("status::changed", Command.getFunction("widget.updateBatteryStatus"))
Command.run("widget.updateBatteryStatus")

-- TODO: recode a graph widget
wBatteryGraph = awful.widget.graph({})
wBatteryGraph:set_color("#424242")
wBatteryGraph:set_max_value(100)
utils.setInterval(function()
	wBatteryGraph:add_value(Battery.infos.perc)
	wBatteryGraph:add_value(Battery.infos.perc)
end, 60, true)




-- Emergency widgets
-- >> Reload
wEmergencyReload = wibox.widget.imagebox( theme.getIcon( "emergency", "rcReload" ), true)
wEmergencyReload:buttons(awful.util.table.join(
awful.button({}, 1, function ()
	awesome.restart()
end)
))

-- >> Edit
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
	right_layout:add(wBatteryGraph)
	right_layout:add(wBattery)
	right_layout:add(wLayoutSwitcher[s])

	local layTopbar = wibox.layout.align.horizontal()
	layTopbar:set_middle(tagsLayout)
	layTopbar:set_right(right_layout)
	layTopbar:set_left(layEmergency)

	topbar[s] = awful.wibox({ position = "top", screen = s })
	topbar[s]:set_widget(layTopbar)
end)
-- }}}




local wibox = require("wibox")

local w = wibox({
	width = 500,
	height = 500,
	x = 300,
	y = 100,
	ontop = true,
	opacity = 1
})
w:set_bg("#03A9F4")

local txtContent = wibox.widget.textbox("Content loading...") --degeuuuuuu
local txtFooter = wibox.widget.textbox("Date loading...") --degeuuuuuu
function toggle_w()
	w.visible = not w.visible
	utils.async.getAll("acpi -b", function(stdout)
		txtContent:set_text(stdout)
	end)
	txtFooter:set_text(os.date())
end

-- populate w's wibox content
do
	layMain = wibox.layout.align.vertical()

	layHeader = wibox.layout.align.horizontal()
	-- Header
	do -- Title
		local text = wibox.widget.textbox("Battery infos")
		text:set_font("terminux 18")
		layHeader:set_middle(text)
	end
	do -- battery level
		local text = wibox.widget.textbox(Battery.infos.perc .. "%")
		text:set_font("terminux 18")
		layHeader:set_right(text)

		Battery:on("percentage::changed", function(self, perc)
			text:set_text(Battery.infos.perc .. "%")
		end)
	end
	layMain:set_top(layHeader)


	txtContent:set_align("center")
	txtContent:set_font("terminux 18")
	layMain:set_middle(txtContent)


	txtFooter:set_align("center")
	txtFooter:set_font("terminux 18")
	layMain:set_bottom(txtFooter)

	w:set_widget(layMain)
end






-- for ping:
local async = require("lain.asyncshell") --TODO: use utils.async


local notif_id = {}



-- Network management
local wpa_cli = {
	cmd = "wpa_cli -i wlo1 "
}

local wallpaper_toggle = {
	state = false,
	id_notif = nil
}


utils.toast.warning("Here is a test warning")


-- {{{ Key bindings
local km = Keymap.new("global")
-- :battery info
km:add({
	ctrl = { mod = "M", key = "b" },
	press = toggle_w,
	release = toggle_w,
})

-- :quake
km:add({
	ctrl = { mod = "M", key = "y" },
	press = function()
		scratch.drop("xterm", {vert = "bottom", sticky = true})
	end,
})

-- Tag navigaton

-- :goto tag prev
-- :goto tag previous
-- :gtp
km:add({
	ctrl = { mod = "M", key = "Left" },
	press = function()
		Command.run("goto.tag", {
			which = Const.PREVIOUS,
		})
	end
})
km:add({
	ctrl = { mod = "MA", key = "j" },
	press = function()
		Command.run("goto.tag", {
			which = Const.PREVIOUS,
		})
	end
})

-- :goto tag next
-- :gtn
km:add({
	ctrl = { mod = "M", key = "Right" },
	press = function()
		Command.run("goto.tag", {
			which = Const.NEXT,
		})
	end
})
km:add({
	ctrl = { mod = "MA", key = "k" },
	press = function()
		Command.run("goto.tag", {
			which = Const.NEXT,
		})
	end
})

-- :goto tag
-- :goto tag last
-- :gt
-- :gtll
km:add({
	ctrl = { mod = "M", key = "Escape" },
	press = function()
		Command.run("goto.tag", {
			which = Const.LAST,
		})
	end
})

-- Move client on tag Left/Right
-- :move client tag left
-- :%mctl
km:add({
	ctrl = { mod = "MS", key = "Left" },
	press = function ()
		if not client.focus then return end
		local c = client.focus
		local idx = awful.tag.getidx()
		local new_idx = (idx == 1 and #tags[c.screen] or idx - 1)

		awful.client.movetotag(tags[c.screen][new_idx])
		awful.tag.viewonly(tags[c.screen][new_idx])
		client.focus = c
	end,
})
km:add({
	ctrl = { mod = "MAS", key = "j" },
	press = function ()
		if not client.focus then return end
		local c = client.focus
		local idx = awful.tag.getidx()
		local new_idx = (idx == 1 and #tags[c.screen] or idx - 1)

		awful.client.movetotag(tags[c.screen][new_idx])
		awful.tag.viewonly(tags[c.screen][new_idx])
		client.focus = c
	end,
})

-- :move client tag right
-- :%mctr
km:add({
	ctrl = { mod = "MS", key = "Right" },
	press = function ()
		if not client.focus then return end
		local c = client.focus
		local idx = awful.tag.getidx()
		local new_idx = (idx == #tags[c.screen] and 1 or idx + 1)

		awful.client.movetotag(tags[c.screen][new_idx])
		awful.tag.viewonly(tags[c.screen][new_idx])
		client.focus = c
	end,
})
km:add({
	ctrl = { mod = "MAS", key = "k" },
	press = function ()
		if not client.focus then return end
		local c = client.focus
		local idx = awful.tag.getidx()
		local new_idx = (idx == #tags[c.screen] and 1 or idx + 1)

		awful.client.movetotag(tags[c.screen][new_idx])
		awful.tag.viewonly(tags[c.screen][new_idx])
		client.focus = c
	end,
})


-- awesome management

-- :awesome restart
-- :ar
km:add({
	ctrl = { mod = "MC", key = "r" },
	press = awesome.restart,
})

-- :awesome quit
-- :aq
km:add({
	ctrl = { mod = "MC", key = "q" },
	press = awesome.quit,
})


-- client selection
-- :select client next
km:add({
	ctrl = { mod = "M", key = "j" },
	press = function ()
		awful.client.focus.byidx( 1)
		if client.focus then client.focus:raise() end
	end,
})
-- :select client previous
km:add({
	ctrl = { mod = "M", key = "k" },
	press = function ()
		awful.client.focus.byidx(-1)
		if client.focus then client.focus:raise() end
	end,
})
-- select last
-- :select client last
-- :select client
km:add({
	ctrl = { mod = "M", key = "Tab" },
	press = function ()
		awful.client.focus.history.previous()
		if client.focus then
			client.focus:raise()
		end
	end,
})


-- In Layout Clients movement

-- :move client			(then use hjkl to move the client)
-- :mc
km:add({
	ctrl = { mod = "MS", key = "j" },
	press = function()
		awful.client.swap.byidx( 1)
	end,
})
km:add({
	ctrl = { mod = "MS", key = "k" },
	press = function()
		awful.client.swap.byidx(-1)
	end,
})

-- Goto client
-- :goto client urgent
-- :gcu
km:add({
	ctrl = { mod = "M", key = "u" },
	press = awful.client.urgent.jumpto,
})


-- Apps spawning
-- :spawn term
km:add({
	ctrl = { mod = "M", key = "t" },
	press = function () awful.util.spawn(global.config.apps.term) end,
})
-- :spawn term2
km:add({
	ctrl = { mod = "MA", key = "t" },
	press = function () awful.util.spawn(global.config.apps.term2) end,
})



-- Clients resize/move

-- :resize <what> <which>
-- :resize client current
-- :resize client mark		or		:resize mark client			????TODO
-- :resize			(default=client)
km:add({
	ctrl = { mod = "M", key = "l" },
	press = function () awful.tag.incmwfact( 0.05) end,
})
km:add({
	ctrl = { mod = "M", key = "h" },
	press = function () awful.tag.incmwfact(-0.05) end,
})

km:add({
	ctrl = { mod = "MS", key = "h" },
	press = function () awful.tag.incnmaster( 1) end,
})
km:add({
	ctrl = { mod = "MS", key = "l" },
	press = function () awful.tag.incnmaster(-1) end,
})

km:add({
	ctrl = { mod = "MC", key = "h" },
	press = function () awful.tag.incncol( 1) end,
})
km:add({
	ctrl = { mod = "MC", key = "l" },
	press = function () awful.tag.incncol(-1) end,
})



-- switch layout

-- :layout next
km:add({
	ctrl = { mod = "M", key = "space" },
	press = function () awful.layout.inc(global.layouts,  1) end,
})
-- :layout previous
km:add({
	ctrl = { mod = "MS", key = "space" },
	press = function () awful.layout.inc(global.layouts, -1) end,
})



-- Menubar
km:add({
	ctrl = { mod = "M", key = "x" },
	press = menubar.show,
})


-- Wallpaper managment
local wallpaper_id = 1;
km:add({
	ctrl = { mod = "M", key = "w" },
	press = function()
		wallpaper_id = awful.util.cycle(#theme.wallpapers, wallpaper_id + 1)
		gears.wallpaper.maximized(theme.wallpaper_dir .. theme.wallpapers[wallpaper_id], 1, true)
		notif_id.wallpaper = utils.toast("Changing wallpaper (" .. wallpaper_id .. ")", { replaces_id = notif_id.wallpaper }).id
	end,
})

-- Computer managment
-- :lock
km:add({
	ctrl = { mod = "M", key = "p" },
	press = lockAndSleep,
})


--##############################
--##### Network management #####
--##############################
-- Main Commands:
-- :wifi		(on)
-- :nowifi		(off)
-- :network <args>
-- :wifi <args>

--- network checker
-- :network check
-- :ping		(alias ?)
km:add({
	ctrl = { mod = "M", key = "g" },
	press = function()
		notif_id.ping = utils.toast("Sending 1 packet to google.fr", {
			position = "bottom_right",
			replaces_id = notif_id.ping
		}).id
		utils.async.getAll("ping google.fr -c 1 -w 1", function(stdout)
			notif_id.ping = utils.toast(stdout, {
				title = "===== Ping google.fr result =====",
				position = "bottom_right",
				replaces_id = notif_id.ping 
			}).id
		end)
	end,
})

--- network infos
-- :network info
-- :wifi info
km:add({
	ctrl = { mod = "M", key = "n" },
	press = function()
		utils.async.getAll(wpa_cli.cmd .. "status", function(stdout)

			if not stdout or stdout == "" then
				utils.toast("Please run 'wifi' in a terminal", { title = "Wifi is not ACTIVATED" })
				return
			end

			local net_now = {
				status = string.match(stdout, "wpa_state=([%a_]*)"),
				ip_addr = string.match(stdout, "ip_address=([%d]+%.[%d]+%.[%d]+%.[%d]+)")
			}
			notif_id.net_info = utils.toast("\n" .. stdout, {
				title = net_now.status .. "  -  " .. (net_now.ip_addr and net_now.ip_addr or "NO IP"),
				replaces_id = notif_id.net_info
			}).id
		end)
	end,
})

--- network selector
-- :wifi connect
km:add({
	ctrl = { mod = "MC", key = "n" },
	press = function()

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
				utils.async.justExec(wpa_cli.cmd .. "select_network " .. networks[key].id, function()
					notif_id.net_selector = utils.toast("Trying to connect...", {
						title = "Network '" .. networks[key].name .. "' selected",
						replaces_id = notif_id.net_selector
					}).id
				end)
			end
			return true
		end)
	end,
})

--- network saved list
-- :wifi list
km:add({
	ctrl = { mod = "MS", key = "n" },
	press = function()
		utils.async.getAll(wpa_cli.cmd .. "list_networks", function(stdout)
			notif_id.net_list = utils.toast(stdout, {
				title = "===== Networks saved list =====",
				replaces_id = notif_id.net_list
			}).id
		end)
	end,
})

---------------------------------------------------------------
------------------ FN keys ------------------------------------
---------------------------------------------------------------
-- ALSA volume control
-- :audio +
km:add({
	ctrl = { key = "XF86AudioRaiseVolume" },
	press = function ()
		awful.util.spawn("amixer -q set Master 1%+")

		utils.async.getAll('amixer get Master', function(stdout)
			local vol_now = {}

			vol_now.perc, vol_now.status = string.match(stdout, "([%d]+)%%.*%[([%l]*)")
			notif_id.volume = utils.toast("Increase", {
				title = "Volume " .. vol_now.perc .. "% [" .. string.upper(vol_now.status) .. "]",
				position = "bottom_right",
				replaces_id = notif_id.volume
			}).id
		end)
	end,
})
-- :audio -
km:add({
	ctrl = { key = "XF86AudioLowerVolume" },
	press = function ()
		awful.util.spawn("amixer -q set Master 1%-")

		utils.async.getAll('amixer get Master', function(stdout)
			local vol_now = {}

			vol_now.perc, vol_now.status = string.match(stdout, "([%d]+)%%.*%[([%l]*)")
			notif_id.volume = utils.toast("Increase", {
				title = "Volume " .. vol_now.perc .. "% [" .. string.upper(vol_now.status) .. "]",
				position = "bottom_right",
				replaces_id = notif_id.volume
			}).id
		end)
	end,
})
-- :audio x
km:add({
	ctrl = { key = "XF86AudioMute" },
	press = function ()
		awful.util.spawn("amixer -q set Master playback toggle")

		utils.async.getAll('amixer get Master', function(stdout)
			local vol_now = {}

			vol_now.perc, vol_now.status = string.match(stdout, "([%d]+)%%.*%[([%l]*)")
			notif_id.volume = utils.toast( vol_now.status == "on" and "Unmute" or "Mute", {
				title = "Volume " .. vol_now.perc .. "% [" .. string.upper(vol_now.status) .. "]",
				position = "bottom_right",
				replaces_id = notif_id.volume
			}).id
		end)
	end,
})


-- Brightness control
-- :brightness +
km:add({
	ctrl = { key = "XF86MonBrightnessDown" },
	press = function ()
		awful.util.spawn("xbacklight -dec 5 -time 1")

		utils.async.getFirstLine('xbacklight -get', function(stdout)
			local perc = string.match(stdout, "(%d+)%..*")

			notif_id.brightness = utils.toast("Decrease", {
				title = "Brightness " .. perc .. "%",
				position = "bottom_right",
				replaces_id = notif_id.brightness
			}).id
		end)
	end,
})
-- :brightness -
km:add({
	ctrl = { key = "XF86MonBrightnessUp" },
	press = function ()
		awful.util.spawn("xbacklight -inc 5 -time 1")

		utils.async.getFirstLine('xbacklight -get', function(stdout)
			local perc = string.match(stdout, "(%d+)%..*")

			notif_id.brightness = utils.toast("Increase", {
				title = "Brightness " .. perc .. "%",
				position = "bottom_right",
				replaces_id = notif_id.brightness
			}).id
		end)
	end,
})


-- Lock screen control
-- :lock
km:add({
	ctrl = { key = "Pause" },
	press = function ()
		awful.util.spawn("/home/lesell_b/.bin/my_i3lock")
		naughty.notify({
			text = "Locking...",
			timeout = 0.5
		})
	end,
})
-- End of definition of 'global' Keymap
km = nil

root.keys(Keymap.apply("global"))


-- Base keymap for clients
Keymap.new("client"):add({
	ctrl = { mod = "MS", key = "c" },
	press = function(c)
		c:kill()
	end,
}):add({
	ctrl = { mod = "M", key = "a" },
	press = function(c)
		c.ontop = not c.ontop
	end
}):add({
	ctrl = { mod = "M", key = "f" },
	press = function(c)
		awful.client.floating.toggle(c)
	end
}):add({
	ctrl = { mod = "M", key = "m" },
	press = function (c)
		c.maximized_horizontal = not c.maximized_horizontal
		c.maximized_vertical	= not c.maximized_vertical
	end
})





clientbuttons = awful.util.table.join(
awful.button({			}, 1, function (c)
	client.focus = c; c:raise()
end),
awful.button({ modkey }, 1, awful.mouse.client.move),
awful.button({ modkey }, 3, awful.mouse.client.resize)
)













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

loadFile("rc/run_once")
