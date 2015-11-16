local awful = require("awful")

function run_once(cmd)
	findme = cmd
	firstspace = cmd:find(" ")
	if firstspace then
		findme = cmd:sub(0, firstspace-1)
	end
	awful.util.spawn_with_shell("pgrep -u $USER -x " .. findme .. " > /dev/null || (" .. cmd .. ")")
end

function just_run(cmd)
	awful.util.spawn_with_shell(cmd)
end

local function add_x_safe_config(tbl)
	return awful.util.table.join(tbl, {
		"xset r rate 500",
		"xset -b",
		"xbacklight -set 70"
	})
end

local to_run = {
	--"wpa_gui -t",
	--"QNetSoul",
	"chromium --no-startup-window",
	"amixer set Master 20%",
}



to_run = add_x_safe_config(to_run)

for i=1, #to_run do
	run_once(to_run[i])
end

