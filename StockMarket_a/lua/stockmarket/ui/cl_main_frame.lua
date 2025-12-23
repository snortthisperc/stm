-- ========================================
-- Main UI Frame
-- ========================================

StockMarket.UI = StockMarket.UI or {}
StockMarket.UI.MainFrame = nil

local SM_Logo = Material("stockmarket/logo.png", "noclamp smooth")
local SM_LOGO_W, SM_LOGO_H = 240, 220 

function StockMarket.UI.OpenMainFrame(initialTicker)
    if IsValid(StockMarket.UI.MainFrame) then
        StockMarket.UI.MainFrame:Close()
    end
    
    local frame = vgui.Create("DFrame")
    frame:SetSize(ScrW() * 0.85, ScrH() * 0.85)
    frame:Center()
    frame:SetTitle("")
    frame:SetDraggable(true)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    
    StockMarket.UI.MainFrame = frame

    if net and net.Start then
        local lp = LocalPlayer()
        if IsValid(lp) and lp:IsSuperAdmin() then
            net.Start("StockMarket_Admin_GetState")
            net.SendToServer()
        end
    end
    
    frame.Paint = function(self, w, h)
        -- Window background
        draw.RoundedBox(12, 0, 0, w, h, StockMarket.UI.Colors.Background)

        -- Title bar
        local headerH = 60
        draw.RoundedBoxEx(12, 0, 0, w, headerH, StockMarket.UI.Colors.BackgroundLight, true, true, false, false)

        -- Centered logo (replaces text title and left logo)
        if SM_Logo then
            local lw, lh = SM_LOGO_W, SM_LOGO_H
            local cx = w * 0.5 - lw * 0.5
            local cy = headerH * 0.5 - lh * 0.5
            surface.SetMaterial(SM_Logo)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(cx, cy, lw, lh)
        else
            -- Fallback to text if logo missing
            draw.SimpleText("Stock Market", "StockMarket_SmallFont", w * 0.5, headerH - 14,
                StockMarket.UI.Colors.TextSecondary, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        end
    end
    
    -- Close button
    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetSize(40, 40)
    closeBtn:SetPos(frame:GetWide() - 50, 10)
    closeBtn:SetText("")
    closeBtn.hovered = false
    
    closeBtn.Paint = function(self, w, h)
        local col = self.hovered and StockMarket.UI.Colors.Danger or StockMarket.UI.Colors.BackgroundDark
        draw.RoundedBox(6, 0, 0, w, h, col)
        draw.SimpleText("X", "StockMarket_SubtitleFont", w/2, h/2, 
            StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    
    closeBtn.OnCursorEntered = function(self)
        self.hovered = true
    end
    
    closeBtn.OnCursorExited = function(self)
        self.hovered = false
    end
    
    closeBtn.DoClick = function()
        frame:Close()
    end
    
    -- Navigation panel
    local navPanel = vgui.Create("DPanel", frame)
    navPanel:SetSize(200, frame:GetTall() - 80)
    navPanel:SetPos(10, 70)
    navPanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, StockMarket.UI.Colors.BackgroundLight)
    end
    
    -- Content panel
    local contentPanel = vgui.Create("DPanel", frame)
    contentPanel:SetSize(frame:GetWide() - 230, frame:GetTall() - 80)
    contentPanel:SetPos(220, 70)
    contentPanel.Paint = nil
    
    -- Navigation tabs
    local tabs = {
        {name = "Market",   icon = "stockmarket/icons/statistics.png",    view = "market"},
        {name = "Portfolio",icon = "stockmarket/icons/portfolio.png",view = "portfolio"},
        {name = "News",     icon = "stockmarket/icons/news.png",     view = "news"},
        --comingsoon--{name = "Groups",   icon = "stockmarket/icons/groups.png",   view = "groups"},
    }
    
    local tabButtons = {}
    local currentView = nil
    
    local function ShowView(viewName, data)
        contentPanel:Clear()
        
        if viewName == "market" then
            currentView = StockMarket.UI.MarketOverview:Create(contentPanel)
            StockMarket.UI.MainFrame.currentView = currentView
        elseif viewName == "portfolio" then
            currentView = StockMarket.UI.PortfolioView:Create(contentPanel)
            StockMarket.UI.MainFrame.currentView = currentView
            frame.portfolioView = currentView
            net.Start("StockMarket_RequestPortfolio")
            net.SendToServer()
        elseif viewName == "news" then
            currentView = StockMarket.UI.NewsFeed:CreatePanel(contentPanel)
            StockMarket.UI.MainFrame.currentView = currentView
        elseif viewName == "groups" then
            currentView = StockMarket.UI.GroupsView:Create(contentPanel)
            StockMarket.UI.MainFrame.currentView = currentView
        elseif viewName == "ticker" then
            currentView = StockMarket.UI.TickerView(contentPanel, data)
            StockMarket.UI.MainFrame.currentView = currentView
        end

        for _, btn in pairs(tabButtons) do
            btn.active = false
        end
    end

        -- Create tab buttons
        for i, tab in ipairs(tabs) do
            local btn = StockMarket.UI.Lib:TabButton(navPanel, tab.name, tab.icon)
            btn:SetSize(180, 50)
            btn:SetPos(10, 10 + (i - 1) * 60)
            btn.viewName = tab.view

            btn.DoClick = function(self)
                ShowView(self.viewName)
                for _, b in pairs(tabButtons) do
                    b.active = false
                end
                self.active = true
            end

            tabButtons[tab.view] = btn
        end

        -- Show initial view
        if initialTicker then
            ShowView("ticker", initialTicker)
        else
            tabButtons["market"].active = true
            ShowView("market")
        end

        -- Refresh prices periodically
        timer.Create("StockMarket_UI_Refresh", 1, 0, function()
            if not IsValid(frame) then
                timer.Remove("StockMarket_UI_Refresh")
                return
            end
            if currentView and currentView.Refresh then
                -- Avoid stateless refresh for portfolio; it needs server data.
                if currentView ~= frame.portfolioView then
                    currentView:Refresh()
                end
            end
        end)

        frame.OnClose = function()
            timer.Remove("StockMarket_UI_Refresh")
        end
    end

    function StockMarket.UI.OpenTickerView(ticker)
        if IsValid(StockMarket.UI.MainFrame) then
            StockMarket.UI.MainFrame:Close()
        end
        StockMarket.UI.OpenMainFrame(ticker)
    end

    function StockMarket.UI.OpenTradeDialog(ticker, isBuy, maxShares)
        -- Simple trade dialog (can be expanded)
        StockMarket.UI.OpenTickerView(ticker)
    end
