--[[ Battery API usage ]]--


local api = require("bewlib.computer.battery")

--[[

]]--

api.connect_signal("computer::battery::changed", function(batInfos)
	if batInfos.perc > 10 then return end
	-- do something with the battery infos when battery < 10%
end)




--example:

api.registerListener(function(batInfos)
	if not (batInfos.perc <= 15 and config.popup_enabled) then return end

	utils.toast("Here is the popup when enabled and battery <= 15% (" .. batInfos.perc .. ")")
end)




--[[



]]--
