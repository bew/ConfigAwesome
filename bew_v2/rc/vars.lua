local awful = require("awful")
local theme = require("beautiful")
local global = require("global")


-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.
local path = awful.util.getdir("config") .. "/themes/bew_v2_theme/theme.lua"
theme.init(path)
global.theme = theme.get()

-- This is used later as the default terminal and editor to run.
terminal = "xterm"
termEditor = os.getenv("EDITOR") or "vim"
geditor = "subl3"
run_in_term_cmd = terminal .. " -e /bin/zsh -c "
editor_cmd = run_in_term_cmd .. termEditor

modkey = "Mod4"
altkey = "Mod1"

-- Table of layouts to cover with awful.layout.inc, order matters.
global.layouts = {
	awful.layout.suit.floating,
	awful.layout.suit.tile,
	awful.layout.suit.tile.left,
	awful.layout.suit.tile.bottom,
	awful.layout.suit.tile.top,
	awful.layout.suit.fair,
	awful.layout.suit.fair.horizontal,
	awful.layout.suit.max.fullscreen,
	awful.layout.suit.magnifier
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
	rcEditor = "/home/lesell_b/soft-portable/subl3"
}

-- }}}
