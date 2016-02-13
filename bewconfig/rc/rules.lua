local awful = require("awful")
awful.rules = require("awful.rules")
local theme = require("beautiful")
local Keymap = require("bewlib.keymap")

-- {{{ Rules
awful.rules.rules = {

	-- All clients will match this rule.
	{
		rule = { },
		properties = {
			focus = true,
			keys = Keymap.getCApiKeys("client"),
			buttons = clientbuttons
		}
	},

	{
		rule_any = {
			class = { "URxvt", "XTerm" }
		},
		properties = {
			size_hints_honor = false,
		},
	},

	{
		rule = {
			class = "QNetSoul"
		},
		properties = {
			floating = true,
			ontop = true,
		},
		callback = function(c)
			c:geometry({
				x		= 1500,
				y		= 25,
				width	= 350,
				height	= 450
			})
		end
	},

	{
		rule = {
			class = "wpa_gui"
		},
		properties = {
			floating = true,
			ontop = true,
		},
		callback = function(c)
			c:geometry({
				x		= 1400,
				y		= 25,
				width	= 350,
				height	= 370
			})
		end
	}

}
-- }}}
