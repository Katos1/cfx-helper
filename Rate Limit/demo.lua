local key = 'armour'

CreateRateLimiter(key, {maxAmount = 100, interval = 3000})
ConsumeRateLimit(key, 25, function(success, amount)
  if not success then
    return print('Rate limit reached!')
  end

  print('Consuming ' .. amount)
end)
