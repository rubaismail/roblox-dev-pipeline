local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PartState = require(ReplicatedStorage.Shared.PartState)
local StationRules = require(ReplicatedStorage.Shared.StationRules)

local function part(kind, bolt, fuel)
	local state = PartState.new(kind)
	state.bolt = bolt or 0
	state.fuel = fuel or 0
	return state
end

return function()
	it("lets a free workbench take any rocket section, but not a tool", function()
		expect(StationRules.accepts("Workbench", part("Engine"), false, false)).to.equal(true)
		expect(StationRules.accepts("Workbench", part("Engine"), true, false)).to.equal(false)
		expect(StationRules.accepts("Workbench", part("Extinguisher"), false, false)).to.equal(false)
	end)

	it("only pumps bolted tanks that aren't full yet", function()
		expect(StationRules.accepts("FuelPump", part("FuelTank", 0), false, false)).to.equal(false)
		expect(StationRules.accepts("FuelPump", part("FuelTank", 1, 0.5), false, false)).to.equal(true)
		expect(StationRules.accepts("FuelPump", part("FuelTank", 1, 1), false, false)).to.equal(false)
		expect(StationRules.accepts("FuelPump", part("Body", 1), false, false)).to.equal(false)
	end)

	it("refuses everything while a station is on fire", function()
		expect(StationRules.accepts("FuelPump", part("FuelTank", 1), false, true)).to.equal(false)
		expect(StationRules.accepts("Bin", part("Body"), false, true)).to.equal(false)
	end)

	it("only lets the crane take stackable sections, even when another part was just stacked", function()
		expect(StationRules.accepts("Crane", part("Body", 0), false, false)).to.equal(false)
		expect(StationRules.accepts("Crane", part("Body", 1), true, false)).to.equal(true)
		expect(StationRules.accepts("Crane", part("FuelTank", 1, 0), false, false)).to.equal(false)
	end)

	it("lets the bin take anything", function()
		expect(StationRules.accepts("Bin", part("Extinguisher"), true, false)).to.equal(true)
	end)

	it("never lets anything be put on the conveyor", function()
		expect(StationRules.accepts("Conveyor", part("Engine", 1), false, false)).to.equal(false)
	end)

	it("puts only the extinguisher back on its rack", function()
		expect(StationRules.accepts("ExtinguisherRack", part("Extinguisher"), false, false)).to.equal(true)
		expect(StationRules.accepts("ExtinguisherRack", part("Engine"), false, false)).to.equal(false)
	end)
end
