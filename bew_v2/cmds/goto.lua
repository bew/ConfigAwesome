local awful = {}
awful.tag = require("awful.tag")

local Command = require("bewlib.command")
local Const = require("bewlib.const")


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

Command.register("goto.workspace")
Command.register("goto.client")

Command.register("tag.moveLeft")
Command.register("tag.moveRight")
Command.register("tag.moveToWorkspaceUp")
Command.register("tag.moveToWorkspaceDown")
