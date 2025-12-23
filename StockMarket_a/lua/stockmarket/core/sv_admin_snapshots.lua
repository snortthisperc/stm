-- ========================================
-- Admin: Restart Snapshots & Rollback
-- ========================================

if not SERVER then return end

StockMarket.AdminSnapshots = StockMarket.AdminSnapshots or {}

-- On server start, snapshot all player portfolios (DB → snapshot table)
local function EnsureSnapshotTables()
    sql.Query([[
        CREATE TABLE IF NOT EXISTS stockmarket_snapshot_players (
            steam_id TEXT PRIMARY KEY,
            cash REAL,
            total_invested REAL,
            realized_profit REAL
        )
    ]])
    sql.Query([[
        CREATE TABLE IF NOT EXISTS stockmarket_snapshot_positions (
            steam_id TEXT,
            ticker TEXT,
            shares INTEGER,
            avg_cost REAL,
            PRIMARY KEY (steam_id, ticker)
        )
    ]])
end
hook.Add("Initialize", "SM_AdminSnapshots_Ensure", EnsureSnapshotTables)

timer.Simple(3, function()
    -- Build fresh snapshot from current DB (players/positions)
    sql.Query("DELETE FROM stockmarket_snapshot_players")
    sql.Query("DELETE FROM stockmarket_snapshot_positions")

    local players = sql.Query("SELECT * FROM stockmarket_players") or {}
    for _, p in ipairs(players) do
        sql.Query(string.format([[
            REPLACE INTO stockmarket_snapshot_players (steam_id, cash, total_invested, realized_profit)
            VALUES (%s, %f, %f, %f)
        ]], sql.SQLStr(p.steam_id), tonumber(p.cash) or 0, tonumber(p.total_invested) or 0, tonumber(p.realized_profit) or 0))
    end

    local positions = sql.Query("SELECT * FROM stockmarket_positions") or {}
    for _, pos in ipairs(positions) do
        sql.Query(string.format([[
            REPLACE INTO stockmarket_snapshot_positions (steam_id, ticker, shares, avg_cost)
            VALUES (%s, %s, %d, %f)
        ]], sql.SQLStr(pos.steam_id), sql.SQLStr(pos.ticker), tonumber(pos.shares) or 0, tonumber(pos.avg_cost) or 0))
    end

    print("[StockMarket] Restart snapshot saved.")
end)

function StockMarket.AdminSnapshots:RollbackPlayerToRestart(steamid)
    if not steamid or steamid == "" then return end

    local snap = sql.QueryRow(string.format([[
        SELECT * FROM stockmarket_snapshot_players WHERE steam_id = %s
    ]], sql.SQLStr(steamid)))
    if not snap then return end

    -- Restore main player row
    sql.Query(string.format([[
        REPLACE INTO stockmarket_players (steam_id, cash, total_invested, realized_profit, last_updated)
        VALUES (%s, %f, %f, %f, %d)
    ]], sql.SQLStr(steamid), tonumber(snap.cash) or 0, tonumber(snap.total_invested) or 0, tonumber(snap.realized_profit) or 0, os.time()))

    -- Restore positions
    sql.Query(string.format("DELETE FROM stockmarket_positions WHERE steam_id = %s", sql.SQLStr(steamid)))
    local rows = sql.Query(string.format([[
        SELECT * FROM stockmarket_snapshot_positions WHERE steam_id = %s
    ]], sql.SQLStr(steamid))) or {}
    for _, r in ipairs(rows) do
        sql.Query(string.format([[
            REPLACE INTO stockmarket_positions (steam_id, ticker, shares, avg_cost, last_updated)
            VALUES (%s, %s, %d, %f, %d)
        ]], sql.SQLStr(steamid), sql.SQLStr(r.ticker), tonumber(r.shares) or 0, tonumber(r.avg_cost) or 0, os.time()))
    end

    -- If player online, refresh their cache/UI
    for _, ply in ipairs(player.GetAll()) do
        if ply:SteamID64() == steamid then
            local port = StockMarket.Persistence:LoadPlayer(ply) -- reload from DB
            StockMarket.PlayerData:SyncPortfolio(ply)
            break
        end
    end

    print("[StockMarket] Rolled back player to restart snapshot: " .. steamid)
end
