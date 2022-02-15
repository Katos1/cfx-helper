local rateLimitTracker = {}

local function msecToSeconds(msec)
  return msec / 1000
end

local function setTrackerState(rateKey, entries)
  assert(type(rateKey) == 'string')
  assert(type(entries) == 'table')
  assert(rateLimitTracker[rateKey])

  local property, value = table.unpack(entries)
  rateLimitTracker[rateKey][property] = value
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

  local rateLimitOptions = rateLimitTracker[rateKey]
  local currTime = os.time()

  -- Make sure ratelimit exists
  if not rateLimitOptions then
    return
  end

  local unlockTime = rateLimitOptions.unlockTime
  local maxAmount = rateLimitOptions.maxAmount
  local newAmount = rateLimitOptions.amount + rateAmount or 0
  local rateInterval = rateLimitOptions.interval
  local isLocked = rateLimitOptions.lockState

  -- Checks if the rate limit is locked
  if unlockTime <= currTime then
    if newAmount > maxAmount then
      if not isLocked then
        -- Locks the ratelimiter
        local lockTime = currTime + msecToSeconds(rateInterval)

        setTrackerState(rateKey, {'lockState', true})
        setTrackerState(rateKey, {'unlockTime', lockTime})

        return cb(false, maxAmount)
      end

      -- Unlocks the ratelimiter
      setTrackerState(rateKey, {'lockState', false})
      setTrackerState(rateKey, {'amount', rateAmount})
    end

    setTrackerState(rateKey, {'amount', newAmount})
    return cb(true, newAmount)
  end

  cb(false, maxAmount)
end
