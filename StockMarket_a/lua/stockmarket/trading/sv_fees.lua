-- ========================================
-- Trading Fees Calculator
-- ========================================

StockMarket.Fees = StockMarket.Fees or {}

function StockMarket.Fees:Calculate(ticker, shares, price, orderType)
    local tickerConfig, sectorData = StockMarket.Config:GetTickerByPrefix(ticker)
    
    local fees = tickerConfig and tickerConfig.tradeFees or StockMarket.Config.DefaultFees
    
    local tradeValue = shares * price
    local isMaker = (orderType == StockMarket.Enums.OrderType.LIMIT)
    
    local percentFee = isMaker and fees.makerPercent or fees.takerPercent
    local calculatedFee = tradeValue * percentFee
    local flatFee = fees.flatFee or 0
    
    local totalFee = calculatedFee + flatFee
    
    return totalFee
end

function StockMarket.Fees:ApplyFee(ply, amount, description)
    if StockMarket.PlayerData:RemoveCash(ply, amount) then
        -- Log transaction
        StockMarket.Transactions:Log(ply, nil, StockMarket.Enums.TransactionType.FEE, 0, 0, amount, description)
        return true
    end
    return false
end
