--!strict
-- The work done on one carried part: how bolted, how fuelled, how long it has sat on a full pump.
-- Plain data with no Instances, so the server can store it in attributes and specs can test it directly.

local Parts = require(script.Parent.Parts)
local Tuning = require(script.Parent.Tuning)

export type State = {
	kind: Parts.Kind,
	bolt: number, -- 0 to 1
	fuel: number, -- 0 to 1, tanks only
	overfill: number, -- seconds spent on the pump after the tank was full
}

local PartState = {}

function PartState.new(kind: Parts.Kind): State
	return { kind = kind, bolt = 0, fuel = 0, overfill = 0 }
end

function PartState.isBolted(state: State): boolean
	return state.bolt >= 1
end

function PartState.needsBolting(state: State): boolean
	return Parts.defs[state.kind].isSection and state.bolt < 1
end

-- The crane takes a section once it is bolted. Tanks also need some fuel, but not necessarily a full tank:
-- launching half-fuelled is a valid, risky choice.
function PartState.isStackable(state: State): boolean
	local def = Parts.defs[state.kind]
	return def.isSection and PartState.isBolted(state) and (not def.needsFuel or state.fuel > 0)
end

function PartState.addBolt(state: State, dt: number)
	state.bolt = math.min(1, state.bolt + dt / Tuning.BOLT_SECONDS)
end

-- Fills a tank on the pump. Returns true once a full tank has been left long enough to catch fire.
function PartState.addFuel(state: State, dt: number): boolean
	if state.fuel < 1 then
		state.fuel = math.min(1, state.fuel + dt / Tuning.FUEL_SECONDS)
		return false
	end
	state.overfill += dt
	return state.overfill >= Tuning.OVERFILL_SECONDS
end

return PartState
