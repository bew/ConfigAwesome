--[[

Awesome WM config

- by Bew78LesellB alias bew -

Starting date ~ 2015-01
Last update Wed Apr 15 16:00:29 CEST 2015

--]]

--assert(false, "testing")

--[[ Grab environnement ]]--
local std = {
	debug = debug,
}

local capi = {
	timer = timer,
	client = client,
	awesome = awesome,
	key = key,
	mouse = mouse,
	screen = screen,
}

-- Standard awesome library
local awful = require("awful")

-- Widget and layout library
local wibox = require("wibox")

-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")

local lain = require("lain")
local gears = require("gears")


-- Autofocus (when changing tag/screen/etc or add/delete client/tag)
require("awful.autofocus")

local scratch = require("scratch")

local global = require("global")

--[[ My lib ]]--
local utils = require("bewlib.utils")
local Keymap = require("bewlib.keymap")
local Const = require("bewlib.const")
local Command = require("bewlib.command")
local Eventemitter = require("bewlib.eventemitter")

local Remote = require("bewlib.remote")

Remote.init("socket")

function loadFile(path)
	local success
	local result

	local path = global.confInfos.path .. "/" .. path .. ".lua"

	-- Execute the file
	local success, err = pcall(function() return dofile(path) end)
	if not success then
		naughty.notify({
			title = "Error while loading file",
			text = "When loading `" .. path .. "`, got the following error:\n" .. err,
			preset = naughty.config.presets.critical
		})
		return print("E: error loading RC file '" .. path .. "': " .. err)
	end

	return err
end

loadFile("loader/vars")
local theme = global.theme
local config = global.config

loadFile("loader/wallpaper")


--[[ === BEWLIB === ]]--

--[[ BATTERY ]]--
local Battery = require("bewlib.computer.battery")
Battery.init({update = 2})

Eventemitter.on("config::load", function()
	Battery:emit("update")
end)


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





--[[ REMOTE ]]--

--local Remote = require("bewlib.remote")

--Remote.init("socket")

local Eventemitter = require("bewlib.eventemitter")

Eventemitter.on("socket", function(event, args)
	utils.toast.debug("get event socket")
	utils.toast.debug(args)
end)

--[[ END REMOTE ]]--




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
	"       ",
	"| no name |",
	"       ",
	"| no name |",
	"       ",
	"| no name |",
	"       ",
	"| no name |",
	"       ",
	"| no name |",
	"       ",
	"| no name |",
}, s, global.layouts[1])
-- }}}

-- Edit the config file
function awesome_edit()
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



-- {{{ Wibox
-- Create a textclock widget
wClock = awful.widget.textclock()

-- Create a wibox for each screen and add it
topbar = {}
bottombar = {}

wLayoutSwitcher = {}




-- Tag list config
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
awful.button({			}, 1, awful.tag.viewonly),
awful.button({ modkey 	}, 1, awful.client.movetotag)
)




-- Battery widget (in statusbar)
local wBatteryContainer
do
	wBatteryContainer = wibox.widget.background()
	local wBattery = wibox.widget.textbox()
	wBattery:set_font("Awesome 10")

	wBatteryContainer:set_widget(wBattery)

	Command.register("widget.updateBatteryStatus", function()
		local status = Battery.infos.status
		local perc = Battery.infos.perc

		local statusStyle
		if status == Battery.DISCHARGING then
			if perc <= 5 then
				-- low
				wBatteryContainer:set_bg("#F44336") -- red 500
				statusStyle = ""
			elseif perc <= 25 then
				-- getting low
				wBatteryContainer:set_bg("#FF9800") -- yellow
				statusStyle = ""
			elseif perc <= 50 then
				-- getting low
				wBatteryContainer:set_bg("#FF9800") -- yellow
				statusStyle = ""
			elseif perc <= 75 then
				-- not bad
				wBatteryContainer:set_bg("#009688")
				statusStyle = ""
			else
				-- good
				wBatteryContainer:set_bg("#43A047")
				statusStyle = ""
			end
		else
			wBatteryContainer:set_bg("#43A047")
			statusStyle = ""
		end

		percStyle = (perc == 100 and "FULL" or perc .. "%")
		wBattery:set_text(" | " .. statusStyle .. " " .. percStyle .. " | ")
	end)


	Battery:on("percentage::changed", Command.getFunction("widget.updateBatteryStatus"))
	Battery:on("status::changed", Command.getFunction("widget.updateBatteryStatus"))
end


-- Battery Low widget (on top) (TODO: movable, like clients)
do
	-- Define widget

	local screen_geom = capi.screen[capi.mouse.screen].geometry
	local wBatteryLow = wibox({
		width = 300,
		height = 50,
		x = screen_geom.width / 2 - 100,
		y = screen_geom.height - 50,
		ontop = true,
		opacity = 1
	});
	wBatteryLow:set_bg("#FF6565")
	local wBatteryLowText = wibox.widget.textbox("BATTERY LOW") --pas beau...
	wBatteryLowText:set_align("center")
	wBatteryLowText:set_font("terminux 18")
	wBatteryLow:set_widget(wBatteryLowText)

	-- Add event reactions

	Battery:on("percentage::changed", function()
		local perc = Battery.infos.perc
		local status = Battery.infos.status

		if perc <= 10 and status == "Discharging" then
			wBatteryLow.visible = true
			wBatteryLowText:set_text("BATTERY LOW (" .. perc .. "%)")
		else
			wBatteryLow.visible = false
		end
	end)

	Battery:on("status::changed", function()
		local status = Battery.infos.status

		if status == "Charging" then
			wBatteryLow.visible = false
		end
	end)
end

-- TODO: recode a graph widget
wBatteryGraph = awful.widget.graph({})
wBatteryGraph:set_color("#424242")
wBatteryGraph:set_max_value(100)
utils.setInterval(function()
	wBatteryGraph:add_value(Battery.infos.perc)
end, 60, true)




-- Emergency widgets
-- >> Reload
local wEmergencyReload = wibox.widget.imagebox( theme.getIcon( "emergency", "rcReload" ), true)
wEmergencyReload:buttons(awful.util.table.join(
awful.button({}, 1, function ()
	awesome.restart()
end)
))

-- >> Edit
local wEmergencyEdit = wibox.widget.imagebox( theme.getIcon( "emergency", "rcEdit" ), true)
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

--temp
mypromptbox = {}

-- TODO: This should be per workspace definition,
-- or this should define the look of the default workspace
foreachScreen(function (s)

	-- Top Bar
	do
		wLayoutSwitcher[s] = awful.widget.layoutbox(s)
		wLayoutSwitcher[s]:buttons(awful.util.table.join(
		awful.button({ }, 1, function () awful.layout.inc(global.layouts,  1) end),
		awful.button({ }, 3, function () awful.layout.inc(global.layouts, -1) end)
		))

		mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)
		mypromptbox[s] = awful.widget.prompt()

		-- Emergency widgets
		local layEmergency = wibox.layout.fixed.horizontal()
		layEmergency:add( wibox.widget.textbox("RC: ") )
		layEmergency:add( wEmergencyReload )
		layEmergency:add( wEmergencyEdit )

		-- Tags layout
		local tagsLayout = wibox.layout.fixed.horizontal()
		tagsLayout:add(mytaglist[s])

		tagsLayout:add(mypromptbox[s]) --temp

		-- Widgets that are aligned to the right
		local right_layout = wibox.layout.fixed.horizontal()
		if s == 1 then
			right_layout:add(wibox.widget.systray())
		end
		right_layout:add(wClock)
		right_layout:add(wBatteryGraph)
		right_layout:add(wBatteryContainer)
		right_layout:add(wLayoutSwitcher[s])

		local layTopbar = wibox.layout.align.horizontal()
		layTopbar:set_middle(tagsLayout)
		layTopbar:set_right(right_layout)
		layTopbar:set_left(layEmergency)

		topbar[s] = awful.wibox({ position = "top", screen = s })
		topbar[s]:set_widget(layTopbar)
	end
end)
-- }}}




local wibox = require("wibox")

-- BatteryBar
do
	local screen_geom = capi.screen[capi.mouse.screen].geometry
	local wBatteryBar = wibox({
		x = 0,
		y = screen_geom.height - 5,
		height = 5,
		width = screen_geom.width,
		type = "desktop",
		visible = true,
		ontop = true,
	})

	local wBar = awful.widget.progressbar({
		height = 10,
	})
	wBar:set_max_value(100)
	wBar:set_color("#4CAF50") -- green 500
	wBar:set_background_color("#F44336") -- red 500

	wBatteryBar:set_widget(wBar)

	Battery:on("percentage::changed", function()
		local perc = Battery.infos.perc
		wBar:set_value(perc)
	end)
end



local w = wibox({
	width = 300,
	height = 300,
	x = 300,
	y = 100,
	ontop = true,
})
w:set_bg("#03A9F4")

local txtContent = wibox.widget.textbox("Content loading...") --degeuuuuuu
local txtFooter = wibox.widget.textbox("Date loading...") --degeuuuuuu
function toggle_w()
	w.visible = not w.visible
	if w.visible then
		utils.async.getAll("acpi -b", function(stdout)
			txtContent:set_text(stdout)
		end)
		txtFooter:set_text(os.date())
	end
end

-- populate w's wibox content
do
	local layMain = wibox.layout.align.vertical()

	local layHeader = wibox.layout.align.horizontal()
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





local notif_id = {}



-- Network management
--TODO: Network.Wrapper.Wpa
local wpa_cli = {
	cmd = "wpa_cli -i wlo1 "
}

local wallpaper_toggle = {
	state = false,
	id_notif = nil
}

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
		-- TODO: more customization on scratch drop, and persistance between restart
		scratch.drop("xterm", {vert = "bottom", sticky = true})
	end,
})

-- Tag navigaton

-- Enter in Tag management Mode
-- :mode manage tag
-- :mmt
km:add({
	ctrl = { mod = "MC", key = "t" },
	--press = Command.getFunction("mode.manage.tag")
})

-- :goto tag prev
-- :goto tag previous
-- :gtp
km:add({
	ctrl = { mod = "M", key = "Left" },
	press = function() -- TODO: Command.getFunction("goto.tag", { which = Const.PREVIOUS, })
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




--TODO: move this command
Command.register("rename.tag", function()
	local tag = awful.tag.selected(mouse.screen)
	awful.prompt.run({ prompt="Rename tag: " }, mypromptbox[mouse.screen].widget,
	function(text)
		if text:len() > 0 then
			tag.name = " " .. text .. " "
		end
	end)
end)

-- :rename tag
-- :rename tag "My Tag"
-- :rename tag current "My Tag"
-- :rt
-- :rt "My Tag"
-- :rtc "My Tag"
km:add({
	ctrl = { mod = "MA", key = "r" },
	press = Command.getFunction("rename.tag"),
})


--TODO: move theses commands
Command.register("move.client.left", function()
	if not client.focus then return end
	local c = client.focus
	local idx = awful.tag.getidx()
	local new_idx = (idx == 1 and #tags[c.screen] or idx - 1)

	awful.client.movetotag(tags[c.screen][new_idx])
	awful.tag.viewonly(tags[c.screen][new_idx])
	client.focus = c
end)

Command.register("move.client.right", function()
	if not client.focus then return end
	local c = client.focus
	local idx = awful.tag.getidx()
	local new_idx = (idx == #tags[c.screen] and 1 or idx + 1)

	awful.client.movetotag(tags[c.screen][new_idx])
	awful.tag.viewonly(tags[c.screen][new_idx])
	client.focus = c
end)

-- Move client on tag Left/Right
-- :move client tag left
-- :%mctl
km:add({
	ctrl = { mod = "MS", key = "Left" },
	press = Command.getFunction("move.client.left"),
})
km:add({
	ctrl = { mod = "MAS", key = "j" },
	press = Command.getFunction("move.client.left"),
})

-- :move client tag right
-- :%mctr
km:add({
	ctrl = { mod = "MS", key = "Right" },
	press = Command.getFunction("move.client.right"),
})
km:add({
	ctrl = { mod = "MAS", key = "k" },
	press = Command.getFunction("move.client.right"),
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
	press = function()
		local zenity = 'zenity --question --text="Are you sure you want to quit Awesome ?" --ok-label="Quit" --cancel-label="Stay here" '
		local cmd = zenity .. " && echo ok || echo cancel"

		utils.async.getFirstLine(cmd, function(stdout)
			utils.toast.debug(stdout)
			if stdout == "ok" then
				utils.toast.debug("QUIT !!!!!!!")
				awesome.quit()
			else
				--utils.toast.info("Awesome Quit canceled")
				utils.toast.debug("Awesome Quit canceled (TODO: toast.info)")
			end
		end)
	end,
})

--TODO:
-- :awesome quit force
-- => no confirmation dialog (and no short command form)


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
-- :select client last
-- :select client    --this command will call :find client
km:add({
	ctrl = { mod = "M", key = "Tab" },
	press = function ()
		awful.client.focus.history.previous()
		if client.focus then
			client.focus:raise()
		end
	end,
})

--TODO: interactive finder (fuzzy ?) (with visual feedback as we type by marking matching client ?)
-- :find <what> <filter>
-- :find client
-- :find client all      -- same as above
-- :find client visible
-- :find client tiled
-- :find client floating
-- etc...


-- In Layout Clients movement

-- :move client			(interactive mode: use hjkl to move the client)
-- :mc

-- :move client down
km:add({
	ctrl = { mod = "MS", key = "j" },
	press = function()
		awful.client.swap.bydirection("down")
	end,
})
-- :move client up
km:add({
	ctrl = { mod = "MS", key = "k" },
	press = function()
		awful.client.swap.bydirection("up")
	end,
})
-- :move client left
km:add({
	ctrl = { mod = "MS", key = "h" },
	press = function()
		awful.client.swap.bydirection("left")
	end,
})
-- :move client right
km:add({
	ctrl = { mod = "MS", key = "l" },
	press = function()
		awful.client.swap.bydirection("right")
	end,
})
--TODO: others
-- :move client first
-- :move client last

--TODO: swap :
-- :swap client 3
-- :swap client current 3  --same
-- :swap client 3 current  --same

-- Goto client
-- :goto client urgent
-- :gcu
km:add({
	ctrl = { mod = "M", key = "u" },
	press = awful.client.urgent.jumpto,
})

--TODO
-- :goto client 3
-- :gc3


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
-- :resize client mark
-- :resize			(default=client)

km:add({
	ctrl = { mod = "M", key = "l" },
	press = function () awful.tag.incmwfact( 0.05) end,
})
km:add({
	ctrl = { mod = "M", key = "h" },
	press = function () awful.tag.incmwfact(-0.05) end,
})

-- See :move client
--km:add({
--	ctrl = { mod = "MS", key = "h" },
--	press = function () awful.tag.incnmaster( 1) end,
--})
--km:add({
--	ctrl = { mod = "MS", key = "l" },
--	press = function () awful.tag.incnmaster(-1) end,
--})

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
	press = function()
		menubar.show()
	end,
})


-- Wallpaper managment
local currentWallpaperID = 1
local lastWallpaperID = 0
--- Select a new random wallpaper
km:add({
	ctrl = { mod = "M", key = "w" },
	press = function()
		local walls = theme.wallpapers
		local selectedID = math.random(#walls) or 1
		gears.wallpaper.maximized(walls[selectedID], 1, true)
		notif_id.wallpaper = utils.toast("Changing wallpaper (" .. selectedID .. ")", { replaces_id = notif_id.wallpaper }).id

		lastWallpaperID = (lastWallpaperID == 0 and 1 or currentWallpaperID)
		currentWallpaperID = selectedID
	end,
})
--- Reselect the last wallpaper
km:add({
	ctrl = { mod = "MS", key = "w" },
	press = function()
		local walls = theme.wallpapers
		local selectedID = lastWallpaperID
		gears.wallpaper.maximized(theme.wallpapers[selectedID], 1, true)
		notif_id.wallpaper = utils.toast("Changing wallpaper (" .. selectedID .. ")", { replaces_id = notif_id.wallpaper }).id

		currentWallpaperID, lastWallpaperID = lastWallpaperID, currentWallpaperID
	end,
})

-- Computer managment (disabled)
-- :lock
--[[
km:add({
ctrl = { mod = "M", key = "p" },
press = lockAndSleep,
})
--]]


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

--- Music infos
-- :musik status
-- :musik infos
-- :ms
-- :mi
km:add({
	ctrl = { mod = "MA", key = "m" },
	press = function()
		utils.async.getAll("mpc status", function(stdout)
			notif_id.music_info = utils.toast(stdout, {
				title = "==== Current Track Status ====",
				position = "bottom_left",
				replaces_id = notif_id.music_info
			}).id
		end)
	end,
})

---------------------------------------------------------------
------------------ FN keys ------------------------------------
---------------------------------------------------------------
-- Volume control
-- :audio +
km:add({
	ctrl = { key = "XF86AudioRaiseVolume" },
	press = function ()
		utils.async.getAll('pamixer --get-volume --increase 1', function(stdout)
			local perc = tonumber(stdout)

			notif_id.volume = utils.toast("Increase", {
				title = "Volume " .. perc .. "%",
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
		utils.async.getAll('pamixer --get-volume --decrease 1', function(stdout)
			local perc = tonumber(stdout)

			notif_id.volume = utils.toast("Decrease", {
				title = "Volume " .. perc .. "%",
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
		utils.async.getAll('pamixer --get-mute --toggle-mute', function(stdout)
			local status = stdout

			notif_id.volume = utils.toast("Toggle Mute", {
				title = "Status : " .. status,
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

--for testing
km:add({
	ctrl = { mod = "M", key = "r" },
	press = function ()
		awful.prompt.run({ prompt = "   >>> Run Lua code: " },
		mypromptbox[mouse.screen].widget,
		function(...)
			local ret = awful.util.eval(...)
			utils.toast.debug(ret, {title = "Lua code result :"})
		end, nil,
		awful.util.getdir("cache") .. "/history_eval")
	end,
})

-- Test keygrabber
km:add({
	ctrl = { mod = "MC", key = "k" },
	press = function()
		utils.toast("starting keygrabber tester")
		local globAlphaNum
		globAlphaNum = awful.keygrabber.run(function(mod, key, event)
			--if event == "release" then return end -- no need to handle press & release simultaneously
			if key == "Escape" then
				awful.keygrabber.stop(globAlphaNum)
				utils.toast("Exiting keygrabber tester")
			end

			if key == "a" then
				utils.toast.warning("starting nested keygrabber tester")
				local numberOfKeyGrabbed
				local specialKeys
				specialKeys = awful.keygrabber.run(function(mod, key, event)
					if not numberOfKeyGrabbed then
						numberOfKeyGrabbed = 1
					else
						numberOfKeyGrabbed = numberOfKeyGrabbed + 1
					end

					if event == "release" and key == "q" then
						awful.keygrabber.stop(specialKeys)
						utils.toast.warning("Exiting nested keygrabber tester")
					end

					local args = {mod, key, event}
					utils.toast.debug(args, { title = "============= " .. tostring(numberOfKeyGrabbed) .. " =============" })

					if key == "b" then
						return false
					end
				end)
			end

			local args = {mod, key, event}
			utils.toast.debug(args)
		end)

	end,
})

--km:add({
--	ctrl = { mod = "any", key = "Super_L" }, --TODO: handle modifier = "any"
--	press = function()
--		utils.toast.debug("Modkey pressed")
--	end,
--})

-- End of definition of 'global' Keymap
km = nil

root.keys(Keymap.getCApiKeys("global"))


-- Base keymap for clients
Keymap.new("client"):add({
	ctrl = { mod = "MS", key = "c" },
	press = function(self, c)
		c:kill()
	end,
}):add({
	ctrl = { mod = "M", key = "a" },
	press = function(self, c)
		c.ontop = not c.ontop
	end
}):add({
	ctrl = { mod = "M", key = "f" },
	press = function(self, c)
		awful.client.floating.toggle(c)
	end
}):add({
	ctrl = { mod = "M", key = "m" },
	press = function(self, c)
		c.maximized_horizontal = not c.maximized_horizontal
		c.maximized_vertical	= not c.maximized_vertical
		c.raise()
	end
}):add({
	ctrl = { mod = "M", key = "o" },
	press = function(self, c)
		c.opacity = (c.opacity == 1 and theme.client_default_opacity or 1)
	end
})

client.connect_signal("manage", function(cl)
	cl:keys(Keymap.getCApiKeys("client"))

	cl.opacity = theme.client_default_opacity
end)

local function moreOpacity(cl)
	local opacity = cl.opacity
	opacity = opacity + 0.02
	opacity = (opacity > 1 and 1 or opacity)
	cl.opacity = opacity
end

local function moreTransparency(cl)
	local opacity = cl.opacity
	opacity = opacity - 0.02
	opacity = (opacity < 0.4 and 0.4 or opacity)
	cl.opacity = opacity
end


clientbuttons = awful.util.table.join(
awful.button({			}, 1, function (c)
	client.focus = c; c:raise()
end),
awful.button({ modkey }, 1, awful.mouse.client.move),
awful.button({ modkey }, 3, awful.mouse.client.resize),
awful.button({ modkey }, 4, moreTransparency),
awful.button({ modkey }, 5, moreOpacity)
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
end)

client.connect_signal("focus", function(c)
	c.border_color = theme.border_focus
end)
client.connect_signal("unfocus", function(c)
	c.border_color = theme.border_normal
end)
-- }}}





-- DEBUGING SIGNALS
local function debugSignal(base, sigName, isMethod)
	local func = function(...)
		utils.toast.debug({...}, { title = sigName })
	end
	local function show()
		utils.toast.debug(nil, { title = sigName, position = "top_left" })
	end
	if isMethod then
		base:connect_signal(sigName, func)
		base:connect_signal(sigName, show)
	else
		base.connect_signal(sigName, func)
		base.connect_signal(sigName, show)
	end
end

--debugSignal(capi.awesome, "spawn::initiated")
--debugSignal(capi.awesome, "spawn::canceled")
--debugSignal(capi.awesome, "spawn::completed")
--debugSignal(capi.awesome, "spawn::timeout")
debugSignal(capi.awesome, "exit")

--debugSignal(client, "list")
--debugSignal(client, "manage")
--debugSignal(client, "unmanage")

local keyobj = capi.key({ modifiers = {modkey}, key = "e" })
root.keys(awful.util.table.join(root.keys(), { keyobj }))
debugSignal(keyobj, "press", true)
debugSignal(keyobj, "release", true)





-- put in event "config::load"
loadFile("rc/run_once")


Eventemitter.emit("config::load") -- give params ?

