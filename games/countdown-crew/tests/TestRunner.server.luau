-- Runs every *.spec file when the place is built from test.project.json. Results print to Output.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TestEZ = require(ReplicatedStorage.DevPackages.TestEZ)

TestEZ.TestBootstrap:run({ ServerScriptService.Tests })
