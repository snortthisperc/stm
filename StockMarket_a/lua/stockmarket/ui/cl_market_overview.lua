-- ========================================
-- Market Overview - All Stocks
-- ========================================

StockMarket.UI.MarketOverview = {}

local SM_IconStats = Material("stockmarket/icons/statistics.png", "smooth")

function StockMarket.UI.MarketOverview:Create(parent)
    local view = vgui.Create("DPanel", parent)
    view:Dock(FILL)
    view.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, StockMarket.UI.Colors.Background)
    end
    
    -- Search bar
    local searchPanel = vgui.Create("DPanel", view)
    searchPanel:Dock(TOP)
    searchPanel:SetTall(60)
    searchPanel:DockMargin(20, 20, 20, 10)
    searchPanel.Paint = nil
    
    local searchEntry = StockMarket.UI.Lib:TextEntry(searchPanel, "Search stocks...")
    searchEntry:Dock(FILL)
    searchEntry:DockMargin(0, 10, 0, 10)
    
    -- Stocks list
    local scroll = StockMarket.UI.Lib:ScrollPanel(view)
    scroll:Dock(FILL)
    scroll:DockMargin(20, 0, 20, 20)
    
    view.Refresh = function(self, filterText)
        scroll:Clear()
        
        local tickers = StockMarket.Config:GetAllTickers()
        --print("[SM Client] MarketOverview Refresh tickers:", #tickers)
        
        -- Sort by sector
        local bySector = {}
        for _, ticker in ipairs(tickers) do
            local sector = ticker.sectorName or "Other"
            if not bySector[sector] then
                bySector[sector] = {}
            end
            table.insert(bySector[sector], ticker)
        end
        
        for sector, stocks in SortedPairs(bySector) do
            -- Sector header
            local sectorHeader = vgui.Create("DPanel", scroll)
            sectorHeader:Dock(TOP)
            sectorHeader:SetTall(40)
            sectorHeader:DockMargin(0, 10, 0, 5)
            sectorHeader.Paint = function(self, w, h)
                -- Sector name (left)
                draw.SimpleText(sector, "StockMarket_SubtitleFont", 10, h/2,
                    StockMarket.UI.Colors.Primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                -- Subtle statistics icon on the right (optional)
                if SM_IconStats then
                    surface.SetMaterial(SM_IconStats)
                    surface.SetDrawColor(255, 255, 255, 40)
                    surface.DrawTexturedRect(w - 28, h/2 - 10, 20, 20)
                end
            end
            
            -- Stock items
            for _, ticker in ipairs(stocks) do
                if filterText and filterText ~= "" then
                    local search = string.lower(filterText)
                    local name = string.lower(ticker.stockName)
                    local prefix = string.lower(ticker.stockPrefix)
                    if not string.find(name, search) and not string.find(prefix, search) then
                        continue
                    end
                end
                
                local stockPanel = StockMarket.UI.Lib:Panel(scroll)
                stockPanel:SetTall(80)
                stockPanel:Dock(TOP)
                stockPanel:DockMargin(0, 0, 0, 8)
                stockPanel:SetCursor("hand")
                stockPanel.hovered = false
                stockPanel.ticker = ticker.stockPrefix
                
                stockPanel.Paint = function(self, w, h)
                    local bgCol = self.hovered and StockMarket.UI.Colors.BackgroundDark or StockMarket.UI.Colors.BackgroundLight
                    draw.RoundedBox(8, 0, 0, w, h, bgCol)
                    
                    -- Ticker badge
                    draw.RoundedBox(6, 15, 15, 80, 50, StockMarket.UI.Colors.Primary)
                    draw.SimpleText(ticker.stockPrefix, "StockMarket_TickerFont", 55, 40, 
                        StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    
                    -- Stock name
                    draw.SimpleText(ticker.stockName, "StockMarket_SubtitleFont", 110, 20, 
                        StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    
                    -- Sector
                    draw.SimpleText(sector, "StockMarket_SmallFont", 110, 50, 
                        StockMarket.UI.Colors.TextMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    
                    -- Current price
                    local priceData = StockMarket.StockData:GetPrice(ticker.stockPrefix)
                    if priceData then
                        draw.SimpleText(StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(priceData.price, 2)), 
                            "StockMarket_PriceFont", w - 20, 20, 
                            StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
                        
                        local up = priceData.change >= 0
                        local changeCol = up and StockMarket.UI.Colors.Positive or StockMarket.UI.Colors.Negative
                        local icon = up and StockMarket.UI.Icons.UpTrend or StockMarket.UI.Icons.DownTrend
                        local changeText = string.format("%s%.2f (%.2f%%)", up and "+" or "", priceData.change, priceData.changePercent)

                        -- compute right-aligned layout: icon (16x16) + gap + text
                        local gap = 4
                        surface.SetFont("StockMarket_TextFont")
                        local tw, th = surface.GetTextSize(changeText)
                        local totalW = 16 + gap + tw
                        local baseX = w - 20 - totalW
                        local baseY = 50

                        -- icon tinted to match color
                        surface.SetMaterial(icon)
                        surface.SetDrawColor(changeCol.r, changeCol.g, changeCol.b, 255)
                        surface.DrawTexturedRect(baseX, baseY + 2, 16, 16)

                        -- text
                        draw.SimpleText(changeText, "StockMarket_TextFont", baseX + 16 + gap, baseY, changeCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    end
                end
                
                stockPanel.OnCursorEntered = function(self)
                    self.hovered = true
                end
                
                stockPanel.OnCursorExited = function(self)
                    self.hovered = false
                end
                
                stockPanel.OnMousePressed = function(self, keyCode)
                    if keyCode == MOUSE_LEFT then
                        StockMarket.UI.OpenTickerView(ticker.stockPrefix)
                    end
                end
            end
        end
    end
    
    searchEntry.OnChange = function(self)
        view:Refresh(self:GetValue())
    end
    
    view:Refresh("")
    
    return view
end

hook.Add("StockMarket_ClientMarketsHydrated", "SM_MarketOverview_AutoRefresh", function()
    --print("[SM Client] StockMarket_ClientMarketsHydrated hook fired in MarketOverview")
    if IsValid(StockMarket.UI.MainFrame) and StockMarket.UI.MainFrame.currentView and StockMarket.UI.MainFrame.currentView.Refresh then
        timer.Simple(0, function()
            if IsValid(StockMarket.UI.MainFrame) and StockMarket.UI.MainFrame.currentView and StockMarket.UI.MainFrame.currentView.Refresh then
                --print("[SM Client] ✓ Calling Refresh from hydration hook")
                StockMarket.UI.MainFrame.currentView:Refresh("")
            end
        end)
    else
        --print("[SM Client] Hook fired but MainFrame not valid or no currentView")
    end
end)