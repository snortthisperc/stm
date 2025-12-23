
-- ========================================
-- Individual Stock Ticker View (CLIENT)
-- ========================================

-- Avoid reassigning globals; just ensure they exist once somewhere (init file).
-- Use locals to reduce global table lookups in hot paths.
local SM = StockMarket
SM.UI = SM.UI or {}
SM.StockData = SM.StockData or {}

-- Provide a local alias for frequently used sub-tables
local UI = SM.UI
local Colors = UI.Colors
local Config = SM.Config

-- Live bar cache receiver (volume/buys/sells)
StockMarket.StockData = StockMarket.StockData or {}
if CLIENT then
    SM.StockData.Bar = SM.StockData.Bar or {}
    net.Receive("StockMarket_BarSnapshot", function()
        local ticker = net.ReadString()
        local vol    = net.ReadUInt(32)
        local buyVol = net.ReadUInt(32)
        local sellVol= net.ReadUInt(32)
        SM.StockData.Bar[ticker] = {
            volume = vol, buyVolume = buyVol, sellVolume = sellVol
        }
        hook.Run("StockMarket_BarUpdated", ticker, vol, buyVol, sellVol)
    end)
end

-- RESTORE ORIGINAL SIGNATURE: TickerView(parent, ticker)
function StockMarket.UI.TickerView(parent, ticker)
    if not ticker or ticker == "" then return nil end
    
    local view = vgui.Create("DPanel", parent)
    view:Dock(FILL)
    view.Paint = function() end
    
    -- keep chart local
    local chart

    -- One scroll wrapping the entire ticker page
    local scroll = StockMarket.UI.Lib:ScrollPanel(view)
    scroll:Dock(FILL)
    scroll:DockMargin(20, 20, 20, 20)

    -- Header
    local header = vgui.Create("DPanel", scroll)
    header:Dock(TOP)
    header:SetTall(80)
    header:DockMargin(0, 0, 0, 20)
    header.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, Colors.BackgroundLight)
        draw.SimpleText(ticker, "StockMarket_TitleFont", 20, 20, Colors.Primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local pd = SM.StockData:GetPrice(ticker)
        if pd then
            local px = Config.CurrencySymbol .. string.Comma(math.Round(pd.price, 2))
            draw.SimpleText(px, "StockMarket_SubtitleFont", w - 20, 20, Colors.TextPrimary, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

            local col  = pd.change >= 0 and Colors.Success or Colors.Danger
            local sign = pd.change >= 0 and "+" or ""
            local diff = string.format("%s%s%.2f (%.2f%%)", sign, Config.CurrencySymbol, pd.change, pd.changePercent)
            draw.SimpleText(diff, "StockMarket_TextFont", w - 20, 50, col, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        end
    end

    -- Stats row
    local statsPanel = vgui.Create("DPanel", scroll)
    statsPanel:Dock(TOP)
    statsPanel:SetTall(40)
    statsPanel:DockMargin(0, 0, 0, 20)
    statsPanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, StockMarket.UI.Colors.BackgroundLight)
    end

    local volLabel = vgui.Create("DLabel", statsPanel)
    volLabel:SetPos(20, 10)
    volLabel:SetFont("StockMarket_SmallFont")
    volLabel:SetTextColor(StockMarket.UI.Colors.TextSecondary)
    volLabel:SetText("Volume: 0   Net Flow: 0")
    volLabel:SizeToContents()

    local highLabel = vgui.Create("DLabel", statsPanel)
    highLabel:SetPos(320, 10)
    highLabel:SetFont("StockMarket_SmallFont")
    highLabel:SetTextColor(StockMarket.UI.Colors.TextSecondary)
    highLabel:SetText("24h High: " .. StockMarket.Config.CurrencySymbol .. "0.00")
    highLabel:SizeToContents()

    local lowLabel = vgui.Create("DLabel", statsPanel)
    lowLabel:SetPos(520, 10)
    lowLabel:SetFont("StockMarket_SmallFont")
    lowLabel:SetTextColor(StockMarket.UI.Colors.TextSecondary)
    lowLabel:SetText("24h Low: " .. StockMarket.Config.CurrencySymbol .. "0.00")
    lowLabel:SizeToContents()

    -- Chart container
    local chartContainer = vgui.Create("DPanel", scroll)
    chartContainer:Dock(TOP)
    chartContainer:SetTall(400)
    chartContainer:DockMargin(0, 0, 0, 20)

    local chart
    local function CreateChart()
        if not (UI.Chart and UI.Chart.Create) then return false end
        chart = UI.Chart:Create(chartContainer)
        chart:Dock(FILL)
        chart:LoadHistory(ticker, 3600)
        return true
    end

    timer.Simple(0, function()
        if not IsValid(view) then return end
        if not CreateChart() then
            timer.Simple(0.05, function()
                if IsValid(view) then CreateChart() end
            end)
        end
    end)

    local function Update24hStats()
        if not IsValid(chart) then return end
        local series = {}
        for i, p in ipairs(chart.data or {}) do table.insert(series, p) end
        if chart.currentLivePoint then table.insert(series, chart.currentLivePoint) end

        if #series == 0 then
            highLabel:SetText("24h High: " .. StockMarket.Config.CurrencySymbol .. "0.00")
            lowLabel:SetText("24h Low: " .. StockMarket.Config.CurrencySymbol .. "0.00")
            highLabel:SizeToContents(); lowLabel:SizeToContents()
            return
        end

        local now = os.time()
        local cutoff = now - 24 * 3600
        local hi, lo = -math.huge, math.huge
        for _, p in ipairs(series) do
            local ts = p.timestamp or 0
            if ts >= cutoff then
                local hiP = p.high or p.close or 0
                local loP = p.low or p.close or 0
                hi = math.max(hi, hiP)
                lo = math.min(lo, loP)
            end
        end
        if hi == -math.huge then hi = 0 end
        if lo ==  math.huge then lo = 0 end

        highLabel:SetText("24h High: " .. StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(hi, 2)))
        lowLabel:SetText("24h Low: " .. StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(lo, 2)))
        highLabel:SizeToContents(); lowLabel:SizeToContents()
    end

    local function UpdateBarStats()
        local bar = StockMarket.StockData.Bar and StockMarket.StockData.Bar[ticker]
        local vol = bar and bar.volume or 0
        local buyV = bar and bar.buyVolume or 0
        local sellV = bar and bar.sellVolume or 0
        local netFlow = buyV - sellV
        volLabel:SetText(string.format("Volume: %s   Net Flow: %s", string.Comma(vol), string.Comma(netFlow)))
        volLabel:SizeToContents()
    end

    local histHook = "SM_TickerStats_H_" .. ticker .. "_" .. tostring(SysTime())
    local priceHook = "SM_TickerStats_P_" .. ticker .. "_" .. tostring(SysTime())
    local barHook   = "SM_TickerStats_B_" .. ticker .. "_" .. tostring(SysTime())

    hook.Add("StockMarket_HistoryUpdated", histHook, function(updatedTicker)
        if not IsValid(view) then hook.Remove("StockMarket_HistoryUpdated", histHook) return end
        if updatedTicker ~= ticker then return end
        Update24hStats()
    end)
    hook.Add("StockMarket_PriceUpdated", priceHook, function(updatedTicker)
        if not IsValid(view) then hook.Remove("StockMarket_PriceUpdated", priceHook) return end
        if updatedTicker ~= ticker then return end
        Update24hStats()
    end)
    hook.Add("StockMarket_BarUpdated", barHook, function(updatedTicker)
        if not IsValid(view) then hook.Remove("StockMarket_BarUpdated", barHook) return end
        if updatedTicker ~= ticker then return end
        UpdateBarStats()
    end)

    timer.Simple(0.2, function()
        if IsValid(view) then
            Update24hStats()
            UpdateBarStats()
        end
    end)

    local refreshId = "SM_ChartRefresh_" .. ticker
    timer.Create(refreshId, 120, 0, function()
        if not IsValid(view) or not IsValid(chart) then timer.Remove(refreshId) return end
        chart:LoadHistory(ticker, 3600)
    end)

    local tradeRow = vgui.Create("DPanel", scroll)
    tradeRow:Dock(TOP)
    tradeRow:SetTall(300)
    tradeRow:DockMargin(0, 0, 0, 0)
    tradeRow.Paint = nil

    -- Helper funcs used by both columns (defined early so Quick Actions can use them)
    local function GetOwnedSharesForTicker(tkr)
        local pf = StockMarket.ClientPortfolio or {}
        for _, p in ipairs(pf.positions or {}) do
            if string.upper(tostring(p.ticker or "")) == string.upper(tostring(tkr or "")) then
                return tonumber(p.shares) or 0
            end
        end
        return 0
    end
    local function GetCurrentPrice(tkr)
        local pd = StockMarket.StockData:GetPrice(tkr)
        return pd and tonumber(pd.price) or 0
    end

    -- Forward declare variables that will be used across columns
    local orderSide = "BUY"
    local sharesInput

    -- Left column: Quick Actions
    local quickCol = vgui.Create("DPanel", tradeRow)
    quickCol:Dock(LEFT)
    quickCol:SetWide(300)
    quickCol:DockMargin(0, 0, 10, 0)
    quickCol.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, StockMarket.UI.Colors.BackgroundLight)
        draw.SimpleText("Quick Actions", "StockMarket_SubtitleFont", 12, 10, StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    -- Middle column: Order Entry (BUY/SELL)
    local trade = vgui.Create("DPanel", tradeRow)
    trade:Dock(LEFT)
    trade:SetWide(420)
    trade:DockMargin(0, 0, 10, 0)
    trade.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, StockMarket.UI.Colors.BackgroundLight)
    end

    local buyBtn  = vgui.Create("DButton", trade)
    buyBtn:SetText("")
    buyBtn:SetPos(20, 20); buyBtn:SetSize(150, 40)
    buyBtn.DoClick = function() orderSide = "BUY" end
    buyBtn.Paint = function(self, w, h)
        local isActive = (orderSide == "BUY")
        local col = isActive and StockMarket.UI.Colors.Primary or StockMarket.UI.Colors.BackgroundDark
        local textCol = isActive and StockMarket.UI.Colors.TextPrimary or StockMarket.UI.Colors.TextSecondary
        draw.RoundedBox(6, 0, 0, w, h, col)
        draw.SimpleText("BUY", "StockMarket_ButtonFont", w/2, h/2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local sellBtn = vgui.Create("DButton", trade)
    sellBtn:SetText("")
    sellBtn:SetPos(180, 20); sellBtn:SetSize(150, 40)
    sellBtn.DoClick = function() orderSide = "SELL" end
    sellBtn.Paint = function(self, w, h)
        local isActive = (orderSide == "SELL")
        local col = isActive and StockMarket.UI.Colors.Primary or StockMarket.UI.Colors.BackgroundDark
        local textCol = isActive and StockMarket.UI.Colors.TextPrimary or StockMarket.UI.Colors.TextSecondary
        draw.RoundedBox(6, 0, 0, w, h, col)
        draw.SimpleText("SELL", "StockMarket_ButtonFont", w/2, h/2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local orderCombo = StockMarket.UI.Lib:ComboBox(trade, {"Market Order",})
    orderCombo:SetPos(20, 80); orderCombo:SetSize(310, 35)

    local sharesLabel = vgui.Create("DLabel", trade)
    sharesLabel:SetPos(20, 130)
    sharesLabel:SetFont("StockMarket_TextFont")
    sharesLabel:SetTextColor(StockMarket.UI.Colors.TextSecondary)
    sharesLabel:SetText("Number of Shares:")
    sharesLabel:SizeToContents()

    sharesInput = vgui.Create("DTextEntry", trade)
    sharesInput:SetPos(20, 160); sharesInput:SetSize(310, 35)
    sharesInput:SetFont("StockMarket_TextFont")
    sharesInput:SetTextColor(StockMarket.UI.Colors.TextPrimary)
    sharesInput:SetDrawBackground(true)
    sharesInput:SetPaintBackground(true)
    sharesInput.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, StockMarket.UI.Colors.Background)
        self:DrawTextEntryText(StockMarket.UI.Colors.TextPrimary, StockMarket.UI.Colors.Primary, StockMarket.UI.Colors.TextPrimary)
    end

    local executeBtn = UI.Lib:Button(trade, "EXECUTE ORDER", function()
        local shares = tonumber(sharesInput:GetValue()) or 0
        if shares <= 0 then
            UI.Notifications:Add("Enter valid share amount", "error") return
        end
        local orderTypeText = orderCombo:GetSelected() or "Market Order"
        local orderType = orderTypeText == "Limit Order" and SM.Enums.OrderType.LIMIT or SM.Enums.OrderType.MARKET
        local side = (orderSide == "BUY") and SM.Enums.OrderSide.BUY or SM.Enums.OrderSide.SELL

        net.Start("StockMarket_PlaceOrder")
            net.WriteInt(1, 8)
            net.WriteString(ticker)
            net.WriteInt(orderType, 8)
            net.WriteInt(side, 8)
            net.WriteInt(shares, 32)
            net.WriteFloat(0)
        net.SendToServer()
    end)
    executeBtn:SetPos(20, 215); executeBtn:SetSize(310, 45)

    -- Right column: Summary (scooted right) - NOW sharesInput exists
    local summary = vgui.Create("DPanel", tradeRow)
    summary:Dock(FILL)
    summary:DockMargin(0, 0, 0, 0)
    summary.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, StockMarket.UI.Colors.Background)
        draw.SimpleText("Order Summary", "StockMarket_SubtitleFont", 15, 15, StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local shares = tonumber(sharesInput:GetValue()) or 0
        local pd = StockMarket.StockData:GetPrice(ticker)
        local price = pd and pd.price or 0
        local total = shares * price
        local fee = StockMarket.Fees and StockMarket.Fees.Calculate and StockMarket.Fees:Calculate(ticker, shares, price, StockMarket.Enums.OrderType.MARKET) or 0
        local grand = total + fee

        local ownedShares = GetOwnedSharesForTicker(ticker) or 0

        local y = 60
        draw.SimpleText("Shares: " .. shares, "StockMarket_TextFont", 15, y, StockMarket.UI.Colors.TextSecondary); y = y + 24
        draw.SimpleText("Your Shares: " .. string.Comma(ownedShares), "StockMarket_TextFont", 15, y, StockMarket.UI.Colors.TextSecondary); y = y + 24
        draw.SimpleText("Price: " .. StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(price, 2)), "StockMarket_TextFont", 15, y, StockMarket.UI.Colors.TextSecondary); y = y + 24
        draw.SimpleText("Subtotal: " .. StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(total, 2)), "StockMarket_TextFont", 15, y, StockMarket.UI.Colors.TextSecondary); y = y + 24
        draw.SimpleText("Fee: " .. StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(fee, 2)), "StockMarket_TextFont", 15, y, StockMarket.UI.Colors.TextSecondary); y = y + 34
        draw.SimpleText("Total: " .. StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(grand, 2)), "StockMarket_SubtitleFont", 15, y, StockMarket.UI.Colors.Primary)
    end

    -- Quick SELL group
    local quickSell = vgui.Create("DPanel", quickCol)
    quickSell:Dock(TOP)
    quickSell:SetTall(90)
    quickSell:DockMargin(10, 44, 10, 8)
    quickSell.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, StockMarket.UI.Colors.Background)
        draw.SimpleText("Quick Sell", "StockMarket_TextFont", 12, 8, StockMarket.UI.Colors.TextSecondary)
    end

    local function MakeSellBtn(parent, label, frac)
        local b = vgui.Create("DButton", parent)
        b:SetText("")
        b:SetTall(30)
        b:Dock(LEFT)
        b:DockMargin(6, 36, 0, 6)
        b:SetWide( (parent:GetWide() - 12) / 4 )
        b.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, StockMarket.UI.Colors.BackgroundDark)
            draw.SimpleText(label, "StockMarket_ButtonFont", w/2, h/2, StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.DoClick = function()
            orderSide = "SELL"
            local owned = GetOwnedSharesForTicker(ticker)
            local target = math.floor(math.max(0, owned * frac))
            sharesInput:SetText(tostring(target))
        end
        return b
    end

    -- Row of four buttons inside quickSell
    timer.Simple(0, function()
        if not IsValid(quickSell) then return end
        local row = vgui.Create("Panel", quickSell)
        row:Dock(FILL)
        row:DockMargin(6, 6, 6, 6)
        row.Paint = nil

        local btns = { {"25%",0.25}, {"50%",0.50}, {"75%",0.75}, {"100%",1.00} }
        for i, spec in ipairs(btns) do
            local b = MakeSellBtn(row, spec[1], spec[2])
            b:SetWide((quickSell:GetWide() - 12 - 18) / 4)
        end
    end)

    -- Quick BUY group
    local quickBuy = vgui.Create("DPanel", quickCol)
    quickBuy:Dock(TOP)
    quickBuy:SetTall(70)
    quickBuy:DockMargin(10, 4, 10, 10)
    quickBuy.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, StockMarket.UI.Colors.Background)
        draw.SimpleText("Quick Buy", "StockMarket_TextFont", 12, 8, StockMarket.UI.Colors.TextSecondary)
    end

    local quickBuyBtn = vgui.Create("DButton", quickBuy)
    quickBuyBtn:Dock(FILL)
    quickBuyBtn:DockMargin(10, 30, 10, 10)
    quickBuyBtn:SetText("")
    quickBuyBtn.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, StockMarket.UI.Colors.Primary)
        local amt = StockMarket.Config.QuickBuy and tonumber(StockMarket.Config.QuickBuy.Amount or 1000) or 1000
        if StockMarket.Config.QuickBuy and StockMarket.Config.QuickBuy.EnableCVarOverride and GetConVar and GetConVar(StockMarket.Config.QuickBuy.CVarName or "") then
            local c = GetConVar(StockMarket.Config.QuickBuy.CVarName or "")
            if c then amt = tonumber(c:GetString()) or amt end
        end
        draw.SimpleText(string.format("Buy %s%s worth", StockMarket.Config.CurrencySymbol, string.Comma(math.floor(amt))), "StockMarket_ButtonFont", w/2, h/2, StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    quickBuyBtn.DoClick = function()
        orderSide = "BUY"
        local amount = tonumber(StockMarket.Config.QuickBuy and StockMarket.Config.QuickBuy.Amount or 1000) or 1000
        if StockMarket.Config.QuickBuy and StockMarket.Config.QuickBuy.EnableCVarOverride and GetConVar and StockMarket.Config.QuickBuy.CVarName then
            local cv = GetConVar(StockMarket.Config.QuickBuy.CVarName)
            if cv then amount = tonumber(cv:GetString()) or amount end
        end
        local px = GetCurrentPrice(ticker)
        if px <= 0 then
            StockMarket.UI.Notifications:Add("Price unavailable", "error"); return
        end
        local sh = math.floor(math.max(0, amount / px))
        if sh <= 0 then
            StockMarket.UI.Notifications:Add("Amount too small for 1 share", "warning"); return
        end
        net.Start("StockMarket_PlaceOrder")
        net.WriteInt(1, 8)
        net.WriteString(ticker)
        net.WriteInt(StockMarket.Enums.OrderType.MARKET, 8)
        net.WriteInt(StockMarket.Enums.OrderSide.BUY, 8)
        net.WriteInt(sh, 32)
        net.WriteFloat(0)
        net.SendToServer()
    end

    -- Lightweight client portfolio cache for "Your Shares"
    StockMarket.ClientPortfolio = StockMarket.ClientPortfolio or { positions = {} }

    -- Ensure we have at least one portfolio snapshot
    timer.Simple(0.1, function()
        local pf = StockMarket.ClientPortfolio or {}
        if not pf.positions or #pf.positions == 0 then
            net.Start("StockMarket_RequestPortfolio")
            net.SendToServer()
        end
    end)

    -- Cleanup hooks/timers when view is destroyed
    view.OnRemove = function()
        hook.Remove("StockMarket_HistoryUpdated", histHook)
        hook.Remove("StockMarket_PriceUpdated", priceHook)
        hook.Remove("StockMarket_BarUpdated", barHook)
        timer.Remove(refreshId)
    end

    return view
end
