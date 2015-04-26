local radical = require("radical")
local wibox = require("wibox")
local theme = require("beautiful")


local utils = require("bewlib.utils")

local menu_style = {
	style = radical.style.classic,
	item_style = radical.style.arrow_alt
}

local menu = radical.context(menu_style)
menu:add_item {text="Screen 1", button1 = function(_menu,item,mods) utils.toast("Hello World from radical !") end}
menu:add_item {text="Screen 9", icon = "/usr/share/awesome/themes/zenburn/layouts/tileleft.png" }
menu:add_item {text="Sub Menu", sub_menu = function()
	local smenu = radical.context(menu_style)
	smenu:add_item{text="item 1"}
	smenu:add_item{text="item 2"}
	return smenu
end}

-- To add the menu to a widget:
foreachScreen(function(s)
	mytaglist[s]:set_menu(menu,3) -- 3 = right mouse button, 1 = left mouse button
end)



local menu_box = radical.box(menu_style)

menu_box:add_item({ text = "bla" })
menu_box:add_item({ text = "bla" })
menu_box:add_item({ text = "bla" })
menu_box:add_item({ text = "bla" })
menu_box:add_item({ text = "bla" })
menu_box:add_item({ text = "bla" })
menu_box:add_item({ text = "sub bla", sub_menu = function()
	local sbox = radical.embed(menu_style)
	sbox:add_item({ text = "blu" })
	sbox:add_item({ text = "blu" })
	sbox:add_item({ text = "blu" })
	return sbox
end })

wClock:set_menu(menu_box)
wClock:set_tooltip("this is the date")
