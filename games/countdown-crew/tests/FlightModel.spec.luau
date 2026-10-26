local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FlightModel = require(ReplicatedStorage.Shared.FlightModel)

local RECIPE = { "Engine", "FuelTank", "Body", "Fins", "NoseCone" }

local function section(kind, fuel)
	return { kind = kind, fuel = fuel or 0 }
end

local function fullStack(tankFuel)
	return {
		section("Engine"),
		section("FuelTank", tankFuel),
		section("Body"),
		section("Fins"),
		section("NoseCone"),
	}
end

return function()
	it("reaches orbit with every section in order and a full tank", function()
		local result = FlightModel.simulate(RECIPE, fullStack(1))
		expect(result.outcome).to.equal("Orbit")
		expect(result.payloadDelivered).to.equal(true)
	end)

	it("blows up when nothing was stacked", function()
		expect(FlightModel.simulate(RECIPE, {}).outcome).to.equal("Exploded")
	end)

	it("blows up when sections are out of order", function()
		local result = FlightModel.simulate(RECIPE, { section("Engine"), section("Body") })
		expect(result.outcome).to.equal("Exploded")
		expect(result.reason).to.equal("Body was stacked out of order")
	end)

	it("blows up when more sections are stacked than the recipe has", function()
		local stack = fullStack(1)
		table.insert(stack, section("Body"))
		expect(FlightModel.simulate(RECIPE, stack).outcome).to.equal("Exploded")
	end)

	it("blows up with an engine and no fuel", function()
		expect(FlightModel.simulate(RECIPE, { section("Engine") }).outcome).to.equal("Exploded")
	end)

	it("reaches high altitude when a section is missing, and says which", function()
		local stack = fullStack(1)
		table.remove(stack) -- no nose cone
		table.remove(stack) -- no fins
		local result = FlightModel.simulate(RECIPE, stack)
		expect(result.outcome).to.equal("HighAltitude")
		expect(result.reason).to.equal("Missing the fins")
		expect(result.payloadDelivered).to.equal(false)
	end)

	it("reaches high altitude with every section but a tank between half and full", function()
		local result = FlightModel.simulate(RECIPE, fullStack(0.6))
		expect(result.outcome).to.equal("HighAltitude")
		expect(result.payloadDelivered).to.equal(true)
	end)

	it("climbs higher with more fuel and more sections", function()
		local low = FlightModel.simulate(RECIPE, fullStack(0.5)).altitude
		local high = FlightModel.simulate(RECIPE, fullStack(0.9)).altitude
		expect(high > low).to.equal(true)
		expect(high < 1000).to.equal(true)
	end)

	it("falls back down with less than half a tank", function()
		expect(FlightModel.simulate(RECIPE, fullStack(0.4)).outcome).to.equal("FellBack")
	end)

	it("has a label for every outcome", function()
		for _, outcome in { "Orbit", "HighAltitude", "FellBack", "Exploded" } do
			expect(FlightModel.LABELS[outcome]).to.be.ok()
		end
	end)
end
