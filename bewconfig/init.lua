--[[

Awesome WM config

- by Bew78LesellB alias bew -

Starting date ~ 2015-01
Last update Wed Apr 15 16:00:29 CEST 2015

--]]

-- Grab environnement
--local std = {
--	debug = debug,
--}

local capi = {
	timer = timer,
	tag = tag,
	client = client,
	awesome = awesome,
	key = key,
	mouse = mouse,
	screen = screen,
	keygrabber = keygrabber,
}

-- Standard awesome library
local awful = require("awful")

-- Widget and layout library
local wibox = require("wibox")

-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")

local gears = require("gears")


-- Autofocus (when changing tag/screen/etc or add/delete client/tag)
require("awful.autofocus")

local scratch = require("scratch")

local global = require("global")

local MsgPack = require("MessagePack") -- used for config backup

--[[ My lib ]]--
local utils = require("bewlib.utils")
local Keymap = require("bewlib.keymap")
local Const = require("bewlib.const")
local Command = require("bewlib.command")
local Eventemitter = require("bewlib.eventemitter")

local Remote = require("bewlib.remote")


local function loadFile(file)
	local path = global.confInfos.path .. "/" .. file .. ".lua"

	-- Execute the file
	local success, err = pcall(dofile, path)
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


-- Init Battery System
------------------------------------------

local Battery = require("bewlib.computer.battery")
Battery.init({update = 2})

Eventemitter.on("config::load", function()
	Battery:emit("update")
end)


Battery:on("status::changed", function(self, status)
	utils.toast("Status changed !!\n"
	.. "==> " .. status)
end)

-- Init Remote System
------------------------------------------

Remote.init("socket")

Eventemitter.on("socket", function(event, args)
	utils.toast.debug("get event socket")
	if not args then
		utils.toast.debug("no arguments to event")
	else
		utils.toast.debug(args)
	end
end)

Eventemitter.on("network::status", function(ev, args)
	utils.toast.debug(args, { position = "bottom_left" })
end)




--Command.test()
-- Load some commands
loadFile("cmds/goto")



-- {{{ default tag
for screen in capi.screen do
	awful.tag({
		" blank ",
	}, screen, global.availableLayouts.tile)
end
-- }}}



-- Edit the config file
local function awesome_edit()
	local function spawnInTerm(cmd)
		local term = global.config.apps.term
		local termcmd = term .. " -e /bin/zsh -c "
		awful.util.spawn(termcmd .. "'" .. cmd .. "'")
	end

	spawnInTerm("cd " .. awful.util.getdir("config") .. " && " .. config.apps.termEditor .. " " .. "rc.lua")
end




-- {{{ Menu
-- Menubar configuration
menubar.utils.terminal = global.config.apps.term
menubar.geometry = {
	x = 0,
	y = 0,
	width = 1500
}
-- }}}



-- {{{ Wibox

-- Battery widget (in statusbar)
local wBatteryContainer
do
	wBatteryContainer = wibox.container.background()
	local wBattery = wibox.widget.textbox()
	wBattery:set_font("Awesome 10")

	wBatteryContainer:set_widget(wBattery)

	local function updateFunction()
		local status = Battery.infos.status
		local perc = Battery.infos.perc

		local statusIcon, bg
		if status == Battery.CHARGING then
			bg = "#43A047"
			statusIcon = ""
		else
			if perc <= 5 then
				-- low
				bg = "#F44336" -- red 500
				statusIcon = ""
			elseif perc <= 25 then
				-- getting low
				bg = "#FF9800" -- yellow
				statusIcon = ""
			elseif perc <= 50 then
				-- getting low
				bg = "#009688" -- teal
				statusIcon = ""
			elseif perc <= 75 then
				-- not bad
				bg = "#43A047" -- green
				statusIcon = ""
			else
				-- good
				bg = "#43A047" -- green
				statusIcon = ""
			end
		end

		wBatteryContainer:set_bg(bg)
		local percStyle = (perc == 100 and "FULL" or perc .. "%")
		wBattery:set_text(" | " .. statusIcon .. " " .. percStyle .. " | ")
	end

	Battery:on("percentage::changed", updateFunction)
	Battery:on("status::changed", updateFunction)
end


-- Battery Low widget (on top) (TODO: movable, like clients)
do
	-- Define widget

	local screen_geom = screen.primary.geometry
	local wBatteryLow = wibox({
		width = 300,
		height = 50,
		x = screen_geom.width / 2 - 100,
		y = screen_geom.height - 50,
		ontop = true,
	})

	wBatteryLow:setup {
		id = "w_back",

		layout = wibox.container.background,
		bg = "#FF6565",

		{
			id = "w_text",
			widget = wibox.widget.textbox,
			align = "center",
			font = "terminux 18",
		},
	}

	-- Add event reactions

	-- change this ?
	wBatteryLow:connect_signal("mouse::enter", function()
		wBatteryLow.opacity = 0.3
	end)

	wBatteryLow:connect_signal("mouse::leave", function()
		wBatteryLow.opacity = 1
	end)

	Battery:on("percentage::changed", function()
		local perc = Battery.infos.perc
		local status = Battery.infos.status

		utils.toast.debug(Battery.infos)

		if perc <= 20 and status == Battery.DISCHARGING then
			utils.toast.debug("show battery low")
			utils.log(wBatteryLow)
			wBatteryLow.visible = true
			local text = wBatteryLow.w_back.w_text
			text:set_text("BATTERY LOW (" .. perc .. "%)")
		else
			wBatteryLow.visible = false
		end
	end)

	Battery:on("status::changed", function()
		local status = Battery.infos.status

		if status == Battery.CHARGING then
			wBatteryLow.visible = false
		end
	end)
end


-- Mini cmus player
---------------------------------------------------------------

local wMusicCtrl, cmus_show_infos
do
	wMusicCtrl = wibox.widget.textbox("")
	wMusicCtrl:set_font("Awesome 10")

	local symbols = {
		play = "",
		pause = "",
		stop = "",
		--prev = "",
		--next = "",
	}
	-- init: after configuration load, launch a full status update


	local cmus_state  = {
		["status"] = "N/A",
		["file"]  = "N/A",
		["duration"]  = "N/A",
	}
	local function cmus_full_update()

		-- Get data from cmus 
		local f = io.popen("cmus-remote -Q")
		if not f then return end

		for line in f:lines() do
			for k, v in string.gmatch(line, "([%w]+)[%s](.*)$") do
				if cmus_state[k] then
					cmus_state[k] = v
				end
			end
		end
		f:close()

		cmus_state.filepath = cmus_state.file
		cmus_state.file = string.match(cmus_state.filepath, "([^/]*)$")
	end

	function cmus_show_infos()
		local str
		if cmus_state.status == "playing" then
			str = symbols.play .. " " .. cmus_state.file
		elseif cmus_state.status == "paused" then
			str = symbols.pause .. " " .. cmus_state.file
		elseif cmus_state.status == "stopped" then
			str = symbols.stop .. " " .. cmus_state.file
		else
			str = cmus_state.status
		end
		utils.toast(str, {title = "Cmus update"})
	end

	local function cmus_event_update(ev, args)
		--temp:
		cmus_full_update()

		cmus_show_infos()
	end

	Eventemitter.on("cmus", cmus_event_update)
	Eventemitter.on("config::load", cmus_event_update)
end


-- Network infos
------------------------------------------

local wNetwork
do
	-- container
	wNetwork = wibox.container.background()

	local wStatus = wibox.widget.textbox()
	wNetwork:set_widget(wStatus)

	--local last_status = ""
	local ssid = ""
	local ip
	local function update()
		local text = " NET : "

		if #ssid > 0 then
			text = text .. ssid .. " "
		end

		if ip then
			text = text .. "[IP]"
		else
			text = text .. "[NO IP]"
		end

		wStatus:set_text(text)
	end
	update()

	Eventemitter.on("network::dhcp", function(ev, args)
		local reason = args.reason

		if reason == "BOUND" or reason == "RENEW" then
			ip = args.new_ip_address
		else
			ip = false
		end
		if reason == "CARRIER" then
			ssid = args.ifssid
		elseif reason == "NOCARRIER" then
			ssid = ""
		end
		--last_status = reason
		update()
	end)
end


------------------------------------------------------------------------------------
-- Emergency widgets
------------------------------------------------------------------------------------

-- >> Reload
local wEmergencyReload = wibox.widget.imagebox( theme.getIcon("emergency", "rcReload"), true)
wEmergencyReload:buttons(awful.util.table.join(
awful.button({}, 1, function ()
	awesome.restart()
end)
))

-- >> Edit
local wEmergencyEdit = wibox.widget.imagebox( theme.getIcon("emergency", "rcEdit"), true)
wEmergencyEdit:buttons(awful.util.table.join(
awful.button({}, 1, function ()
	awesome_edit()
end)
))





-- Create a textclock widget
local wTime = wibox.widget.textclock(" %H:%M ")

-- Create a wibox for each screen and add it
local topbar = {}

-- Tag list config
local mytaglist = {}
mytaglist.buttons = awful.util.table.join(
awful.button({			}, 1, awful.tag.viewonly),
awful.button({ modkey 	}, 1, awful.client.movetotag)
)



-- TODO: This should be per workspace definition,
-- or this should define the look of the default workspace
awful.screen.connect_for_each_screen(function(s)

	local spacer = wibox.widget.textbox("      ")

	s.my_layout_switcher = awful.widget.layoutbox(s)
	s.my_layout_switcher:buttons(awful.util.table.join(
	awful.button({ }, 1, function () awful.layout.inc(global.layouts,  1) end),
	awful.button({ }, 3, function () awful.layout.inc(global.layouts, -1) end)
	))

	mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)
	s.mypromptbox = awful.widget.prompt()

	topbar[s] = awful.wibar({ position = "top", screen = s })

	topbar[s]:setup {
		layout = wibox.layout.align.horizontal,

		-- Left
		{
			layout = wibox.layout.fixed.horizontal,

			-- Emergency widgets
			{
				layout = wibox.layout.fixed.horizontal,

				{
					widget = wibox.widget.textbox,
					text = "RC: ",
				},
				wEmergencyReload,
				wEmergencyEdit,
			},
			spacer,
			mytaglist[s],
		},
		-- Middle
		s.mypromptbox,
		-- Right
		{
			layout = wibox.layout.fixed.horizontal,

			wibox.widget.systray(),
			wNetwork,
			wTime,
			wBatteryContainer,
			wMusicCtrl,
			s.my_layout_switcher,
		},
	}

end)
-- }}}




-- BatteryBar
do
	local screen_geom = screen.primary.geometry
	local wBatteryBar = wibox({
		x = 0,
		y = screen_geom.height - 5,
		height = 5,
		width = screen_geom.width,
		type = "desktop",
		visible = true,
		ontop = true,
	})

	wBatteryBar:setup {
		id = "w_bar",
		widget = wibox.widget.progressbar,

		max_value = 100,
		color = "#4CAF50", -- green 500
		background_color = "#F44336", -- red 500
	}

	Battery:on("percentage::changed", function()
		local perc = Battery.infos.perc
		wBatteryBar.w_bar:set_value(perc)
	end)
end


local wBatteryInfos = wibox({
	width = 300,
	height = 300,
	x = 300,
	y = 100,
	ontop = true,
})
wBatteryInfos:set_bg("#03A9F4")

-- populate wBatteryInfos's wibox content
do
	local w_perc = wibox.widget.textbox(Battery.infos.perc .. "%")
	w_perc:set_font("terminus 18")

	-- Header
	wBatteryInfos:setup {
		id = "w_main",
		layout = wibox.layout.align.vertical,

		{
			-- top
			layout = wibox.layout.align.horizontal,

			{
				-- Title
				widget = wibox.widget.textbox,
				text = "Battery infos",
				font = "terminus 18",
			},
			w_perc,
		},
		{
			-- middle
			id = "w_content",
			widget = wibox.widget.textbox,

			text = "Content loading",
			align = "center",
			font = "terminux 18",
		}
	}

	Battery:on("percentage::changed", function(self, perc)
		w_perc:set_text(perc .. "%")
	end)
end



local function showAcpi()
	local function grabber(_, _, _)
		-- I was trying to handle long-press, visually it works,
		-- but internally it really doesn't work :(
		capi.keygrabber.stop()
		wBatteryInfos.visible = false
	end

	wBatteryInfos.visible = true
	awful.spawn.easy_async("acpi -b", function(stdout)
		wBatteryInfos.w_main.w_content:set_text(stdout)
	end)

	capi.keygrabber.run(grabber)
end



local notif_id = {}

--TODO: Network.init(Network.Wrapper.Wpa({ iface = "wlo1" }))
local wpa_cli = {
	cmd = "wpa_cli -i wlo1 "
}

------------------------------------------------------------------------------------
-- {{{ Key bindings
------------------------------------------------------------------------------------

-- luacheck: ignore km
local km = Keymap.new("global")

-- TODO: theme switching on the fly
-- :theme <which> [<what> = all]
-- :theme dark statusbar
-- :theme light

-- :rc reload		(restart awesome)
-- :rc info

-- :lua <luacode>		(edit in vim ?)
km:add({
	ctrl = { mod = "M", key = "r" },
	press = function ()
		awful.prompt.run({
			prompt = "   >>> Run Lua code: ",
			textbox = awful.screen.focused().mypromptbox.widget,
			exe_callback = function(...)
				local ret = awful.util.eval(...)
				utils.toast.debug(ret, {title = "Lua code result :"})
			end,
			history_path = awful.util.getdir("cache") .. "/history_eval",
		})
	end,
})


-- :battery info
km:add({
	ctrl = { mod = "M", key = "b" },
	press = showAcpi,
})

-- :guake
km:add({
	ctrl = { mod = "M", key = "y" },
	press = function()
		-- TODO: more customization on scratch drop, and persistance between awesome restart
		scratch.drop(global.config.apps.term, {vert = "bottom", sticky = true})
	end,
})

---------------------------------------------------------------
-- Tag navigaton
---------------------------------------------------------------

-- Enter in Tag management Mode
-- :mode manage tag				TODO: what is a mode ?
-- :mmt
km:add({
	ctrl = { mod = "MC", key = "t" },
	--press = Command.getFunction("mode.manage.tag")
	press = function()

	end,
})

-- Goto
-- :goto <what> <position/fuzzy> <filter>

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
	ctrl = { mod = "M", key = "j" },
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
	ctrl = { mod = "M", key = "k" },
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
	local tag = capi.mouse.screen.selected_tag
	awful.prompt.run({
		prompt = "Rename tag: ",
		textbox = awful.screen.focused().mypromptbox.widget,
		exe_callback = function(text)
			if text:len() > 0 then
				tag.name = " " .. text .. " "
			end
		end
	})
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
-- thoses commands should accept a client / range of clients to move
Command.register("move.client.left", function()
	if not capi.client.focus then return end

	local c = capi.client.focus
	local tag = c.screen.selected_tag
	local new_idx = awful.util.cycle(#c.screen.tags, tag.index - 1)

	local new_tag = c.screen.tags[new_idx]

	c:move_to_tag(new_tag)
	new_tag:view_only()
	capi.client.focus = c
end)

Command.register("move.client.right", function()
	if not capi.client.focus then return end

	local c = capi.client.focus
	local tag = c.screen.selected_tag
	local new_idx = awful.util.cycle(#c.screen.tags, tag.index + 1)

	local new_tag = c.screen.tags[new_idx]

	c:move_to_tag(new_tag)
	new_tag:view_only()
	capi.client.focus = c
end)

Command.register("move.tag.left", function()
	local tag = capi.mouse.screen.selected_tag
	local new_idx = awful.util.cycle(#capi.mouse.screen.tags, tag.index - 1)

	tag.index = new_idx
	tag:view_only()
end)

Command.register("move.tag.right", function()
	local tag = capi.mouse.screen.selected_tag
	local new_idx = awful.util.cycle(#capi.mouse.screen.tags, tag.index + 1)

	tag.index = new_idx
	tag:view_only()
end)

Command.register("add.tag.right", function()
	local tag = capi.mouse.screen.selected_tag
	local new_idx = tag.index + 1
	local new_tag = awful.tag.add(" new ", {
		layout = tag.layout,
	})

	new_tag.index = new_idx
	new_tag:view_only()
end)

Command.register("delete.tag.current", function()
	local tag = capi.mouse.screen.selected_tag

	local confirm_notif = utils.toast("Y / N", {
		title = "Delete this tag ?",
	})

	local function delete_tag()
		tag:delete()
	end

	keygrabber.run(function(_, key, event)
		if event == "release" then return true end
		keygrabber.stop()
		naughty.destroy(confirm_notif)

		if key == "y" then
			delete_tag()
		end
		return true
	end)

end)

-- Move client to tag Left/Right
-- :move client tag left
-- :%mctl
km:add({
	ctrl = { mod = "MS", key = "Left" },
	press = Command.getFunction("move.client.left"),
})
km:add({
	ctrl = { mod = "MS", key = "j" },
	press = Command.getFunction("move.client.left"),
})

-- :move client tag right
-- :%mctr
km:add({
	ctrl = { mod = "MS", key = "Right" },
	press = Command.getFunction("move.client.right"),
})
km:add({
	ctrl = { mod = "MS", key = "k" },
	press = Command.getFunction("move.client.right"),
})

-- :move tag left
-- :%mtr
km:add({
	ctrl = { mod = "MS", key = "h" },
	press = Command.getFunction("move.tag.left"),
})

-- :move tag right
-- :%mtr
km:add({
	ctrl = { mod = "MS", key = "l" },
	press = Command.getFunction("move.tag.right"),
})


-- :add tag right
-- :%atr
km:add({
	ctrl = { mod = "M", key = "i" },
	press = Command.getFunction("add.tag.right"),
})

-- :delete tag
-- :delete tag current
-- :%dt
-- :%dtc
km:add({
	ctrl = { mod = "M", key = "d" },
	press = Command.getFunction("delete.tag.current"),
})


---------------------------------------------------------------
-- awesome management
---------------------------------------------------------------

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
		local zenity_cmd = zenity .. " && echo ok || echo cancel"

		utils.async.getFirstLine(zenity_cmd, function(stdout)
			utils.toast.debug(stdout)
			if stdout == "ok" then
				utils.toast.debug("QUIT !!!!!!!")
				awesome.quit()
			else
				--TODO: utils.toast.info
				--utils.toast.info("Awesome Quit canceled")
				utils.toast.debug("Awesome Quit canceled")
			end
		end)
	end,
})

--TODO:
-- :awesome quit force
-- => no confirmation dialog (and no short command form)

---------------------------------------------------------------
-- Client management
---------------------------------------------------------------

-- See ':goto'
-- goto / select:
-- - select : just focus
-- - goto : focus & raise

-- :select client next
km:add({
	ctrl = { mod = "MA", key = "j" },
	press = function ()
		awful.client.focus.byidx( 1)
		if client.focus then client.focus:raise() end
	end,
})
-- :select client previous
km:add({
	ctrl = { mod = "MA", key = "k" },
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
-- :find <what> [<filter> = all]
-- :find client
-- :find client all      -- same as above
-- :find client visible
-- :find client tiled
-- :find client floating
-- etc...
--
-- FIXME: why use find, over select/goto ?


-- In Layout Clients movement

-- :move <what> [<where> = (intag / layout)] [<position> = interactive]

-- :move client			(interactive mode: use hjkl to move the client)
-- :mc

-- :move client down
km:add({
	ctrl = { mod = "MSA", key = "j" },
	press = function()
		awful.client.swap.bydirection("down")
	end,
})
-- :move client up
km:add({
	ctrl = { mod = "MSA", key = "k" },
	press = function()
		awful.client.swap.bydirection("up")
	end,
})
-- :move client left
km:add({
	ctrl = { mod = "MSA", key = "h" },
	press = function()
		awful.client.swap.bydirection("left")
	end,

})
-- :move client right
km:add({
	ctrl = { mod = "MSA", key = "l" },
	press = function()
		awful.client.swap.bydirection("right")
	end,
})
--TODO: others
-- :move client first
-- :move client last

--TODO: swap :
-- :swap <what> <first> [<second> = current]
-- :swap client 3
-- :swap client current 3  --same
-- :swap client 3 current  --same

-- :goto client urgent
-- :gcu
km:add({
	ctrl = { mod = "M", key = "u" },
	press = awful.client.urgent.jumpto,
})

--TODO
-- :goto client 3
-- :gc3

---------------------------------------------------------------
-- Terminal spawn
---------------------------------------------------------------

-- FIXME: see ':run'
-- :spawn term
km:add({
	--ctrl = { mod = "M", key = "t" },
	ctrl = { mod = "M", key = "Return" }, -- fallback, I don't use it
	press = function () awful.spawn(global.config.apps.term) end,
})

---- :spawn term2
--km:add({
--	ctrl = { mod = "MA", key = "t" },
--	press = function () awful.util.spawn(global.config.apps.term2) end,
--})



---------------------------------------------------------------
-- Clients resize/move
---------------------------------------------------------------

-- TODO: can we resize something else than client ?
-- How about the ':mode resize' ?

-- :resize [<what> = client] [<filter-one> = current]
-- :resize
-- :resize client current -- same
-- :resize client mark

km:add({
	ctrl = { mod = "M", key = "l" },
	press = function () awful.tag.incmwfact( 0.05) end,
})
km:add({
	ctrl = { mod = "M", key = "h" },
	press = function () awful.tag.incmwfact(-0.05) end,
})

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



---------------------------------------------------------------
-- App Launcher
---------------------------------------------------------------

-- (replace :spawn ?)
-- :run				(interactive)
-- :run <what>
local applauncher = {}

-- key -> do_something
applauncher.binds = {
	x = {
		func = menubar.show,
		desc = "MENUBAR",
	},
	t = { cmd = config.apps.term },
	["²"] = { cmd = config.apps.term },
	f = { cmd = config.apps.webrowser },
}

-- TODO (maybe): reverse bind map : do_something -> { key, key, key, ... }

function applauncher.grabber(mod, key, event)
	if event == "release" then return true end
	capi.keygrabber.stop()

	local app_match = applauncher.binds[key]
	if not app_match then
		notif_id.applauncher = utils.toast("CANCEL", {
			title = "App Launcher",
			replaces_id = notif_id.applauncher,
		}).id
		return
	end

	notif_id.applauncher = utils.toast("Lanching " .. (app_match.cmd or app_match.desc or ""), {
		title = "App Launcher",
		replaces_id = notif_id.applauncher,
	}).id

	if app_match.cmd then -- bind is a cmd

		-- TODO: a more async spawn system
		awful.spawn(os.getenv("HOME") .. "/.bin/execit" .. " " .. app_match.cmd)

	elseif app_match.func then -- bind is a function
		app_match.func()
	end

end

-- App Launcher trigger
km:add({
	ctrl = { mod = "M", key = "x" },
	press = function()

		local help_str = ""
		for key, app_bind in pairs(applauncher.binds) do
			help_str = help_str .. "[ " .. key:upper() .. " ] → " .. (app_bind.desc or app_bind.cmd or "unknown") .. "\n"
		end
		help_str = help_str .. "\nPress any other key to cancel"

		notif_id.applauncher = utils.toast(help_str, {
			title = "App Launcher\n==============",
			timeout = 0,
			replaces_id = notif_id.applauncher,
		}).id

		capi.keygrabber.run(applauncher.grabber)
	end,
})

---------------------------------------------------------------
-- Wallpaper managment
---------------------------------------------------------------

-- :wall [<position> = last] [<group> = current]
-- :wall next
-- :wall prev
-- :wall last
-- :wall 1242
--
-- group can be :
-- * builtin group
-- > all
-- > last
-- > next
-- > prev
-- * named group
-- > fav(orite)
-- > black(list)
-- > theme:plane
-- > theme:asia

local currentWallpaperID = 1
local lastWallpaperID = 0
--- Select a new random wallpaper
km:add({
	ctrl = { mod = "M", key = "w" },
	press = function()
		local walls = theme.wallpapers
		local selectedID = math.random(#walls) or 1
		gears.wallpaper.maximized(walls[selectedID], capi.mouse.screen)
		notif_id.wallpaper = utils.toast("Changing wallpaper (" .. selectedID .. ")", { replaces_id = notif_id.wallpaper }).id

		lastWallpaperID = (lastWallpaperID == 0 and 1 or currentWallpaperID)
		currentWallpaperID = selectedID
	end,
})
--- Reselect the last wallpaper
km:add({
	ctrl = { mod = "MS", key = "w" },
	press = function()
		local selectedID = lastWallpaperID
		gears.wallpaper.maximized(theme.wallpapers[selectedID], capi.mouse.screen)
		notif_id.wallpaper = utils.toast("Changing wallpaper (" .. selectedID .. ")", { replaces_id = notif_id.wallpaper }).id

		currentWallpaperID, lastWallpaperID = lastWallpaperID, currentWallpaperID
	end,
})

-- manage wallpaper (currently, just show info)
km:add({
	ctrl = { mod = "MC", key = "w" },
	press = function()
		local infos = ""
		infos = infos .. "Current : [" .. currentWallpaperID .. "] " .. theme.wallpapers[currentWallpaperID] .. "\n"
		if lastWallpaperID > 0 then
			infos = infos .. "Last : [" .. lastWallpaperID .. "] " .. theme.wallpapers[lastWallpaperID]
		end
		notif_id.wallpaper = utils.toast(infos, { title = "=== Wallpaper Managment ===", replaces_id = notif_id.wallpaper }).id
	end,
})

---------------------------------------------------------------
-- Network management
---------------------------------------------------------------

-- Main Commands:
-- :net <action> <args>
-- :wifi <action> <args>

-- aliases
-- :wifi		(:wifi (enable / check ?))
-- :nowifi		(:wifi disable)

--- network checker
-- :net check [<host> = google.fr]
-- :ping		(alias of :net check)
km:add({
	ctrl = { mod = "M", key = "g" },
	press = function()
		local host = "google.fr"
		notif_id.ping = utils.toast("Sending 1 packet to " .. host, {
			position = "bottom_right",
			replaces_id = notif_id.ping
		}).id
		awful.spawn.easy_async("ping " .. host .. " -c 1 -w 1", function(stdout)
			notif_id.ping = utils.toast(stdout, {
				title = "===== Ping " .. host .. " result =====",
				position = "bottom_right",
				replaces_id = notif_id.ping
			}).id
		end)
	end,
})

--- network infos
-- :net info
-- :wifi info
km:add({
	ctrl = { mod = "M", key = "n" },
	press = function()
		awful.spawn.easy_async(wpa_cli.cmd .. "status", function(stdout)

			if not stdout or stdout == "" then
				utils.toast("Please start wpa_supplicant", { title = "Wifi is not ACTIVATED" })
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
-- :wifi connect [interactive]
-- :wifi connect <ssid/id>
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
				utils.async(wpa_cli.cmd .. "select_network " .. networks[key].id, function()
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
		awful.spawn.easy_async(wpa_cli.cmd .. "list_networks", function(stdout)
			notif_id.net_list = utils.toast(stdout, {
				title = "===== Networks saved list =====",
				replaces_id = notif_id.net_list
			}).id
		end)
	end,
})

---------------------------------------------------------------
-- Music
---------------------------------------------------------------

-- :musik <action>
-- :musik status
-- :musik info
-- :ms
-- :mi
km:add({
	ctrl = { mod = "MC", key = "m" },
	press = function()
		cmus_show_infos()
	end,
})

---------------------------------------------------------------
-- Volume
---------------------------------------------------------------

-- Volume control
-- :audio increase
-- :audio +
km:add({
	ctrl = { key = "XF86AudioRaiseVolume" },
	press = function ()
		awful.spawn.easy_async('pamixer --get-volume --increase 1', function(stdout)
			local perc = tonumber(stdout)

			notif_id.volume = utils.toast("Increase", {
				title = "Volume " .. perc .. "%",
				position = "bottom_right",
				replaces_id = notif_id.volume
			}).id
		end)
	end,
})
-- :audio decrease
-- :audio -
km:add({
	ctrl = { key = "XF86AudioLowerVolume" },
	press = function ()
		awful.spawn.easy_async('pamixer --get-volume --decrease 1', function(stdout)
			local perc = tonumber(stdout)

			notif_id.volume = utils.toast("Decrease", {
				title = "Volume " .. perc .. "%",
				position = "bottom_right",
				replaces_id = notif_id.volume
			}).id
		end)
	end,
})
-- :audio mute
-- :audio x
km:add({
	ctrl = { key = "XF86AudioMute" },
	press = function ()
		awful.spawn.easy_async('pamixer --get-mute --toggle-mute', function(stdout)
			local status = stdout

			notif_id.volume = utils.toast("Toggle Mute", {
				title = "Status : " .. status,
				position = "bottom_right",
				replaces_id = notif_id.volume
			}).id
		end)
	end,
})

---------------------------------------------------------------
-- Brightness
---------------------------------------------------------------

-- :bright <level>
-- :bright max
-- :bright med
-- :bright low
-- :bright auto		(possible ?)

-- :bright +
-- :brightness +
km:add({
	ctrl = { key = "XF86MonBrightnessDown" },
	press = function ()
		awful.util.spawn("xbacklight -dec 5 -time 1")

		utils.async.getFirstLine('xbacklight -get', function(stdout)
			local perc = string.match(stdout, "(%d+)%..*")
			if not perc then return end

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
			if not perc then return end

			notif_id.brightness = utils.toast("Increase", {
				title = "Brightness " .. perc .. "%",
				position = "bottom_right",
				replaces_id = notif_id.brightness
			}).id
		end)
	end,
})


---------------------------------------------------------------
-- Lockscreen
---------------------------------------------------------------

-- :lock
km:add({
	ctrl = { key = "Pause" },
	press = function ()
		awful.util.spawn_with_shell("i3locker")
		naughty.notify({
			text = "Locking...",
			timeout = 0.5
		})
	end,
})

---------------------------------------------------------------
-- Test keygrabber
---------------------------------------------------------------

km:add({
	ctrl = { mod = "MC", key = "k" },
	press = function()
		utils.toast("starting keygrabber tester")

		------------------------------------------
		-- outer keygrabber
		------------------------------------------

		local globAlphaNum
		globAlphaNum = awful.keygrabber.run(function(mod, key, event)

			if key == "Escape" then
				awful.keygrabber.stop(globAlphaNum)
				utils.toast("Exiting keygrabber tester")
			end

			if key == "a" then
				utils.toast.warning("starting nested keygrabber tester")
				local nbKeyGrabbed
				local specialKeys

				------------------------------------------
				-- inner keygrabber
				------------------------------------------

				-- luacheck: ignore mod key event
				specialKeys = awful.keygrabber.run(function(mod, key, event)
					if not nbKeyGrabbed then
						nbKeyGrabbed = 1
					else
						nbKeyGrabbed = nbKeyGrabbed + 1
					end

					if event == "release" and key == "q" then
						awful.keygrabber.stop(specialKeys)
						utils.toast.warning("Exiting nested keygrabber tester")
					end

					utils.toast.debug({mod, key, event}, {
						title = "============= " .. tostring(nbKeyGrabbed) .. " ============="
					})

					if key == "b" then
						return false
					end
				end)
			end

			utils.toast.debug({mod, key, event})
		end)

	end,
})

------------------------------------------
-- Test: Do something when modkey press/release
------------------------------------------

-- FIXME: Very weird behavior when this is activated...
-- > restart config
-- > try to kill client : will not always work => random somewhere

--km:add({
--	ctrl = { key = "Super_L" },
--	press = function()
--		utils.toast.debug("Modkey pressed")
--	end,
--})
--
--km:add({
--	ctrl = { mod = "M", key = "Super_L" },
--	release = function()
--		utils.toast.debug("Modkey released")
--	end,
--})

-- FIXME END

--km:add({
--	ctrl = { anyMod = true, key = "Super_L" }, --TODO: handle modifier = "any"
--	press = function()
--		utils.toast.debug("Modkey pressed")
--	end,
--	release = function()
--		utils.toast.debug("Modkey released")
--	end,
--})

------------------------------------------
-- End of definition of 'global' Keymap
------------------------------------------

km = nil
root.keys(Keymap.getCApiKeys("global"))

------------------------------------------------------------------------------------
-- Client's keymap
------------------------------------------------------------------------------------

-- :client <action>
-- :client kill
-- :client info
-- :client set <option> = <value>		(ex :client set opacity = 1)

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
		utils.toast("ON TOP : " .. tostring(c.ontop))
	end
}):add({
	ctrl = { mod = "M", key = "f" },
	press = function(self, c)
		awful.client.floating.toggle(c)
		utils.toast("FLOATING : " .. tostring(awful.client.floating.get(c)))
	end
}):add({
	ctrl = { mod = "M", key = "m" },
	press = function(self, c)
		c.maximized_horizontal = not c.maximized_horizontal
		c.maximized_vertical	= not c.maximized_vertical
		c:raise()
		utils.toast("MAXIMIZED : " .. tostring(c.maximized_vertical and c.maximized_horizontal and true or false))
	end
}):add({
	ctrl = { mod = "MA", key = "a" },
	press = function(self, c)
		c.sticky = not c.sticky
		utils.toast("STICKY : " .. tostring(c.sticky))
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


-- luacheck: ignore clientbuttons
-- FIXME: ugly..
clientbuttons = awful.util.table.join(
awful.button({}, 1, function (c)
	client.focus = c
	c:raise()
end),
awful.button({ modkey }, 1, awful.mouse.client.move),
awful.button({ modkey }, 3, awful.mouse.client.resize),
awful.button({ modkey }, 4, moreTransparency),
awful.button({ modkey }, 5, moreOpacity)
)



loadFile("rc/rules")



-- Signals

------------------------------------------------------------------------------------
-- {{{ Signals
------------------------------------------------------------------------------------

-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
	-- Enable sloppy focus
	c:connect_signal("mouse::enter", function()
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

---------------------------------------------------------------
-- Client focus / unfocus
---------------------------------------------------------------

client.connect_signal("focus", function(c)
	if type(theme.border_focus) == "function" then
		c.border_color = theme.border_focus(c)
	else
		c.border_color = theme.border_focus
	end

	c.border_width = theme.border_width
end)

client.connect_signal("unfocus", function(c)
	c.border_color = theme.border_normal
end)
-- }}}





------------------------------------------------------------------------------------
-- DEBUGING SIGNALS
------------------------------------------------------------------------------------

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
debugSignal(capi.awesome, "debug::error")

--debugSignal(client, "list")
--debugSignal(client, "manage")
--debugSignal(client, "unmanage")

local keyobj = capi.key({ modifiers = {modkey}, key = "e" })
root.keys(awful.util.table.join(root.keys(), { keyobj }))
debugSignal(keyobj, "press", true)
debugSignal(keyobj, "release", true)





-- put in event "config::load"
loadFile("rc/run_once")


---------------------------------------------------------------
-- Register some exit hooks -- TODO: move this..
---------------------------------------------------------------

capi.awesome.connect_signal("exit", function(restart)
	if restart then
		Eventemitter.emit("awesome::restart")
	else
		Eventemitter.emit("awesome::exit")
	end
end)


------------------------------------------------------------------------------------
-- Save / reload between awesome restart's
------------------------------------------------------------------------------------

local backup_file_path = "/tmp/awesome_backup_restart"

-- Save hook
---------------------------------------------------------------

Eventemitter.on("awesome::restart", function()
	
	utils.log("making backup")

	-- Construct backup
	------------------------------------------

	local backup = {
		screens = {},
	}

	for screen in capi.screen do
		utils.log("backup screen " .. tostring(screen))
		local screen_tags = screen.tags

		local screen_info = {
			--nb_tags = #screen_tags,
			tags = {},
		}

		for _, tag in ipairs(screen_tags) do
			local tag_info = {
				name = tag.name,
				selected = tag.selected,
				activated = tag.activated,
				layout = awful.tag.getproperty(tag, "layout").name,
			}
			table.insert(screen_info.tags, tag_info)
		end

		table.insert(backup.screens, screen.index, screen_info)
	end

	-- Save backup to tmp file
	------------------------------------------

	utils.log(backup)

	--local backup_serial = MsgPack.pack(backup)
	local status, backup_serial_or_error = pcall(MsgPack.pack, backup)
	if not status then
		utils.log("Error while packing backup through MsgPack: " .. backup_serial_or_error)
		return
	end
	local backup_serial = backup_serial_or_error

	local file, open_err = io.open(backup_file_path, "w")
	if not file then
		utils.log("Cannot open backup file : " .. open_err)
		return
	end

	do
		local ok, write_err = file:write(backup_serial)
		if not ok then
			utils.toast.error(write_err, { title = "Cannot write to backup file" })
		end
	end
	file:close()
	utils.log("backup finished")
end)

-- Restore hook
---------------------------------------------------------------

Eventemitter.on("config::load", function()

	-- Extract backup from tmp file
	------------------------------------------

	local backup

	do
		local file = io.open(backup_file_path, "r")
		if not file then
			return
		end

		local backup_serial = file:read("*a")
		local status, backup_or_error = pcall(MsgPack.unpack, backup_serial)
		if not status then
			utils.toast.error(backup_or_error, { title = "Cannot convert backup to Lua table" })
			return
		end
		backup = backup_or_error

		file:close()
	end

	-- Restore backup
	-- FIXME: put all this 'restore' code into a pcall to protect against failure ?
	------------------------------------------


	-- for each known screen
	for screen in capi.screen do
		local screen_info = backup.screens[screen.index]

		if not screen_info then
			goto continue
		end

		local before_restore_screen_tags = screen.tags

		for _, tag_info in ipairs(screen_info.tags) do
			local new_tag = awful.tag.add(tag_info.name, {
				screen = screen,
			})

			new_tag.selected = tag_info.selected
			new_tag.activated = tag_info.activated

			if global.availableLayouts[tag_info.layout] then
				awful.tag.setproperty(new_tag, "layout", global.availableLayouts[tag_info.layout])
			end
		end

		local after_restore_screen_tags = screen.tags

		if #after_restore_screen_tags > #before_restore_screen_tags then
			for _, old_tag in ipairs(before_restore_screen_tags) do
				old_tag:delete()
			end
		end

		::continue::
	end

end)

------------------------------------------------------------------------------------
-- Config loaded, trigger some events ;)
------------------------------------------------------------------------------------

Eventemitter.emit("config::load") -- give params ?


