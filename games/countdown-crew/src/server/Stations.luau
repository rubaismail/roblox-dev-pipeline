--!strict
-- Runs the stations each frame: bolting at workbenches, the fuel pump and its fires, the extinguisher rack and
-- the parts conveyor. Server only.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Interaction = require(ReplicatedStorage.Shared.Interaction)
local PartState = require(ReplicatedStorage.Shared.PartState)
local Parts = require(ReplicatedStorage.Shared.Parts)
local Tuning = require(ReplicatedStorage.Shared.Tuning)
local Items = require(script.Parent.Items)

local Stations = {}

local stations: { BasePart } = {}
local conveyorStart = CFrame.identity
local extinguishProgress: { [BasePart]: number } = {}

function Stations.init(list: { BasePart }, conveyorSpawn: CFrame)
	stations = list
	conveyorStart = conveyorSpawn
end

local function ofType(stationType: string): { BasePart }
	local found = {}
	for _, station in stations do
		if station:GetAttribute("StationType") == stationType then
			table.insert(found, station)
		end
	end
	return found
end

local function setFire(station: BasePart, on: boolean)
	station:SetAttribute("OnFire", on)
	local fire = station:FindFirstChild("Fire")
	if on and not fire then
		local newFire = Instance.new("Fire")
		newFire.Size = 8
		newFire.Heat = 12
		newFire.Parent = station
	elseif not on and fire then
		fire:Destroy()
	end
	extinguishProgress[station] = nil
end

function Stations.reset()
	for _, station in stations do
		station:SetAttribute("Occupied", false)
		setFire(station, false)
	end
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
end

-- Advances every station by dt. `using` holds the players pressing Use. Returns true if a fire started.
function Stations.tick(dt: number, using: { [Player]: boolean }): boolean
	for player in using do
		local root = rootOf(player)
		if root then
			local held = Interaction.heldItem(player.UserId)
			local station = Interaction.useTarget(root, held)
			if station and station:GetAttribute("OnFire") == true then
				local progress = (extinguishProgress[station] or 0) + dt
				extinguishProgress[station] = progress
				if progress >= Tuning.EXTINGUISH_SECONDS then
					setFire(station, false)
				end
			elseif station then
				local item = Interaction.itemOnStation(station)
				if item then
					local state = Interaction.readState(item)
					PartState.addBolt(state, dt)
					Items.write(item, state)
				end
			end
		end
	end

	local fireStarted = false
	for _, pump in ofType("FuelPump") do
		local item = Interaction.itemOnStation(pump)
		if item then
			local state = Interaction.readState(item)
			if PartState.addFuel(state, dt) then
				-- The tank is lost; the conveyor sends a new one because the recipe still needs it
				Items.destroy(item)
				setFire(pump, true)
				fireStarted = true
			else
				Items.write(item, state)
			end
		end
	end
	return fireStarted
end

-- Keeps one extinguisher on the pad at all times.
function Stations.restockRack()
	if Items.countKind("Extinguisher") > 0 then
		return
	end
	for _, rack in ofType("ExtinguisherRack") do
		local item = Items.spawn("Extinguisher", rack.CFrame)
		Items.placeOn(item, rack)
		return
	end
end

-- Sends the next part the rocket still needs, one at a time, so the pad never fills with spares.
function Stations.feedConveyor(recipe: { Parts.Kind }, stacked: number)
	local stillNeeded: { [Parts.Kind]: number } = {}
	for index = stacked + 1, #recipe do
		local kind = recipe[index]
		stillNeeded[kind] = (stillNeeded[kind] or 0) + 1
	end
	for index = stacked + 1, #recipe do
		local kind = recipe[index]
		if Items.countKind(kind) < stillNeeded[kind] then
			Items.spawn(kind, conveyorStart)
			return
		end
	end
end

return Stations
