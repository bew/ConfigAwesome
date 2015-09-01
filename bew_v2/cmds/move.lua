-- Grab environment
local capi = {
	tag = tag,
	client = client,
}

-- Resolve Dependencies
local Command = require("bewlib.command")
local awful = require("awful")

local function bla()
end

Command.register("move.clientToTag")

Command.register("move.tagToWorkspace")

Command.register("move.workspaceToScreen")
