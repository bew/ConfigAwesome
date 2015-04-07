-- Module dependencies
local naughty = require("naughty")

-- Module environement
local mod = {}

function mod.toast (text, options)
	local options = options or {}
	options.text = text
	naughty.notify(options)
end

return mod
