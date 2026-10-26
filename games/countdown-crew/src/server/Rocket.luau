--!strict
-- The rocket on the launch platform: grows a section each time the crane stacks one, then plays the launch.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local FlightModel = require(ReplicatedStorage.Shared.FlightModel)
local Parts = require(ReplicatedStorage.Shared.Parts)

local Rocket = {}

local SCALE = 1.6 -- sections on the rocket are drawn bigger than the carried parts

local model: Model
local base = CFrame.identity
local height = 0

function Rocket.init(parent: Instance, baseCFrame: CFrame)
	model = Instance.new("Model")
	model.Name = "Rocket"
	model.Parent = parent
	base = baseCFrame
end

function Rocket.reset()
	model:ClearAllChildren()
	model.PrimaryPart = nil
	height = 0
end

function Rocket.addSection(kind: Parts.Kind)
	local def = Parts.defs[kind]
	local size = def.size * SCALE
	local part = Instance.new("Part")
	part.Name = kind
	part.Anchored = true
	part.CanCollide = false
	part.Size = size
	part.Color = def.color
	part.Material = Enum.Material.SmoothPlastic
	part.CFrame = base * CFrame.new(0, height + size.Y / 2, 0)
	part.Parent = model
	height += size.Y
	if not model.PrimaryPart then
		model.PrimaryPart = part
	end
end

local function explode(position: Vector3)
	local explosion = Instance.new("Explosion")
	explosion.Position = position
	explosion.BlastRadius = 10
	explosion.BlastPressure = 0 -- a show, not a weapon: nobody on the pad gets hurt or flung
	explosion.DestroyJointRadiusPercent = 0
	explosion.Parent = Workspace
end

-- Moves the rocket by offsetAt(t) for `seconds`, where t runs from 0 to 1.
local function animate(seconds: number, offsetAt: (number) -> CFrame)
	local start = model:GetPivot()
	local elapsed = 0
	while elapsed < seconds do
		elapsed += RunService.Heartbeat:Wait()
		model:PivotTo(start * offsetAt(math.min(elapsed / seconds, 1)))
	end
end

-- Plays the flight for a result. Yields until the animation ends.
function Rocket.fly(result: FlightModel.Result)
	if not model.PrimaryPart or result.outcome == "Exploded" then
		explode(base.Position + Vector3.new(0, math.max(height / 2, 2), 0))
		model:ClearAllChildren()
		return
	end

	local flame = Instance.new("Fire")
	flame.Size = 10
	flame.Heat = -25 -- negative heat points the flame down, under the engine
	flame.Parent = model.PrimaryPart

	if result.outcome == "FellBack" then
		animate(2, function(t)
			return CFrame.new(0, result.altitude * math.sin(t * math.pi / 2), 0)
		end)
		flame:Destroy()
		animate(1.2, function(t)
			return CFrame.new(0, result.altitude * (1 - t * t), 0)
		end)
		explode(model:GetPivot().Position)
		model:ClearAllChildren()
		return
	end

	local wobble = if result.outcome == "HighAltitude" then 1 else 0
	animate(5, function(t)
		local sway = wobble * math.sin(t * 25) * 0.15 * t
		return CFrame.new(wobble * 12 * t * t, result.altitude * t * t, 0) * CFrame.Angles(0, 0, sway)
	end)
end

return Rocket
