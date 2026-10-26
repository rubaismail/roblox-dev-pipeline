--!strict
-- Mission data: which rocket each launch asks for and how long the crew gets.

local Parts = require(script.Parent.Parts)

export type Launch = {
	recipe: { Parts.Kind }, -- bottom to top; the crane must stack it in this order
	countdown: number, -- seconds for a crew of 3 or 4
}

export type Mission = {
	id: string,
	name: string,
	payload: string,
	launches: { Launch },
	starThresholds: { number }, -- total points for 1, 2 and 3 stars
}

-- Countdown multiplier by crew size. Solo and duo crews get extra time; big crews get less.
local CREW_TIME_SCALE = { 1.4, 1.15, 1, 1, 0.9, 0.9 }

local Missions = {}

Missions.EarthPad = {
	id = "EarthPad",
	name = "Earth Pad",
	payload = "Weather satellite",
	launches = {
		{ recipe = { "Engine", "FuelTank", "NoseCone" }, countdown = 100 },
		{ recipe = { "Engine", "FuelTank", "Body", "NoseCone" }, countdown = 110 },
		{ recipe = { "Engine", "FuelTank", "Body", "Fins", "NoseCone" }, countdown = 120 },
	},
	starThresholds = { 150, 300, 420 },
} :: Mission

function Missions.countdownFor(launch: Launch, crewSize: number): number
	local index = math.clamp(math.floor(crewSize), 1, #CREW_TIME_SCALE)
	return math.floor(launch.countdown * CREW_TIME_SCALE[index] + 0.5)
end

return Missions
