--!strict
-- Server entry point. Game systems get required and started from here.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Countdown = require(ReplicatedStorage.Shared.Countdown)

print(`[Countdown Crew] server started, launch in {Countdown.format(90)}`)
