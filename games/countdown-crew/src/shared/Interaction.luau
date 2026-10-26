--!strict
-- Decides what a player's buttons would act on right now. The server uses it to act and the client uses it
-- to highlight the same target, so what you see highlighted is what you get.

local CollectionService = game:GetService("CollectionService")

local Parts = require(script.Parent.Parts)
local PartState = require(script.Parent.PartState)
local StationRules = require(script.Parent.StationRules)
local Tuning = require(script.Parent.Tuning)

export type Target = {
	action: "Grab" | "Place" | "Drop" | "None",
	item: BasePart?,
	station: BasePart?,
}

local Interaction = {}

Interaction.ITEM_TAG = "CrewItem"
Interaction.STATION_TAG = "CrewStation"

function Interaction.readState(item: BasePart): PartState.State
	return {
		kind = item:GetAttribute("Kind") :: Parts.Kind,
		bolt = (item:GetAttribute("Bolt") :: number?) or 0,
		fuel = (item:GetAttribute("Fuel") :: number?) or 0,
		overfill = (item:GetAttribute("Overfill") :: number?) or 0,
	}
end

function Interaction.heldItem(userId: number): BasePart?
	for _, item in CollectionService:GetTagged(Interaction.ITEM_TAG) do
		if item:GetAttribute("HeldBy") == userId then
			return item :: BasePart
		end
	end
	return nil
end

function Interaction.itemOnStation(station: BasePart): BasePart?
	for _, item in CollectionService:GetTagged(Interaction.ITEM_TAG) do
		if item:GetAttribute("Station") == station.Name then
			return item :: BasePart
		end
	end
	return nil
end

-- Distance from a point to the footprint of a part, ignoring height, so long stations like the conveyor
-- are in reach from anywhere along their side.
local function flatDistance(origin: Vector3, part: BasePart): number
	local localPos = part.CFrame:PointToObjectSpace(origin)
	local half = part.Size / 2
	local dx = math.max(math.abs(localPos.X) - half.X, 0)
	local dz = math.max(math.abs(localPos.Z) - half.Z, 0)
	return math.sqrt(dx * dx + dz * dz)
end

-- Lower is better; nil when out of reach. Things in front of the player win over things behind.
local function score(root: BasePart, part: BasePart): number?
	local distance = flatDistance(root.Position, part)
	if distance > Tuning.INTERACT_RANGE then
		return nil
	end
	local offset = part.Position - root.Position
	local flat = Vector3.new(offset.X, 0, offset.Z)
	local facing = if flat.Magnitude > 0.01 then root.CFrame.LookVector:Dot(flat.Unit) else 1
	return (distance + 0.5) * (1.5 - 0.5 * facing)
end

local function best(root: BasePart, candidates: { Instance }, keep: (BasePart) -> boolean): BasePart?
	local bestPart: BasePart? = nil
	local bestScore = math.huge
	for _, candidate in candidates do
		local part = candidate :: BasePart
		if keep(part) then
			local value = score(root, part)
			if value and value < bestScore then
				bestPart, bestScore = part, value
			end
		end
	end
	return bestPart
end

-- What the Grab button does: pick up the nearest free item, put the held item on a station, or drop it.
function Interaction.grabTarget(root: BasePart, held: BasePart?): Target
	if held then
		local state = Interaction.readState(held)
		local station = best(root, CollectionService:GetTagged(Interaction.STATION_TAG), function(candidate)
			return StationRules.accepts(
				candidate:GetAttribute("StationType") :: string,
				state,
				candidate:GetAttribute("Occupied") == true,
				candidate:GetAttribute("OnFire") == true
			)
		end)
		if station then
			return { action = "Place", station = station }
		end
		return { action = "Drop" }
	end

	local item = best(root, CollectionService:GetTagged(Interaction.ITEM_TAG), function(candidate)
		return candidate:GetAttribute("HeldBy") == 0
	end)
	if item then
		return { action = "Grab", item = item }
	end
	return { action = "None" }
end

-- What holding Use works on: a fire if you carry the extinguisher, otherwise a workbench with unbolted work.
function Interaction.useTarget(root: BasePart, held: BasePart?): BasePart?
	local stations = CollectionService:GetTagged(Interaction.STATION_TAG)
	if held then
		if held:GetAttribute("Kind") ~= "Extinguisher" then
			return nil
		end
		return best(root, stations, function(station)
			return station:GetAttribute("OnFire") == true
		end)
	end
	return best(root, stations, function(station)
		if station:GetAttribute("StationType") ~= "Workbench" then
			return false
		end
		local item = Interaction.itemOnStation(station)
		return item ~= nil and PartState.needsBolting(Interaction.readState(item))
	end)
end

return Interaction
