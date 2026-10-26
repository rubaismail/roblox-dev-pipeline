--!strict
-- Server entry point: builds the pad, wires player actions to the mission and starts the mission loop.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Missions = require(ReplicatedStorage.Shared.Missions)
local Net = require(ReplicatedStorage.Shared.Net)
local Items = require(script.Parent.Items)
local Mission = require(script.Parent.Mission)
local PadBuilder = require(script.Parent.PadBuilder)
local RateLimiter = require(script.Parent.RateLimiter)
local Rocket = require(script.Parent.Rocket)
local Stations = require(script.Parent.Stations)

local pad = PadBuilder.build()
Items.init(pad.folder, pad.stations)
Stations.init(pad.stations, pad.conveyorStart)
Rocket.init(pad.folder, pad.rocketBase)

-- Holding Use and mashing Grab stays well under 10 a second; anything faster is dropped.
local actionLimiter = RateLimiter.new(20, 10)

-- The only remote clients can fire. It takes one known action name; what that action may do (distance, phase,
-- what is held) is checked by Mission and Interaction on the server.
Net.actionRemote().OnServerEvent:Connect(function(player: Player, action: unknown)
	if type(action) ~= "string" or not (Net.Actions :: { [string]: boolean })[action] then
		return
	end
	-- UseEnd is never dropped, so a limited player can't get stuck holding Use
	if action ~= "UseEnd" and not actionLimiter:allow(player, os.clock()) then
		return
	end
	Mission.handleAction(player, action)
end)

local function watch(player: Player)
	player.CharacterRemoving:Connect(function()
		Items.dropHeld(player)
	end)
end
Players.PlayerAdded:Connect(watch)
for _, player in Players:GetPlayers() do
	watch(player)
end
Players.PlayerRemoving:Connect(function(player)
	Mission.forget(player)
	actionLimiter:forget(player)
end)

print("[Countdown Crew] server started")
Mission.run(Missions.EarthPad)
