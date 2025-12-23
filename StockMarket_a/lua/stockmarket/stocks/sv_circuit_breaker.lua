-- ========================================
-- Circuit Breaker System
-- ========================================

StockMarket.CircuitBreaker = StockMarket.CircuitBreaker or {}
StockMarket.CircuitBreaker.States = {}

local function safeNum(v, fallback)
    v = tonumber(v)
    if v == nil or v ~= v then return fallback end
    return v
end

function StockMarket.CircuitBreaker:Check(ticker, currentPrice, config)
    if not StockMarket.Config.CircuitBreaker.enabled then return false end

    currentPrice = safeNum(currentPrice, nil)
    if not currentPrice then
        -- If we have no usable price, don't engage breaker this tick
        return false
    end

    local state = self.States[ticker]
    if not state then
        state = {
            windowStart = os.time(),
            windowHigh = currentPrice,
            halted = false,
            haltUntil = 0
        }
        self.States[ticker] = state
    end

    -- Check if currently halted
    if state.halted and os.time() < (state.haltUntil or 0) then
        return true -- Still halted
    elseif state.halted then
        -- Resume trading
        state.halted = false
        self:ResumeTrading(ticker)
        return false
    end

    -- Update window
    local windowSeconds = (config and config.circuitBreaker and config.circuitBreaker.windowSeconds) or StockMarket.Config.CircuitBreaker.windowSeconds or 300
    if os.time() - (state.windowStart or 0) > windowSeconds then
        state.windowStart = os.time()
        state.windowHigh  = currentPrice
    end

    -- Track high safely
    state.windowHigh = safeNum(state.windowHigh, currentPrice)
    if currentPrice > state.windowHigh then
        state.windowHigh = currentPrice
    end

    -- Check for drop
    local high = safeNum(state.windowHigh, currentPrice)
    if high <= 0 then
        return false
    end

    local dropPercent = ((high - currentPrice) / high) * 100
    dropPercent = safeNum(dropPercent, 0)

    local triggerPercent = (config and config.circuitBreaker and config.circuitBreaker.dropPercent) or StockMarket.Config.CircuitBreaker.dropPercentTrigger or 15

    if dropPercent >= triggerPercent then
        -- Trigger halt
        local haltDuration = (config and config.circuitBreaker and config.circuitBreaker.haltSeconds) or StockMarket.Config.CircuitBreaker.haltDurationSeconds or 60
        state.halted = true
        state.haltUntil = os.time() + haltDuration
        self:HaltTrading(ticker, haltDuration)
        return true
    end

    return false
end

function StockMarket.CircuitBreaker:HaltTrading(ticker, duration)
    MsgC(Color(255, 100, 100), string.format("[StockMarket] Circuit breaker triggered for %s - trading halted for %ds\n", ticker, duration))

    -- Broadcast to clients
    net.Start("StockMarket_EventAlert")
    net.WriteString("CIRCUIT BREAKER: " .. ticker .. " trading halted!")
    net.WriteString(ticker)
    net.WriteBool(true) -- isHalt
    net.Broadcast()
end

function StockMarket.CircuitBreaker:ResumeTrading(ticker)
    MsgC(Color(100, 255, 100), string.format("[StockMarket] Trading resumed for %s\n", ticker))

    net.Start("StockMarket_EventAlert")
    net.WriteString("Trading resumed: " .. ticker)
    net.WriteString(ticker)
    net.WriteBool(false)
    net.Broadcast()
end

function StockMarket.CircuitBreaker:IsHalted(ticker)
    local state = self.States[ticker]
    if not state then return false end
    return (state.halted == true) and os.time() < (state.haltUntil or 0)
end
