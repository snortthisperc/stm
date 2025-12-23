-- ========================================
-- Admin Tools
-- ========================================

StockMarket.Admin = StockMarket.Admin or {}

util.AddNetworkString("StockMarket_Admin_AdjustPosition")

function StockMarket.Admin:IsAdmin(ply)
    if not IsValid(ply) then return false end
    for _, group in ipairs(StockMarket.Config.AdminGroups) do
        if ply:IsUserGroup(group) then return true end
    end
    return false
end

function StockMarket.Admin:TriggerEvent(ticker, eventHandle)
    local tickerConfig = StockMarket.Config:GetTickerByPrefix(ticker)
    if not tickerConfig then return false end
    
    for _, event in ipairs(tickerConfig.stockEvents) do
        if event.handle == eventHandle then
            StockMarket.Events:TriggerEvent(ticker, event)
            return true
        end
    end
    return false
end

function StockMarket.Admin:SetPrice(ticker, price)
    StockMarket.StockEngine:SetPrice(ticker, price)
    return true
end

function StockMarket.Admin:HaltTrading(ticker, duration)
    StockMarket.CircuitBreaker:HaltTrading(ticker, duration)
    return true
end

net.Receive("StockMarket_Admin_AdjustPosition", function(len, ply)
    if not ply:IsSuperAdmin() then return end
    
    local steamid = net.ReadString()
    local ticker = net.ReadString()
    local action = net.ReadString()  -- "set_shares", "set_avg", "sell_all", "remove"
    local value = net.ReadFloat()
    
    if not steamid or steamid == "" or not ticker or ticker == "" then return end

    local function CLAMP_SHARES(v)
        v = math.floor(tonumber(v) or 0)
        if v < 0 then v = 0 end
        if v > 10^9 then v = 10^9 end
        return v
    end
    local function CLAMP_MONEY(v)
        v = tonumber(v) or 0
        if v < 0 then v = 0 end
        if v > 10^12 then v = 10^12 end
        return v
    end
    
    if action == "set_shares" then
        value = math.max(0, math.floor(value))
        sql.Query(string.format([[
            UPDATE stockmarket_positions 
            SET shares = %d, last_updated = %d
            WHERE steam_id = %s AND ticker = %s
        ]], value, os.time(), sql.SQLStr(steamid), sql.SQLStr(ticker)))
        
        -- Remove position if shares are now 0
        if value == 0 then
            sql.Query(string.format([[
                DELETE FROM stockmarket_positions 
                WHERE steam_id = %s AND ticker = %s
            ]], sql.SQLStr(steamid), sql.SQLStr(ticker)))
        end
        
    elseif action == "set_avg" then
        value = math.max(0, tonumber(value) or 0)
        sql.Query(string.format([[
            UPDATE stockmarket_positions 
            SET avg_cost = %f, last_updated = %d
            WHERE steam_id = %s AND ticker = %s
        ]], value, os.time(), sql.SQLStr(steamid), sql.SQLStr(ticker)))
        
    elseif action == "sell_all" then
        -- Get current price and shares
        local pos = sql.QueryRow(string.format([[
            SELECT shares, avg_cost FROM stockmarket_positions 
            WHERE steam_id = %s AND ticker = %s
        ]], sql.SQLStr(steamid), sql.SQLStr(ticker)))
        
        if pos then
            local shares = tonumber(pos.shares) or 0
            local avgCost = tonumber(pos.avg_cost) or 0
            local currentPrice = StockMarket.StockEngine:GetPrice(ticker) or 0
            local proceeds = shares * currentPrice
            local profit = shares * (currentPrice - avgCost)
            
            -- Credit player's stockmarket cash
            sql.Query(string.format([[
                UPDATE stockmarket_players 
                SET cash = cash + %f, realized_profit = realized_profit + %f
                WHERE steam_id = %s
            ]], proceeds, profit, sql.SQLStr(steamid)))
            
            -- Remove position
            sql.Query(string.format([[
                DELETE FROM stockmarket_positions 
                WHERE steam_id = %s AND ticker = %s
            ]], sql.SQLStr(steamid), sql.SQLStr(ticker)))
        end
        
    elseif action == "remove" then
        sql.Query(string.format([[
            DELETE FROM stockmarket_positions 
            WHERE steam_id = %s AND ticker = %s
        ]], sql.SQLStr(steamid), sql.SQLStr(ticker)))
    end

    for _, targetPly in ipairs(player.GetAll()) do
        if targetPly:SteamID64() == steamid then
            -- Reload their data from database
            if StockMarket.Persistence then
                StockMarket.Persistence:LoadPlayer(targetPly)
            end
            
            -- Re-sync their portfolio to client
            if StockMarket.PlayerData then
                StockMarket.PlayerData:SyncPortfolio(targetPly)
            end
            
            -- Send confirmation
            net.Start("StockMarket_AdminNotify")
            net.WriteString(string.format("Synced %s's portfolio", targetPly:GetName()))
            net.Send(ply)
            
            break
        end
    end
end)

net.Receive("StockMarket_AdminAction", function(len, ply)
    if not StockMarket.Admin:IsAdmin(ply) then return end

    local action = net.ReadString()

    if action == "trigger_event" then
        local ticker = net.ReadString()
        local eventHandle = net.ReadString()
        StockMarket.Admin:TriggerEvent(ticker, eventHandle)

    elseif action == "set_price" then
        local ticker = net.ReadString()
        local price = net.ReadFloat()
        StockMarket.Admin:SetPrice(ticker, price)

    elseif action == "halt_trading" then
        local ticker = net.ReadString()
        local duration = net.ReadUInt(32)
        StockMarket.Admin:HaltTrading(ticker, duration)
    end
end)
