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
            class = "discord"
        },
        properties = {
            floating = true,
            --ontop = true,
        },
        callback = function(c)
            c:geometry({
                width  = 1600,
                height = 800,
            })
            awful.placement.centered(c)
        end
    },
}
-- }}}
