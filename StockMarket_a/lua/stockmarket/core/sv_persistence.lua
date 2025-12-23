-- ========================================
-- Persistence Layer
-- ========================================

StockMarket.Persistence = StockMarket.Persistence or {}

-- History request/response (server)
if SERVER then
    util.AddNetworkString("StockMarket_RequestHistory")
    util.AddNetworkString("StockMarket_HistoryData")

    StockMarket._rl_hist = StockMarket._rl_hist or {}
    local function HistLimited(ply)
        local sid = IsValid(ply) and ply:SteamID64() or "?"
        local st = StockMarket._rl_hist[sid] or { last = 0, count = 0 }
        local now = CurTime()
        if now - st.last > 1 then
            st.last = now
            st.count = 0
        end
        st.count = st.count + 1
        StockMarket._rl_hist[sid] = st
        return st.count > 5
    end

    net.Receive("StockMarket_RequestHistory", function(_, ply)
        if HistLimited(ply) then return end

        local ticker = net.ReadString()
        local seconds = net.ReadInt(32) or 3600
        local now = os.time()
        local startTime = now - math.max(60, seconds)
        local history = StockMarket.Persistence:GetHistory(ticker, startTime, now) or {}

        net.Start("StockMarket_HistoryData")
        net.WriteString(ticker)
        net.WriteUInt(#history, 16)
        for i = 1, #history do
            local h = history[i]
            net.WriteUInt(h.timestamp or 0, 32)
            net.WriteFloat(h.open or 0)
            net.WriteFloat(h.high or 0)
            net.WriteFloat(h.low or 0)
            net.WriteFloat(h.close or 0)
            net.WriteUInt(h.volume or 0, 32)
        end
        net.Send(ply)
    end)
end

-- Save player portfolio
function StockMarket.Persistence:SavePlayer(ply)
    local sid = ply:SteamID64()
    local portfolio = StockMarket.PlayerData:GetPortfolio(ply)
    if not portfolio then return end

    sql.Query(string.format([[
        REPLACE INTO stockmarket_players (steam_id, cash, total_invested, realized_profit, last_updated)
        VALUES (%s, %f, %f, %f, %d)
    ]], sql.SQLStr(sid), portfolio.cash or 0, portfolio.totalInvested or 0, 
        portfolio.realizedProfit or 0, os.time()))

    sql.Query(string.format("DELETE FROM stockmarket_positions WHERE steam_id = %s", sql.SQLStr(sid)))

    for ticker, pos in pairs(portfolio.positions or {}) do
        sql.Query(string.format([[
            INSERT INTO stockmarket_positions (steam_id, ticker, shares, avg_cost, last_updated)
            VALUES (%s, %s, %d, %f, %d)
        ]], sql.SQLStr(sid), sql.SQLStr(ticker), pos.shares, pos.avgCost, os.time()))
    end
end

-- Load player portfolio
function StockMarket.Persistence:LoadPlayer(ply)
    local sid = ply:SteamID64()

    local result = sql.Query(string.format(
        "SELECT * FROM stockmarket_players WHERE steam_id = %s", sql.SQLStr(sid)
    ))

    local portfolio = {
        cash = 0,
        totalInvested = 0,
        realizedProfit = 0,
        positions = {}
    }

    if result and result[1] then
        portfolio.cash = tonumber(result[1].cash) or 0
        portfolio.totalInvested = tonumber(result[1].total_invested) or 0
        portfolio.realizedProfit = tonumber(result[1].realized_profit) or 0
    else
        portfolio.cash = StockMarket.Config.StartingCash or 50000
    end

    local positions = sql.Query(string.format(
        "SELECT * FROM stockmarket_positions WHERE steam_id = %s", sql.SQLStr(sid)
    ))

    if positions then
        for _, pos in ipairs(positions) do
            portfolio.positions[pos.ticker] = {
                shares = tonumber(pos.shares),
                avgCost = tonumber(pos.avg_cost)
            }
        end
    end

    StockMarket.PlayerData:SetPortfolio(ply, portfolio)
    return portfolio
end

-- Save stock state
function StockMarket.Persistence:SaveStockState(ticker, data)
    sql.Query(string.format([[
        REPLACE INTO stockmarket_stock_state (ticker, current_price, last_update, halted, active_event)
        VALUES (%s, %f, %d, %d, %s)
    ]], sql.SQLStr(ticker), data.price, os.time(), data.halted and 1 or 0, 
        sql.SQLStr(data.activeEvent or "")))
end

-- Load stock state
function StockMarket.Persistence:LoadStockState(ticker)
    local result = sql.Query(string.format(
        "SELECT * FROM stockmarket_stock_state WHERE ticker = %s", sql.SQLStr(ticker)
    ))

    if result and result[1] then
        return {
            price = tonumber(result[1].current_price),
            halted = result[1].halted == 1,
            activeEvent = result[1].active_event ~= "" and result[1].active_event or nil
        }
    end
    return nil
end

-- Save price bar to history
function StockMarket.Persistence:SavePriceBar(ticker, bar)
    sql.Query(string.format([[
        INSERT INTO stockmarket_history (ticker, timestamp, open, high, low, close, volume)
        VALUES (%s, %d, %f, %f, %f, %f, %d)
    ]], sql.SQLStr(ticker), bar.timestamp, bar.open, bar.high, bar.low, bar.close, bar.volume or 0))
end

-- Get price history
function StockMarket.Persistence:GetHistory(ticker, startTime, endTime)
    local now = os.time()
    startTime = tonumber(startTime) or (now - 24 * 60 * 60)
    endTime   = tonumber(endTime)   or now

    -- Ensure startTime <= endTime
    if startTime > endTime then
        startTime, endTime = endTime, startTime
    end

    local query = string.format([[
        SELECT * FROM stockmarket_history 
        WHERE ticker = %s AND timestamp >= %d AND timestamp <= %d
        ORDER BY timestamp ASC
    ]], sql.SQLStr(ticker), startTime, endTime)

    return sql.Query(query) or {}
end

-- Cleanup old history
function StockMarket.Persistence:CleanupHistory()
    local retention = StockMarket.Config.Persistence.history.retention["1m"] or 2880
    local cutoff = os.time() - (retention * 60)
    sql.Query(string.format("DELETE FROM stockmarket_history WHERE timestamp < %d", cutoff))
end

-- Auto-save timer
timer.Create("StockMarket_AutoSave", StockMarket.Config.Persistence.autosaveSeconds, 0, function()
    for _, ply in ipairs(player.GetAll()) do
        StockMarket.Persistence:SavePlayer(ply)
    end
end)

-- ============================
-- Admin: Aggregates & Snapshots
-- ============================

-- Server stats
function StockMarket.Persistence:GetServerStats()
    -- Total cash in DB
    local totalCash = 0
    local rows = sql.Query("SELECT SUM(cash) AS s FROM stockmarket_players")
    if rows and rows[1] and rows[1].s then totalCash = tonumber(rows[1].s) or 0 end

    -- NEW: Sum online DarkRP money
    local onlineDarkRPMoney = 0
    for _, ply in ipairs(player.GetAll()) do
        if ply.getDarkRPVar then
            onlineDarkRPMoney = onlineDarkRPMoney + (tonumber(ply:getDarkRPVar("money")) or 0)
        end
    end

    -- Compute net worth per player (cash + positions@current)
    local positions = sql.Query("SELECT * FROM stockmarket_positions") or {}
    local priceLookup = {}
    for _, t in ipairs(StockMarket.Config:GetAllTickers()) do
        priceLookup[t.stockPrefix] = StockMarket.StockEngine:GetPrice(t.stockPrefix) or t.newStockValue or 0
    end

    local perPlayerValue = {}
    for _, pos in ipairs(positions) do
        local sid = pos.steam_id
        local shares = tonumber(pos.shares) or 0
        local px = priceLookup[pos.ticker] or 0
        perPlayerValue[sid] = (perPlayerValue[sid] or 0) + shares * px
    end

    local players = sql.Query("SELECT steam_id, realized_profit FROM stockmarket_players") or {}
    local totalValue = totalCash
    local avgRealized, avgUnreal = 0, 0
    local count = math.max(1, #players)

    for _, p in ipairs(players) do
        local sid = p.steam_id
        local invested = perPlayerValue[sid] or 0
        totalValue = totalValue + invested
        avgRealized = avgRealized + (tonumber(p.realized_profit) or 0)
    end
    avgRealized = avgRealized / count

    -- Unrealized needs avg cost; quick approx via positions table diff from avg_cost:
    -- (MarketValue - CostBasis) across all
    local costBasis = 0
    local marketValue = 0
    for _, pos in ipairs(positions) do
        local shares = tonumber(pos.shares) or 0
        local px = priceLookup[pos.ticker] or 0
        marketValue = marketValue + shares * px
        costBasis = costBasis + shares * (tonumber(pos.avg_cost) or 0)
    end
    avgUnreal = (marketValue - costBasis) / count

    local function money(n) return StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(n or 0, 2)) end
    return {
        totalValueText = money(totalValue),
        onlineDarkRPText = money(onlineDarkRPMoney),  -- NEW
        avgRealizedText = money(avgRealized),
        avgUnrealizedText = money(avgUnreal),
        -- Raw values for client-side color pills
        avgRealizedRaw = avgRealized,
        avgUnrealizedRaw = avgUnreal,
    }
end

-- List online players with quick net worth
function StockMarket.Persistence:GetOnlinePlayersSnapshot()
    local list = {}
    local priceLookup = {}
    for _, t in ipairs(StockMarket.Config:GetAllTickers()) do
        priceLookup[t.stockPrefix] = StockMarket.StockEngine:GetPrice(t.stockPrefix) or t.newStockValue or 0
    end

    for _, ply in ipairs(player.GetAll()) do
        local sid = ply:SteamID64()
        local portfolio = StockMarket.PlayerData:GetPortfolio(ply)
        if not portfolio then portfolio = StockMarket.Persistence:LoadPlayer(ply) end

        local net = portfolio.cash or 0
        for ticker, pos in pairs(portfolio.positions or {}) do
            net = net + (pos.shares or 0) * (priceLookup[ticker] or 0)
        end
        table.insert(list, {
            name = ply:Nick(),
            steamid = sid,
            net = StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(net, 2))
        })
    end
    table.SortByMember(list, "name", true)
    return list
end

-- Fetch a given player's portfolio snapshot (for admin view)
function StockMarket.Persistence:GetPlayerPortfolioSnapshot(steamid)
    if not steamid then return {} end
    local row = sql.QueryRow(string.format("SELECT * FROM stockmarket_players WHERE steam_id = %s", sql.SQLStr(steamid)))
    local cash = row and tonumber(row.cash) or 0
    local realizedProfit = row and tonumber(row.realized_profit) or 0

    local priceLookup = {}
    for _, t in ipairs(StockMarket.Config:GetAllTickers()) do
        priceLookup[t.stockPrefix] = StockMarket.StockEngine:GetPrice(t.stockPrefix) or t.newStockValue or 0
    end

    local positions = sql.Query(string.format("SELECT * FROM stockmarket_positions WHERE steam_id = %s", sql.SQLStr(steamid))) or {}
    local out = { positions = {}, net = 0, steamid = steamid }  -- NEW: added steamid
    local net = cash
    local totalUnrealized = 0  -- NEW

    for _, p in ipairs(positions) do
        local shares = tonumber(p.shares) or 0
        local avgCost = tonumber(p.avg_cost) or 0  -- NEW
        local price = priceLookup[p.ticker] or 0
        local marketValue = shares * price
        local unrealized = shares * (price - avgCost)  -- NEW
        
        net = net + marketValue
        totalUnrealized = totalUnrealized + unrealized  -- NEW
        
        table.insert(out.positions, {
            ticker = p.ticker,
            shares = shares,
            avgCost = avgCost,  -- NEW
            price = StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(price, 2)),
            marketValue = marketValue,  -- NEW (raw number)
            unrealized = unrealized,  -- NEW
        })
    end
    
    out.net = StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(net, 2))
    out.realized = realizedProfit  -- NEW
    out.unrealized = totalUnrealized  -- NEW
    
    return out
end
