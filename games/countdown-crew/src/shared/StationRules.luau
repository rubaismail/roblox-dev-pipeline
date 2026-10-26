--!strict
-- Which parts each station will take. Shared so the client highlights exactly what the server allows.

local Parts = require(script.Parent.Parts)
local PartState = require(script.Parent.PartState)

export type StationType = "Conveyor" | "Workbench" | "FuelPump" | "Crane" | "Bin" | "ExtinguisherRack"

local StationRules = {}

function StationRules.accepts(stationType: string, part: PartState.State, occupied: boolean, onFire: boolean): boolean
	if onFire then
		return false
	end
	if stationType == "Bin" then
		return true
	end
	if stationType == "Crane" then
		return PartState.isStackable(part)
	end
	if occupied then
		return false
	end

	local def = Parts.defs[part.kind]
	if stationType == "Workbench" then
		return def.isSection
	elseif stationType == "FuelPump" then
		return def.needsFuel and PartState.isBolted(part) and part.fuel < 1
	elseif stationType == "ExtinguisherRack" then
		return part.kind == "Extinguisher"
	end
	return false
end

return StationRules
