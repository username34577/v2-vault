-- Number formatting shared by the HUD, shop, signs and leaderboard.
local Format = {}

local UNITS = { "", "K", "M", "B", "T", "Qd" }

-- 950 -> "950", 1234 -> "1.2K", 15000 -> "15K"
function Format.short(n: number?): string
	n = math.floor(n or 0)
	local value = n
	local i = 1
	while math.abs(value) >= 1000 and i < #UNITS do
		value /= 1000
		i += 1
	end
	if i == 1 then
		return tostring(n)
	end
	if value >= 100 or value == math.floor(value) then
		return string.format("%d%s", math.floor(value), UNITS[i])
	end
	return string.format("%.1f%s", math.floor(value * 10) / 10, UNITS[i])
end

return Format
