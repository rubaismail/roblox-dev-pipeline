--!strict
-- A token bucket per key (one per player), so a client spamming a remote can't flood the server.
-- Pure: the caller passes the time, which keeps it testable.

export type RateLimiter = {
	capacity: number,
	refillPerSecond: number,
	buckets: { [any]: { tokens: number, updated: number } },
	allow: (self: RateLimiter, key: any, now: number) -> boolean,
	forget: (self: RateLimiter, key: any) -> (),
}

local RateLimiter = {}

local function allow(self: RateLimiter, key: any, now: number): boolean
	local bucket = self.buckets[key]
	if not bucket then
		bucket = { tokens = self.capacity, updated = now }
		self.buckets[key] = bucket
	end
	bucket.tokens = math.min(self.capacity, bucket.tokens + (now - bucket.updated) * self.refillPerSecond)
	bucket.updated = now
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

local function forget(self: RateLimiter, key: any)
	self.buckets[key] = nil
end

-- Allows bursts of `capacity` calls, then `refillPerSecond` calls per second.
function RateLimiter.new(capacity: number, refillPerSecond: number): RateLimiter
	return {
		capacity = capacity,
		refillPerSecond = refillPerSecond,
		buckets = {},
		allow = allow,
		forget = forget,
	}
end

return RateLimiter
