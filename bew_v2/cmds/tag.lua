local Command = require("bewlib.command")
local capi = {
	tag = require("awful").tag,
}


Command.register("tag.gotoPrevious", capi.tag.viewprev)
Command.register("tag.gotoNext", capi.tag.viewnext)
Command.register("tag.gotoLast", capi.tag.history.restore)

Command.register("tag.moveLeft")
Command.register("tag.moveRight")
Command.register("tag.moveToWorkspaceUp")
Command.register("tag.moveToWorkspaceDown")
