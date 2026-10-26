--!strict
-- Server entry point: builds the pad, wires player actions to the mission and starts the mission loop.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Missions = require(ReplicatedStorage.Shared.Missions)
local Net = require(ReplicatedStorage.Shared.Net)
local Items = require(script.Parent.Items)
local Mission = require(script.Parent.Mission)
local PadBuilder = require(script.Parent.PadBuilder)
local Rocket = require(script.Parent.Rocket)
local Stations = require(script.Parent.Stations)

local pad = PadBuilder.build()
Items.init(pad.folder, pad.stations)
Stations.init(pad.stations, pad.conveyorStart)
Rocket.init(pad.folder, pad.rocketBase)

Net.actionRemote().OnServerEvent:Connect(function(player: Player, action: unknown)
	if type(action) == "string" and (Net.Actions :: { [string]: boolean })[action] then
		Mission.handleAction(player, action)
	end
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
Players.PlayerRemoving:Connect(Mission.forget)

print("[Countdown Crew] server started")
Mission.run(Missions.EarthPad)
