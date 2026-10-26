--!strict
-- Pure helpers for the launch countdown. No Roblox services, so specs can cover all of it.

local Countdown = {}

-- Formats whole seconds as "M:SS", e.g. 75 -> "1:15". Negative input clamps to "0:00".
function Countdown.format(seconds: number): string
	local total = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", total // 60, total % 60)
end

return Countdown
