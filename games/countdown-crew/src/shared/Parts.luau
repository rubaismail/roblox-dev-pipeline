--!strict
-- Every kind of thing a player can carry: rocket sections plus tools.

export type Kind = "Engine" | "FuelTank" | "Body" | "Fins" | "NoseCone" | "Extinguisher"

export type Def = {
	displayName: string,
	color: Color3,
	size: Vector3,
	isSection: boolean, -- goes on the rocket
	needsFuel: boolean,
}

local Parts = {}

Parts.defs = {
	Engine = {
		displayName = "Engine",
		color = Color3.fromRGB(70, 72, 82),
		size = Vector3.new(3, 2.5, 3),
		isSection = true,
		needsFuel = false,
	},
	FuelTank = {
		displayName = "Fuel tank",
		color = Color3.fromRGB(235, 236, 242),
		size = Vector3.new(3, 3.5, 3),
		isSection = true,
		needsFuel = true,
	},
	Body = {
		displayName = "Body",
		color = Color3.fromRGB(205, 64, 64),
		size = Vector3.new(3, 3, 3),
		isSection = true,
		needsFuel = false,
	},
	Fins = {
		displayName = "Fins",
		color = Color3.fromRGB(60, 120, 220),
		size = Vector3.new(4, 1.5, 4),
		isSection = true,
		needsFuel = false,
	},
	NoseCone = {
		displayName = "Nose cone",
		color = Color3.fromRGB(240, 200, 60),
		size = Vector3.new(2.5, 2.5, 2.5),
		isSection = true,
		needsFuel = false,
	},
	Extinguisher = {
		displayName = "Extinguisher",
		color = Color3.fromRGB(220, 30, 30),
		size = Vector3.new(1.2, 2.4, 1.2),
		isSection = false,
		needsFuel = false,
	},
} :: { [Kind]: Def }

function Parts.isKind(value: unknown): boolean
	return type(value) == "string" and (Parts.defs :: any)[value] ~= nil
end

return Parts
