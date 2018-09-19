--[[

Awesome WM config

- by Bew78LesellB alias bew -

Starting date ~ 2015-01
Last update Wed Apr 15 16:00:29 CEST 2015

--]]

-- Grab environnement
--local std = {
--    debug = debug,
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


-- Autofocus (when changing tag/screen/etc or add/delete client/tag)
require("awful.autofocus")

local global = require("global")

local MsgPack = require("mpack") -- used for config backup

--[[ My lib ]]--
local utils = require("bewlib.utils")
local Keymap = require("bewlib.keymap")
local Const = require("bewlib.const")
local Command = require("bewlib.command")
local Eventemitter = require("bewlib.eventemitter")

local Scratch = require("bewlib.scratch")

local Remote = require("bewlib.remote")

local function loadFile(file)
    local path = global.confInfos.path .. "/" .. file .. ".lua"

    -- Execute the file
    local success, err_or_result = pcall(dofile, path)
    if not success then
        naughty.notify({
            title = "Error while loading file",
            text = "When loading `" .. path .. "`, got the following error:\n" .. err_or_result,
            preset = naughty.config.presets.critical
        })
        return print("E: error loading RC file '" .. path .. "': " .. err_or_result)
    end

    return err_or_result
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


Battery:on("status::changed", function(_, status)
    utils.toast("Status changed !!\n"
    .. "==> " .. status)
end)

-- Init Remote System
------------------------------------------

Remote.init("socket")

Eventemitter.on("socket", function(_, args)
    utils.toast.debug("get event socket")
    if not args then
        utils.toast.debug("no arguments to event")
    else
        utils.toast.debug(args)
    end
end)

--Eventemitter.on("network::status", function(ev, args)
local notif_id_by_dhcp_interface = {}
Eventemitter.on("network::dhcp", function(_, args)
    local str = ""
    str = str .. args.interface .. ": " .. args.reason

    local notif = utils.toast(str, {
        position = "bottom_left",
        replaces_id = notif_id_by_dhcp_interface[args.interface]
    })
    notif_id_by_dhcp_interface[args.interface] = notif.id
end)

-- Init Scratch client config
------------------------------------------

Scratch.prog = global.config.apps.term
Scratch.default_options = {
    vert = "bottom",
    horiz = "center",
    width = 0.75,
    height = 0.50,
    sticky = true,
    ontop = true,
}





--Command.test()
-- Load some commands
loadFile("cmds/goto")



-- {{{ default tag for current & future screens
awful.screen.connect_for_each_screen(function (screen)
    local tag = awful.tag.add("blank", {
        layout = global.availableLayouts.tile,
        screen = screen,
        gap = 7,
    })
    tag:view_only()
end)
-- }}}



-- Edit the config file
local function awesome_edit()
    local function spawnInTerm(cmd)
        local term = global.config.apps.term
        local termcmd = term .. " -e /bin/zsh -c "
        awful.util.spawn(termcmd .. "'" .. cmd .. "'")
    end

    spawnInTerm("cd " .. global.confInfos.path .. " && " .. config.apps.termEditor .. " " .. "init.lua")
end




-- {{{ Menu
-- Menubar configuration
menubar.utils.terminal = global.config.apps.term
do
    local geo = capi.screen.primary.geometry
    menubar.geometry = {
        x = geo.x + 0,
        y = geo.y + 0,
        width = 1500
    }
    capi.screen.connect_signal("added", function(scr)
        -- update menubar coords
        local _geo = capi.screen.primary.geometry
        menubar.geometry = {
            x = _geo.x + 0,
            y = _geo.y + 0,
        }
    end)
end
-- }}}



-- {{{ Wibox

-- Battery widget (in statusbar)
local wBatteryContainer
do
    wBatteryContainer = wibox.container.background()
    local wBattery = wibox.widget.textbox()
    wBattery.font = "Awesome 10"

    wBatteryContainer.widget = wBattery

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

        wBatteryContainer.bg = bg
        local percStyle = (perc == 100 and "FULL" or perc .. "%")
        wBattery.text = " | " .. statusIcon .. " " .. percStyle .. " | "
    end

    Battery:on("percentage::changed", updateFunction)
    Battery:on("status::changed", updateFunction)
end


-- Battery Low widget (on top) (TODO: movable, like clients)
do
    -- Define widget

    local geo = capi.screen.primary.geometry
    local wBatteryLow = wibox({
        width = 300,
        height = 50,
        x = geo.x + geo.width / 2 - 100,
        y = geo.y + geo.height - 50,
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

        if perc <= 10 and status == Battery.DISCHARGING then
            wBatteryLow.visible = true
            local text = wBatteryLow.w_back.w_text
            text.text = "BATTERY LOW (" .. perc .. "%)"
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
--
-- TODO: on mouse:hover on the widget
--  => show player controls & progressbar (as tooltip?)
--

local wMusicCtrl, cmus_show_infos
do
    local symbols = {
        play = "",
        pause = "",
        stop = "",
        --prev = "",
        --next = "",
    }
    -- init: after configuration load, launch a full status update

    local cmus_state
    local function cmus_state_reset()
        cmus_state = {
            status = "N/A",
            file  = "N/A",
            duration  = "N/A",
            running = false,
        }
    end
    local function cmus_state_init()
        cmus_state_reset()

        -- TODO: start life pulser on cmus
        --  - if cmus is closed:
        --    => hide the wMusicCtrl widget
        --    => stop the life pulser
    end

    local function cmus_state_update()

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

    local function cmus_state_as_string()
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
        return str
    end


    cmus_state_init()

    wMusicCtrl = wibox.widget.textbox("")
    wMusicCtrl.font = "Awesome 8"

    local function cmus_widget_update()
        wMusicCtrl.text = cmus_state_as_string()

        if not wMusicCtrl.visible then
            wMusicCtrl.visible = true
        end
    end

    -- set 'global' function to update widget and show status
    function cmus_show_infos()
        local str = cmus_state_as_string()
        utils.toast(str, {title = "Cmus update"})

        cmus_widget_update()
    end

    Eventemitter.on("cmus", function()
        cmus_state_update()

        cmus_show_infos()
    end)
end


-- Network infos
------------------------------------------

local wNetwork
do
    -- container
    wNetwork = wibox.container.background()

    local wStatus = wibox.widget.textbox()
    wNetwork.widget = wStatus

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

        wStatus.text = text
    end
    update()

    Eventemitter.on("network::dhcp", function(_, args)
        if not (args.interface == 'wlo1' or args.interface == 'enp0s25') then
            return
        end

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


local function tag_rename(t)
    awful.prompt.run({
        prompt = "Rename tag: ",
        text = t.name,
        textbox = awful.screen.focused().mypromptbox.widget,
        exe_callback = function(text)
            t.name = text
        end
    })
end
Command.register("rename.tag", function()
    local t = capi.mouse.screen.selected_tag
    tag_rename(t)
end)




-- Create a textclock widget
local wTime = wibox.widget.textclock(" %H:%M ")

-- Create a wibox for each screen and add it
local topbar = {}

-- Tag list config
local mytaglist = {}
mytaglist.buttons = awful.util.table.join(
awful.button({}, 1, awful.tag.viewonly),
awful.button({ modkey }, 1, awful.client.movetotag),
awful.button({}, 3, function(t)
    if client.focus then
        client.focus:move_to_tag(t)
    end
end),
awful.button({}, 2, function(t)
    tag_rename(t)
end
)
)

local custom_taglist_update = loadFile('widget/taglist')

-- TODO: This should be per workspace definition,
-- or this should define the look of the default workspace
local spacer = wibox.widget.textbox("      ")
awful.screen.connect_for_each_screen(function(screen)

    screen.my_layout_switcher = awful.widget.layoutbox(screen)
    screen.my_layout_switcher:buttons(awful.util.table.join(
    awful.button({ }, 1, function () awful.layout.inc(global.layouts,  1) end),
    awful.button({ }, 3, function () awful.layout.inc(global.layouts, -1) end)
    ))

    mytaglist[screen] = awful.widget.taglist(screen,
    awful.widget.taglist.filter.all,
    mytaglist.buttons,
    nil,
    custom_taglist_update
    )
    screen.mypromptbox = awful.widget.prompt()

    topbar[screen] = awful.wibar({ position = "top", screen = screen })

    topbar[screen]:setup {
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
            mytaglist[screen],
        },
        -- Middle
        screen.mypromptbox,
        -- Right
        {
            layout = wibox.layout.fixed.horizontal,

            wMusicCtrl,
            spacer,
            wibox.widget.systray(),
            wNetwork,
            wTime,
            wBatteryContainer,
            screen.my_layout_switcher,
        },
    }

end)
-- }}}




-- BatteryBar
do
    local geo = capi.screen.primary.geometry
    local wBatteryBar = wibox({
        x = geo.x,
        y = geo.y + geo.height - 5,
        height = 5,
        width = geo.width,
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
        wBatteryBar.w_bar.value = perc
    end)
end


local wBatteryInfos
do
    local geo = capi.screen.primary.geometry
    wBatteryInfos = wibox({
        x = geo.x + 300,
        y = geo.y + 100,
        width = 700,
        height = 40,
        ontop = true,
    })
    wBatteryInfos.bg = "#2e7d32"

-- populate wBatteryInfos's wibox content
    local w_perc = wibox.widget.textbox(Battery.infos.perc .. "%")
    w_perc.font = "terminus 18"

    -- Header
    wBatteryInfos:setup {
        id = "w_content",
        widget = wibox.widget.textbox,

        text = "Content loading",
        align = "center",
        font = "terminux 18",
    }

    Battery:on("percentage::changed", function(_, perc)
        w_perc.text = perc .. "%"
    end)
end



local function toggle_acpi_infos()
    if wBatteryInfos.visible == false then
        awful.spawn.easy_async("acpi -b", function(stdout)
            wBatteryInfos.w_content.text = stdout
        end)
        local geo = awful.screen.focused().geometry
        wBatteryInfos.x = geo.x + 300
        wBatteryInfos.y = geo.y + 100
        wBatteryInfos.visible = true
    else
        wBatteryInfos.visible = false
    end
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

-- :rc reload    (restart awesome)
-- :rc info

-- :lua <luacode>    (edit in vim ?)
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
    press = toggle_acpi_infos,
})

--- Disable battery reoprting (usually used when ACPI fails)
km:add({
    ctrl = { mod = "MC", key = "b" },
    press = function ()
        Battery.disabled = not Battery.disabled
        utils.toast("Battery update disabled state: " .. tostring(Battery.disabled))
    end,
})

-- :scratch
km:add({
    ctrl = { mod = "M", key = "y" },
    press = function()
        Scratch.toggle()
    end,
})

-- Swap focused client with current scratch
-- :scratch swap
km:add({
    ctrl = { mod = "MS", key = "y" },
    press = function()
        local focus_c = capi.client.focus
        local old_scratch_client = Scratch.get_client()
        if focus_c == old_scratch_client then
            -- focused client is the scratch client
            Scratch.disable_current()

        elseif old_scratch_client then
            -- swap focused client with scratched client
            Scratch.swap_with(focus_c)

        else
            -- no current scratch client
            -- => just make focused client the scratch client
            Scratch.make_scratch(focus_c)
        end
    end,
})

---------------------------------------------------------------
-- Tag navigaton
---------------------------------------------------------------

-- Enter in Tag management Mode
-- :mode manage tag              TODO: what is a mode ?
-- :mmt
--km:add({
--    ctrl = { mod = "MC", key = "t" },
--    press = function()
--        change_mode("tag_management")
--    end,
--})

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


-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it work on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    -- View tag only.
    km:add({
        ctrl = { mod = "M", key = "#" .. i + 9 },
        description = "view tag #" .. i,
        press = function()
            local screen = awful.screen.focused()
            local tag = screen.tags[i]
            if tag then
                tag:view_only()
            end
        end
    })

    -- Move client to tag.
    km:add({
        ctrl = { mod = "MS", key = "#" .. i + 9 },
        description = "move focused client to tag #" .. i,
        press = function()
            if client.focus then
                local tag = client.focus.screen.tags[i]
                if tag then
                    client.focus:move_to_tag(tag)
                end
            end
        end
    })
end


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
    local scr = capi.mouse.screen
    local tag = scr.selected_tag
    local new_idx = awful.util.cycle(#scr.tags, tag.index + 1)

    tag.index = new_idx
    tag:view_only()
end)

Command.register("add.tag.right", function()
    local scr = capi.mouse.screen
    local tag = scr.selected_tag
    local new_idx = tag.index + 1
    local new_tag = awful.tag.add("", {
        layout = tag.layout,
        screen = scr,
        gap = 7,
    })

    new_tag.index = new_idx
    new_tag:view_only()
end)

Command.register("add.tag.left", function()
    local scr = capi.mouse.screen
    local tag = scr.selected_tag
    local new_idx = tag.index -- insert at current tag index
    local new_tag = awful.tag.add("", {
        layout = tag.layout,
        screen = scr,
        gap = 7,
    })

    new_tag.index = new_idx
    new_tag:view_only()
end)

Command.register("delete.tag.current", function()
    local scr = capi.mouse.screen
    local nb_tags = #scr.tags
    local tag = scr.selected_tag

    local confirm_notif = utils.toast("Y / N", {
        title = "Delete this tag ?",
    })

    local function try_delete_tag()
        if nb_tags == 1 then
            utils.toast.error("Cannot delete last tag!", {
                timeout = 5,
                traceback = false,
            })
        else
            if not tag:delete() then
                utils.toast.error("Cannot delete this tag\nIs the tag not empty?", {
                    timeout = 5,
                    traceback = false,
                })
            end
        end
    end

    capi.keygrabber.run(function(_, key, event)
        if event == "release" then return true end
        capi.keygrabber.stop()
        naughty.destroy(confirm_notif)

        if key == "y" then
            try_delete_tag()
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
    ctrl = { mod = "MS", key = "i" },
    press = Command.getFunction("add.tag.right"),
})

-- :add tag left
-- :%ath
km:add({
    ctrl = { mod = "M", key = "i" },
    press = Command.getFunction("add.tag.left"),
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
-- Screen
---------------------------------------------------------------

local gmath = require("gears.math")

local function get_screen_relative(offset)
    local focused_scr = awful.screen.focused()
    local new_index = gmath.cycle(capi.screen.count(), focused_scr.index + offset)
    return capi.screen[new_index]
end

-- Goto screen
------------------------------------------

-- :goto screen next
km:add({
    ctrl = { mod = "M", key = "s" },
    press = function()
        local new_screen = get_screen_relative(1)
        awful.screen.focus(new_screen)
    end
})

-- :goto screen prev
km:add({
    ctrl = { mod = "M", key = "q" },
    press = function()
        local new_screen = get_screen_relative(-1)
        awful.screen.focus(new_screen)
    end
})

-- TMP
km:add({
    ctrl = { mod = "MA", key = "m" },
    press = function()
        local new_screen = capi.screen.primary
        capi.mouse.coords({x = 10, y = 10})
    end
})

-- Move client to screen
------------------------------------------

-- :move screen next
km:add({
    ctrl = { mod = "MS", key = "s" },
    press = function()
        if capi.screen.count() == 1 then
            utils.toast("There is only 1 screen")
            return
        end

        local new_screen = get_screen_relative(1)
        capi.client.focus:move_to_screen(new_screen)
    end
})

-- :move screen prev
km:add({
    ctrl = { mod = "MS", key = "q" },
    press = function()
        if capi.screen.count() == 1 then
            utils.toast("There is only 1 screen")
            return
        end

        local new_screen = get_screen_relative(1)
        capi.client.focus:move_to_screen(new_screen)
    end
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
        local text = "Are you sure you want to quit Awesome ?"
        local zenity_cmd = 'zenity --question --text="' .. text .. '" --ok-label="Quit" --cancel-label="Stay here" '

        awful.spawn.easy_async(zenity_cmd, function(_, _, _, exit_code)
            if exit_code == 0 then
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

-- :move client            (interactive mode: use hjkl to move the client)
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
    press = function () awful.spawn(global.config.apps.term, {
        tag = capi.mouse.screen.selected_tag,
    }) end,
})



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
-- :run                (interactive)
-- :run <what>
local applauncher = {}

-- key -> do_something
applauncher.binds = {
    x = {
        func = menubar.show,
        desc = "MENUBAR",
    },
    [" "] = { cmd = config.apps.term },
    f = { cmd = config.apps.webrowser },
    v = { cmd = config.apps.webrowser2 },
    d = { cmd = "discord" },
}

-- TODO (maybe): reverse bind map : do_something -> { key, key, key, ... }

function applauncher.grabber(mod, key, event) -- luacheck: ignore mod
    if event == "release" then return true end
    capi.keygrabber.stop()

    local app_match = applauncher.binds[key]
    if not app_match then
        notif_id.applauncher = utils.toast("CANCEL - key:" .. key, {
            title = "App Launcher",
            replaces_id = notif_id.applauncher,
        }).id
        return
    end

    notif_id.applauncher = utils.toast("Launching " .. (app_match.cmd or app_match.desc or ""), {
        title = "App Launcher",
        replaces_id = notif_id.applauncher,
    }).id

    if app_match.cmd then -- bind is a cmd

        awful.spawn(app_match.cmd, {
            tag = capi.mouse.screen.selected_tag,
        })

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

        -- shouldn't be a Notification but a kind of dialog
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

--- Select a new random wallpaper
km:add({
    ctrl = { mod = "M", key = "w" },
    press = function()
        local screen = capi.mouse.screen

        screen.wallpaper_selector:next()
    end,
})
--- Reselect the last wallpaper
km:add({
    ctrl = { mod = "MS", key = "w" },
    press = function()
        local screen = capi.mouse.screen

        screen.wallpaper_selector:previous()
    end,
})

--- Show current wallpaper infos
km:add({
    ctrl = { mod = "MC", key = "w" },
    press = function()
        local screen = capi.mouse.screen

        local wall = screen.wallpaper_selector:current()
        utils.toast(wall, {
            title = "Current wallpaper",
        })
    end,
})

---------------------------------------------------------------
-- Network management
---------------------------------------------------------------

-- Main Commands:
-- :net <action> <args>
-- :wifi <action> <args>

-- aliases
-- :wifi        (:wifi (enable / check ?))
-- :nowifi      (:wifi disable)

--- network checker
-- :net check [<host> = google.fr]
-- :ping        (alias of :net check)
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
        capi.keygrabber.run(function(mod, key, event) -- luacheck: ignore mod
            if event == "release" then return true end
            capi.keygrabber.stop()
            naughty.destroy(help_notif)

            if networks[key] then
                awful.spawn.easy_async(wpa_cli.cmd .. "select_network " .. networks[key].id, function()
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

local function audio_volume_get(callback)
    awful.spawn.easy_async('pamixer --get-volume', function(stdout)
        local perc = tonumber(stdout)

        if callback then
            callback(perc)
        end
    end)
end

local function audio_volume_increase(by)
    awful.spawn.spawn('pamixer --increase ' .. by)
end

local function audio_volume_decrease(by)
    awful.spawn.spawn('pamixer --decrease ' .. by)
end

-- Helpers
------------------------------------------

local function audio_volume_show(message)
    audio_volume_get(function(perc)
        if not message then
            message = "Current level"
        end

        notif_id.volume = utils.toast(message, {
            title = "Volume " .. perc .. "%",
            position = "bottom_right",
            replaces_id = notif_id.volume,
        }).id
    end)
end

local function audio_volume_up_show(by)
    audio_volume_increase(by)

    utils.setTimeout(function()
        audio_volume_show("Increase by " .. by)
    end, 0.1)
end

local function audio_volume_down_show(by)
    audio_volume_decrease(by)
    utils.setTimeout(function()
        audio_volume_show("Decrease by " .. by)
    end, 0.1)
end

-- Bindings
------------------------------------------

-- Volume control
-- :audio inc[rease]
-- :audio +
km:add({
    ctrl = { key = "XF86AudioRaiseVolume" },
    press = function ()
        audio_volume_up_show(1)
    end,
})

-- :audio dec[rease]
-- :audio -
km:add({
    ctrl = { key = "XF86AudioLowerVolume" },
    press = function ()
        audio_volume_down_show(1)
    end,
})

-- :audio ++
km:add({
    ctrl = { mod = "S", key = "XF86AudioRaiseVolume" },
    press = function ()
        audio_volume_up_show(5)
    end,
})

-- :audio --
km:add({
    ctrl = { mod = "S", key = "XF86AudioLowerVolume" },
    press = function ()
        audio_volume_down_show(5)
    end,
})

-- :audio mute
-- :audio x
km:add({
    ctrl = { key = "XF86AudioMute" },
    press = function ()
        awful.spawn.easy_async('pamixer --toggle-mute', function()
            awful.spawn.easy_async('pamixer --get-mute', function(stdout)
                local status = string.gsub(stdout, "\n", "")
                local mute_str

                if status == "true" then
                    mute_str = "Mute"
                elseif status == "false" then
                    mute_str = "Unmute"
                else
                    mute_str = "Unknown mute status: " .. status
                end

                notif_id.volume = utils.toast(mute_str, {
                    position = "bottom_right",
                    replaces_id = notif_id.volume
                }).id
            end)
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
-- :bright auto        (possible ?)

-- Brightness controls
------------------------------------------

local function brightness_get(callback)
    awful.spawn.easy_async("light -G", function(stdout)
        local level = tonumber(stdout)

        if callback then
            callback(level)
        end
    end)
end

local function brightness_increase(by)
    awful.spawn("light -A " .. by)
end

local function brightness_decrease(by)
    awful.spawn("light -U " .. by)
end

-- Helpers
------------------------------------------

local function brightness_show(message)
    brightness_get(function(perc)
        if not message then
            message = "Current level"
        end

        notif_id.brightness = utils.toast(message, {
            title = "Brightness " .. perc .. "%",
            position = "bottom_right",
            replaces_id = notif_id.brightness,
        }).id
    end)
end

local function brightness_up_show(by)
    brightness_increase(by)
    brightness_show("Increase by " .. by)
end

local function brightness_down_show(by)
    brightness_decrease(by)
    brightness_show("Decrease by " .. by)
end

-- Bindings
------------------------------------------

-- :bright +
-- :brightness +
km:add({
    ctrl = { key = "XF86MonBrightnessDown" },
    press = function ()
        brightness_down_show(1)
    end,
})

-- :bright -
-- :brightness -
km:add({
    ctrl = { key = "XF86MonBrightnessUp" },
    press = function ()
        brightness_up_show(1)
    end,
})

-- :bright ++
-- :brightness ++
km:add({
    ctrl = { mod = "S", key = "XF86MonBrightnessDown" },
    press = function ()
        brightness_down_show(5)
    end,
})

-- :bright --
-- :brightness --
km:add({
    ctrl = { mod = "S", key = "XF86MonBrightnessUp" },
    press = function ()
        brightness_up_show(5)
    end,
})


---------------------------------------------------------------
-- Lockscreen
---------------------------------------------------------------

-- :lock
km:add({
    ctrl = { key = "Pause" },
    press = function ()
        naughty.notify({
            text = "Locking...",
            timeout = 0.5
        })
        awful.spawn.with_shell("i3colocker")
    end,
})

-- Lock & sleep
-- :sleep
km:add({
    ctrl = { mod = "C", key = "Pause" },
    press = function ()
        awful.spawn.with_shell("i3colocker")
        naughty.notify({
            text = "Sleeping...",
            timeout = 0.5
        })
        utils.setTimeout(function()
            awful.spawn.easy_async("systemctl suspend", function(stdout, stderr)
                utils.toast.debug({ out = stdout, err = stderr })
            end)
        end, 0.5)
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

        local outer_grabber
        outer_grabber = awful.keygrabber.run(function(mod, key, event)

            if key == "Escape" then
                awful.keygrabber.stop(outer_grabber)
                utils.toast("Exiting keygrabber tester")
            end

            if key == "a" then
                utils.toast.warning("starting nested keygrabber tester")
                local nbKeyGrabbed
                local inner_grabber

                ------------------------------------------
                -- inner keygrabber
                ------------------------------------------

                -- luacheck: ignore mod key event
                inner_grabber = awful.keygrabber.run(function(mod, key, event)
                    if not nbKeyGrabbed then
                        nbKeyGrabbed = 1
                    else
                        nbKeyGrabbed = nbKeyGrabbed + 1
                    end

                    if event == "release" and key == "q" then
                        awful.keygrabber.stop(inner_grabber)
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
--    ctrl = { key = "Super_L" },
--    press = function()
--        utils.toast.debug("Modkey pressed")
--    end,
--})
--
--km:add({
--    ctrl = { mod = "M", key = "Super_L" },
--    release = function()
--        utils.toast.debug("Modkey released")
--    end,
--})

-- FIXME END

--km:add({
--    ctrl = { anyMod = true, key = "Super_L" }, --TODO: handle mod = "any" or mod = "*"
--    press = function()
--        utils.toast.debug("Modkey pressed")
--    end,
--    release = function()
--        utils.toast.debug("Modkey released")
--    end,
--})

------------------------------------------
-- End of definition of 'global' Keymap
------------------------------------------

km = nil
root.keys(Keymap.getCApiKeys("global"))


awful.client.property.persist("locked", "boolean")


------------------------------------------------------------------------------------
-- Client's keymap
------------------------------------------------------------------------------------

local function refresh_border_color(c)

    if client.focus == c then
        if c.locked then
            c.border_color = theme.border_focus_when_locked
        else
            c.border_color = theme.border_focus
        end
    else
        if c.locked then
            c.border_color = theme.border_normal_when_locked
        else
            c.border_color = theme.border_normal
        end
    end

end



-- :client <action>
-- :client kill
-- :client info
-- :client set <option> = <value>        (ex :client set opacity = 1)

-- Base keymap for clients
Keymap.new("client"):add({
    ctrl = { mod = "MS", key = "c" },
    press = function(_, c)
        if c.locked then
            utils.toast.warning("The client is LOCKED. You need to unlock it first")
            return
        end

        c:kill()
    end,
}):add({
    ctrl = { mod = "MC", key = "l" },
    press = function(_, c)
        c.locked = not c.locked
        refresh_border_color(c)

        local action
        if c.locked then
            action = "LOCKED"
        else
            action = "UNLOCKED"
        end
        notif_id.client_locked = utils.toast(action, {
            replaces_id = notif_id.client_locked
        }).id
    end
}):add({
    ctrl = { mod = "M", key = "a" },
    press = function(_, c)
        c.ontop = not c.ontop
        notif_id.client_ontop = utils.toast("ON TOP : " .. tostring(c.ontop), {
            replaces_id = notif_id.client_ontop
        }).id
    end
}):add({
    ctrl = { mod = "M", key = "f" },
    press = function(_, c)
        awful.client.floating.toggle(c)
        notif_id.client_floating = utils.toast("FLOATING : " .. tostring(awful.client.floating.get(c)), {
            replaces_id = notif_id.client_floating
        }).id
    end
}):add({
    ctrl = { mod = "M", key = "m" },
    press = function(_, c)
        c.maximized = not c.maximized
        if c.maximized then
            c:raise()
        end
        notif_id.client_maximized = utils.toast("MAXIMIZED : " .. tostring(c.maximized), {
            replaces_id = notif_id.client_maximized
        }).id
    end
}):add({
    ctrl = { mod = "MA", key = "a" },
    press = function(_, c)
        c.sticky = not c.sticky
        notif_id.client_sticky = utils.toast("STICKY : " .. tostring(c.sticky), {
            replaces_id = notif_id.client_sticky
        }).id
    end
}):add({
    ctrl = { mod = "M", key = "o" },
    press = function(_, c)
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
capi.client.connect_signal("manage", function (c, startup)
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
    refresh_border_color(c)
    c.border_width = theme.border_width
end)

client.connect_signal("unfocus", function(c)
    refresh_border_color(c)
end)
-- }}}





------------------------------------------------------------------------------------
-- DEBUGING SIGNALS
------------------------------------------------------------------------------------

local function debugSignal(base, sigName, isMethod)
    local func = function(...)
        utils.toast.debug(utils.inspect({...}), {
            title = "Params for event " .. sigName
        })
    end
    local function show()
        utils.toast.debug(sigName, { position = "top_left" })
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

        local backup_raw = file:read("*a")
        local success, backup_or_error = pcall(MsgPack.unpack, backup_raw)
        if not success then
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
                gap = 7,
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


