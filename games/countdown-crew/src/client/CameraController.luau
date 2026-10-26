--!strict
-- One fixed, angled camera that keeps the whole crew in view, then follows the rocket during a launch.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Net = require(ReplicatedStorage.Shared.Net)

local CameraController = {}

local PAD_CENTER = Vector3.new(0, 0, -4)
local CREW_OFFSET = Vector3.new(0, 52, 40) -- looks down at about 50 degrees
local LAUNCH_OFFSET = Vector3.new(-45, 12, 60)
local FOLLOW = 0.35 -- how far the view leans from the pad's centre towards the crew

local function crewCentre(): Vector3
	local total, count = Vector3.zero, 0
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		if root then
			total += root.Position
			count += 1
		end
	end
	if count == 0 then
		return PAD_CENTER
	end
	local average = total / count
	return PAD_CENTER:Lerp(Vector3.new(average.X, 0, average.Z), FOLLOW)
end

local function rocketPosition(): Vector3?
	local pad = Workspace:FindFirstChild("Pad")
	local rocket = if pad then pad:FindFirstChild("Rocket") :: Model? else nil
	if rocket and rocket.PrimaryPart then
		return rocket:GetPivot().Position
	end
	return nil
end

function CameraController.start()
	local state = Net.missionState()
	local camera = Workspace.CurrentCamera
	camera.FieldOfView = 50

	RunService:BindToRenderStep("CrewCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
		-- Respawning resets the camera type, so set it every frame
		camera.CameraType = Enum.CameraType.Scriptable
		local goal: CFrame
		local rocket = if state:GetAttribute("Phase") == "Launch" then rocketPosition() else nil
		if rocket then
			goal = CFrame.lookAt(rocket + LAUNCH_OFFSET, rocket)
		else
			local focus = crewCentre()
			goal = CFrame.lookAt(focus + CREW_OFFSET, focus)
		end
		camera.CFrame = camera.CFrame:Lerp(goal, math.min(1, dt * 4))
	end)
end

return CameraController
