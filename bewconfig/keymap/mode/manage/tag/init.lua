local Keymap = require("bewlib.keymap")

local Command = require("bewlib.command")



local km = Keymap.new("mode.manage.tag")

km:add({
    ctrl = { key = "Escape" },
    press = function()
        Keymap.pop(km)
    end,
})

km:add({
    ctrl = { key = "a" },
    press = function()
        Keymap.pop(km)
        Keymap.push("mode.manage.tag.add")
    end,
})
