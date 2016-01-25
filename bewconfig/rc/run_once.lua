local Autorun = require("bewlib.autorun")

Autorun.addOnce("xset r rate 500")
Autorun.addOnce("xset -b")
Autorun.addOnce("xbacklight -set 70")

Autorun.addOnce("wpa_gui -t")
--Autorun.addOnce("QNetSoul")
--Autorun.addOnce("chromium --no-startup-window")
Autorun.addOnce("pamixer --set-volume 40")

