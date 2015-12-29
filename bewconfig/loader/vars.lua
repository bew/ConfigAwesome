local awful = require("awful")
local beautiful = require("beautiful")
local global = require("global")
local lain = require("lain") --for layout
local treesome = require("treesome") --for layout

local utils = require("bewlib.utils")

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
local path = awful.util.getdir("config") .. "/themes/bewconfig/theme.lua"
beautiful.init(path)
global.theme = beautiful.get()

-- This is used later as the default terminal and editor to run.
terminal = "xterm"
geditor = "subl3"
run_in_term_cmd = terminal .. " -e /bin/zsh -c "

modkey = "Mod4"
altkey = "Mod1"

-- Table of layouts to cover with awful.layout.inc, order matters.
global.layouts = {
	awful.layout.suit.tile,
	--awful.layout.suit.tile.left,
	awful.layout.suit.tile.bottom,
	--awful.layout.suit.tile.top,
	awful.layout.suit.fair,
	awful.layout.suit.fair.horizontal,
	awful.layout.suit.floating,
	--lain.layout.termfair, -- WTF ?
	--lain.layout.uselessfair,
	--lain.layout.uselesstile
	treesome,
}

local config = {}
global.config = config

config.default = {
	titlebar = {
		show = false
	}
}

config.apps = {
	term = "xterm",
	term2 = "urxvt",
	webrowser = "chromium",
	webrowser2 = "luakit",
	termEditor = os.getenv("EDITOR") or "vim",
	rcEditor = os.getenv("HOME") .. "/soft-portable/subl3"
}

const = {
	mouseLeft = 1,
	mouseRight = 2,
	mouseMiddle = 3,
	mouseScrollUp = 4,
	mouseScrollDown = 5,
}

-- }}}
