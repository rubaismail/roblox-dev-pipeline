local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PartState = require(ReplicatedStorage.Shared.PartState)
local Tuning = require(ReplicatedStorage.Shared.Tuning)

return function()
	describe("bolting", function()
		it("starts unbolted and needs bolting", function()
			local state = PartState.new("Engine")
			expect(PartState.isBolted(state)).to.equal(false)
			expect(PartState.needsBolting(state)).to.equal(true)
		end)

		it("is bolted after BOLT_SECONDS of work, and never goes past 1", function()
			local state = PartState.new("Body")
			PartState.addBolt(state, Tuning.BOLT_SECONDS / 2)
			expect(state.bolt).to.be.near(0.5)
			PartState.addBolt(state, Tuning.BOLT_SECONDS)
			expect(state.bolt).to.equal(1)
			expect(PartState.needsBolting(state)).to.equal(false)
		end)

		it("never asks to bolt a tool", function()
			expect(PartState.needsBolting(PartState.new("Extinguisher"))).to.equal(false)
		end)
	end)

	describe("fuelling", function()
		it("fills over FUEL_SECONDS without catching fire", function()
			local state = PartState.new("FuelTank")
			expect(PartState.addFuel(state, Tuning.FUEL_SECONDS)).to.equal(false)
			expect(state.fuel).to.equal(1)
		end)

		it("catches fire once a full tank sits on the pump for OVERFILL_SECONDS", function()
			local state = PartState.new("FuelTank")
			PartState.addFuel(state, Tuning.FUEL_SECONDS)
			expect(PartState.addFuel(state, Tuning.OVERFILL_SECONDS - 0.1)).to.equal(false)
			expect(PartState.addFuel(state, 0.2)).to.equal(true)
		end)
	end)

	describe("isStackable", function()
		it("needs a section to be bolted", function()
			local state = PartState.new("NoseCone")
			expect(PartState.isStackable(state)).to.equal(false)
			state.bolt = 1
			expect(PartState.isStackable(state)).to.equal(true)
		end)

		it("needs a tank to have some fuel, but not a full tank", function()
			local state = PartState.new("FuelTank")
			state.bolt = 1
			expect(PartState.isStackable(state)).to.equal(false)
			state.fuel = 0.3
			expect(PartState.isStackable(state)).to.equal(true)
		end)

		it("never stacks a tool", function()
			local state = PartState.new("Extinguisher")
			state.bolt = 1
			expect(PartState.isStackable(state)).to.equal(false)
		end)
	end)
end
