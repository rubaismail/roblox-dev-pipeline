--!strict
-- Client entry point: starts the camera, controls and HUD.

local StarterGui = game:GetService("StarterGui")

local CameraController = require(script.Parent.CameraController)
local Controls = require(script.Parent.Controls)
local Hud = require(script.Parent.Hud)

-- Roblox's player list sits top-right, over the HOLD and LAUNCH NOW buttons. A crew of 6 doesn't need it.
pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.PlayerList, false)

CameraController.start()
Controls.start()
Hud.start(Controls.send)
