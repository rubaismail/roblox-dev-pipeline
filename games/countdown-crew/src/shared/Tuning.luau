--!strict
-- Every number a designer may want to tune during playtests, in one place.

local Tuning = {
	-- Stations
	BOLT_SECONDS = 2.5, -- holding Use at a workbench until a part is bolted
	FUEL_SECONDS = 6, -- a tank on the pump goes from empty to full
	OVERFILL_SECONDS = 6, -- a full tank left on the pump this long catches fire
	EXTINGUISH_SECONDS = 1.5, -- spraying a fire until it goes out
	CONVEYOR_SPAWN_SECONDS = 3,
	CONVEYOR_SPEED = 8,

	-- Players
	INTERACT_RANGE = 6, -- studs from the edge of a station or item
	THROW_SPEED = 38,
	THROW_LIFT = 16,
	DASH_SPEED = 55,
	DASH_SECONDS = 0.15,
	DASH_COOLDOWN = 0.8,

	-- Mission flow
	INTERMISSION_SECONDS = 5,
	BRIEFING_SECONDS = 6,
	LAUNCH_SECONDS = 9,
	RESULTS_SECONDS = 12,
	HOLDS_PER_MISSION = 2,
	HOLD_SECONDS = 15,

	-- Anything that falls below this height is removed and the conveyor sends a new one
	VOID_Y = -40,
}

return Tuning
