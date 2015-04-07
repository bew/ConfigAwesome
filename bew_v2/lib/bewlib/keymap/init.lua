-- Module dependencies
local toast = require("bewlib.utils").toast

-- Module environement
local mod = {}

function mod.new (keymapName, options)
	self.name = keymapName
	self.parent = options.parent or nil
end


function mod:addBind (bindOpt)
	if type(bindOpt) ~= "table" then
		return nil
	end
	local bind = {}
	bind.comment = type(bindOpt.comment) == "string" and bindOpt.comment or ""
	bind.cmd = type(bindOpt.cmd) == "string" and bindOpt.cmd or nil
	bind.callback = type(bindOpt.cmd) == "function" and bindOpt.cmd or nil
end



return mod
