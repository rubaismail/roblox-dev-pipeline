--!strict
-- Creates rocket parts and tools and moves them between hands, stations and the floor. Server only.
-- Each item is one Part tagged CrewItem whose attributes hold its PartState plus HeldBy (a UserId, 0 when free)
-- and Station (the name of the station it sits on, "" when loose).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Interaction = require(ReplicatedStorage.Shared.Interaction)
local PartState = require(ReplicatedStorage.Shared.PartState)
local Parts = require(ReplicatedStorage.Shared.Parts)
local Tuning = require(ReplicatedStorage.Shared.Tuning)

local Items = {}

local folder: Folder
local stationsByName: { [string]: BasePart } = {}

local BAR_BOLT = Color3.fromRGB(250, 200, 60)
local BAR_FUEL = Color3.fromRGB(80, 170, 255)
local BAR_DANGER = Color3.fromRGB(255, 70, 50)

function Items.init(parent: Instance, stations: { BasePart })
	folder = Instance.new("Folder")
	folder.Name = "Items"
	folder.Parent = parent
	for _, station in stations do
		stationsByName[station.Name] = station
	end
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
end

local function makeBillboard(item: BasePart, def: Parts.Def)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Info"
	gui.Size = UDim2.fromOffset(90, 34)
	gui.StudsOffset = Vector3.new(0, def.size.Y / 2 + 1.2, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 120

	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.Size = UDim2.new(1, 0, 0, 18)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBold
	name.TextScaled = true
	name.TextColor3 = Color3.new(1, 1, 1)
	name.TextStrokeTransparency = 0.3
	name.Text = def.displayName
	-- Hidden until it matters: the client shows it on the part you are about to grab or are holding
	name.Visible = false
	name.Parent = gui

	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.Position = UDim2.fromOffset(5, 22)
	bar.Size = UDim2.new(1, -10, 0, 8)
	bar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	bar.BorderSizePixel = 0
	bar.Visible = def.isSection
	bar.Parent = gui

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0, 1)
	fill.BorderSizePixel = 0
	fill.BackgroundColor3 = BAR_BOLT
	fill.Parent = bar

	gui.Parent = item
end

-- Bolt progress first; once bolted, a tank shows its fuel instead, turning red while it overfills.
local function refreshBar(item: BasePart, state: PartState.State)
	local def = Parts.defs[state.kind]
	local gui = item:FindFirstChild("Info")
	if not gui or not def.isSection then
		return
	end
	local bar = gui:FindFirstChild("Bar") :: Frame
	local fill = bar:FindFirstChild("Fill") :: Frame
	if not PartState.isBolted(state) then
		fill.Size = UDim2.fromScale(state.bolt, 1)
		fill.BackgroundColor3 = BAR_BOLT
		bar.Visible = true
	elseif def.needsFuel then
		fill.Size = UDim2.fromScale(state.fuel, 1)
		fill.BackgroundColor3 = if state.overfill > 0 then BAR_DANGER else BAR_FUEL
		bar.Visible = true
	else
		bar.Visible = false
	end
end

function Items.write(item: BasePart, state: PartState.State)
	item:SetAttribute("Bolt", state.bolt)
	item:SetAttribute("Fuel", state.fuel)
	item:SetAttribute("Overfill", state.overfill)
	refreshBar(item, state)
end

local function leaveStation(item: BasePart)
	local stationName = item:GetAttribute("Station") :: string?
	if not stationName or stationName == "" then
		return
	end
	local station = stationsByName[stationName]
	if station then
		station:SetAttribute("Occupied", false)
		-- Taking a tank off the pump resets its overfill clock
		if station:GetAttribute("StationType") == "FuelPump" then
			local state = Interaction.readState(item)
			state.overfill = 0
			Items.write(item, state)
		end
	end
	item:SetAttribute("Station", "")
end

local function release(item: BasePart)
	local weld = item:FindFirstChild("HoldWeld")
	if weld then
		weld:Destroy()
	end
	item:SetAttribute("HeldBy", 0)
	item.Massless = false
	item.CanCollide = true
end

function Items.attach(player: Player, item: BasePart)
	local root = rootOf(player)
	if not root then
		return
	end
	leaveStation(item)
	item.Anchored = false
	item.CanCollide = false
	item.Massless = true
	item.CFrame = root.CFrame * CFrame.new(0, 0.6, -2.4)
	local weld = Instance.new("WeldConstraint")
	weld.Name = "HoldWeld"
	weld.Part0 = root
	weld.Part1 = item
	weld.Parent = item
	item:SetAttribute("InFlight", false)
	item:SetAttribute("HeldBy", player.UserId)
end

-- A thrown item caught by a player with empty hands goes straight into them.
local function onTouched(item: BasePart, hit: BasePart)
	if item:GetAttribute("InFlight") ~= true or not hit.Parent then
		return
	end
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player or player.UserId == item:GetAttribute("ThrownBy") then
		return
	end
	if Interaction.heldItem(player.UserId) == nil then
		Items.attach(player, item)
	end
end

function Items.spawn(kind: Parts.Kind, cframe: CFrame): BasePart
	local def = Parts.defs[kind]
	local item = Instance.new("Part")
	item.Name = kind
	item.Size = def.size
	item.Color = def.color
	item.Material = Enum.Material.SmoothPlastic
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.CFrame = cframe
	item:SetAttribute("Kind", kind)
	item:SetAttribute("HeldBy", 0)
	item:SetAttribute("Station", "")
	item:SetAttribute("InFlight", false)
	makeBillboard(item, def)
	Items.write(item, PartState.new(kind))
	CollectionService:AddTag(item, Interaction.ITEM_TAG)
	item.Touched:Connect(function(hit)
		onTouched(item, hit)
	end)
	item.Parent = folder
	return item
end

function Items.placeOn(item: BasePart, station: BasePart)
	release(item)
	item.Anchored = true
	item.CFrame = CFrame.new(station.Position + Vector3.new(0, station.Size.Y / 2 + item.Size.Y / 2, 0))
	item:SetAttribute("Station", station.Name)
	station:SetAttribute("Occupied", true)
end

function Items.dropToFloor(item: BasePart, root: BasePart)
	release(item)
	item.Anchored = false
	item.CFrame = root.CFrame * CFrame.new(0, 0, -3)
end

function Items.throw(item: BasePart, player: Player, root: BasePart)
	release(item)
	item.Anchored = false
	item.CFrame = root.CFrame * CFrame.new(0, 1, -3)
	item:SetAttribute("InFlight", true)
	item:SetAttribute("ThrownBy", player.UserId)
	item.AssemblyLinearVelocity = root.CFrame.LookVector * Tuning.THROW_SPEED + Vector3.new(0, Tuning.THROW_LIFT, 0)
	-- The thrower's machine simulates the flight so it feels instant; the server takes it back after it lands
	pcall(item.SetNetworkOwner, item, player)
	task.delay(1.5, function()
		if item.Parent and item:GetAttribute("HeldBy") == 0 then
			item:SetAttribute("InFlight", false)
			if not item.Anchored then
				pcall(item.SetNetworkOwner, item, nil)
			end
		end
	end)
end

-- Lets go of whatever the player holds, where it is. Used when a character respawns or leaves.
function Items.dropHeld(player: Player)
	local item = Interaction.heldItem(player.UserId)
	if item then
		release(item)
	end
end

function Items.destroy(item: BasePart)
	leaveStation(item)
	item:Destroy()
end

function Items.clearAll()
	for _, item in folder:GetChildren() do
		item:Destroy()
	end
	for _, station in stationsByName do
		station:SetAttribute("Occupied", false)
	end
end

function Items.all(): { BasePart }
	return folder:GetChildren() :: { any }
end

function Items.countKind(kind: Parts.Kind): number
	local count = 0
	for _, item in folder:GetChildren() do
		if item:GetAttribute("Kind") == kind then
			count += 1
		end
	end
	return count
end

return Items
