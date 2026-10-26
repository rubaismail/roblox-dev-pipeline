--!strict
-- The on-screen HUD: countdown, the rocket's build order, score, HOLD and LAUNCH NOW buttons, and banners.
-- Built from code and driven entirely by the MissionState attributes and the LaunchResult event.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Countdown = require(ReplicatedStorage.Shared.Countdown)
local Net = require(ReplicatedStorage.Shared.Net)
local Parts = require(ReplicatedStorage.Shared.Parts)

local Hud = {}

local WHITE = Color3.new(1, 1, 1)
local PANEL = Color3.fromRGB(20, 22, 30)
local DONE = Color3.fromRGB(90, 200, 110)
local WRONG = Color3.fromRGB(230, 70, 60)

local PHASE_TEXT = {
	Waiting = "Waiting for crew",
	Intermission = "Next mission in",
	Briefing = "Briefing",
	Countdown = "T-minus",
	Launch = "Launch!",
	Results = "Mission complete",
}

local function label(parent: Instance, name: string, size: UDim2, position: UDim2, textSize: number): TextLabel
	local text = Instance.new("TextLabel")
	text.Name = name
	text.Size = size
	text.Position = position
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.TextColor3 = WHITE
	text.TextStrokeTransparency = 0.5
	text.TextSize = textSize
	text.Text = ""
	text.Parent = parent
	return text
end

local function button(parent: Instance, name: string, text: string, color: Color3, position: UDim2): TextButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.Size = UDim2.fromOffset(150, 48)
	b.AnchorPoint = Vector2.new(1, 0)
	b.Position = position
	b.BackgroundColor3 = color
	b.Font = Enum.Font.GothamBlack
	b.TextColor3 = WHITE
	b.TextSize = 20
	b.Text = text
	b.Visible = false
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = b
	b.Parent = parent
	return b
end

local function split(list: string?): { string }
	if not list or list == "" then
		return {}
	end
	return string.split(list, ",")
end

function Hud.start(send: (string) -> ())
	local state = Net.missionState()
	local gui = Instance.new("ScreenGui")
	gui.Name = "CrewHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	gui.Parent = (Players.LocalPlayer :: Player):WaitForChild("PlayerGui")

	-- Countdown, top centre
	local phase = label(gui, "Phase", UDim2.fromOffset(300, 22), UDim2.new(0.5, -150, 0, 6), 18)
	local timer = label(gui, "Timer", UDim2.fromOffset(300, 56), UDim2.new(0.5, -150, 0, 26), 52)

	-- Build order: one chip per section, ticked off as the crane stacks them
	local recipeRow = Instance.new("Frame")
	recipeRow.Name = "Recipe"
	recipeRow.BackgroundTransparency = 1
	recipeRow.Size = UDim2.fromOffset(700, 30)
	recipeRow.Position = UDim2.new(0.5, -350, 0, 86)
	recipeRow.Parent = gui
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = recipeRow

	-- Mission info, top left
	local info = label(gui, "Info", UDim2.fromOffset(260, 66), UDim2.fromOffset(12, 6), 18)
	info.TextXAlignment = Enum.TextXAlignment.Left
	info.TextYAlignment = Enum.TextYAlignment.Top

	-- Buttons, top right, big enough for thumbs
	local hold = button(gui, "Hold", "HOLD +15s", Color3.fromRGB(230, 140, 30), UDim2.new(1, -12, 0, 12))
	local launch = button(gui, "LaunchNow", "LAUNCH NOW", Color3.fromRGB(50, 170, 80), UDim2.new(1, -12, 0, 68))
	hold.Activated:Connect(function()
		send("Hold")
	end)
	launch.Activated:Connect(function()
		send("LaunchNow")
	end)

	-- Banner, centre
	local banner = label(gui, "Banner", UDim2.new(0.8, 0, 0, 180), UDim2.fromScale(0.1, 0.3), 30)
	banner.TextWrapped = true
	banner.TextScaled = true
	local bannerSize = Instance.new("UITextSizeConstraint")
	bannerSize.MaxTextSize = 30
	bannerSize.Parent = banner
	banner.BackgroundColor3 = PANEL
	banner.BackgroundTransparency = 1
	local bannerToken = 0
	local function showBanner(text: string, seconds: number?)
		bannerToken += 1
		local token = bannerToken
		banner.Text = text
		banner.BackgroundTransparency = 0.35
		if seconds then
			task.delay(seconds, function()
				if bannerToken == token then
					banner.Text = ""
					banner.BackgroundTransparency = 1
				end
			end)
		end
	end
	local function hideBanner()
		bannerToken += 1
		banner.Text = ""
		banner.BackgroundTransparency = 1
	end

	-- Controls reminder, bottom left, keyboard only
	local help = label(gui, "Help", UDim2.fromOffset(720, 22), UDim2.new(0, 12, 1, -30), 16)
	help.TextXAlignment = Enum.TextXAlignment.Left
	help.Text = "E grab/drop   F (hold) bolt or spray   Q throw   Shift dash   H hold countdown   L launch now"
	help.Visible = UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled

	local function refreshRecipe()
		for _, child in recipeRow:GetChildren() do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		local recipe = split(state:GetAttribute("Recipe") :: string?)
		local stack = split(state:GetAttribute("Stack") :: string?)
		for index, kind in recipe do
			local stacked = stack[index]
			local chip = Instance.new("TextLabel")
			chip.LayoutOrder = index
			chip.Size = UDim2.fromOffset(104, 28)
			chip.Font = Enum.Font.GothamBold
			chip.TextSize = 15
			chip.TextColor3 = WHITE
			chip.BackgroundColor3 = if stacked == nil then PANEL elseif stacked == kind then DONE else WRONG
			chip.BackgroundTransparency = 0.2
			local def = (Parts.defs :: any)[kind]
			local name = if def then def.displayName else kind
			chip.Text = if stacked == nil
				then `{index}. {name}`
				elseif stacked == kind then `✓ {name}`
				else `✗ {name}`
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 8)
			corner.Parent = chip
			-- A swatch in the part's colour, so players learn which grey-box part is which
			if def then
				chip.Size = UDim2.fromOffset(124, 28)
				local padding = Instance.new("UIPadding")
				padding.PaddingLeft = UDim.new(0, 22)
				padding.Parent = chip
				local swatch = Instance.new("Frame")
				swatch.Size = UDim2.fromOffset(14, 14)
				swatch.Position = UDim2.new(0, -16, 0.5, -7)
				swatch.BackgroundColor3 = def.color
				swatch.BorderSizePixel = 0
				swatch.Parent = chip
			end
			chip.Parent = recipeRow
		end
	end

	local function refresh()
		local phaseName = state:GetAttribute("Phase") :: string?
		local timeLeft = (state:GetAttribute("TimeLeft") :: number?) or 0
		phase.Text = PHASE_TEXT[phaseName or ""] or ""
		timer.Text = if phaseName == "Waiting"
				or phaseName == "Launch"
				or phaseName == "Results"
			then ""
			else Countdown.format(timeLeft)
		timer.TextColor3 = if phaseName == "Countdown" and timeLeft <= 10 then WRONG else WHITE

		local launchIndex = (state:GetAttribute("LaunchIndex") :: number?) or 0
		local launchCount = (state:GetAttribute("LaunchCount") :: number?) or 0
		local holdsLeft = (state:GetAttribute("HoldsLeft") :: number?) or 0
		info.Text = `{state:GetAttribute("MissionName") or ""}\nLaunch {launchIndex}/{launchCount}`
			.. `   Score {state:GetAttribute("Score") or 0}\nHolds left {holdsLeft}`

		local recipeSize = #split(state:GetAttribute("Recipe") :: string?)
		local stackSize = #split(state:GetAttribute("Stack") :: string?)
		hold.Visible = phaseName == "Countdown" and holdsLeft > 0
		launch.Visible = phaseName == "Countdown" and recipeSize > 0 and stackSize == recipeSize
		recipeRow.Visible = phaseName == "Briefing" or phaseName == "Countdown" or phaseName == "Launch"

		if phaseName == "Briefing" then
			showBanner(`Launch {launchIndex}: build it bottom to top, in this order`)
		elseif phaseName == "Results" then
			local stars = (state:GetAttribute("Stars") :: number?) or 0
			local starText = string.rep("★", stars) .. string.rep("☆", 3 - stars)
			showBanner(`Mission complete!\n{starText}\nScore {state:GetAttribute("Score") or 0}`)
		elseif phaseName ~= "Launch" then
			hideBanner()
		end
	end

	state.AttributeChanged:Connect(function(attribute)
		if attribute == "Recipe" or attribute == "Stack" then
			refreshRecipe()
		end
		refresh()
	end)
	refreshRecipe()
	refresh()

	Net.launchResultRemote().OnClientEvent:Connect(function(result: any)
		local lines = table.concat(result.lines, "\n")
		showBanner(`{result.label}!\n{result.reason}\n+{result.points} points\n{lines}`, 8)
	end)
end

return Hud
