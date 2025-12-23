-- ========================================
-- Stock Market Events System
-- ========================================

StockMarket.Events = StockMarket.Events or {}
StockMarket.Events.ActiveEvents = {}
StockMarket.Events.EventQueue = {}

function StockMarket.Events:Initialize()
    -- Schedule random events
    timer.Create("StockMarket_EventScheduler", 300, 0, function()
        self:ScheduleRandomEvent()
    end)
end

function StockMarket.Events:ScheduleRandomEvent()
    local tickers = StockMarket.Config:GetAllTickers()
    if #tickers == 0 then return end
    
    -- Pick random ticker
    local ticker = table.Random(tickers)
    if #ticker.stockEvents == 0 then return end
    
    -- Pick random event based on weights
    local totalWeight = 0
    for _, event in ipairs(ticker.stockEvents) do
        totalWeight = totalWeight + event.weight
    end
    
    local rand = math.random() * totalWeight
    local selectedEvent = nil
    local accumulated = 0
    
    for _, event in ipairs(ticker.stockEvents) do
        accumulated = accumulated + event.weight
        if rand <= accumulated then
            selectedEvent = event
            break
        end
    end
    
    if not selectedEvent then return end
    
    -- Schedule pre-alert
    local preAlertTime = selectedEvent.preAlertSeconds or 15
    timer.Simple(math.random(60, 600), function()
        self:SendPreAlert(ticker.stockPrefix, selectedEvent)
        
        -- Schedule actual event
        timer.Simple(preAlertTime, function()
            self:TriggerEvent(ticker.stockPrefix, selectedEvent)
        end)
    end)
end

function StockMarket.Events:SendPreAlert(ticker, event)
    net.Start("StockMarket_EventPreAlert")
    net.WriteString(event.message)
    net.WriteString(ticker)
    net.Broadcast()
    
    MsgC(Color(255, 255, 100), string.format("[StockMarket] Pre-alert: %s (%s)\n", event.message, ticker))
end

function StockMarket.Events:TriggerEvent(ticker, event)
    local impactType = event.impact.type
    local magnitude = event.impact.magnitude
    local duration = event.impact.duration
    
    local activeEvent = {
        ticker = ticker,
        handle = event.handle,
        type = impactType,
        magnitude = magnitude,
        endTime = os.time() + duration,
        driftModifier = 0,
        volatilityMultiplier = 1.0,
        ignoreMoveCap = false
    }
    
    -- Configure based on type
    if impactType == "JUMP" then
        -- Instant price jump
        local currentPrice = StockMarket.StockEngine:GetPrice(ticker)
        local newPrice = StockMarket.RandomWalk:GenerateJump(currentPrice, magnitude)
        StockMarket.StockEngine:SetPrice(ticker, newPrice)
        activeEvent.ignoreMoveCap = true
    elseif impactType == "DRIFT" then
        activeEvent.driftModifier = magnitude * 0.1
    elseif impactType == "PUMP" then
        activeEvent.driftModifier = magnitude * 0.15
        activeEvent.volatilityMultiplier = 1.5
        activeEvent.ignoreMoveCap = true
    elseif impactType == "CRASH" then
        activeEvent.driftModifier = magnitude * 0.15
        activeEvent.volatilityMultiplier = 2.0
        activeEvent.ignoreMoveCap = true
    elseif impactType == "VOLATILITY" then
        activeEvent.volatilityMultiplier = magnitude * 0.5
    end
    
    self.ActiveEvents[ticker] = activeEvent
    
    -- Broadcast alert
    net.Start("StockMarket_EventAlert")
    net.WriteString(event.message)
    net.WriteString(ticker)
    net.WriteBool(false)
    net.Broadcast()
    
    MsgC(Color(255, 200, 100), string.format("[StockMarket] Event triggered: %s (%s)\n", event.handle, ticker))
    
    -- Schedule cleanup
    timer.Simple(duration, function()
        self.ActiveEvents[ticker] = nil
    end)
end

function StockMarket.Events:GetActiveEvent(ticker)
    local event = self.ActiveEvents[ticker]
    if event and os.time() < event.endTime then
        return event
    end
    return nil
end

-- Initialize on load
if SERVER then
    timer.Simple(5, function()
        StockMarket.Events:Initialize()
    end)
end
