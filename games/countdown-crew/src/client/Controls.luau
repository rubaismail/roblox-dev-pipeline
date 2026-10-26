--!strict
-- Grab, Use, Throw and Dash on keyboard, gamepad and touch, plus the highlight on whatever Grab would act on.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Interaction = require(ReplicatedStorage.Shared.Interaction)
local Net = require(ReplicatedStorage.Shared.Net)
local Tuning = require(ReplicatedStorage.Shared.Tuning)

local Controls = {}

-- Above the default character controls, so ButtonA grabs instead of jumping on a gamepad
local PRIORITY = Enum.ContextActionPriority.High.Value

local player = Players.LocalPlayer
local remote: RemoteEvent
local lastDash = -math.huge

local function rootOf(): BasePart?
	local character = player.Character
	return if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
end

function Controls.send(action: string)
	remote:FireServer(action)
end

local function onPress(action: string)
	return function(_: string, inputState: Enum.UserInputState): Enum.ContextActionResult
		if inputState == Enum.UserInputState.Begin then
			Controls.send(action)
		end
		return Enum.ContextActionResult.Sink
	end
end

local function onUse(_: string, inputState: Enum.UserInputState): Enum.ContextActionResult
	if inputState == Enum.UserInputState.Begin then
		Controls.send("UseStart")
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		Controls.send("UseEnd")
	end
	return Enum.ContextActionResult.Sink
end

-- The local player owns their character's physics, so the dash runs here with no server round trip.
local function onDash(_: string, inputState: Enum.UserInputState): Enum.ContextActionResult
	if inputState ~= Enum.UserInputState.Begin or os.clock() - lastDash < Tuning.DASH_COOLDOWN then
		return Enum.ContextActionResult.Sink
	end
	local root = rootOf()
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not root or not humanoid then
		return Enum.ContextActionResult.Sink
	end
	lastDash = os.clock()
	local move = humanoid.MoveDirection
	local direction = if move.Magnitude > 0.1 then move else root.CFrame.LookVector
	direction = Vector3.new(direction.X, 0, direction.Z).Unit
	task.spawn(function()
		local elapsed = 0
		while elapsed < Tuning.DASH_SECONDS and root.Parent do
			root.AssemblyLinearVelocity = direction * Tuning.DASH_SPEED
				+ Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
			elapsed += RunService.Heartbeat:Wait()
		end
	end)
	return Enum.ContextActionResult.Sink
end

-- A title also creates a touch button. Roblox lays touch buttons out around the jump area by default, which is
-- what we use until playtests say otherwise.
local function bind(name: string, handler: any, title: string?, ...: Enum.KeyCode)
	ContextActionService:BindActionAtPriority(name, handler, title ~= nil, PRIORITY, ...)
	if title then
		ContextActionService:SetTitle(name, title)
	end
end

local function startHighlight()
	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 0.75
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = Workspace.CurrentCamera

	task.spawn(function()
		while true do
			local root = rootOf()
			local adornee: Instance? = nil
			if root then
				local target = Interaction.grabTarget(root, Interaction.heldItem(player.UserId))
				adornee = target.item or target.station
				highlight.OutlineColor = if target.action == "Place"
					then Color3.fromRGB(90, 230, 120)
					else Color3.fromRGB(255, 255, 255)
			end
			highlight.Adornee = adornee
			highlight.Enabled = adornee ~= nil
			task.wait(0.1)
		end
	end)
end

function Controls.start()
	remote = Net.actionRemote()
	bind("CrewGrab", onPress("Grab"), "Grab", Enum.KeyCode.E, Enum.KeyCode.ButtonA)
	bind("CrewUse", onUse, "Use", Enum.KeyCode.F, Enum.KeyCode.ButtonX)
	bind("CrewThrow", onPress("Throw"), "Throw", Enum.KeyCode.Q, Enum.KeyCode.ButtonB)
	bind("CrewDash", onDash, "Dash", Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonR1)
	-- HOLD and LAUNCH NOW are on-screen HUD buttons for touch, so they get no touch button here
	bind("CrewHold", onPress("Hold"), nil, Enum.KeyCode.H, Enum.KeyCode.ButtonY)
	bind("CrewLaunch", onPress("LaunchNow"), nil, Enum.KeyCode.L, Enum.KeyCode.DPadUp)
	startHighlight()
end

return Controls
