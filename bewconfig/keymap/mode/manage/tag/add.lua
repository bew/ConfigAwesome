local Keymap = require("bewlib.keymap")

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




--[[
Command.register("goto.tag", {
	argsFilter = {
		"which",
	},
	callback = function(args)
		args = args or {}
		local which = args.which or Const.LAST

		if which == Const.LAST then
			awful.tag.history.restore()
		elseif which == Const.NEXT then
			awful.tag.viewnext()
		elseif which == Const.PREVIOUS then
			awful.tag.viewprev()
		end
	end,
})
--]]
