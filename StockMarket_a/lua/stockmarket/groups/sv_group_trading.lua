-- ========================================
-- Investment Group Trading
-- ========================================

StockMarket.GroupTrading = StockMarket.GroupTrading or {}
StockMarket.GroupTrading._rl = StockMarket.GroupTrading._rl or {}
local GT_BURST, GT_REFILL = 5, 1
local function GT_Limited(ply, groupId)
    local sid = IsValid(ply) and ply:SteamID64() or "?"
    local key = string.format("%s:%d", sid, groupId or 0)
    local now = CurTime()
    local st = StockMarket.GroupTrading._rl[key] or { last = now, tokens = GT_BURST }
    local dt = now - st.last
    if dt > 0 then
        st.tokens = math.min(GT_BURST, st.tokens + dt * GT_REFILL)
        st.last = now
    end
    if st.tokens < 1 then
        StockMarket.GroupTrading._rl[key] = st
        return true
    end
    st.tokens = st.tokens - 1
    StockMarket.GroupTrading._rl[key] = st
    return false
end

local function ClampShares(sh)
    sh = math.floor(tonumber(sh) or 0)
    if sh < 1 then return 0 end
    if sh > 10^7 then sh = 10^7 end
    return sh
end

local function EnforceMaxOrderSize(tickerConfig, shares)
    if not tickerConfig then return true, nil end
    local float = tonumber(tickerConfig.marketStocks or 0) or 0
    if float <= 0 then return true, nil end
    local pct = tonumber(StockMarket.Config.MaxOrderSize or 0.10) or 0.10
    local maxSize = math.floor(float * pct)
    if shares > maxSize then
        return false, string.format("Order exceeds %.0f%% of float (max %s)", pct*100, string.Comma(maxSize))
    end
    return true, nil
end

function StockMarket.GroupTrading:PlaceOrder(ply, groupId, ticker, orderType, side, shares, limitPrice)
    if GT_Limited(ply, groupId) then
        return false, "Too many group orders. Slow down."
    end
    shares = ClampShares(shares)
    if shares <= 0 then
        return false, "Invalid share amount"
    end
    local tickerConfig = StockMarket.Config:GetTickerByPrefix(ticker)
    if not tickerConfig then return false, "Invalid ticker" end
    local ok, msg = EnforceMaxOrderSize(tickerConfig, shares)
    if not ok then return false, msg end

    -- Check permissions
    if not StockMarket.Groups:CanTrade(groupId, ply) then
        return false, "Insufficient permissions"
    end

    local group = StockMarket.Groups:GetGroup(groupId)
    if not group then return false, "Group not found" end

    local currentPrice = StockMarket.StockEngine:GetPrice(ticker)
    if not currentPrice then return false, "Price unavailable" end

    -- Market orders only for now
    if orderType == StockMarket.Enums.OrderType.MARKET then
        if side == StockMarket.Enums.OrderSide.BUY then
            return self:ExecuteBuy(ply, groupId, ticker, shares, currentPrice)
        else
            return self:ExecuteSell(ply, groupId, ticker, shares, currentPrice)
        end
    end

    return false, "Order type not supported"
end

function StockMarket.GroupTrading:ExecuteBuy(ply, groupId, ticker, shares, price)
    local totalCost = shares * price
    local fee = StockMarket.Fees:Calculate(ticker, shares, price, StockMarket.Enums.OrderType.MARKET)
    local totalRequired = totalCost + fee
    
    if not StockMarket.Groups:RemoveCash(groupId, totalRequired) then
        return false, "Insufficient group funds"
    end
    
    -- Add position
    local existing = sql.Query(string.format([[
        SELECT * FROM stockmarket_group_positions WHERE group_id = %d AND ticker = %s
    ]], groupId, sql.SQLStr(ticker)))
    
    if existing and existing[1] then
        local pos = existing[1]
        local oldShares = tonumber(pos.shares)
        local oldAvg = tonumber(pos.avg_cost)
        local newAvg = ((oldShares * oldAvg) + (shares * price)) / (oldShares + shares)
        
        sql.Query(string.format([[
            UPDATE stockmarket_group_positions 
            SET shares = %d, avg_cost = %f 
            WHERE group_id = %d AND ticker = %s
        ]], oldShares + shares, newAvg, groupId, sql.SQLStr(ticker)))
    else
        sql.Query(string.format([[
            INSERT INTO stockmarket_group_positions (group_id, ticker, shares, avg_cost)
            VALUES (%d, %s, %d, %f)
        ]], groupId, sql.SQLStr(ticker), shares, price))
    end
    
    StockMarket.Groups.Cache[groupId] = nil -- Invalidate
    return true, "Group order filled"
end

function StockMarket.GroupTrading:ExecuteSell(ply, groupId, ticker, shares, price)
    if not IsValid(ply) then return false, "Player not valid" end
    if shares <= 0 then return false, "Invalid share count" end
    if price <= 0 then return false, "Invalid price" end
    
    local group = StockMarket.Groups:GetGroup(groupId)
    if not group then return false, "Group not found" end
    
    local playerRole = StockMarket.Groups:GetPlayerRole(groupId, ply)
    if (playerRole or 0) < (StockMarket.Enums.GroupRole.TRADER or 1) then
        return false, "Insufficient permissions to sell"
    end
    
    local rl = StockMarket.GroupTrading.RateLimiter
    local key = ply:SteamID64() .. "_" .. groupId
    if rl[key] and (CurTime() - rl[key]) < 0.5 then
        return false, "Order rate limited"
    end
    rl[key] = CurTime()
    
    local position = group.positions and group.positions[ticker]
    if not position or position.shares < shares then
        return false, "Insufficient shares in group"
    end
    
    local fee = (StockMarket.Fees and StockMarket.Fees.Calculate(
        ticker, shares, price, StockMarket.Enums.OrderSide.SELL
    )) or 0
    
    local netProceeds = (shares * price) - fee
    if netProceeds <= 0 then
        return false, "Sale proceeds invalid"
    end
    
    -- Update database
    sql.Query(string.format([[
        UPDATE stockmarket_group_positions
        SET shares = shares - %d
        WHERE group_id = %d AND ticker = %s
    ]], shares, groupId, sql.SQLStr(ticker)))
    
    sql.Query(string.format([[
        UPDATE stockmarket_group_funds
        SET cash = cash + %f
        WHERE group_id = %d
    ]], netProceeds, groupId))
    
    -- Log transaction
    if StockMarket.Transactions then
        StockMarket.Transactions:Log(ply:SteamID64(), ticker, StockMarket.Enums.TransactionType.SELL, shares, price, fee)
    end
    
    -- Add cash
    StockMarket.Groups:AddCash(groupId, netProceeds)
    
    -- IMPORTANT: Invalidate cache so next GetGroup fetches fresh data
    if StockMarket.Groups.Cache then
        StockMarket.Groups.Cache[groupId] = nil
    end
    
    -- Broadcast to group members (optional)
    net.Start("StockMarket_GroupUpdate")
    net.WriteUInt(groupId, 16)
    net.WriteString(ticker)
    net.WriteInt(shares, 32)
    net.WriteFloat(price)
    net.Broadcast()
    
    return true, string.format("Sold %d shares at %.2f", shares, price)
end

net.Receive("StockMarket_GroupTrade", function(len, ply)
    local groupId = net.ReadInt(32)
    local ticker = net.ReadString()
    local orderType = net.ReadInt(16)
    local side = net.ReadInt(16)
    local shares = net.ReadInt(32)
    local limitPrice = net.ReadFloat()

    local ok, msg = StockMarket.GroupTrading:PlaceOrder(ply, groupId, ticker, orderType, side, shares, limitPrice)

    net.Start("StockMarket_GroupUpdate")
    net.WriteString(ok and "trade_success" or "trade_error")
    net.WriteString(msg or (ok and "OK" or "Error"))
    net.Send(ply)
end)
