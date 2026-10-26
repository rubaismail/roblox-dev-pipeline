local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Countdown = require(ReplicatedStorage.Shared.Countdown)

return function()
	describe("format", function()
		it("pads seconds to two digits", function()
			expect(Countdown.format(65)).to.equal("1:05")
		end)

		it("formats zero", function()
			expect(Countdown.format(0)).to.equal("0:00")
		end)

		it("clamps negative time to zero", function()
			expect(Countdown.format(-3)).to.equal("0:00")
		end)

		it("drops fractional seconds", function()
			expect(Countdown.format(59.9)).to.equal("0:59")
		end)
	end)
end
