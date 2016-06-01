local awful = require("awful")
local beautiful = require("beautiful")
local global = require("global")

-- layouts
local lain = require("lain")
local treesome = require("treesome")

-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
local path = awful.util.getdir("config") .. "/themes/bewconfig/theme.lua"
beautiful.init(path)
global.theme = beautiful.get()

-- This is used later as the default terminal and editor to run.
terminal = "urxvt"
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
	lain.layout.termfair, -- WTF ?
	lain.layout.uselessfair,
	lain.layout.uselesstile,
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
	term = "urxvt",
	term2 = "xterm",
	webrowser = "firefox",
	webrowser2 = "luakit",
	termEditor = os.getenv("EDITOR") or "vim",
	rcEditor = os.getenv("EDITOR") or "vim",
}

-- }}}
