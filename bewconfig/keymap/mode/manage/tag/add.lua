local Keymap = require("bewlib.keymap")
local Const = require("bewlib.const")

local Command = require("bewlib.command")



local km = Keymap.new("mode.manage.tag.add")

km:add({
    ctrl = { key = "Escape" },
    press = function(self)
        Keymap.pop(self)
    end,
})

-- :add tag end
-- :atA
km:add({
    ctrl = { mod = "S", key = "a" },
    press = function()
        Command.run("add.tag", {
            where = Const.END,
        })
    end,
})
