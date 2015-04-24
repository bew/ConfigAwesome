local radical = require("radical")
local wibox = require("wibox")


local utils = require("bewlib.utils")
local debug = require("gears.debug").dump_return


local menu = radical.context {}
menu:add_item({ text = "item 1" })
menu:add_item({ text = "item 2" })
menu:add_item({
	text = "Sub menu",
	sub_menu = function()
		local smenu = radical.context({})
		smenu:add_item({ text = "item 3" })
		smenu:add_item({ text = "item 4" })
		return smenu
	end
})

local w = wibox({
	x = 400,
	y = 400,
	width = 400,
	height = 400
})
utils.toast(debug(w), { timeout = 60, title = "Widget w :" })
--w:set_bg("#03A9F4")
w:set_menu(menu)



function tests_radical_1()
	w.visible = not w.visible
end


