local rateLimitTracker = {}

local function msecToSeconds(msec)
  return msec / 1000
end

function CreateRateLimiter(rateKey, rateOptions)
  assert(type(rateKey) == 'string')
  assert(type(rateOptions) == 'table')

  if rateLimitTracker[rateKey] then
    return
  end

  rateOptions.amount = 0
  rateOptions.lockState = false
  rateOptions.unlockTime = os.time()

  rateLimitTracker[rateKey] = rateOptions
end

function ConsumeRateLimit(rateKey, rateAmount, cb)
  assert(type(rateKey) == 'string')
  assert(type(rateAmount) == 'number')
  assert(type(cb) == 'function')

  -- Make sure ratelimit exists
  local rateLimitOptions = rateLimitTracker[rateKey]
  if not rateLimitOptions then
    return
  end

  local currTime = os.time()
  local maxAmount = rateLimitOptions.maxAmount
  local newAmount = rateLimitOptions.amount + rateAmount or 0
  local rateInterval = rateLimitOptions.interval
  local isLocked = rateLimitOptions.lockState

  -- Checks if the rate limit is locked
  if rateLimitOptions.unlockTime <= currTime then
    if newAmount > maxAmount then
      if not isLocked then
        -- Locks the ratelimiter
        rateLimitTracker[rateKey].lockState = true
        rateLimitTracker[rateKey].unlockTime = currTime + msecToSeconds(rateInterval)

        return cb(false, maxAmount)
      end

      -- Unlocks the ratelimiter
      rateLimitTracker[rateKey].lockState = false
      rateLimitTracker[rateKey].amount = rateAmount

      return cb(true, newAmount)
    end

    rateLimitOptions.amount = newAmount
    return cb(true, newAmount)
  end

  cb(false, maxAmount)
end
