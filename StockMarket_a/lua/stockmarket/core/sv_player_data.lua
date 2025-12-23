-- ========================================
-- Player Data Management
-- ========================================

StockMarket.PlayerData = StockMarket.PlayerData or {}
StockMarket.PlayerData.Cache = StockMarket.PlayerData.Cache or {}

function StockMarket.PlayerData:GetPortfolio(ply)
    if not IsValid(ply) then return nil end
    return self.Cache[ply:SteamID64()]
end

function StockMarket.PlayerData:SetPortfolio(ply, portfolio)
    if not IsValid(ply) then return end
    self.Cache[ply:SteamID64()] = portfolio
end

function StockMarket.PlayerData:GetCash(ply)
    local portfolio = self:GetPortfolio(ply)
    return portfolio and portfolio.cash or 0
end

function StockMarket.PlayerData:AddCash(ply, amount)
    local portfolio = self:GetPortfolio(ply)
    if not portfolio then return false end
    
    portfolio.cash = portfolio.cash + amount
    self:SyncPortfolio(ply)
    return true
end

function StockMarket.PlayerData:RemoveCash(ply, amount)
    local portfolio = self:GetPortfolio(ply)
    if not portfolio or portfolio.cash < amount then return false end
    
    portfolio.cash = portfolio.cash - amount
    self:SyncPortfolio(ply)
    return true
end

function StockMarket.PlayerData:GetPosition(ply, ticker)
    local portfolio = self:GetPortfolio(ply)
    if not portfolio then return nil end
    return portfolio.positions[ticker]
end

function StockMarket.PlayerData:AddPosition(ply, ticker, shares, price)
    local portfolio = self:GetPortfolio(ply)
    if not portfolio then return false end
    
    local pos = portfolio.positions[ticker]
    if pos then
        -- Update average cost
        local totalCost = (pos.shares * pos.avgCost) + (shares * price)
        pos.shares = pos.shares + shares
        pos.avgCost = totalCost / pos.shares
    else
        portfolio.positions[ticker] = {
            shares = shares,
            avgCost = price
        }
    end
    
    portfolio.totalInvested = portfolio.totalInvested + (shares * price)
    self:SyncPortfolio(ply)
    return true
end

function StockMarket.PlayerData:RemovePosition(ply, ticker, shares, price)
    local portfolio = self:GetPortfolio(ply)
    if not portfolio then return false end
    
    local pos = portfolio.positions[ticker]
    if not pos or pos.shares < shares then return false end
    
    pos.shares = pos.shares - shares
    
    -- Calculate realized profit
    local costBasis = shares * pos.avgCost
    local saleValue = shares * price
    local profit = saleValue - costBasis
    portfolio.realizedProfit = portfolio.realizedProfit + profit
    portfolio.totalInvested = portfolio.totalInvested - costBasis
    
    if pos.shares <= 0 then
        portfolio.positions[ticker] = nil
    end
    
    self:SyncPortfolio(ply)
    return true, profit
end

function StockMarket.PlayerData:SyncPortfolio(ply)
    if not IsValid(ply) then return end

    local portfolio = self:GetPortfolio(ply)
    if not portfolio then return end

    -- positions is a dictionary keyed by ticker; transform to array for deterministic order
    local positionsArr = {}
    for ticker, pos in pairs(portfolio.positions or {}) do
        positionsArr[#positionsArr + 1] = {
            ticker = ticker,
            shares = tonumber(pos.shares) or 0,
            avgCost = tonumber(pos.avgCost) or 0
        }
    end

    net.Start("StockMarket_PortfolioUpdate")
    net.WriteFloat(tonumber(portfolio.cash or 0) or 0)
    net.WriteFloat(tonumber(portfolio.totalInvested or 0) or 0)
    net.WriteFloat(tonumber(portfolio.realizedProfit or 0) or 0)
    net.WriteUInt(#positionsArr, 16)
    for i = 1, #positionsArr do
        local p = positionsArr[i]
        net.WriteString(p.ticker or "")
        net.WriteInt(p.shares or 0, 32)
        net.WriteFloat(p.avgCost or 0)
    end
    net.Send(ply)
end

function StockMarket.PlayerData:CalculateNetWorth(ply)
    local portfolio = self:GetPortfolio(ply)
    if not portfolio then return 0 end
    
    local total = portfolio.cash
    
    -- positions is a dictionary keyed by ticker symbols (non-sequential); pairs is correct
    for ticker, pos in pairs(portfolio.positions or {}) do
        local currentPrice = StockMarket.StockEngine:GetPrice(ticker)
        if currentPrice then
            total = total + (pos.shares * currentPrice)
        end
    end
    
    return total
end

-- Hooks
hook.Add("PlayerInitialSpawn", "StockMarket_LoadPlayer", function(ply)
    timer.Simple(1, function()
        if not IsValid(ply) then return end
        StockMarket.Persistence:LoadPlayer(ply)
        StockMarket.PlayerData:SyncPortfolio(ply)
    end)
end)

hook.Add("PlayerDisconnected", "StockMarket_SavePlayer", function(ply)
    StockMarket.Persistence:SavePlayer(ply)
    StockMarket.PlayerData.Cache[ply:SteamID64()] = nil
end)
