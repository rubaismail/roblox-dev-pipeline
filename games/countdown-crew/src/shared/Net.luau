--!strict
-- Everything the server and clients share over the network. The server creates each instance; clients wait for it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

-- Actions a client may send. The server ignores anything else.
Net.Actions = {
	Grab = true, -- grab, place or drop, depending on what is in reach
	UseStart = true,
	UseEnd = true,
	Throw = true,
	Hold = true,
	LaunchNow = true,
}

local function getOrCreate(className: string, name: string): Instance
	if RunService:IsServer() then
		local existing = ReplicatedStorage:FindFirstChild(name)
		if existing then
			return existing
		end
		local instance = Instance.new(className)
		instance.Name = name
		instance.Parent = ReplicatedStorage
		return instance
	end
	return ReplicatedStorage:WaitForChild(name)
end

-- Client to server: one action name per press or release.
function Net.actionRemote(): RemoteEvent
	return getOrCreate("RemoteEvent", "CrewAction") :: RemoteEvent
end

-- Server to clients: the flight result and points, fired once per launch.
function Net.launchResultRemote(): RemoteEvent
	return getOrCreate("RemoteEvent", "LaunchResult") :: RemoteEvent
end

-- The mission's live state, as attributes on one folder:
-- Phase, TimeLeft, MissionName, LaunchIndex, LaunchCount, Recipe and Stack (comma-separated kinds),
-- Score, HoldsLeft, Stars.
function Net.missionState(): Folder
	return getOrCreate("Folder", "MissionState") :: Folder
end

return Net
