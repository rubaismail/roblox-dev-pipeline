local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Scoring = require(ReplicatedStorage.Shared.Scoring)

local function result(outcome, payloadDelivered)
	return { outcome = outcome, altitude = 0, payloadDelivered = payloadDelivered, reason = "" }
end

return function()
	describe("launch", function()
		it("adds payload, no-fire and early-launch bonuses to an orbit", function()
			local breakdown = Scoring.launch(result("Orbit", true), false, 12.7)
			expect(breakdown.total).to.equal(100 + 25 + 15 + 12)
			expect(#breakdown.lines).to.equal(4)
		end)

		it("drops the no-fire bonus after a fire", function()
			expect(Scoring.launch(result("HighAltitude", false), true, 0).total).to.equal(50)
		end)

		it("gives an explosion no bonuses at all", function()
			local breakdown = Scoring.launch(result("Exploded", false), false, 30)
			expect(breakdown.total).to.equal(0)
			expect(#breakdown.lines).to.equal(1)
		end)
	end)

	describe("stars", function()
		local thresholds = { 150, 300, 420 }

		it("counts the thresholds reached", function()
			expect(Scoring.stars(0, thresholds, 0)).to.equal(0)
			expect(Scoring.stars(150, thresholds, 0)).to.equal(1)
			expect(Scoring.stars(500, thresholds, 0)).to.equal(3)
		end)

		it("caps a mission that used a HOLD one star below the top", function()
			expect(Scoring.stars(500, thresholds, 1)).to.equal(2)
			expect(Scoring.stars(160, thresholds, 2)).to.equal(1)
		end)
	end)
end
