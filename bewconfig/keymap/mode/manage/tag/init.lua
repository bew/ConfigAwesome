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
