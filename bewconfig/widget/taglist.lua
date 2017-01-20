local wibox = require("wibox")
local dpi = require("beautiful").xresources.apply_dpi
local wcommon = require("awful.widget.common")

--- Create a border container
-- @param child_widget The contained widget
-- @param position The border position. One of "top", "bottom", "left",
--   or "right". Can also be an array of theses positions name.
-- @param size The border size
-- @param color The border color
local function create_border(child_widget, position, size, color)
	local w_border = wibox.container.margin(child_widget)

	if type(position) == "table" then
		for _, pos in ipairs(position) do
			w_border[pos] = size
		end
	elseif position == "top" or position == "bottom" or position == "left" or position == "right" then
		w_border[position] = size
	end

	if color then
		w_border.color = color
	end
	return w_border
end

--- Common update method.
-- @param w_list The widget.
-- @tab buttons
-- @func label Function to generate label parameters from an object.
--   The function gets passed an object from `objects`, and
--   has to return `text`, `bg`, `bg_image`, `icon`.
-- @tab data Current data/cache, indexed by objects.
-- @tab objects Objects to be displayed / updated.
local function taglist_update(w_list, buttons, label, data, objects)
	-- update the widgets, creating them if needed
	w_list:reset()

	local function build_cache(obj)
		local c = {
			status = {},
		}

		c.text = wibox.widget.textbox()
		c.text_container = wibox.container.margin(c.text, dpi(10), dpi(10))

		c.status.not_empty = create_border(c.text_container, "top", dpi(2))

		local margins = wibox.container.margin(c.status.not_empty, dpi(4), dpi(4))

		c.status.selected = create_border(margins, "bottom", dpi(3))

		c.container = wibox.container.margin()
		c.container:buttons(wcommon.create_buttons(buttons, obj))

		c.container.widget = c.status.selected

		data[obj] = c
		return c
	end

	for _, obj in ipairs(objects) do
		local c = data[obj] or build_cache(obj)

		local text, selected_color = label(obj)

		if text == nil or text == "" then
			c.text_container:set_margins(0)
		else
			-- The text might be invalid, so use pcall.
			if not c.text:set_markup_silently(text) then
				c.text:set_markup("<i>&lt;Invalid text&gt;</i>")
			end
		end
		c.status.selected.color = selected_color

		local clients = obj:clients()
		if #clients > 0 then -- tag is not empty
			c.status.not_empty.color = "#ff5722"
		else
			c.status.not_empty.color = nil
		end

		w_list:add(c.container)
	end
end

-- TODO: return a more structured object
return taglist_update
