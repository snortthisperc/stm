-- ========================================
-- Stock Engine - Main Update Loop (clean, guarded, no 'continue')
-- ========================================

StockMarket.StockEngine = StockMarket.StockEngine or {}
StockMarket.StockEngine.Prices = StockMarket.StockEngine.Prices or {}
StockMarket.StockEngine.PreviousPrices = StockMarket.StockEngine.PreviousPrices or {}
StockMarket.StockEngine.CurrentBars = StockMarket.StockEngine.CurrentBars or {}

-- Seed a ticker's in-memory state safely
function StockMarket.StockEngine:EnsureSeeded(prefix, startPrice)
    if not prefix or prefix == "" then return end

    local p = tonumber(startPrice)
    if not p or p ~= p or p == math.huge or p == -math.huge then
        p = 1
    end

    if not self.Prices[prefix] then
        self.Prices[prefix] = p
        self.PreviousPrices[prefix] = p
    end

    if not self.CurrentBars[prefix] then
        self.CurrentBars[prefix] = {
            open = p, high = p, low = p, close = p,
            volume = 0, buyVolume = 0, sellVolume = 0,
            timestamp = os.time()
        }
    end
    print("[SM Server] EnsureSeeded", prefix, "startPrice:", p)
end

function StockMarket.StockEngine:Start()
    -- Initialize prices from config or database
    local tickers = StockMarket.Config:GetAllTickers()
    for _, ticker in ipairs(tickers) do
        local saved = StockMarket.Persistence:LoadStockState(ticker.stockPrefix)
        local startVal = saved and tonumber(saved.price) or tonumber(ticker.newStockValue) or 1
        self:EnsureSeeded(ticker.stockPrefix, startVal)
    end

    -- Seed one initial bar so charts have at least one point immediately
    for prefix, bar in pairs(self.CurrentBars) do
        StockMarket.Persistence:SavePriceBar(prefix, {
            timestamp = os.time(),
            open = bar.open,
            high = bar.high,
            low  = bar.low,
            close = bar.close,
            volume = bar.volume or 0
        })
    end

    -- Start update loop
    timer.Create("StockMarket_PriceUpdate", StockMarket.Config.TickRateSeconds, 0, function()
        self:UpdatePrices()
    end)

    -- Bar completion (every 60s for 1m bars)
    timer.Create("StockMarket_BarComplete", 60, 0, function()
        self:CompleteBars()
    end)
end

function StockMarket.StockEngine:UpdatePrices()
    local tickers = StockMarket.Config:GetAllTickers()

    for _, ticker in ipairs(tickers) do
        local prefix = ticker.stockPrefix

        -- Ensure seeded if ticker was added at runtime
        if not self.Prices[prefix] or not self.CurrentBars[prefix] then
            local start = tonumber(ticker.newStockValue) or 1
            self:EnsureSeeded(prefix, start)
        end

        -- Check if halted
        if StockMarket.CircuitBreaker:IsHalted(prefix) then
            -- still broadcast bar snapshot so UI volume widgets update even if halted
            local barH = self.CurrentBars[prefix]
            if barH then
                net.Start("StockMarket_BarSnapshot")
                net.WriteString(prefix)
                net.WriteUInt(barH.volume or 0, 32)
                net.WriteUInt(barH.buyVolume or 0, 32)
                net.WriteUInt(barH.sellVolume or 0, 32)
                net.Broadcast()
            end
            goto continue_ticker
        end

        local currentPrice = tonumber(self.Prices[prefix])

        -- Sector lookup: prefer sectorKey if present; fallback to sectorName.
        local sectorData
        if ticker.sectorKey and StockMarket.Config.Markets[ticker.sectorKey] then
            sectorData = StockMarket.Config.Markets[ticker.sectorKey]
        else
            sectorData = StockMarket.Config.Markets[ticker.sectorName] or {}
        end
        local sectorVolatility = tonumber(sectorData.sectorVolatility) or 1.0
        local activeEvent = StockMarket.Events:GetActiveEvent(prefix)

        -- Skip invalid price
        if not currentPrice then
            goto continue_ticker
        end

        -- Generate new price
        local newPrice, change = StockMarket.RandomWalk:Generate(
            prefix, currentPrice, ticker, sectorVolatility, activeEvent
        )

        -- If generator failed, skip this tick
        if not newPrice or not isnumber(newPrice) then
            goto continue_ticker
        end

        -- Circuit breaker
        local halted = StockMarket.CircuitBreaker:Check(prefix, newPrice, ticker)
        if halted then
            goto continue_ticker
        end

        self.PreviousPrices[prefix] = currentPrice
        self.Prices[prefix] = newPrice

        -- Update bar
        local bar = self.CurrentBars[prefix]
        if not bar then
            self:EnsureSeeded(prefix, newPrice)
            bar = self.CurrentBars[prefix]
        end

        -- All numeric
        bar.close = newPrice
        bar.high = math.max(tonumber(bar.high) or newPrice, newPrice)
        bar.low  = math.min(tonumber(bar.low)  or newPrice, newPrice)

        -- Broadcast price update
        self:BroadcastPriceUpdate(prefix, newPrice, change)

        -- Broadcast live bar snapshot
        net.Start("StockMarket_BarSnapshot")
        net.WriteString(prefix)
        net.WriteUInt(bar.volume or 0, 32)
        net.WriteUInt(bar.buyVolume or 0, 32)
        net.WriteUInt(bar.sellVolume or 0, 32)
        net.Broadcast()

        -- Save state periodically
        if math.random() < 0.1 then
            StockMarket.Persistence:SaveStockState(prefix, {
                price = newPrice,
                halted = false,
                activeEvent = activeEvent and activeEvent.handle or nil
            })
        end

        ::continue_ticker::
    end
end

function StockMarket.StockEngine:CompleteBars()
    for prefix, bar in pairs(self.CurrentBars) do
        -- Save bar to history
        StockMarket.Persistence:SavePriceBar(prefix, bar)

        -- Start new bar
        self.CurrentBars[prefix] = {
            open = bar.close,
            high = bar.close,
            low  = bar.close,
            close = bar.close,
            volume = 0,
            buyVolume = 0,
            sellVolume = 0,
            timestamp = os.time()
        }
    end

    -- Cleanup old history every hour (within the first 60 seconds of each hour)
    if os.time() % 3600 < 60 then
        StockMarket.Persistence:CleanupHistory()
    end
end

function StockMarket.StockEngine:BroadcastPriceUpdate(ticker, price, change)
    local prevPrice = self.PreviousPrices[ticker] or price
    local changePercent = prevPrice > 0 and ((price - prevPrice) / prevPrice) * 100 or 0

    net.Start("StockMarket_PriceUpdate")
    net.WriteString(ticker)
    net.WriteFloat(price)
    net.WriteFloat(price - prevPrice)
    net.WriteFloat(changePercent)
    net.Broadcast()
end

function StockMarket.StockEngine:GetPrice(ticker)
    return self.Prices[ticker]
end

function StockMarket.StockEngine:SetPrice(ticker, price)
    self.Prices[ticker] = price
    self:BroadcastPriceUpdate(ticker, price, 0)
end

function StockMarket.StockEngine:SyncAll(ply)
    local data = {}
    for ticker, price in pairs(self.Prices) do
        local prevPrice = self.PreviousPrices[ticker] or price
        data[ticker] = {
            price = price,
            change = price - prevPrice,
            changePercent = prevPrice > 0 and ((price - prevPrice) / prevPrice) * 100 or 0
        }
    end

    net.Start("StockMarket_FullSync")
    local keys = {}
    for t in pairs(data) do keys[#keys + 1] = t end
    net.WriteUInt(#keys, 16)
    for i = 1, #keys do
        local t = keys[i]
        local d = data[t]
        net.WriteString(t)
        net.WriteFloat(d.price or 0)
        net.WriteFloat(d.change or 0)
        net.WriteFloat(d.changePercent or 0)
    end
    net.Send(ply)
end

-- Sync on player join
hook.Add("PlayerInitialSpawn", "StockMarket_SyncPrices", function(ply)
    timer.Simple(2, function()
        if IsValid(ply) then
            StockMarket.StockEngine:SyncAll(ply)
        end
    end)
end)

-- When config changes via admin, rebuild internal caches (optional)
hook.Add("StockMarket_ConfigChanged", "StockEngine_Reload", function()
    StockMarket.StockEngine.allTickers = {}
    for sectorKey, sector in pairs(StockMarket.Config.Markets or {}) do
        for _, ticker in ipairs(sector.tickers or {}) do
            if ticker.enabled ~= false then
                table.insert(StockMarket.StockEngine.allTickers, ticker)
            end
        end
    end
    print("[StockMarket] Stock engine reloaded after config change. Active tickers: " .. #StockMarket.StockEngine.allTickers)
end)
