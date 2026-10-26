--!strict
-- Works out what a rocket does at T-0 from the sections the crew stacked.

local Parts = require(script.Parent.Parts)

export type Outcome = "Orbit" | "HighAltitude" | "FellBack" | "Exploded"

export type Section = {
	kind: Parts.Kind,
	fuel: number, -- only matters for tanks
}

export type Result = {
	outcome: Outcome,
	altitude: number, -- studs the launch animation climbs
	payloadDelivered: boolean,
	reason: string,
}

local FlightModel = {}

FlightModel.LABELS = {
	Orbit = "Reached orbit",
	HighAltitude = "High altitude",
	FellBack = "Fell back down",
	Exploded = "Blew up on the pad",
} :: { [Outcome]: string }

local function result(outcome: Outcome, altitude: number, payloadDelivered: boolean, reason: string): Result
	return { outcome = outcome, altitude = altitude, payloadDelivered = payloadDelivered, reason = reason }
end

function FlightModel.simulate(recipe: { Parts.Kind }, stack: { Section }): Result
	if #stack == 0 then
		return result("Exploded", 0, false, "Nothing was stacked on the pad")
	end

	for index, section in stack do
		if recipe[index] ~= section.kind then
			return result("Exploded", 0, false, `{Parts.defs[section.kind].displayName} was stacked out of order`)
		end
	end

	local tanksNeeded, fuel = 0, 0
	for _, kind in recipe do
		if Parts.defs[kind].needsFuel then
			tanksNeeded += 1
		end
	end
	for _, section in stack do
		if Parts.defs[section.kind].needsFuel then
			fuel += section.fuel
		end
	end
	local fuelFraction = if tanksNeeded > 0 then fuel / tanksNeeded else 1
	if fuelFraction <= 0 then
		return result("Exploded", 0, false, "No fuel, so the engine blew up on the pad")
	end

	local complete = #stack == #recipe
	local hasNose = false
	for _, section in stack do
		if section.kind == "NoseCone" then
			hasNose = true
		end
	end

	if complete and fuelFraction >= 1 then
		return result("Orbit", 1000, true, "Every section on, tank full")
	end

	if fuelFraction >= 0.5 then
		local reason = if complete
			then "The tank wasn't full"
			else `Missing the {string.lower(Parts.defs[recipe[#stack + 1]].displayName)}`
		local altitude = math.floor(250 + 450 * math.min(fuelFraction, 1) * (#stack / #recipe))
		return result("HighAltitude", altitude, hasNose, reason)
	end

	return result("FellBack", 60, false, "Not enough fuel to get away")
end

return FlightModel
