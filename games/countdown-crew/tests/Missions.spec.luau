local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Missions = require(ReplicatedStorage.Shared.Missions)
local Parts = require(ReplicatedStorage.Shared.Parts)

return function()
	describe("countdownFor", function()
		local launch = { recipe = { "Engine" }, countdown = 100 }

		it("uses the base time for a crew of 3 or 4", function()
			expect(Missions.countdownFor(launch, 3)).to.equal(100)
			expect(Missions.countdownFor(launch, 4)).to.equal(100)
		end)

		it("gives solo and duo crews more time and big crews less", function()
			expect(Missions.countdownFor(launch, 1)).to.equal(140)
			expect(Missions.countdownFor(launch, 2)).to.equal(115)
			expect(Missions.countdownFor(launch, 6)).to.equal(90)
		end)

		it("treats an empty server as solo and an oversized one as six", function()
			expect(Missions.countdownFor(launch, 0)).to.equal(140)
			expect(Missions.countdownFor(launch, 12)).to.equal(90)
		end)
	end)

	describe("EarthPad", function()
		it("starts every recipe with an engine and only uses rocket sections", function()
			for _, launch in Missions.EarthPad.launches do
				expect(launch.recipe[1]).to.equal("Engine")
				for _, kind in launch.recipe do
					expect(Parts.defs[kind].isSection).to.equal(true)
				end
			end
		end)

		it("has one star threshold per star, rising", function()
			local thresholds = Missions.EarthPad.starThresholds
			expect(#thresholds).to.equal(3)
			expect(thresholds[1] < thresholds[2] and thresholds[2] < thresholds[3]).to.equal(true)
		end)
	end)
end
