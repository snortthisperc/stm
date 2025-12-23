-- ========================================
-- Portfolio Management
-- ========================================

StockMarket.Portfolio = StockMarket.Portfolio or {}

function StockMarket.Portfolio:GetSummary(ply)
    local portfolio = StockMarket.PlayerData:GetPortfolio(ply)
    if not portfolio then return nil end
    
    local positions = {}
    local totalValue = portfolio.cash
    local totalUnrealizedPnL = 0
    
    for ticker, pos in pairs(portfolio.positions) do
        local currentPrice = StockMarket.StockEngine:GetPrice(ticker)
        if currentPrice then
            local marketValue = pos.shares * currentPrice
            local costBasis = pos.shares * pos.avgCost
            local unrealizedPnL = marketValue - costBasis
            local unrealizedPnLPercent = costBasis > 0 and (unrealizedPnL / costBasis) * 100 or 0
            
            totalValue = totalValue + marketValue
            totalUnrealizedPnL = totalUnrealizedPnL + unrealizedPnL
            
            table.insert(positions, {
                ticker = ticker,
                shares = pos.shares,
                avgCost = pos.avgCost,
                currentPrice = currentPrice,
                marketValue = marketValue,
                costBasis = costBasis,
                unrealizedPnL = unrealizedPnL,
                unrealizedPnLPercent = unrealizedPnLPercent
            })
        end
    end
    
    return {
        cash = portfolio.cash,
        totalValue = totalValue,
        totalInvested = portfolio.totalInvested,
        realizedProfit = portfolio.realizedProfit,
        unrealizedProfit = totalUnrealizedPnL,
        positions = positions
    }
end

    net.Receive("StockMarket_RequestPortfolio", function(len, ply)
        local summary = StockMarket.Portfolio:GetSummary(ply)
        if not summary then return end

        net.Start("StockMarket_PortfolioUpdate")
        net.WriteFloat(tonumber(summary.cash or 0) or 0)
        net.WriteFloat(tonumber(summary.totalInvested or 0) or 0)
        net.WriteFloat(tonumber(summary.realizedProfit or 0) or 0)

        local positions = summary.positions or {}
        net.WriteUInt(#positions, 16)
        for i = 1, #positions do
            local p = positions[i]
            net.WriteString(p.ticker or "")
            net.WriteInt(tonumber(p.shares or 0) or 0, 32)
            net.WriteFloat(tonumber(p.avgCost or 0) or 0)
        end

        net.Send(ply)
    end)