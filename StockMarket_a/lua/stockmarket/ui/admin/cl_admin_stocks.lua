-- ========================================
-- Admin Panel - Stocks/Category Manager (Complete with Modern Performance Monitor)
-- ========================================

if not CLIENT then return end

StockMarket.UI = StockMarket.UI or {}
StockMarket.UI.Admin = StockMarket.UI.Admin or {}
StockMarket.UI.AdminMonitor = StockMarket.UI.AdminMonitor or nil

local ICON_SIZE = 18
local ICONS = {
    edit   = Material("stockmarket/icons/edit.png", "smooth"),
    delete = Material("stockmarket/icons/delete.png", "smooth"),
    add    = Material("stockmarket/icons/create.png", "smooth"),
    preview= Material("stockmarket/icons/preview.png", "smooth")
}

-- Constants and quick colors
local ROW_H = 60
local CAT_H = 68
local PAD_X = 14
local PAD_Y = 10
local ACTION_RAIL_W = 120

local function SmallButton(parent, label, C, onClick, w)
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b:SetTall(32)
    b:SetWide(w or 90)
    local hover = false
    b.Paint = function(self, w2, h2)
        draw.RoundedBox(6, 0, 0, w2, h2, hover and C.PrimaryHover or C.Primary)
        draw.SimpleText(label, "StockMarket_ButtonFont", w2/2, h2/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    b.OnCursorEntered = function() hover = true end
    b.OnCursorExited  = function() hover = false end
    b.DoClick = function() if onClick then onClick() end end
    return b
end

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
           draw.SimpleText("X", "StockMarket_SubtitleFont", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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

    ModernButton(quickActions, "Monitor All Active", "+", function()
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

    ModernButton(quickActions, "Clear All Cards", "-", function()
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
            draw.SimpleText("v", "StockMarket_SmallFont", w - 10, h/2, C.TextSecondary, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
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
        draw.SimpleText("R Reset All", "StockMarket_SmallFont", w/2, h/2, C.TextPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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

    -- IMPROVED TICKER CARD
    function fr:AddTickerCard(t)
        local key = t.stockPrefix or t.stockName or ("CAM_" .. math.random(1000,9999))
        if IsValid(self.cards[key]) then
            self.cards[key]._params = t
            self.cards[key]:_refresh()
            return self.cards[key]
        end

        local card = vgui.Create("DPanel")
        card:SetSize(420, 340)
        grid:Add(card)
        self.cards[key] = card

        card._params = t
        card._offsetMins = 0

        -- Modern card design
        card.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, C.BackgroundLight)
            draw.RoundedBox(8, 0, 0, w, 50, Color(32, 36, 45))
            
            local p = card._params or {}
            
            draw.SimpleText(
                p.stockPrefix or "TICK",
                "StockMarket_TitleFont",
                16, 14,
                C.Primary,
                TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
            )
            
            draw.SimpleText(
                p.stockName or "Stock",
                "StockMarket_SmallFont",
                16, 38,
                C.TextSecondary,
                TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
            )
            
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

        card._btnClose = ModernButton(btnContainer, "X", "Remove", function()
            if IsValid(card) then
                grid:RemoveItem(card)
                fr.cards[key] = nil
                card:Remove()
            end
        end, card:GetWide() - 44)

        card._btnPop = ModernButton(btnContainer, "^", "Popout", function()
            local pop = vgui.Create("DFrame")
            pop:SetSize(math.min(ScrW() * 0.75, 1000), math.min(ScrH() * 0.75, 700))
            pop:Center()
            pop:SetTitle("")
            pop:MakePopup()
            
            pop.Paint = function(self, w, h)
                draw.RoundedBox(8, 0, 0, w, h, C.Background)
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

        local chartSection = vgui.Create("DPanel", card)
        chartSection:SetPos(12, 62)
        chartSection:SetSize(card:GetWide() - 24, 200)
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

        local infoPanel = vgui.Create("DPanel", card)
        infoPanel:SetPos(12, 274)
        infoPanel:SetSize(card:GetWide() - 24, 54)
        infoPanel.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, C.Background)
            
            local p = card._params
            
            draw.SimpleText("Drift: " .. string.format("%.4f", tonumber(p.drift or 0) or 0), "StockMarket_SmallFont", 12, 10, C.TextSecondary)
            draw.SimpleText("Volatility: " .. string.format("%.2f", tonumber(p.volatility or 1) or 1), "StockMarket_SmallFont", 12, 28, C.TextSecondary)
            
            draw.SimpleText("Horizon: " .. getHorizonMins() .. "m", "StockMarket_SmallFont", w - 12, 10, C.TextSecondary, TEXT_ALIGN_RIGHT)
            draw.SimpleText("Step: " .. getStepSecs() .. "s", "StockMarket_SmallFont", w - 12, 28, C.TextSecondary, TEXT_ALIGN_RIGHT)
            
            local currentPrice = tonumber(p.newStockValue or 1) or 1
            draw.SimpleText(
                StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(currentPrice, 2)),
                "StockMarket_SubtitleFont",
                w/2, h/2,
                C.Primary,
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER
            )
        end

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

        function card:_skip(mins)
            self._offsetMins = (self._offsetMins or 0) + mins
            self:_refresh()
        end

        card:_refresh(true)
        applyCardWidths()
        return card
    end

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
-- HELPER FUNCTIONS
-- ========================================

local function IconButton(parent, iconMat, tip, onClick)
    local btn = vgui.Create("DButton", parent)
    btn:SetText("")
    btn:SetSize(32, 32)
    btn.hovered = false
    btn.icon = iconMat

    btn.Paint = function(self, w, h)
        local alpha = self.hovered and 28 or 0
        draw.RoundedBox(6, 0, 0, w, h, Color(255,255,255, alpha))
        if self.icon then
            surface.SetMaterial(self.icon)
            surface.SetDrawColor(255,255,255, self.hovered and 255 or 220)
            local s = ICON_SIZE
            surface.DrawTexturedRect(math.floor((w - s)/2), math.floor((h - s)/2), s, s)
        end
    end
    btn.OnCursorEntered = function(self) self.hovered = true end
    btn.OnCursorExited  = function(self) self.hovered = false end
    btn.DoClick = function() if onClick then onClick(self) end end

    if tip and StockMarket.UI.Lib and StockMarket.UI.Lib.AddTooltip then
        StockMarket.UI.Lib:AddTooltip(btn, tip)
    end

    return btn
end

local function asColor(c, fallback)
    if istable(c) and c.r and c.g and c.b then return c end
    return fallback or Color(255, 255, 255)
end

local function DrawPill(x, y, text, bg, fg, padX, padY, font)
    text = text or ""
    padX = padX or 10
    padY = padY or 6
    font = font or "StockMarket_SmallFont"

    surface.SetFont(font)
    local tw, th = surface.GetTextSize(text)
    local w, h = tw + padX, th + padY

    local bgCol = asColor(bg, Color(45, 78, 120))
    local fgCol = asColor(fg, color_white)

    draw.RoundedBox(6, x, y, w, h, bgCol)
    draw.SimpleText(text, font, x + w/2, y + h/2, fgCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    return w, h
end

local function CategoryHeader(parent, sectorKey, sectorData, C, onAddTicker, onEditCategory, onDeleteCategory)
    local pnl = vgui.Create("DPanel", parent)
    pnl:Dock(TOP)
    pnl:SetTall(CAT_H)
    pnl:DockMargin(0, 0, 0, 8)
    pnl.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, C.BackgroundLight)
    end

    local left = vgui.Create("DPanel", pnl)
    left:Dock(FILL)
    left:DockMargin(PAD_X, PAD_Y, 4, PAD_Y)
    left.Paint = function(self, w, h)
        local name = (sectorData.sectorName)
        draw.SimpleText(name, "StockMarket_SubtitleFont", 0, 0, C.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local px = 0
        local py = 28

        local vol = tonumber(sectorData.sectorVolatility or 1) or 1
        local volText = string.format("Vol x%.2f", vol)
        local volW = select(1, DrawPill(px, py, volText, Color(45, 78, 120), color_white, 12, 6, "StockMarket_SmallFont"))
        px = px + volW + 8

        local isEnabled = sectorData.enabled ~= false
        local stText = isEnabled and "Enabled" or "Disabled"
        local stBg = isEnabled and Color(34, 197, 94) or Color(239, 68, 68)
        local stW = select(1, DrawPill(px, py, stText, stBg, color_white, 12, 6, "StockMarket_SmallFont"))
        px = px + stW + 8

        local risk = vol * 10
        local opText = risk >= 20 and "DP HIGH" or (risk >= 12 and "DP MED" or "DP LOW")
        local opCol = risk >= 20 and StockMarket.UI.Colors.Danger
                  or (risk >= 12 and StockMarket.UI.Colors.Warning or StockMarket.UI.Colors.Success)
        DrawPill(px, py, opText, opCol, color_white, 12, 6, "StockMarket_SmallFont")
    end

    local rail = vgui.Create("Panel", pnl)
    rail:Dock(RIGHT)
    rail:SetWide(120) 
    rail:DockMargin(4, PAD_Y, PAD_X, PAD_Y)
    rail.Paint = nil

    local btnAdd  = IconButton(rail, ICONS.add,   "Add Stock", function() onAddTicker(sectorKey) end)
    local btnEdit = IconButton(rail, ICONS.edit,  "Edit Category", function() onEditCategory(sectorKey, sectorData) end)
    local btnDel  = IconButton(rail, ICONS.delete,"Delete Category", function()
        Derma_Query("Delete category ".. (sectorData.sectorName or sectorKey) .." ?", "Confirm",
            "Delete", function()
                net.Start("StockMarket_Admin_DeleteCategory")
                net.WriteString(sectorKey)
                net.SendToServer()
                timer.Simple(0.15, function()
                    net.Start("StockMarket_Admin_GetState"); net.SendToServer()
                end)
            end, "Cancel"
        )
    end)

    btnDel:SetPos(88, 0)
    btnEdit:SetPos(44, 0)
    btnAdd:SetPos(0, 0)

    return pnl
end

local DRAG_NAME = "SM_Admin_StockRow"
local function StockRow(parent, sectorKey, t, C, onEdit, onDelete)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:SetTall(ROW_H)
    row:DockMargin(0, 0, 0, 6)
    row:SetCursor("sizeall")
    row.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, C.BackgroundLight)
    end

    local left = vgui.Create("DPanel", row)
    left:Dock(FILL)
    left:DockMargin(PAD_X, PAD_Y, 4, PAD_Y)
    left.Paint = function(self, w, h)
        local nameText = (t.stockName or "Stock") .. " (" .. (t.stockPrefix or "TICK") .. ")"
        draw.SimpleText(nameText, "StockMarket_TextFont", 0, 0, C.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local priceText = string.format("Price: %s%s", StockMarket.Config.CurrencySymbol, tostring(t.newStockValue or 0))
        local drift = tonumber(t.drift or 0) or 0
        local vol = tonumber(t.volatility or 1) or 1

        local driftCol = drift > 0 and StockMarket.UI.Colors.Success
                      or (drift < 0 and StockMarket.UI.Colors.Danger or StockMarket.UI.Colors.TextSecondary)

        local y = 24
        local x = 0

        surface.SetFont("StockMarket_SmallFont")
        draw.SimpleText(priceText, "StockMarket_SmallFont", x, y, StockMarket.UI.Colors.TextSecondary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        local priceW = surface.GetTextSize(priceText)
        x = x + priceW + 12

        local driftText = string.format("• Drift %.3f", drift)
        draw.SimpleText(driftText, "StockMarket_SmallFont", x, y, driftCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        local driftW = surface.GetTextSize(driftText)
        x = x + driftW + 12

        local baseBlue = StockMarket.UI.Colors.Info or Color(59,130,246)
        local alpha = math.Clamp(80 + (vol - 1) * 70, 60, 180)
        local volBg = Color(baseBlue.r, baseBlue.g, baseBlue.b, alpha)
        local volText = string.format("Vol %.2f", vol)

        surface.SetFont("StockMarket_SmallFont")
        local tw, th = surface.GetTextSize(volText)
        local padx, pady = 12, 4
        local pw, ph = tw + padx, th + pady
        draw.RoundedBox(6, x, y - 1, pw, ph, volBg)
        draw.SimpleText(volText, "StockMarket_SmallFont", x + pw/2, y - 1 + ph/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local rail = vgui.Create("Panel", row)
    rail:Dock(RIGHT)
    rail:SetWide(120)
    rail:DockMargin(4, PAD_Y, PAD_X, PAD_Y)
    rail.Paint = nil

    local btnDel   = IconButton(rail, ICONS.delete, "Delete", function() onDelete(sectorKey, t) end)
    local btnEdit  = IconButton(rail, ICONS.edit,   "Edit",   function() onEdit(sectorKey, t) end)
    local btnPrev  = IconButton(rail, ICONS.preview,"Open Monitor", function()
        local mon = AdminPredictiveMonitor(C)
        mon:AddTickerCard(t)
    end)

    btnDel:SetPos(88, 0)
    btnEdit:SetPos(44, 0)  
    btnPrev:SetPos(0, 0)

    row._sectorKey = sectorKey
    row._tickerPrefix = t.stockPrefix

    row:Droppable(DRAG_NAME)

    return row
end

local function SelfSizingList(parent)
    local list = vgui.Create("DPanel", parent)
    list:Dock(TOP)
    list:DockMargin(0, 0, 0, 12)
    list:SetTall(0)
    list.Paint = nil

    function list:PerformLayout(w, h)
        local total = 0
        local children = self:GetChildren() or {}
        for _, child in ipairs(children) do
            if IsValid(child) then
                total = total + child:GetTall()
                local l,t,r,b = child:GetDockMargin()
                total = total + t + b
            end
        end
        self:SetTall(total + 2)
    end

    function list:OnChildAdded() self:InvalidateLayout(true) end
    function list:OnChildRemoved() self:InvalidateLayout(true) end

    return list
end

local function InputRow(form, label, default)
    local row = vgui.Create("DPanel", form)
    row:Dock(TOP)
    row:SetTall(42)
    row:DockMargin(0, 4, 0, 6)
    row.Paint = nil

    local lbl = vgui.Create("DLabel", row)
    lbl:Dock(LEFT)
    lbl:SetWide(170)
    lbl:SetText(label)
    lbl:SetFont("StockMarket_TextFont")
    lbl:SetTextColor(Color(220,220,220))
    lbl:SetContentAlignment(4)

    local ent = vgui.Create("DTextEntry", row)
    ent:Dock(FILL)
    ent:SetFont("StockMarket_TextFont")
    ent:SetText(default or "")
    ent:SetTextColor(Color(255,255,255))
    ent:SetDrawBackground(true)
    ent:SetPaintBackground(true)
    ent.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(35,38,46))
        self:DrawTextEntryText(Color(255,255,255), Color(220,50,50), Color(255,255,255))
    end

    return ent
end

function StockMarket.UI.Admin._OpenCategoryDialog(mode, sectorKey, sectorData, C)
    local fr = vgui.Create("DFrame")
    fr:SetSize(520, 420); fr:Center(); fr:SetTitle(""); fr:MakePopup()
    fr.Paint = function(self,w,h) draw.RoundedBox(8,0,0,w,h, Color(28,31,38)) end

    local form = vgui.Create("DPanel", fr)
    form:Dock(FILL); form:DockMargin(10,10,10,50); form.Paint = nil

    local name = InputRow(form, "Sector Name", sectorData and sectorData.sectorName or "")
    local vol  = InputRow(form, "Sector Volatility (0.1-3.0)", (sectorData and tostring(sectorData.sectorVolatility or 1) or "1.0"))

    local enabled = vgui.Create("DCheckBoxLabel", form)
    enabled:Dock(TOP); enabled:DockMargin(170,6,0,0); enabled:SetText("Enabled")
    enabled:SetChecked(sectorData and sectorData.enabled ~= false or true)
    enabled:SetTextColor(Color(220,220,220)); enabled:SetFont("StockMarket_TextFont")

    local save = SmallButton(fr, "Save", {Primary=Color(220,38,38),PrimaryHover=Color(248,113,113)}, function()
        local payload = {
            sectorKey = sectorKey or "",
            sectorName = name:GetValue(),
            sectorVolatility = tonumber(vol:GetValue()) or 1.0,
            enabled = enabled:GetChecked()
        }
        net.Start("StockMarket_Admin_SaveCategory")
        net.WriteString(payload.sectorKey or "")
        net.WriteString(payload.sectorName or "")
        net.WriteFloat(tonumber(payload.sectorVolatility or 1) or 1)
        net.WriteBool(payload.enabled ~= false)
        net.SendToServer()
        fr:Close()
        timer.Simple(0.15, function()
            net.Start("StockMarket_Admin_GetState")
            net.SendToServer()
        end)
    end)
    save:Dock(BOTTOM); save:DockMargin(10,0,10,10); save:SetTall(38)
end

function StockMarket.UI.Admin.BuildPredictionSeries(params)
    local p0 = math.max(0.01, tonumber(params.startPrice) or 1)
    local mu = tonumber(params.drift) or 0
    local sigma = tonumber(params.sigma) or 1
    local minTickV = tonumber(params.minTick)
    local maxTickV = tonumber(params.maxTick)
    local horizonMins = math.max(1, tonumber(params.horizonMins) or 60)
    local stepSecs = math.max(1, tonumber(params.stepSecs) or 60)

    local dailyCap = tonumber(StockMarket.Config.PriceGen and StockMarket.Config.PriceGen.maxDailyMoveCap) or 0.25
    local stepsPerDay = math.max(1, math.floor((24*60*60) / stepSecs))
    local perStepCap = dailyCap / stepsPerDay

    local now = os.time()
    local steps = math.floor((horizonMins * 60) / stepSecs)

    local series = {}
    local price = p0
    table.insert(series, {timestamp = now - steps * stepSecs, open = price, high = price, low = price, close = price, volume = 0})

    for i = 1, steps do
        local rand = (math.Rand(-1,1) + math.Rand(-1,1) + math.Rand(-1,1)) / 3

        local move
        if minTickV and maxTickV then
            local tickSpan = (maxTickV - minTickV)
            move = math.Clamp(rand * sigma * tickSpan, minTickV, maxTickV) + (mu * tickSpan)
        else
            move = price * ((mu) + (sigma * 0.01) * rand)
        end

        local proposed = price + move

        local maxUp = price * (1 + perStepCap)
        local maxDn = price * (1 - perStepCap)
        proposed = math.min(math.max(proposed, maxDn), maxUp)

        proposed = math.max(0.01, proposed)

        local ts = now - (steps - i) * stepSecs
        local hi = math.max(price, proposed)
        local lo = math.min(price, proposed)
        table.insert(series, {timestamp = ts, open = price, high = hi, low = lo, close = proposed, volume = 0})
        price = proposed
    end

    return series
end

function StockMarket.UI.Admin.ComputeQuickStats(startPrice, mu, sigma, horizonMins)
    local driftPer = (tonumber(mu) or 0) * 100
    local sig = tonumber(sigma) or 1
    local riskScore = math.abs(driftPer) + sig * 10
    return {
        driftPer = driftPer,
        sigma = sig,
        riskScore = riskScore,
        horizonMins = horizonMins
    }
end

function StockMarket.UI.Admin._OpenTickerDialog(mode, sectorKey, t, C)
    local fr = vgui.Create("DFrame")
    fr:SetSize(940, 660)
    fr:Center(); fr:SetTitle(""); fr:MakePopup()
    fr.Paint = function(self,w,h) draw.RoundedBox(8,0,0,w,h, Color(28,31,38)) end

    local form = vgui.Create("DPanel", fr)
    form:Dock(FILL); form:DockMargin(10,10,10,50); form.Paint = nil

    local name = InputRow(form, "Stock Name", t and t.stockName or "")
    local prefix = InputRow(form, "Stock Prefix (Ticker)", t and t.stockPrefix or "")
    local market = InputRow(form, "Market Stocks", t and tostring(t.marketStocks or 1000) or "1000")
    local value = InputRow(form, "Stock Value", t and tostring(t.newStockValue or 100) or "100")
    local minTick = InputRow(form, "Min Tick", t and tostring(t.minTick or 0.01) or "0.01")
    local maxTick = InputRow(form, "Max Tick", t and tostring(t.maxTick or 5) or "5")
    local drift = InputRow(form, "Drift", t and tostring(t.drift or 0) or "0")
    local vol = InputRow(form, "Volatility", t and tostring(t.volatility or 1) or "1")
    local diff = InputRow(form, "Difficulty", t and tostring(t.stockDifficulty or 1) or "1")

    local enabled = vgui.Create("DCheckBoxLabel", form)
    enabled:Dock(TOP); enabled:DockMargin(170,6,0,0); enabled:SetText("Enabled")
    enabled:SetChecked(t and t.enabled ~= false or true)
    enabled:SetTextColor(Color(220,220,220)); enabled:SetFont("StockMarket_TextFont")

    local save = SmallButton(fr, "Save", {Primary=Color(220,38,38),PrimaryHover=Color(248,113,113)}, function()
        local payload = {
            stockName = name:GetValue(),
            stockPrefix = prefix:GetValue(),
            marketStocks = tonumber(market:GetValue()) or 1000,
            newStockValue = tonumber(value:GetValue()) or 100,
            minTick = tonumber(minTick:GetValue()) or 0.01,
            maxTick = tonumber(maxTick:GetValue()) or 5,
            drift = tonumber(drift:GetValue()) or 0,
            volatility = tonumber(vol:GetValue()) or 1,
            stockDifficulty = tonumber(diff:GetValue()) or 1,
            enabled = enabled:GetChecked()
        }
        net.Start("StockMarket_Admin_SaveTicker")
        net.WriteString(sectorKey or "")
        net.WriteString(payload.stockName or "")
        net.WriteString(payload.stockPrefix or "")
        net.WriteUInt(payload.marketStocks, 32)
        net.WriteFloat(payload.newStockValue)
        net.WriteFloat(payload.minTick)
        net.WriteFloat(payload.maxTick)
        net.WriteFloat(payload.drift)
        net.WriteFloat(payload.volatility)
        net.WriteUInt(payload.stockDifficulty, 32)
        net.WriteBool(payload.enabled)
        net.SendToServer()
        fr:Close()
        timer.Simple(0.15, function()
            net.Start("StockMarket_Admin_GetState")
            net.SendToServer()
        end)
    end)
    save:Dock(BOTTOM); save:DockMargin(10,0,10,10); save:SetTall(38)
end

-- ========================================
-- MAIN STOCKS VIEW
-- ========================================

function StockMarket.UI.Admin.Stocks(content, C)
    local top = vgui.Create("DPanel", content)
    top:Dock(TOP)
    top:SetTall(54)
    top:DockMargin(0, 0, 0, 10)
    top.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, C.BackgroundLight)
        draw.SimpleText("Stocks & Categories", "StockMarket_SubtitleFont", 14, h/2, C.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local topRail = vgui.Create("Panel", top)
    topRail:Dock(RIGHT)
    topRail:SetWide(340)
    topRail:DockMargin(0, 8, 14, 8)

    local btnW, btnH = 160, 38

    local addAll = vgui.Create("DButton", topRail)
    addAll:SetText("")
    addAll:SetSize(btnW, btnH)
    addAll:Dock(RIGHT)
    addAll:DockMargin(8, 0, 0, 0)
    local hovAll = false
    addAll.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, hovAll and C.PrimaryHover or C.Primary)
        draw.SimpleText("Monitor All", "StockMarket_ButtonFont", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    addAll.OnCursorEntered = function() hovAll = true end
    addAll.OnCursorExited  = function() hovAll = false end
    addAll.DoClick = function()
        local mon = AdminPredictiveMonitor(C)
        if StockMarket.UI.__LastAdminState then
            for sectorKey, sectorData in pairs(StockMarket.UI.__LastAdminState) do
                for _, tk in ipairs(sectorData.tickers or {}) do
                    mon:AddTickerCard(tk)
                end
            end
        else
            net.Start("StockMarket_Admin_GetState")
            net.SendToServer()
            local hookId = "SM_AdminState_ToMonitor_" .. tostring(SysTime())
            net.Receive("StockMarket_Admin_State", function()
                local count = net.ReadUInt(16) or 0
                local state = {}
                for i = 1, count do
                    local sectorKey = net.ReadString()
                    local sector = {
                        sectorName = net.ReadString(),
                        sectorVolatility = net.ReadFloat(),
                        enabled = net.ReadBool(),
                        tickers = {}
                    }
                    local tCount = net.ReadUInt(16) or 0
                    for j = 1, tCount do
                        sector.tickers[j] = {
                            stockName = net.ReadString(),
                            stockPrefix = net.ReadString(),
                            marketStocks = net.ReadUInt(32),
                            newStockValue = net.ReadFloat(),
                            minTick = net.ReadFloat(),
                            maxTick = net.ReadFloat(),
                            drift = net.ReadFloat(),
                            volatility = net.ReadFloat(),
                            stockDifficulty = net.ReadUInt(32),
                            enabled = net.ReadBool()
                        }
                    end
                    state[sectorKey] = sector
                end
                StockMarket.UI.__LastAdminState = state
                for _, data in pairs(state) do
                    for _, tk in ipairs(data.tickers or {}) do
                        mon:AddTickerCard(tk)
                    end
                end
            end)
        end
    end

    local addCat = vgui.Create("DButton", topRail)
    addCat:SetText("")
    addCat:SetSize(btnW, btnH)
    addCat:Dock(RIGHT)
    local hovCat = false
    addCat.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, hovCat and C.PrimaryHover or C.Primary)
        draw.SimpleText("+ Create Category", "StockMarket_ButtonFont", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    addCat.OnCursorEntered = function() hovCat = true end
    addCat.OnCursorExited  = function() hovCat = false end
    addCat.DoClick = function()
        StockMarket.UI.Admin._OpenCategoryDialog("create", nil, nil, C)
    end

    local scroll = vgui.Create("DScrollPanel", content)
    scroll:Dock(FILL)

    net.Start("StockMarket_Admin_GetState")
    net.SendToServer()

    net.Receive("StockMarket_Admin_State", function()
        local count = net.ReadUInt(16) or 0
        local state = {}

        for i = 1, count do
            local sectorKey = net.ReadString()
            local sector = {
                sectorName = net.ReadString(),
                sectorVolatility = net.ReadFloat(),
                enabled = net.ReadBool(),
                tickers = {}
            }

            local tickerCount = net.ReadUInt(16) or 0
            for j = 1, tickerCount do
                sector.tickers[j] = {
                    stockName = net.ReadString(),
                    stockPrefix = net.ReadString(),
                    marketStocks = net.ReadUInt(32),
                    newStockValue = net.ReadFloat(),
                    minTick = net.ReadFloat(),
                    maxTick = net.ReadFloat(),
                    drift = net.ReadFloat(),
                    volatility = net.ReadFloat(),
                    stockDifficulty = net.ReadUInt(32),
                    enabled = net.ReadBool()
                }
            end

            state[sectorKey] = sector
        end

        StockMarket.UI.__LastAdminState = state

        if not IsValid(scroll) then return end
        scroll:Clear()

        local ordered = {}
        for key, data in pairs(state) do
            table.insert(ordered, { key = key, name = data.sectorName or key, data = data })
        end
        table.sort(ordered, function(a,b) return string.lower(a.name) < string.lower(b.name) end)

        for _, it in ipairs(ordered) do
            local sectorKey = it.key
            local sectorData = it.data

            if not IsValid(scroll) then return end
            CategoryHeader(scroll, sectorKey, sectorData, C,
                function(sKey) StockMarket.UI.Admin._OpenTickerDialog("create", sKey, nil, C) end,
                function(sKey, data) StockMarket.UI.Admin._OpenCategoryDialog("edit", sKey, data, C) end,
                function(sKey, data)
                    Derma_Query("Delete category ".. (data.sectorName or sKey) .." ?", "Confirm",
                        "Delete", function()
                            net.Start("StockMarket_Admin_DeleteCategory")
                            net.WriteString(sKey)
                            net.SendToServer()
                            timer.Simple(0.15, function()
                                net.Start("StockMarket_Admin_GetState")
                                net.SendToServer()
                            end)
                        end, "Cancel"
                    )
                end
            )

            if not IsValid(scroll) then return end
            local rows = SelfSizingList(scroll)
            if not IsValid(rows) then return end
            rows._sectorKey = sectorKey

            for _, t in ipairs(sectorData.tickers or {}) do
                StockRow(rows, sectorKey, t, C,
                    function(sKey, ticker) StockMarket.UI.Admin._OpenTickerDialog("edit", sKey, ticker, C) end,
                    function(sKey, ticker)
                        Derma_Query("Delete ticker ".. (ticker.stockName or "?") .." (".. (ticker.stockPrefix or "?") ..") ?", "Confirm",
                            "Delete", function()
                                net.Start("StockMarket_Admin_DeleteTicker"); net.WriteString(sKey); net.WriteString(ticker.stockPrefix or ""); net.SendToServer()
                                timer.Simple(0.15, function()
                                    net.Start("StockMarket_Admin_GetState"); net.SendToServer()
                                end)
                            end, "Cancel"
                        )
                    end
                )
            end

            rows:Receiver(DRAG_NAME, function(self, panels, bDoDrop)
                if not bDoDrop or not panels or #panels == 0 then return end
                local dragged = panels[1]
                if not IsValid(dragged) then return end
                local fromSector = dragged._sectorKey
                local prefix     = dragged._tickerPrefix
                local toSector   = self._sectorKey
                if not fromSector or not prefix or fromSector == toSector then return end
                net.Start("StockMarket_Admin_Reorder")
                net.WriteString(fromSector); net.WriteString(toSector); net.WriteString(prefix)
                net.SendToServer()
                timer.Simple(0.15, function()
                    net.Start("StockMarket_Admin_GetState"); net.SendToServer()
                end)
            end)
        end
    end)
end