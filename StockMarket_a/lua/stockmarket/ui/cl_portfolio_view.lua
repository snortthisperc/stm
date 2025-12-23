-- ========================================
-- Portfolio View
-- ========================================

StockMarket.UI.PortfolioView = {}

function StockMarket.UI.PortfolioView:Create(parent)
    local view = vgui.Create("DPanel", parent)
    view:Dock(FILL)
    view.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, StockMarket.UI.Colors.Background)
    end

    -- Wrap entire content in a single scroll
    local scroll = StockMarket.UI.Lib:ScrollPanel(view)
    scroll:Dock(FILL)
    scroll:DockMargin(20, 20, 20, 20)

    -- Header cards container
    local headerPanel = vgui.Create("DPanel", scroll)
    headerPanel:Dock(TOP)
    headerPanel:SetTall(120)
    headerPanel:DockMargin(0, 0, 0, 10)
    headerPanel.Paint = nil

    local cards = {}
    local cardData = {
        {title = "Total Value", value = "$0.00", key = "totalValue"},
        {title = "Cash", value = "$0.00", key = "cash"},
        {title = "Realized P/L", value = "$0.00", key = "realizedProfit"},
        {title = "Unrealized P/L", value = "$0.00", key = "unrealizedProfit"}
    }

    -- Create 4 info cards, evenly spaced; compute width on layout
    headerPanel.PerformLayout = function(pnl, w, h)
        local padding = 20
        local eachW = math.floor((w - padding * 3) / 4)
        local x = 0
        for i = 1, 4 do
            local key = cardData[i].key
            local card = cards[key]
            if IsValid(card) then
                card:SetPos(x, 0)
                card:SetSize(eachW, h)
            end
            x = x + eachW + padding
        end
    end

    for i, data in ipairs(cardData) do
        local card = StockMarket.UI.Lib:InfoCard(headerPanel, data.title, data.value)
        cards[data.key] = card
    end

    -- Title
    local titleLabel = vgui.Create("DLabel", scroll)
    titleLabel:Dock(TOP)
    titleLabel:SetTall(30)
    titleLabel:DockMargin(0, 10, 0, 5)
    titleLabel:SetFont("StockMarket_SubtitleFont")
    titleLabel:SetTextColor(StockMarket.UI.Colors.TextPrimary)
    titleLabel:SetText("Your Positions")

    -- Positions list container
    local listPanel = vgui.Create("DPanel", scroll)
    listPanel:Dock(TOP)
    listPanel:DockMargin(0, 0, 0, 0)
    listPanel:SetTall(0)
    listPanel.Paint = nil

    listPanel.PerformLayout = function(pnl, w, h)
        local total = 0
        for _, child in ipairs(pnl:GetChildren()) do
            total = total + child:GetTall()
            local _, t, _, b = child:GetDockMargin()
            total = total + t + b
        end
        pnl:SetTall(total)
    end

        -- Refresh implementation
        view.Refresh = function(self, portfolio)
            -- Use cached portfolio if none provided (timer-safe)
            portfolio = portfolio or StockMarket.ClientPortfolio or {}
            local positions = portfolio.positions or {}
            if not istable(positions) then positions = {} end

            -- Get real DarkRP wallet balance
            local darkRPMoney = 0
            if IsValid(LocalPlayer()) and LocalPlayer().getDarkRPVar then
                darkRPMoney = tonumber(LocalPlayer():getDarkRPVar("money")) or 0
            else
                darkRPMoney = tonumber(portfolio.cash or 0) or 0
            end

            -- Calculate real total value from positions (uses 'positions', not portfolio.positions)
            local stocksValue = 0
            for _, pos in ipairs(positions) do
                local pd = StockMarket.StockData:GetPrice(pos.ticker or "") or {}
                local price = tonumber(pd.price) or 0
                stocksValue = stocksValue + (tonumber(pos.shares) or 0) * price
            end

            local realTotalValue = darkRPMoney + stocksValue

            -- Update Total Value card (DarkRP money + stocks)
            cards.totalValue.Paint = function(pnl, w, h)
                draw.RoundedBox(8, 0, 0, w, h, StockMarket.UI.Colors.BackgroundLight)
                draw.SimpleText("Total Value", "StockMarket_SmallFont", 12, 12, StockMarket.UI.Colors.TextSecondary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText(
                    StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(realTotalValue or 0, 2)),
                    "StockMarket_TitleFont", 12, 35, StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
                )
            end

            -- Update Cash card (DarkRP wallet only)
            cards.cash.Paint = function(pnl, w, h)
                draw.RoundedBox(8, 0, 0, w, h, StockMarket.UI.Colors.BackgroundLight)
                draw.SimpleText("Cash", "StockMarket_SmallFont", 12, 12, StockMarket.UI.Colors.TextSecondary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText(
                    StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(darkRPMoney or 0, 2)),
                    "StockMarket_TitleFont", 12, 35, StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
                )
            end

            -- Realized P/L (from server portfolio data)
            cards.realizedProfit.Paint = function(pnl, w, h)
                local realizedPL = tonumber(portfolio.realizedProfit) or 0
                draw.RoundedBox(8, 0, 0, w, h, StockMarket.UI.Colors.BackgroundLight)
                draw.SimpleText("Realized P/L", "StockMarket_SmallFont", 12, 12, StockMarket.UI.Colors.TextSecondary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                local col = realizedPL >= 0 and StockMarket.UI.Colors.Success or StockMarket.UI.Colors.Danger
                draw.SimpleText(
                    StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(realizedPL, 2)),
                    "StockMarket_TitleFont", 12, 35, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
                )
            end

            -- Unrealized P/L (either from server or compute fallback)
            cards.unrealizedProfit.Paint = function(pnl, w, h)
                -- Prefer server-provided unrealizedProfit; fallback: compute from positions
                local unrealizedPL = tonumber(portfolio.unrealizedProfit)
                if unrealizedPL == nil then
                    local tmpUnrealized = 0
                    for _, p in ipairs(positions) do
                        local shares = tonumber(p.shares) or 0
                        local avgCost = tonumber(p.avgCost) or 0
                        local pd = StockMarket.StockData:GetPrice(p.ticker or "") or {}
                        local price = tonumber(pd.price) or 0
                        tmpUnrealized = tmpUnrealized + (shares * (price - avgCost))
                    end
                    unrealizedPL = tmpUnrealized
                end

                draw.RoundedBox(8, 0, 0, w, h, StockMarket.UI.Colors.BackgroundLight)
                draw.SimpleText("Unrealized P/L", "StockMarket_SmallFont", 12, 12, StockMarket.UI.Colors.TextSecondary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                local col = unrealizedPL >= 0 and StockMarket.UI.Colors.Success or StockMarket.UI.Colors.Danger
                draw.SimpleText(
                    StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(unrealizedPL, 2)),
                    "StockMarket_TitleFont", 12, 35, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
                )
            end

            -- Rebuild positions list
            listPanel:Clear()

            if #positions == 0 then
                local empty = vgui.Create("DLabel", listPanel)
                empty:Dock(TOP)
                empty:SetTall(100)
                empty:SetFont("StockMarket_TextFont")
                empty:SetTextColor(StockMarket.UI.Colors.TextMuted)
                empty:SetText("No positions yet. Start trading!")
                empty:SetContentAlignment(5)
                return
            end

            for _, pos in ipairs(positions) do
                local row = StockMarket.UI.Lib:Panel(listPanel)
                row:Dock(TOP)
                row:SetTall(90)
                row:DockMargin(0, 0, 0, 10)

                -- Right side action area (Sell button)
                local actions = vgui.Create("DPanel", row)
                actions:Dock(RIGHT)
                actions:SetWide(120)
                actions.Paint = nil

                local sellBtn = StockMarket.UI.Lib:Button(actions, "SELL", function()
                    StockMarket.UI.OpenTickerView(pos.ticker)
                end)
                sellBtn:Dock(BOTTOM)
                sellBtn:DockMargin(10, 10, 10, 10)
                sellBtn:SetTall(32)

                row.Paint = function(pnl, w, h)
                    draw.RoundedBox(8, 0, 0, w, h, StockMarket.UI.Colors.BackgroundLight)

                    draw.SimpleText(pos.ticker or "TICK", "StockMarket_TickerFont", 20, 20, StockMarket.UI.Colors.Primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    draw.SimpleText((pos.shares or 0) .. " shares @ " .. StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(pos.avgCost or 0, 2)),
                        "StockMarket_SmallFont", 20, 45, StockMarket.UI.Colors.TextSecondary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

                    -- Safe guards
                    local shares = tonumber(pos.shares) or 0
                    local avgCost = tonumber(pos.avgCost) or 0

                    local pd = StockMarket.StockData:GetPrice(pos.ticker or "") or {}
                    local price = tonumber(pd.price) or 0

                    local marketValue = shares * price
                    local costBasis = shares * avgCost
                    local unrealizedPnL = marketValue - costBasis
                    local unrealizedPct = costBasis > 0 and (unrealizedPnL / costBasis) * 100 or 0

                    draw.SimpleText("Current: " .. StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(price, 2)),
                        "StockMarket_TextFont", w - actions:GetWide() - 300, 20, StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                    draw.SimpleText("Value: " .. StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(marketValue, 2)),
                        "StockMarket_TextFont", w - actions:GetWide() - 300, 45, StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

                    local pnlCol = (unrealizedPnL or 0) >= 0 and StockMarket.UI.Colors.Success or StockMarket.UI.Colors.Danger
                    local pnlSymbol = (unrealizedPnL or 0) >= 0 and "+" or ""
                    draw.SimpleText(
                        pnlSymbol .. StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(unrealizedPnL or 0, 2)) ..
                        string.format(" (%.2f%%)", unrealizedPct),
                        "StockMarket_TextFont",
                        w - actions:GetWide() - 20, 33, pnlCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER
                    )
                end
            end
        end

    return view
end

-- Network receiver
net.Receive("StockMarket_PortfolioUpdate", function()
    local portfolio = {
        cash = net.ReadFloat(),
        totalInvested = net.ReadFloat(),
        realizedProfit = net.ReadFloat(),
        positions = {}
    }
    local count = net.ReadUInt(16) or 0
    for i = 1, count do
        local t = net.ReadString()
        local shares = net.ReadInt(32)
        local avgCost = net.ReadFloat()
        portfolio.positions[#portfolio.positions + 1] = {
            ticker = t,
            shares = shares,
            avgCost = avgCost
        }
    end

    StockMarket.ClientPortfolio = portfolio

    if StockMarket.UI.MainFrame and StockMarket.UI.MainFrame.portfolioView then
        StockMarket.UI.MainFrame.portfolioView:Refresh(portfolio)
    end
end)
