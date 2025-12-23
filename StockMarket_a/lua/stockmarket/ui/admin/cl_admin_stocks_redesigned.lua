-- ========================================
-- Admin Panel - Performance Monitor (Complete Redesign)
-- Modern, cohesive interface with improved UX
-- ========================================

if not CLIENT then return end

StockMarket.UI = StockMarket.UI or {}
StockMarket.UI.Admin = StockMarket.UI.Admin or {}
StockMarket.UI.AdminMonitor = StockMarket.UI.AdminMonitor or nil

-- ========================================
-- MODERN PERFORMANCE MONITOR
-- ========================================

local function AdminPredictiveMonitor(C)
    if IsValid(StockMarket.UI.AdminMonitor) then
        local fr = StockMarket.UI.AdminMonitor
        fr:MakePopup(); fr:MoveToFront()
        return fr
    end

    local fr = vgui.Create("DFrame")
    fr:SetSize(math.min(ScrW() * 0.9, 1600), math.min(ScrH() * 0.9, 1000))
    fr:Center()
    fr:SetTitle("")
    fr:MakePopup()
    fr:SetSizable(true)
    fr:SetMinWidth(1000)
    fr:SetMinHeight(600)
    StockMarket.UI.AdminMonitor = fr

    -- Modern frame design
    fr.Paint = function(self, w, h)
        -- Main background
        draw.RoundedBox(12, 0, 0, w, h, C.Background)
        
        -- Header with gradient effect
        draw.RoundedBox(12, 0, 0, w, 80, Color(32, 36, 45))
        draw.RoundedBoxEx(12, 0, 0, w, 80, C.BackgroundLight, true, true, false, false)
        
        -- Title
        draw.SimpleText("Performance Monitor", "StockMarket_TitleFont", 24, 28, C.Primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Real-time stock prediction and analysis", "StockMarket_SmallFont", 24, 54, C.TextSecondary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    -- Close button
    local closeBtn = vgui.Create("DButton", fr)
    closeBtn:SetSize(40, 40)
    closeBtn:SetPos(fr:GetWide() - 50, 20)
    closeBtn:SetText("")
    closeBtn.hovered = false
    closeBtn.Paint = function(self, w, h)
        local col = self.hovered and C.Danger or Color(255, 255, 255, 30)
        draw.RoundedBox(8, 0, 0, w, h, col)
        draw.SimpleText("×", "StockMarket_SubtitleFont", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.OnCursorEntered = function(self) self.hovered = true end
    closeBtn.OnCursorExited = function(self) self.hovered = false end
    closeBtn.DoClick = function() fr:Close() end
    
    fr.OnSizeChanged = function()
        if IsValid(closeBtn) then
            closeBtn:SetPos(fr:GetWide() - 50, 20)
        end
    end

    -- Control panel (modern design)
    local controlPanel = vgui.Create("DPanel", fr)
    controlPanel:Dock(TOP)
    controlPanel:SetTall(100)
    controlPanel:DockMargin(16, 96, 16, 12)
    controlPanel.Paint = function(self, w, h)
        draw.RoundedBox(10, 0, 0, w, h, C.BackgroundLight)
        
        -- Section dividers
        surface.SetDrawColor(255, 255, 255, 10)
        surface.DrawRect(w * 0.25, 12, 1, h - 24)
        surface.DrawRect(w * 0.75, 12, 1, h - 24)
    end

    -- Left section: Quick Actions
    local quickActions = vgui.Create("DPanel", controlPanel)
    quickActions:Dock(LEFT)
    quickActions:SetWide(controlPanel:GetWide() * 0.25 - 8)
    quickActions:DockMargin(12, 12, 12, 12)
    quickActions.Paint = nil

    local sectionLabel1 = vgui.Create("DLabel", quickActions)
    sectionLabel1:Dock(TOP)
    sectionLabel1:SetTall(20)
    sectionLabel1:SetFont("StockMarket_SmallFont")
    sectionLabel1:SetTextColor(C.TextSecondary)
    sectionLabel1:SetText("QUICK ACTIONS")

    local function ModernButton(parent, text, icon, onClick, color)
        local btn = vgui.Create("DButton", parent)
        btn:Dock(TOP)
        btn:SetTall(28)
        btn:DockMargin(0, 4, 0, 0)
        btn:SetText("")
        btn.hovered = false
        
        btn.Paint = function(self, w, h)
            local bgCol = self.hovered and (color or C.Primary) or Color(255, 255, 255, 15)
            draw.RoundedBox(6, 0, 0, w, h, bgCol)
            
            local textCol = self.hovered and color_white or C.TextPrimary
            if icon then
                draw.SimpleText(icon .. " " .. text, "StockMarket_SmallFont", w/2, h/2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                draw.SimpleText(text, "StockMarket_SmallFont", w/2, h/2, textCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
        
        btn.OnCursorEntered = function(self) self.hovered = true end
        btn.OnCursorExited = function(self) self.hovered = false end
        btn.DoClick = onClick
        
        return btn
    end

    ModernButton(quickActions, "Monitor All Active", "⊕", function()
        if StockMarket.UI.__LastAdminState then
            for _, sectorData in pairs(StockMarket.UI.__LastAdminState) do
                for _, tk in ipairs(sectorData.tickers or {}) do
                    if tk.enabled ~= false then
                        fr:AddTickerCard(tk)
                    end
                end
            end
        end
    end, C.Primary)

    ModernButton(quickActions, "Clear All Cards", "⊗", function()
        if fr.cards then
            for key, card in pairs(fr.cards) do
                if IsValid(card) then
                    card:Remove()
                end
            end
            fr.cards = {}
        end
    end, C.Danger)

    -- Middle section: Prediction Settings
    local predSettings = vgui.Create("DPanel", controlPanel)
    predSettings:Dock(FILL)
    predSettings:DockMargin(12, 12, 12, 12)
    predSettings.Paint = nil

    local sectionLabel2 = vgui.Create("DLabel", predSettings)
    sectionLabel2:Dock(TOP)
    sectionLabel2:SetTall(20)
    sectionLabel2:SetFont("StockMarket_SmallFont")
    sectionLabel2:SetTextColor(C.TextSecondary)
    sectionLabel2:SetText("PREDICTION SETTINGS")

    local settingsRow = vgui.Create("DPanel", predSettings)
    settingsRow:Dock(TOP)
    settingsRow:SetTall(32)
    settingsRow:DockMargin(0, 4, 0, 0)
    settingsRow.Paint = nil

    -- Helper function for modern combo boxes
    local function ModernComboBox(parent, label, choices, defaultIdx)
        local container = vgui.Create("DPanel", parent)
        container:Dock(LEFT)
        container:SetWide((parent:GetWide() - 16) / 2)
        container:DockMargin(0, 0, 8, 0)
        container.Paint = nil

        local lbl = vgui.Create("DLabel", container)
        lbl:Dock(LEFT)
        lbl:SetWide(80)
        lbl:SetFont("StockMarket_SmallFont")
        lbl:SetTextColor(C.TextSecondary)
        lbl:SetText(label)
        lbl:SetContentAlignment(4)

        local combo = vgui.Create("DComboBox", container)
        combo:Dock(FILL)
        combo:SetFont("StockMarket_TextFont")
        
        for i, choice in ipairs(choices) do
            combo:AddChoice(choice.label, choice.value, i == defaultIdx)
        end
        
        combo.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, C.Background)
            
            local _, value = self:GetSelected()
            local displayText = ""
            for _, choice in ipairs(choices) do
                if choice.value == value then
                    displayText = choice.label
                    break
                end
            end
            
            draw.SimpleText(displayText, "StockMarket_TextFont", 10, h/2, C.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            
            -- Dropdown arrow
            draw.SimpleText("▼", "StockMarket_SmallFont", w - 10, h/2, C.TextSecondary, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
        
        return combo
    end

    local horizon = ModernComboBox(settingsRow, "Horizon:", {
        {label = "30 minutes", value = 30},
        {label = "1 hour", value = 60},
        {label = "4 hours", value = 240},
        {label = "24 hours", value = 1440}
    }, 1)

    local step = ModernComboBox(settingsRow, "Step:", {
        {label = "1 minute", value = 60},
        {label = "2 minutes", value = 120},
        {label = "5 minutes", value = 300}
    }, 2)

    local function getHorizonMins()
        local _, value = horizon:GetSelected()
        return tonumber(value) or 30
    end
    
    local function getStepSecs()
        local _, value = step:GetSelected()
        return tonumber(value) or 120
    end

    -- Right section: Time Controls
    local timeControls = vgui.Create("DPanel", controlPanel)
    timeControls:Dock(RIGHT)
    timeControls:SetWide(controlPanel:GetWide() * 0.25 - 8)
    timeControls:DockMargin(12, 12, 12, 12)
    timeControls.Paint = nil

    local sectionLabel3 = vgui.Create("DLabel", timeControls)
    sectionLabel3:Dock(TOP)
    sectionLabel3:SetTall(20)
    sectionLabel3:SetFont("StockMarket_SmallFont")
    sectionLabel3:SetTextColor(C.TextSecondary)
    sectionLabel3:SetText("TIME TRAVEL")

    local timeRow1 = vgui.Create("DPanel", timeControls)
    timeRow1:Dock(TOP)
    timeRow1:SetTall(28)
    timeRow1:DockMargin(0, 4, 0, 0)
    timeRow1.Paint = nil

    local timeRow2 = vgui.Create("DPanel", timeControls)
    timeRow2:Dock(TOP)
    timeRow2:SetTall(28)
    timeRow2:DockMargin(0, 4, 0, 0)
    timeRow2.Paint = nil

    local function TimeButton(parent, label, mins)
        local btn = vgui.Create("DButton", parent)
        btn:Dock(LEFT)
        btn:SetWide((parent:GetWide() - 4) / 2)
        btn:DockMargin(0, 0, 4, 0)
        btn:SetText("")
        btn.hovered = false
        
        btn.Paint = function(self, w, h)
            local bgCol = self.hovered and C.PrimaryHover or C.Primary
            draw.RoundedBox(6, 0, 0, w, h, bgCol)
            draw.SimpleText(label, "StockMarket_SmallFont", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        
        btn.OnCursorEntered = function(self) self.hovered = true end
        btn.OnCursorExited = function(self) self.hovered = false end
        btn.DoClick = function()
            if fr.cards then
                for _, card in pairs(fr.cards) do
                    if IsValid(card) and card._skip then
                        card:_skip(mins)
                    end
                end
            end
        end
        
        return btn
    end

    TimeButton(timeRow1, "+5m", 5)
    TimeButton(timeRow1, "+30m", 30)
    TimeButton(timeRow2, "+2h", 120)
    TimeButton(timeRow2, "+1d", 1440)

    local resetBtn = vgui.Create("DButton", timeControls)
    resetBtn:Dock(TOP)
    resetBtn:SetTall(28)
    resetBtn:DockMargin(0, 8, 0, 0)
    resetBtn:SetText("")
    resetBtn.hovered = false
    
    resetBtn.Paint = function(self, w, h)
        local bgCol = self.hovered and Color(255, 255, 255, 30) or Color(255, 255, 255, 10)
        draw.RoundedBox(6, 0, 0, w, h, bgCol)
        draw.SimpleText("⟲ Reset All", "StockMarket_SmallFont", w/2, h/2, C.TextPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    resetBtn.OnCursorEntered = function(self) self.hovered = true end
    resetBtn.OnCursorExited = function(self) self.hovered = false end
    resetBtn.DoClick = function()
        if fr.cards then
            for _, card in pairs(fr.cards) do
                if IsValid(card) and card._refresh then
                    card:_refresh(true)
                end
            end
        end
    end

    -- Scroll container for cards
    local scroll = vgui.Create("DScrollPanel", fr)
    scroll:Dock(FILL)
    scroll:DockMargin(16, 0, 16, 16)
    
    local sbar = scroll:GetVBar()
    sbar:SetWide(10)
    sbar.Paint = function(self, w, h)
        draw.RoundedBox(5, 0, 0, w, h, Color(255, 255, 255, 10))
    end
    sbar.btnGrip.Paint = function(self, w, h)
        draw.RoundedBox(5, 0, 0, w, h, C.Primary)
    end
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end

    -- Grid layout for cards
    local grid = vgui.Create("DIconLayout", scroll)
    grid:Dock(FILL)
    grid:SetSpaceX(16)
    grid:SetSpaceY(16)
    grid:DockMargin(0, 0, 0, 0)

    fr.cards = fr.cards or {}

    -- Dynamic column calculation
    local function computeColumns(w)
        if w >= 1400 then return 3 end
        if w >= 900 then return 2 end
        return 1
    end
    
    local function applyCardWidths()
        if not IsValid(fr) or not IsValid(grid) then return end
        local w = fr:GetWide() - 48
        local cols = computeColumns(w)
        local cw = math.max(400, math.floor((w - (grid:GetSpaceX() * (cols - 1))) / cols))
        for _, card in pairs(fr.cards) do
            if IsValid(card) then card:SetWide(cw) end
        end
    end
    
    fr.OnSizeChanged = function()
        timer.Simple(0, applyCardWidths)
        if IsValid(closeBtn) then
            closeBtn:SetPos(fr:GetWide() - 50, 20)
        end
    end

    -- IMPROVED TICKER CARD (matching your new design)
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

    -- Update cards when settings change
    horizon.OnSelect = function()
        if fr.cards then
            for _, card in pairs(fr.cards) do
                if IsValid(card) and card._refresh then
                    card:_refresh()
                end
            end
        end
    end

    step.OnSelect = function()
        if fr.cards then
            for _, card in pairs(fr.cards) do
                if IsValid(card) and card._refresh then
                    card:_refresh()
                end
            end
        end
    end

    timer.Simple(0, applyCardWidths)
    return fr
end

-- ========================================
-- MAIN STOCKS MANAGEMENT VIEW
-- ========================================

function StockMarket.UI.Admin.Stocks(content, C)
    -- Modern header
    local header = vgui.Create("DPanel", content)
    header:Dock(TOP)
    header:SetTall(80)
    header:DockMargin(0, 0, 0, 16)
    header.Paint = function(self, w, h)
        draw.RoundedBox(10, 0, 0, w, h, C.BackgroundLight)
        
        -- Title
        draw.SimpleText("Stock Management", "StockMarket_SubtitleFont", 20, 20, C.Primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText("Manage categories and stocks", "StockMarket_SmallFont", 20, 48, C.TextSecondary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    -- Action buttons in header
    local btnMonitor = vgui.Create("DButton", header)
    btnMonitor:SetSize(180, 40)
    btnMonitor:SetPos(header:GetWide() - 200, 20)
    btnMonitor:SetText("")
    btnMonitor.hovered = false
    btnMonitor.Paint = function(self, w, h)
        local bgCol = self.hovered and C.PrimaryHover or C.Primary
        draw.RoundedBox(8, 0, 0, w, h, bgCol)
        draw.SimpleText("📊 Performance Monitor", "StockMarket_ButtonFont", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnMonitor.OnCursorEntered = function(self) self.hovered = true end
    btnMonitor.OnCursorExited = function(self) self.hovered = false end
    btnMonitor.DoClick = function()
        AdminPredictiveMonitor(C)
    end

    -- Scroll panel for content
    local scroll = vgui.Create("DScrollPanel", content)
    scroll:Dock(FILL)
    
    local sbar = scroll:GetVBar()
    sbar:SetWide(10)
    sbar.Paint = function(self, w, h)
        draw.RoundedBox(5, 0, 0, w, h, Color(255, 255, 255, 10))
    end
    sbar.btnGrip.Paint = function(self, w, h)
        draw.RoundedBox(5, 0, 0, w, h, C.Primary)
    end
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end

    -- Content container
    local container = vgui.Create("DPanel", scroll)
    container:Dock(TOP)
    container:DockMargin(0, 0, 0, 0)
    container.Paint = nil

    -- Request state from server
    net.Start("StockMarket_Admin_GetState")
    net.SendToServer()

    -- TODO: Add the rest of the stock management interface here
    -- This would include category headers, stock rows, etc.
    -- For now, this provides the modern Performance Monitor
end