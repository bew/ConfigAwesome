## Workspace

### Global

`Mod+h`: Previous WS
`Mod+l`: Next WS

`Mod+s`: enter WS mode

### WS mode

`Esc`: quit WS mode (with confirmation, `Esc` to confirm)

`j` & `k`: select left/right tag
`h` & `l`: select left/right WS

`a` & `i`: Create WS (a => after, i => before)
`d`: Delete WS (with confirmation, `y` to confirm)
`r`: Rename WS
`S-h` & `S-l`: Move WS (left/right)

`S-j` & `S-k`: Move tag to WS (left/right)

Note: `Mod` key is ignored in this mode


## Tag

### Global

`Mod+t`: enter tag mode
`Mod+Space`: cycle tag layouts

### Tag mode

`h`/`l`: change master client size
`A-hjkl`: move client in a direction


## Client

### Global

`Mod+c`: enter client mode

### Client mode

`Esc`: quit client mode

Without `Shift`: do the action, quit client mode
With `Shift`: do the action, stay in client mode

`l`: toggle client lock
`f`: toggle client floating
`m`: toggle client maximize
`s`: toggle client sticky
`t`: toggle client ontop

`Tab`/`S-Tab`: cycle layer modes (onbottom, lower, above, ontop) (makes sense?)



## Alarm system

Maybe don't do it in the WM/DE?


## DBus based data gathering

lgi, Gio notes: https://github.com/pavouk/lgi/blob/master/docs/gio.md

Battery infos from upower:

- [Widget `upower_battery`](https://github.com/lexa/awesome_upower_battery)
(Using `lgi.require('UPowerGlib')`, need sth to be installed)

- [Widget `power_widget`](https://github.com/stefano-m/awesome-power_widget)

