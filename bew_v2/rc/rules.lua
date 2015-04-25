local awful = require("awful")
awful.rules = require("awful.rules")
local theme = require("beautiful")

-- {{{ Rules
awful.rules.rules = {
	-- All clients will match this rule.
	{
		rule = { },
		properties = {
  			border_width = theme.border_width,
			border_color = theme.border_focus,
			focus = true,
			keys = clientkeys,
			buttons = clientbuttons
		}
	},
	{
		rule = {
			class = "QNetSoul"
		},
		properties = {
			floating = true
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
			class = "Wpa_gui"
		},
		properties = {
			floating = true
		},
		callback = function(c)
			c:geometry({
				x		= 1400,
				y		= 25,
				width	= 350,
				height	= 370
			})
			-- naughty.notify({
			-- 	text = "Setting pos & geometry\nof " .. c.name,
			-- 	timeout = 2
			-- })
		end
	}
}
-- }}}
