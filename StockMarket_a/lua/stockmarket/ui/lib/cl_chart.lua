-- ========================================
-- Chart Component (Candlestick + Line)
-- ========================================


StockMarket.UI = StockMarket.UI or {}
StockMarket.UI.Chart = StockMarket.UI.Chart or {}
StockMarket.UI.Lib = StockMarket.UI.Lib or {}
local SM = StockMarket

function StockMarket.UI.Chart:Create(parent)
    local chart = vgui.Create("DPanel", parent)
    chart:Dock(FILL)

    chart.data = {}
    chart.ticker = nil
    chart.minPrice = 0
    chart.maxPrice = 0
    chart.currentLivePoint = nil
    chart.lastHistoryTs = 0

    chart.Paint = function(self, w, h)
        -- Background
        surface.SetDrawColor(StockMarket.UI.Colors.BackgroundLight)
        surface.DrawRect(0, 0, w, h)

        -- Define paddings FIRST (so we can use them below)
        local paddingLeft  = 70
        local paddingRight = 20  -- extra room on the right edge
        local paddingTop   = 40
        local paddingBot   = 40

        -- Account for scrollbars (if inside a DScrollPanel)
        local effectiveW = w
        local holder = self:GetParent()
        if IsValid(holder) and holder:GetParent() and holder:GetParent():GetName() == "DScrollPanel" then
            -- Typical GMod vertical scrollbar width is ~8
            effectiveW = w - 8
        end

        -- Then use effectiveW instead of w for right edge calculations
        local chartW = effectiveW - (paddingLeft + paddingRight)
        local chartH = h - (paddingTop + paddingBot)

        -- Build series (history + live)
        local series = {}
        for i, point in ipairs(self.data) do
            series[#series + 1] = point
        end
        if self.currentLivePoint then
            if (#series == 0) or (self.currentLivePoint.timestamp > (series[#series].timestamp or 0)) then
                series[#series + 1] = self.currentLivePoint
            end
        end

        if #series == 0 then
            local msg = self.ticker and "Loading history..." or "No data available"
            draw.SimpleText(msg, "StockMarket_TextFont", w/2, h/2, StockMarket.UI.Colors.TextMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end

        -- Range calc
        self.minPrice = math.huge
        self.maxPrice = -math.huge
        for _, point in ipairs(series) do
            self.minPrice = math.min(self.minPrice, point.low or point.close or 0)
            self.maxPrice = math.max(self.maxPrice, point.high or point.close or 0)
        end
        local range = self.maxPrice - self.minPrice
        if range <= 0 then range = 1 end

        -- Grid lines + left axis labels
        surface.SetDrawColor(StockMarket.UI.Colors.Border)
        for i = 0, 4 do
            local y = paddingTop + (chartH / 4) * i
            surface.DrawLine(paddingLeft, y, effectiveW - paddingRight, y)
            local priceAtLine = self.maxPrice - (range / 4) * i
            draw.SimpleText(
                StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(priceAtLine, 2)),
                "StockMarket_SmallFont",
                paddingLeft - 5,
                y,
                StockMarket.UI.Colors.TextSecondary,
                TEXT_ALIGN_RIGHT,
                TEXT_ALIGN_CENTER
            )
        end

        -- Points
        local points = {}
        for i, point in ipairs(series) do
            local x = paddingLeft + (chartW / math.max(1, (#series - 1))) * (i - 1)
            local price = point.close or point.price or 0
            local y = paddingTop + chartH - ((price - self.minPrice) / range) * chartH
            -- Clamp to right edge to avoid minor overshoot
            if x > (effectiveW - paddingRight) then x = effectiveW - paddingRight end
            points[#points + 1] = { x = x, y = y, price = price }
        end

        -- Line
        surface.SetDrawColor(StockMarket.UI.Colors.Primary)
        for i = 1, #points - 1 do
            surface.DrawLine(points[i].x, points[i].y, points[i + 1].x, points[i + 1].y)
        end

        -- Dots
        for _, p in ipairs(points) do
            surface.DrawRect(p.x - 2, p.y - 2, 4, 4)
        end

        -- Tooltip (respect effective right edge)
        local mx, my = self:CursorPos()
        if mx >= paddingLeft and mx <= (effectiveW - paddingRight) and my >= paddingTop and my <= (h - paddingBot) then
            local closestDist, closestPoint = math.huge, nil
            for _, p in ipairs(points) do
                local dist = math.abs(mx - p.x)
                if dist < closestDist then closestDist, closestPoint = dist, p end
            end
            if closestPoint and closestDist < 20 then
                local tooltipText = StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(closestPoint.price, 2))
                surface.SetFont("StockMarket_SmallFont")
                local tw, th = surface.GetTextSize(tooltipText)
                local tx = closestPoint.x + 10
                local ty = closestPoint.y - 20
                draw.RoundedBox(4, tx, ty, tw + 12, th + 8, StockMarket.UI.Colors.Background)
                draw.SimpleText(tooltipText, "StockMarket_SmallFont", tx + 6, ty + 4, StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end
        end
    end

    function chart:SetData(data)
        self.data = data or {}
        if #self.data > 0 then
            self.lastHistoryTs = self.data[#self.data].timestamp or 0
        else
            self.lastHistoryTs = 0
        end
        self.currentLivePoint = nil
        self:InvalidateLayout(true)
        self:InvalidateParent(true)
    end

    function chart:LoadHistory(ticker, seconds)
        self.ticker = ticker
        local cached = StockMarket.StockData and StockMarket.StockData.History and StockMarket.StockData.History[ticker]
        if cached and #cached > 0 then
            self:SetData(cached)
        end
        net.Start("StockMarket_RequestHistory")
        net.WriteString(ticker)
        net.WriteInt(seconds or 3600, 32)
        net.SendToServer()
    end

    chart._historyHookId = "SM_History_" .. tostring(chart) .. "_" .. tostring(SysTime())
    hook.Add("StockMarket_HistoryUpdated", chart._historyHookId, function(updatedTicker, history)
        if not IsValid(chart) then
            hook.Remove("StockMarket_HistoryUpdated", chart._historyHookId)
            return
        end
        if chart.ticker ~= updatedTicker then return end
        chart:SetData(history or {})
    end)

    chart._priceHookId = "SM_Price_" .. tostring(chart) .. "_" .. tostring(SysTime())
    hook.Add("StockMarket_PriceUpdated", chart._priceHookId, function(updatedTicker, newPrice, change, changePercent)
        if not IsValid(chart) then
            hook.Remove("StockMarket_PriceUpdated", chart._priceHookId)
            return
        end
        if chart.ticker ~= updatedTicker then return end

        local now = os.time()
        local minuteTs = now
        if not chart.currentLivePoint then
            local seed = newPrice
            local last = (#chart.data > 0) and chart.data[#chart.data] or nil
            if last and last.close then seed = last.close end
            chart.currentLivePoint = {
                timestamp = minuteTs,
                open = seed,
                high = newPrice,
                low  = newPrice,
                close = newPrice,
                volume = 0
            }
        else
            local lp = chart.currentLivePoint
            lp.timestamp = minuteTs
            lp.close = newPrice
            lp.high = math.max(lp.high, newPrice)
            lp.low  = math.min(lp.low, newPrice)
        end
        chart:InvalidateLayout(true)
        chart:InvalidateParent(true)
    end)

    chart.OnRemove = function()
        if chart._historyHookId then
            hook.Remove("StockMarket_HistoryUpdated", chart._historyHookId)
        end
        if chart._priceHookId then
            hook.Remove("StockMarket_PriceUpdated", chart._priceHookId)
        end
    end

    return chart
end

-- Wrapper so existing code using Lib:Chart still works
function StockMarket.UI.Lib:Chart(parent)
    return StockMarket.UI.Chart:Create(parent)
end

-- Global receiver for history data stays unchanged
net.Receive("StockMarket_HistoryData", function()
    local ticker = net.ReadString()
    local count = net.ReadUInt(16) or 0
    local history = {}
    for i = 1, count do
        history[i] = {
            timestamp = net.ReadUInt(32),
            open = net.ReadFloat(),
            high = net.ReadFloat(),
            low  = net.ReadFloat(),
            close = net.ReadFloat(),
            volume = net.ReadUInt(32)
        }
    end

    StockMarket.StockData = StockMarket.StockData or {}
    StockMarket.StockData.History = StockMarket.StockData.History or {}
    StockMarket.StockData.History[ticker] = history

    print("[StockMarket] Client received history for", ticker, "points:", #history)
    hook.Run("StockMarket_HistoryUpdated", ticker, history)
end)