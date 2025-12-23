-- ========================================
-- IMPROVED Performance Monitor for Stock Market Admin
-- Modern, functional, theme-matching design
-- ========================================

-- This is the improved AddTickerCard function
-- Replace the existing function in cl_admin_stocks.lua (around line 300-470)

function fr:AddTickerCard(t)
    local key = t.stockPrefix or t.stockName or ("CAM_" .. math.random(1000,9999))
    if IsValid(self.cards[key]) then
        self.cards[key]._params = t
        self.cards[key]:_refresh()
        return self.cards[key]
    end

    -- IMPROVED: Better card sizing
    local card = vgui.Create("DPanel")
    card:SetSize(420, 340) -- Increased size for better chart visibility
    grid:Add(card)
    self.cards[key] = card

    card._params = t
    card._offsetMins = 0

    -- IMPROVED: Modern card design
    card.Paint = function(self, w, h)
        -- Main card background
        draw.RoundedBox(8, 0, 0, w, h, C.BackgroundLight)
        
        -- Header section with gradient effect
        draw.RoundedBox(8, 0, 0, w, 50, Color(32, 36, 45))
        
        local p = card._params or {}
        
        -- Ticker symbol (large, prominent)
        draw.SimpleText(
            p.stockPrefix or "TICK",
            "StockMarket_TitleFont",
            16, 14,
            C.Primary,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
        )
        
        -- Stock name (smaller, below ticker)
        draw.SimpleText(
            p.stockName or "Stock",
            "StockMarket_SmallFont",
            16, 38,
            C.TextSecondary,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
        )
        
        -- Risk badge (top right)
        local riskInfo = StockMarket.UI.Admin.ComputeQuickStats and StockMarket.UI.Admin.ComputeQuickStats(
            tonumber(p.newStockValue or 1) or 1,
            tonumber(p.drift or 0) or 0,
            tonumber(p.volatility or 1) or 1,
            30
        ) or { riskScore = 0 }
        
        local risk = riskInfo.riskScore or 0
        local riskLabel, riskCol
        if risk >= 25 then
            riskLabel, riskCol = "HIGH RISK", StockMarket.UI.Colors.Danger
        elseif risk >= 15 then
            riskLabel, riskCol = "MED RISK", StockMarket.UI.Colors.Warning
        else
            riskLabel, riskCol = "LOW RISK", StockMarket.UI.Colors.Success
        end
        
        surface.SetFont("StockMarket_SmallFont")
        local tw, th = surface.GetTextSize(riskLabel)
        local badgeW, badgeH = tw + 16, th + 8
        local badgeX = w - badgeW - 16
        draw.RoundedBox(6, badgeX, 12, badgeW, badgeH, riskCol)
        draw.SimpleText(riskLabel, "StockMarket_SmallFont", badgeX + badgeW/2, 12 + badgeH/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- IMPROVED: Modern action buttons
    local btnContainer = vgui.Create("DPanel", card)
    btnContainer:SetPos(0, 0)
    btnContainer:SetSize(card:GetWide(), 50)
    btnContainer.Paint = nil

    local function ModernButton(parent, icon, tooltip, onClick, xPos)
        local btn = vgui.Create("DButton", parent)
        btn:SetText("")
        btn:SetSize(32, 32)
        btn:SetPos(xPos, 9)
        btn.hovered = false
        
        btn.Paint = function(self, w, h)
            local bgCol = self.hovered and Color(255, 255, 255, 40) or Color(255, 255, 255, 15)
            draw.RoundedBox(6, 0, 0, w, h, bgCol)
            draw.SimpleText(icon, "StockMarket_ButtonFont", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        btn.OnCursorEntered = function(self) self.hovered = true end
        btn.OnCursorExited = function(self) self.hovered = false end
        btn.DoClick = onClick
        
        return btn
    end

    -- Close button
    card._btnClose = ModernButton(btnContainer, "×", "Remove", function()
        if IsValid(card) then
            grid:RemoveItem(card)
            fr.cards[key] = nil
            card:Remove()
        end
    end, card:GetWide() - 44)

    -- Popout button
    card._btnPop = ModernButton(btnContainer, "⤢", "Popout", function()
        local pop = vgui.Create("DFrame")
        pop:SetSize(math.min(ScrW() * 0.75, 1000), math.min(ScrH() * 0.75, 700))
        pop:Center()
        pop:SetTitle("")
        pop:MakePopup()
        
        pop.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, C.Background)
            
            -- Header
            draw.RoundedBox(8, 8, 8, w - 16, 60, C.BackgroundLight)
            draw.SimpleText(t.stockPrefix or "TICK", "StockMarket_TitleFont", 24, 24, C.Primary)
            draw.SimpleText(t.stockName or "Stock", "StockMarket_TextFont", 24, 48, C.TextSecondary)
        end

        local holder = vgui.Create("DPanel", pop)
        holder:Dock(FILL)
        holder:DockMargin(16, 80, 16, 16)
        holder.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, C.BackgroundLight)
        end
        
        local chartHolder = vgui.Create("DPanel", holder)
        chartHolder:Dock(FILL)
        chartHolder:DockMargin(12, 12, 12, 12)
        chartHolder.Paint = nil
        
        local c = StockMarket.UI.Lib:Chart(chartHolder)
        c:Dock(FILL)
        c:SetData(StockMarket.UI.Admin.BuildPredictionSeries({
            startPrice = tonumber(t.newStockValue or 1) or 1,
            drift = tonumber(t.drift or 0) or 0,
            sigma = tonumber(t.volatility or 1) or 1,
            horizonMins = getHorizonMins(),
            stepSecs = getStepSecs()
        }))
    end, card:GetWide() - 82)

    -- IMPROVED: Chart section with better sizing
    local chartSection = vgui.Create("DPanel", card)
    chartSection:SetPos(12, 62)
    chartSection:SetSize(card:GetWide() - 24, 200) -- Larger chart
    chartSection.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, C.Background)
    end

    local chartHolder = vgui.Create("DPanel", chartSection)
    chartHolder:Dock(FILL)
    chartHolder:DockMargin(8, 8, 8, 8)
    chartHolder.Paint = nil

    local chart = StockMarket.UI.Lib:Chart(chartHolder)
    chart:Dock(FILL)
    chartHolder.chart = chart

    -- IMPROVED: Info panel with better layout
    local infoPanel = vgui.Create("DPanel", card)
    infoPanel:SetPos(12, 274)
    infoPanel:SetSize(card:GetWide() - 24, 54)
    infoPanel.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, C.Background)
        
        local p = card._params
        
        -- Left column: Stock info
        draw.SimpleText("Drift: " .. string.format("%.4f", tonumber(p.drift or 0) or 0), "StockMarket_SmallFont", 12, 10, C.TextSecondary)
        draw.SimpleText("Volatility: " .. string.format("%.2f", tonumber(p.volatility or 1) or 1), "StockMarket_SmallFont", 12, 28, C.TextSecondary)
        
        -- Right column: Prediction info
        draw.SimpleText("Horizon: " .. getHorizonMins() .. "m", "StockMarket_SmallFont", w - 12, 10, C.TextSecondary, TEXT_ALIGN_RIGHT)
        draw.SimpleText("Step: " .. getStepSecs() .. "s", "StockMarket_SmallFont", w - 12, 28, C.TextSecondary, TEXT_ALIGN_RIGHT)
        
        -- Center: Current price
        local currentPrice = tonumber(p.newStockValue or 1) or 1
        draw.SimpleText(
            StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(currentPrice, 2)),
            "StockMarket_SubtitleFont",
            w/2, h/2,
            C.Primary,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER
        )
    end

    -- Refresh function
    function card:_refresh(resetOffset)
        if resetOffset then self._offsetMins = 0 end
        local p = self._params
        local cfg = {
            startPrice  = tonumber(p.newStockValue or 1) or 1,
            drift       = tonumber(p.drift or 0) or 0,
            sigma       = tonumber(p.volatility or 1) or 1,
            minTick     = tonumber(p.minTick or nil),
            maxTick     = tonumber(p.maxTick or nil),
            horizonMins = getHorizonMins() + (self._offsetMins or 0),
            stepSecs    = getStepSecs()
        }
        local series = StockMarket.UI.Admin.BuildPredictionSeries and StockMarket.UI.Admin.BuildPredictionSeries(cfg) or {}
        if chart.SetData then chart:SetData(series) end
        infoPanel:InvalidateLayout(true)
    end

    -- Skip function for time travel
    function card:_skip(mins)
        self._offsetMins = (self._offsetMins or 0) + mins
        self:_refresh()
    end

    card:_refresh(true)
    applyCardWidths()
    return card
end