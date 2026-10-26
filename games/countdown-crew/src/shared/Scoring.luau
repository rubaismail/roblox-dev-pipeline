--!strict
-- Points for each launch and stars for the mission.

local FlightModel = require(script.Parent.FlightModel)

export type Breakdown = {
	total: number,
	lines: { string }, -- one line per score source, for the results banner
}

local Scoring = {}

Scoring.OUTCOME_POINTS = {
	Orbit = 100,
	HighAltitude = 50,
	FellBack = 10,
	Exploded = 0,
} :: { [FlightModel.Outcome]: number }

Scoring.PAYLOAD_BONUS = 25
Scoring.NO_FIRE_BONUS = 15

-- secondsLeft is what was on the countdown when the rocket went up; it is above zero only after LAUNCH NOW.
function Scoring.launch(result: FlightModel.Result, hadFire: boolean, secondsLeft: number): Breakdown
	local total = Scoring.OUTCOME_POINTS[result.outcome]
	local lines = { `{FlightModel.LABELS[result.outcome]}: {total}` }

	-- Bonuses reward a crew that got something into the air, never one that blew it up
	if result.outcome ~= "Exploded" then
		if result.payloadDelivered then
			total += Scoring.PAYLOAD_BONUS
			table.insert(lines, `Payload delivered: +{Scoring.PAYLOAD_BONUS}`)
		end
		if not hadFire then
			total += Scoring.NO_FIRE_BONUS
			table.insert(lines, `No fires: +{Scoring.NO_FIRE_BONUS}`)
		end
		local early = math.max(0, math.floor(secondsLeft))
		if early > 0 then
			total += early
			table.insert(lines, `Launched early: +{early}`)
		end
	end

	return { total = total, lines = lines }
end

-- Using a HOLD caps the mission one star below the top.
function Scoring.stars(total: number, thresholds: { number }, holdsUsed: number): number
	local stars = 0
	for _, threshold in thresholds do
		if total >= threshold then
			stars += 1
		end
	end
	if holdsUsed > 0 then
		stars = math.min(stars, #thresholds - 1)
	end
	return stars
end

return Scoring
