local ServerScriptService = game:GetService("ServerScriptService")

local RateLimiter = require(ServerScriptService.Server.RateLimiter)

return function()
	it("allows a burst up to capacity, then refuses", function()
		local limiter = RateLimiter.new(3, 1)
		expect(limiter:allow("a", 0)).to.equal(true)
		expect(limiter:allow("a", 0)).to.equal(true)
		expect(limiter:allow("a", 0)).to.equal(true)
		expect(limiter:allow("a", 0)).to.equal(false)
	end)

	it("refills over time, but never above capacity", function()
		local limiter = RateLimiter.new(2, 4)
		limiter:allow("a", 0)
		limiter:allow("a", 0)
		expect(limiter:allow("a", 0.1)).to.equal(false)
		expect(limiter:allow("a", 0.25)).to.equal(true)
		-- A long pause refills to 2, not more
		expect(limiter:allow("a", 100)).to.equal(true)
		expect(limiter:allow("a", 100)).to.equal(true)
		expect(limiter:allow("a", 100)).to.equal(false)
	end)

	it("keeps a separate bucket per key", function()
		local limiter = RateLimiter.new(1, 1)
		expect(limiter:allow("a", 0)).to.equal(true)
		expect(limiter:allow("b", 0)).to.equal(true)
		expect(limiter:allow("a", 0)).to.equal(false)
	end)

	it("starts a forgotten key fresh", function()
		local limiter = RateLimiter.new(1, 0)
		limiter:allow("a", 0)
		limiter:forget("a")
		expect(limiter:allow("a", 0)).to.equal(true)
	end)
end
