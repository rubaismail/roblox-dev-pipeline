--!strict
-- Client entry point: starts the camera, controls and HUD.

local CameraController = require(script.Parent.CameraController)
local Controls = require(script.Parent.Controls)
local Hud = require(script.Parent.Hud)

CameraController.start()
Controls.start()
Hud.start(Controls.send)
