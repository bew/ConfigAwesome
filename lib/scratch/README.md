# Scratch-pad - Scratch-drop (Quake terminal like)

## Languages

Scratch is a Lua module that provides a basic drop-down applications and scratchpad manager for awesome v3.4.

### Introduction
Awesome v2 users will be familiar with the scratchpad functionality, and they should know that this module tries to stay as close as possible to v2 scratchpad. Where awesome v2 provided `client_setscratch` and `client_togglescratch`, this module also provides two functions; `scratch.pad.set` and `scratch.pad.toggle`. For those that never used the awesome scratchpad a short description:

* Calling the `set` function on a client it is automatically centered on screen and set floating
** Client also assumes other properties, of which size, sticky and screen are all controllable
* Calling the `toggle` function client is hidden, or shown, depending on its state when scratch is not empty
* Calling the `set` function on a scratched client will un-scratch it, and calling it on another client will replace the scratch

**NOTE**: You can't scratch multiple clients with this module, not until `tabbing` support is added to `awful`, or an adequate alternative solution presents it self.

This module also contains a drop-down applications manager, the `scratch.drop` module. The module will toggle the visibility of your favorite terminal emulator, app launcher like gmrun or any other application, placing it along a screen edge when visible. This functionality will be familliar to those who played computer games like Quake. When you call `scratch.drop` for a given application it will create a new window for it when it doesn't exist, and will toggle between hidden and visible states if one does exist, by placing it along the defined screen edge.

### Download
`Scratch` is hosted on http://git.sysphere.org/awesome-configs/tree/ and installing it is a matter of moving the module directory, and all its files, to your awesome configuration directory:

	$ mv scratch $XDG_CONFIG_HOME/awesome/

### Usage
To use this module require it at the top of your `rc.lua`:

	local scratch = require("scratch")

### Using the scratchpad
Call the `set` function from a `clientkeys` binding:

	scratch.pad.set(c, width, height, sticky, screen)

... and the `toggle` function from a `globalkeys` binding:

	scratch.pad.toggle(screen)


Parameters:

* c      - Client to scratch or un-scratch
* width  - Width in absolute pixels, or width percentage
           when <= 1 (0.50 (50% of the screen) by default)
* height - Height in absolute pixels, or height percentage
           when <= 1 (0.50 (50% of the screen) by default)
* sticky - Visible on all tags, false by default
* screen - Optional screen, mouse.screen by default

#### Examples
Calling the `toggle` function from your `globalkeys`:

	awful.key({ modkey }, "s", function () scratch.pad.toggle() end),

Calling the `set` function from your `clientkeys`:

	awful.key({ modkey }, "d", function (c) scratch.pad.set(c, 0.60, 0.60, true) end),

### Using the scratchdrop
Call `scratch.drop` from a `globalkeys` binding:

	scratch.drop(prog, vert, horiz, width, height, sticky, screen)


Parameters:

* prog   - Program to run; "urxvt", "gmrun", "thunderbird"
* vert   - Vertical; "bottom", "center" or "top" (default)
* horiz  - Horizontal; "left", "right" or "center" (default)
* width  - Width in absolute pixels, or width percentage
           when <= 1 (1 (100% of the screen) by default)
* height - Height in absolute pixels, or height percentage
           when <= 1 (0.25 (25% of the screen) by default)
* sticky - Visible on all tags, false by default
* screen - Optional screen, mouse.screen by default

#### Examples
Calling `scratch.drop` from your `globalkeys`:

	awful.key({ modkey }, "F11", function () scratch.drop("gmrun") end),
	awful.key({ modkey }, "F12", function () scratch.drop("urxvt", "bottom") end),
