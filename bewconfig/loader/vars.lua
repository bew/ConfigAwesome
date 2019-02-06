local awful = require("awful")
local beautiful = require("beautiful")
local global = require("global")

-- layouts
local treesome = require("treesome")

-- {{{ Variable definitions
local path = awful.util.getdir("config") .. "/themes/bewconfig/theme.lua"
beautiful.init(path)
global.theme = beautiful.get()

modkey = "Mod4"

awful.layout.suit.floating.resize_jump_to_corner = false

-- Table of layouts to cover with awful.layout.inc, order matters.
global.availableLayouts = {
    floating = awful.layout.suit.floating,
    tile = awful.layout.suit.tile,
    tileleft = awful.layout.suit.tile.left,
    tilebottom = awful.layout.suit.tile.bottom,
    tiletop = awful.layout.suit.tile.top,
    treesome = treesome,
}

global.layouts = {
    global.availableLayouts.tile,
    global.availableLayouts.tileleft,
    global.availableLayouts.tilebottom,
    global.availableLayouts.tiletop,
    global.availableLayouts.treesome,
    global.availableLayouts.floating,
}

awful.util.shell = "zsh"

local config = {}
global.config = config

config.default = {
    titlebar = {
        show = false
    }
}

config.apps = {
    term = "alacritty",
    term2 = "urxvt",
    webrowser = "firefox",
    webrowser2 = "vivaldi-stable",
    termEditor = os.getenv("EDITOR") or "vim",
    rcEditor = os.getenv("EDITOR") or "vim",
}

-- }}}
