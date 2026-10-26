--!strict
-- Builds the greybox launch pad from code, so the prototype runs in an empty place with no Studio-built map.
-- Positions are in studs; the floor's top surface is at y = 0.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Interaction = require(ReplicatedStorage.Shared.Interaction)
local Tuning = require(ReplicatedStorage.Shared.Tuning)

export type Pad = {
	folder: Folder,
	stations: { BasePart },
	rocketBase: CFrame,
	conveyorStart: CFrame,
}

local PadBuilder = {}

local function block(parent: Instance, name: string, size: Vector3, position: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

-- Painted on the face that points at the fixed camera, so names never float over the HUD or each other.
local function label(part: BasePart, text: string)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Label"
	gui.Face = Enum.NormalId.Back -- +Z, towards the camera
	gui.LightInfluence = 0
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	local textLabel = Instance.new("TextLabel")
	textLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	textLabel.Position = UDim2.fromScale(0.5, 0.5)
	textLabel.Size = UDim2.fromScale(0.9, 0.6)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextScaled = true
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.TextStrokeTransparency = 0.4
	textLabel.Text = text
	textLabel.Parent = gui
	gui.Parent = part
end

local function station(
	parent: Instance,
	name: string,
	stationType: string,
	size: Vector3,
	position: Vector3,
	color: Color3,
	text: string
): Part
	local part = block(parent, name, size, position, color)
	part:SetAttribute("StationType", stationType)
	part:SetAttribute("Occupied", false)
	part:SetAttribute("OnFire", false)
	CollectionService:AddTag(part, Interaction.STATION_TAG)
	label(part, text)
	return part
end

-- Template places come with a baseplate and spawn that would overlap the pad.
local function removeTemplateLeftovers()
	local baseplate = Workspace:FindFirstChild("Baseplate")
	if baseplate then
		baseplate:Destroy()
	end
	for _, child in Workspace:GetChildren() do
		if child:IsA("SpawnLocation") then
			child:Destroy()
		end
	end
end

function PadBuilder.build(): Pad
	removeTemplateLeftovers()

	local folder = Instance.new("Folder")
	folder.Name = "Pad"
	folder.Parent = Workspace

	local concrete = Color3.fromRGB(150, 152, 158)
	local wall = Color3.fromRGB(110, 112, 120)
	block(folder, "Floor", Vector3.new(90, 2, 60), Vector3.new(0, -1, 0), concrete)
	block(folder, "WallNorth", Vector3.new(94, 3, 2), Vector3.new(0, 1.5, -31), wall)
	block(folder, "WallSouth", Vector3.new(94, 3, 2), Vector3.new(0, 1.5, 31), wall)
	block(folder, "WallWest", Vector3.new(2, 3, 60), Vector3.new(-46, 1.5, 0), wall)
	block(folder, "WallEast", Vector3.new(2, 3, 60), Vector3.new(46, 1.5, 0), wall)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "CrewSpawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 0.5, 18)
	spawn.Color = Color3.fromRGB(90, 160, 90)
	spawn.Parent = folder

	local stations: { BasePart } = {}
	local function add(part: BasePart)
		table.insert(stations, part)
	end

	-- The belt is an anchored part with a surface velocity, so loose parts ride it to the stopper
	local conveyor = station(
		folder,
		"Conveyor",
		"Conveyor",
		Vector3.new(22, 3, 5),
		Vector3.new(-30, 1.5, -24),
		Color3.fromRGB(45, 45, 50),
		"Parts conveyor"
	)
	conveyor.AssemblyLinearVelocity = Vector3.new(Tuning.CONVEYOR_SPEED, 0, 0)
	add(conveyor)
	block(folder, "ConveyorStopper", Vector3.new(1, 2, 5), Vector3.new(-18.5, 4, -24), wall)

	local bench = Color3.fromRGB(160, 120, 80)
	add(
		station(folder, "Workbench1", "Workbench", Vector3.new(5, 3, 5), Vector3.new(-10, 1.5, -24), bench, "Workbench")
	)
	add(station(folder, "Workbench2", "Workbench", Vector3.new(5, 3, 5), Vector3.new(-2, 1.5, -24), bench, "Workbench"))
	add(
		station(
			folder,
			"FuelPump",
			"FuelPump",
			Vector3.new(5, 4, 5),
			Vector3.new(-6, 2, 2),
			Color3.fromRGB(70, 130, 200),
			"Fuel pump"
		)
	)
	add(
		station(
			folder,
			"Crane",
			"Crane",
			Vector3.new(7, 3, 7),
			Vector3.new(18, 1.5, -20),
			Color3.fromRGB(240, 190, 40),
			"Crane: stack here"
		)
	)
	add(station(folder, "Bin", "Bin", Vector3.new(4, 3, 4), Vector3.new(-32, 1.5, 12), wall, "Scrap bin"))
	add(
		station(
			folder,
			"ExtinguisherRack",
			"ExtinguisherRack",
			Vector3.new(3, 3, 3),
			Vector3.new(12, 1.5, 12),
			Color3.fromRGB(200, 40, 40),
			"Extinguisher"
		)
	)

	-- The rocket stands behind a fence; only the crane can reach it
	block(folder, "LaunchPlatform", Vector3.new(12, 1, 12), Vector3.new(36, 0.5, -18), Color3.fromRGB(60, 60, 66))
	block(folder, "GantryFence", Vector3.new(1, 3, 20), Vector3.new(28.5, 1.5, -18), wall)

	return {
		folder = folder,
		stations = stations,
		rocketBase = CFrame.new(36, 1, -18),
		conveyorStart = CFrame.new(-39, 5, -24),
	}
end

return PadBuilder
