-- ========================================
-- Random Walk Price Generator
-- ========================================

StockMarket.RandomWalk = StockMarket.RandomWalk or {}

function StockMarket.RandomWalk:Generate(ticker, currentPrice, config, sectorVolatility, activeEvent)
    if not currentPrice or not tonumber(currentPrice) then
        return nil, nil
    end
    if not config then return currentPrice, 0 end

    local difficulty = tonumber(config.stockDifficulty) or 2000
    local drift = tonumber(config.drift) or 0
    local tickerVolatility = tonumber(config.volatility) or 1.0
    local minTick = tonumber(config.minTick) or -3
    local maxTick = tonumber(config.maxTick) or 3
    
    -- Calculate base sigma from difficulty
    local K = StockMarket.Config.PriceGen.K
    local baseSigma = math.Clamp(K / difficulty, 
        StockMarket.Config.PriceGen.minSigma, 
        StockMarket.Config.PriceGen.maxSigma)
    
    -- Apply volatilities
    local sigma = baseSigma * sectorVolatility * tickerVolatility
    
    -- Apply event modifiers
    if activeEvent then
        drift = drift + (activeEvent.driftModifier or 0)
        sigma = sigma * (activeEvent.volatilityMultiplier or 1.0)
    end
    
    -- Generate random change using Box-Muller transform for normal distribution
    local u1 = math.random()
    local u2 = math.random()
    local z = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    
    -- Price change
    local change = (drift + (z * sigma))
    change = math.Clamp(change, minTick, maxTick)
    
    -- Apply change
    local newPrice = currentPrice + change
    
    -- Enforce minimum price
    newPrice = math.max(newPrice, StockMarket.Config.PriceGen.minPrice)
    
    -- Check daily move cap (unless event overrides)
    if not (activeEvent and activeEvent.ignoreMoveCap) then
        local maxMove = currentPrice * StockMarket.Config.PriceGen.maxDailyMoveCap
        newPrice = math.Clamp(newPrice, currentPrice - maxMove, currentPrice + maxMove)
    end
    
    return newPrice, change
end

function StockMarket.RandomWalk:GenerateJump(currentPrice, magnitude)
    -- Instant jump (for JUMP events)
    local jumpPercent = magnitude / 100
    return currentPrice * (1 + jumpPercent)
end
