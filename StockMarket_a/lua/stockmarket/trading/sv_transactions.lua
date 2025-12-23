-- ========================================
-- Transaction Logger
-- ========================================

StockMarket.Transactions = StockMarket.Transactions or {}

function StockMarket.Transactions:Log(ply, ticker, transactionType, shares, price, fee, note)
    local sid = IsValid(ply) and ply:SteamID64() or "SYSTEM"
    
    sql.Query(string.format([[
        INSERT INTO stockmarket_transactions (steam_id, ticker, type, shares, price, fee, timestamp)
        VALUES (%s, %s, %d, %d, %f, %f, %d)
    ]], sql.SQLStr(sid), sql.SQLStr(ticker or ""), transactionType, shares, price, fee or 0, os.time()))
end

function StockMarket.Transactions:GetHistory(ply, limit)
    limit = limit or 50
    local sid = ply:SteamID64()
    
    local result = sql.Query(string.format([[
        SELECT * FROM stockmarket_transactions 
        WHERE steam_id = %s 
        ORDER BY timestamp DESC 
        LIMIT %d
    ]], sql.SQLStr(sid), limit))
    
    return result or {}
end
