--[[ Battery management ]]--

-- Grab environement
local capi = {
	timer = timer
}

-- Module dependencies

-- Module environement
local mod = {}

-- private vars
local bat_info = {
	present = 0,
	techno = "",
	serial_nb = "",
	manufacturer = "",
	modelName = "",
	status = "Not present",
	perc = "N/A",
	time = "N/A",
	watt = "N/A"
}

local function get_battery_info()

	local bstr  = "/sys/class/power_supply/" .. battery

	local present = first_line(bstr .. "/present")
	bat_now.present = present == "1" and true or false

	if bat_now.present then
		local rate  = first_line(bstr .. "/power_now") or first_line(bstr .. "/current_now")

		local ratev = first_line(bstr .. "/voltage_now")

		local rem   = first_line(bstr .. "/energy_now") or
					  first_line(bstr .. "/charge_now")

		local tot   = first_line(bstr .. "/energy_full") or
					  first_line(bstr .. "/charge_full")

		bat_info.status = first_line(bstr .. "/status") or "N/A"

		rate  = tonumber(rate) or 1
		ratev = tonumber(ratev)
		rem   = tonumber(rem)
		tot   = tonumber(tot)

		local time_rat = 0
		if bat_now.status == "Charging"
		then
			time_rat = (tot - rem) / rate
		elseif bat_now.status == "Discharging"
		then
			time_rat = rem / rate
		end

		local hrs = math.floor(time_rat)
		if hrs < 0 then hrs = 0 elseif hrs > 23 then hrs = 23 end

		local min = math.floor((time_rat - hrs) * 60)
		if min < 0 then min = 0 elseif min > 59 then min = 59 end

		bat_now.time = string.format("%02d:%02d", hrs, min)

		bat_now.perc = first_line(bstr .. "/capacity")

		if not bat_now.perc then
			local perc = (rem / tot) * 100
			if perc <= 100 then
				bat_now.perc = string.format("%d", perc)
			elseif perc > 100 then
				bat_now.perc = "100"
			elseif perc < 0 then
				bat_now.perc = "0"
			end
		end

		if rate ~= nil and ratev ~= nil then
			bat_now.watt = string.format("%.2fW", (rate * ratev) / 1e12)
		else
			bat_now.watt = "N/A"
		end

	end
	return bat_info
end

return mod
