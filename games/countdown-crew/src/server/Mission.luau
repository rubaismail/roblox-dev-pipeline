--!strict
-- The mission loop: intermission, then briefing, countdown and launch three times, then results.
-- Also turns player actions into item moves, because what an action may do depends on the phase.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FlightModel = require(ReplicatedStorage.Shared.FlightModel)
local Interaction = require(ReplicatedStorage.Shared.Interaction)
local Missions = require(ReplicatedStorage.Shared.Missions)
local Net = require(ReplicatedStorage.Shared.Net)
local Scoring = require(ReplicatedStorage.Shared.Scoring)
local Tuning = require(ReplicatedStorage.Shared.Tuning)
local Items = require(script.Parent.Items)
local Rocket = require(script.Parent.Rocket)
local Stations = require(script.Parent.Stations)

local Mission = {}

local state = Net.missionState()
local launchResultRemote = Net.launchResultRemote()

local using: { [Player]: boolean } = {}
local stack: { FlightModel.Section } = {}
local holdRequested = false
local launchRequested = false

local function rootOf(player: Player): BasePart?
	local character = player.Character
	return if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
end

local function kindsToString(kinds: { string }): string
	return table.concat(kinds, ",")
end

local function stackKinds(): { string }
	local kinds = {}
	for _, section in stack do
		table.insert(kinds, section.kind)
	end
	return kinds
end

-- TimeLeft only changes when the whole second changes, so it doesn't flood the network.
local function setTimeLeft(seconds: number)
	local shown = math.max(0, math.ceil(seconds))
	if state:GetAttribute("TimeLeft") ~= shown then
		state:SetAttribute("TimeLeft", shown)
	end
end

local function runPhase(phase: string, seconds: number)
	state:SetAttribute("Phase", phase)
	local left = seconds
	setTimeLeft(left)
	while left > 0 do
		left -= RunService.Heartbeat:Wait()
		setTimeLeft(left)
	end
end

local function place(item: BasePart, station: BasePart)
	local stationType = station:GetAttribute("StationType")
	if stationType == "Crane" then
		local part = Interaction.readState(item)
		table.insert(stack, { kind = part.kind, fuel = part.fuel })
		Items.destroy(item)
		Rocket.addSection(part.kind)
		state:SetAttribute("Stack", kindsToString(stackKinds()))
	elseif stationType == "Bin" then
		Items.destroy(item)
	else
		Items.placeOn(item, station)
	end
end

function Mission.handleAction(player: Player, action: string)
	if action == "Hold" then
		holdRequested = true
		return
	elseif action == "LaunchNow" then
		launchRequested = true
		return
	elseif action == "UseStart" then
		using[player] = true
		return
	elseif action == "UseEnd" then
		using[player] = nil
		return
	end

	if state:GetAttribute("Phase") ~= "Countdown" then
		return
	end
	local root = rootOf(player)
	if not root then
		return
	end
	local held = Interaction.heldItem(player.UserId)

	if action == "Grab" then
		local target = Interaction.grabTarget(root, held)
		if target.action == "Grab" and target.item then
			Items.attach(player, target.item)
		elseif target.action == "Place" and held and target.station then
			place(held, target.station)
		elseif target.action == "Drop" and held then
			Items.dropToFloor(held, root)
		end
	elseif action == "Throw" and held then
		Items.throw(held, player, root)
	end
end

function Mission.forget(player: Player)
	using[player] = nil
	Items.dropHeld(player)
end

local function removeFallenItems()
	for _, item in Items.all() do
		if item.Position.Y < Tuning.VOID_Y then
			Items.destroy(item)
		end
	end
end

type Totals = { score: number, holdsLeft: number, holdsUsed: number }

-- Runs the countdown for one launch. Returns the seconds left on the clock and whether a fire broke out.
local function runCountdown(launch: Missions.Launch, totals: Totals): (number, boolean)
	local left = Missions.countdownFor(launch, #Players:GetPlayers())
	local hadFire = false
	local spawnTimer = 0
	holdRequested, launchRequested = false, false
	state:SetAttribute("Phase", "Countdown")

	while left > 0 do
		local dt = RunService.Heartbeat:Wait()
		left -= dt

		if holdRequested then
			holdRequested = false
			if totals.holdsLeft > 0 then
				totals.holdsLeft -= 1
				totals.holdsUsed += 1
				left += Tuning.HOLD_SECONDS
				state:SetAttribute("HoldsLeft", totals.holdsLeft)
			end
		end
		-- LAUNCH NOW only counts once every section is on, so one player can't throw away the crew's run
		if launchRequested then
			launchRequested = false
			if #stack == #launch.recipe then
				break
			end
		end

		if Stations.tick(dt, using) then
			hadFire = true
		end
		spawnTimer -= dt
		if spawnTimer <= 0 then
			spawnTimer = Tuning.CONVEYOR_SPAWN_SECONDS
			Stations.feedConveyor(launch.recipe, #stack)
		end
		Stations.restockRack()
		removeFallenItems()
		setTimeLeft(left)
	end
	return math.max(0, left), hadFire
end

local function runLaunch(mission: Missions.Mission, index: number, totals: Totals)
	local launch = mission.launches[index]
	Items.clearAll()
	Stations.reset()
	Rocket.reset()
	table.clear(stack)
	state:SetAttribute("LaunchIndex", index)
	state:SetAttribute("Recipe", kindsToString(launch.recipe))
	state:SetAttribute("Stack", "")

	runPhase("Briefing", Tuning.BRIEFING_SECONDS)
	local secondsLeft, hadFire = runCountdown(launch, totals)

	state:SetAttribute("Phase", "Launch")
	setTimeLeft(0)
	table.clear(using)
	local result = FlightModel.simulate(launch.recipe, stack)
	local breakdown = Scoring.launch(result, hadFire, secondsLeft)
	totals.score += breakdown.total
	state:SetAttribute("Score", totals.score)
	launchResultRemote:FireAllClients({
		outcome = result.outcome,
		label = FlightModel.LABELS[result.outcome],
		reason = result.reason,
		points = breakdown.total,
		lines = breakdown.lines,
	})
	local started = os.clock()
	Rocket.fly(result)
	task.wait(math.max(0, Tuning.LAUNCH_SECONDS - (os.clock() - started)))
end

function Mission.run(mission: Missions.Mission)
	state:SetAttribute("MissionName", mission.name)
	state:SetAttribute("LaunchCount", #mission.launches)
	while true do
		while #Players:GetPlayers() == 0 do
			state:SetAttribute("Phase", "Waiting")
			Players.PlayerAdded:Wait()
		end
		local totals = { score = 0, holdsLeft = Tuning.HOLDS_PER_MISSION, holdsUsed = 0 }
		state:SetAttribute("Score", 0)
		state:SetAttribute("HoldsLeft", totals.holdsLeft)
		state:SetAttribute("Stars", 0)
		state:SetAttribute("LaunchIndex", 0)
		runPhase("Intermission", Tuning.INTERMISSION_SECONDS)

		for index in mission.launches do
			runLaunch(mission, index, totals)
		end

		state:SetAttribute("Stars", Scoring.stars(totals.score, mission.starThresholds, totals.holdsUsed))
		runPhase("Results", Tuning.RESULTS_SECONDS)
	end
end

return Mission
