-- ========================================
-- Admin Runtime Mutations (DB-backed)
-- ========================================

if not SERVER then return end

StockMarket.AdminRuntime = StockMarket.AdminRuntime or {}

-- Utility: persist config changes in SQLite tables to survive restarts
-- Tables:
--   stockmarket_cfg_sectors (key TEXT PRIMARY KEY, json TEXT)
--   stockmarket_cfg_tickers (sector TEXT, prefix TEXT, json TEXT, PRIMARY KEY (sector, prefix))
--   stockmarket_cfg_events  (prefix TEXT, handle TEXT, json TEXT, PRIMARY KEY (prefix, handle))

-- Serialize helpers
local function toJSON(tbl) return util.TableToJSON(tbl or {}, false) end
local function fromJSON(str) return util.JSONToTable(str or "") or {} end

local function EnsureTables()
    sql.Query([[
        CREATE TABLE IF NOT EXISTS stockmarket_cfg_sectors(
            sector TEXT PRIMARY KEY,
            volatility REAL,
            sectorVolatility REAL,
            minPrice REAL,
            maxPrice REAL
        )
    ]])
    
    sql.Query([[
        CREATE TABLE IF NOT EXISTS stockmarket_cfg_tickers(
            sector TEXT,
            prefix TEXT,
            displayName TEXT,
            tradeFees REAL,
            volatility REAL,
            PRIMARY KEY (sector, prefix)
        )
    ]])
    
    sql.Query([[
        CREATE TABLE IF NOT EXISTS stockmarket_cfg_events(
            event_id INTEGER PRIMARY KEY AUTOINCREMENT,
            ticker TEXT,
            event_type TEXT,
            trigger_type TEXT,
            trigger_value REAL,
            effect REAL,
            duration INTEGER,
            payload TEXT,
            enabled INTEGER,
            created_at INTEGER
        )
    ]])
end

local function toJSON(tbl)
    return util.TableToJSON(tbl)
end

local function fromJSON(str)
    return util.JSONToTable(str) or {}
end

hook.Add("Initialize", "SM_AdminRuntime_EnsureTables", EnsureTables)

function StockMarket.AdminRuntime:GetValidTickerSet()
    local set = {}
    for sectorKey, sector in pairs(StockMarket.Config.Markets or {}) do
        if sector.enabled ~= false then
            for _, t in ipairs(sector.tickers or {}) do
                if t and t.enabled ~= false and t.stockPrefix and t.stockPrefix ~= "" then
                    set[t.stockPrefix] = true
                end
            end
        end
    end
    return set
end

-- Remove positions for tickers that no longer exist in config
-- If steamid provided, prunes only that player's positions; otherwise prunes all players.
function StockMarket.AdminRuntime:PruneOrphanPositions(steamid)
    local valid = self:GetValidTickerSet()
    local where = ""
    if steamid and steamid ~= "" then
        where = string.format("WHERE steam_id = %s", sql.SQLStr(steamid))
    end

    -- Select distinct tickers in scope
    local rows = sql.Query(string.format("SELECT DISTINCT ticker FROM stockmarket_positions %s", where)) or {}

    local toRemove = {}
    for _, r in ipairs(rows) do
        local tk = tostring(r.ticker or "")
        if tk == "" or not valid[tk] then
            table.insert(toRemove, tk)
        end
    end

    if #toRemove == 0 then return 0 end

    for _, tk in ipairs(toRemove) do
        if steamid and steamid ~= "" then
            sql.Query(string.format("DELETE FROM stockmarket_positions WHERE steam_id = %s AND ticker = %s",
                sql.SQLStr(steamid), sql.SQLStr(tk)))
        else
            sql.Query(string.format("DELETE FROM stockmarket_positions WHERE ticker = %s", sql.SQLStr(tk)))
        end
    end

    return #toRemove
end

-- Merge a ticker row into runtime StockMarket.Config.Markets
local function MergeTickerIntoConfig(sectorKey, t)
    if not sectorKey or sectorKey == "" then return end
    if not t or not t.stockPrefix or t.stockPrefix == "" then return end

    -- Ensure sector table exists
    if not StockMarket.Config.Markets[sectorKey] then
        StockMarket.Config.Markets[sectorKey] = {
            sectorName = sectorKey,
            sectorVolatility = 1.0,
            enabled = true,
            tickers = {}
        }
    end
    local sector = StockMarket.Config.Markets[sectorKey]
    sector.tickers = sector.tickers or {}

    -- Replace or insert by stockPrefix
    local replaced = false
    for i = 1, #sector.tickers do
        if sector.tickers[i] and sector.tickers[i].stockPrefix == t.stockPrefix then
            sector.tickers[i] = t
            replaced = true
            break
        end
    end
    if not replaced then
        table.insert(sector.tickers, t)
    end
end

local function LoadPersistedConfig()
    -- load sectors
    local srows = sql.Query("SELECT key, json FROM stockmarket_cfg_sectors") or {}
    for _, r in ipairs(srows) do
        local key = r.key
        local s = fromJSON(r.json)
        if key and key ~= "" then
            if not StockMarket.Config.Markets[key] then
                StockMarket.Config.Markets[key] = { tickers = {} }
            end
            local ref = StockMarket.Config.Markets[key]
            ref.sectorName = s.sectorName or key
            ref.sectorVolatility = tonumber(s.sectorVolatility) or 1.0
            ref.enabled = (s.enabled ~= false)
            ref.tickers = ref.tickers or {}
        end
    end

    -- load tickers
    local trows = sql.Query("SELECT sector, prefix, json FROM stockmarket_cfg_tickers") or {}
    for _, r in ipairs(trows) do
        local sectorKey = r.sector
        local t = fromJSON(r.json)
        if sectorKey and t and t.stockPrefix and t.stockPrefix ~= "" then
            MergeTickerIntoConfig(sectorKey, t)
        end
    end

    -- Optionally seed engine if available
    if StockMarket and StockMarket.StockEngine and StockMarket.StockEngine.EnsureSeeded then
        for sectorKey, sector in pairs(StockMarket.Config.Markets or {}) do
            for _, tk in ipairs(sector.tickers or {}) do
                if tk.enabled ~= false then
                    StockMarket.StockEngine:EnsureSeeded(tk.stockPrefix, tonumber(tk.newStockValue) or 1)
                end
            end
        end
    end

    print("[StockMarket] Persisted config loaded. Sectors:", table.Count(StockMarket.Config.Markets))
end

-- Load after tables exist; ensure it runs before engine Start
hook.Add("Initialize", "SM_AdminRuntime_LoadPersistedConfig", function()
    -- slight delay to guarantee EnsureTables is complete
    timer.Simple(0, LoadPersistedConfig)
end)

local function EnsureTables()
    sql.Query([[
        CREATE TABLE IF NOT EXISTS stockmarket_cfg_sectors (
            key TEXT PRIMARY KEY,
            json TEXT
        )
    ]])
    sql.Query([[
        CREATE TABLE IF NOT EXISTS stockmarket_cfg_tickers (
            sector TEXT,
            prefix TEXT,
            json TEXT,
            PRIMARY KEY (sector, prefix)
        )
    ]])
    sql.Query([[
        CREATE TABLE IF NOT EXISTS stockmarket_cfg_events (
            prefix TEXT,
            handle TEXT,
            json TEXT,
            PRIMARY KEY (prefix, handle)
        )
    ]])
end

hook.Add("Initialize", "SM_AdminRuntime_EnsureTables", EnsureTables)

-- Serialize helpers
local function toJSON(tbl) return util.TableToJSON(tbl or {}, false) end
local function fromJSON(str) return util.JSONToTable(str or "") or {} end

-- Sector persistence
function StockMarket.AdminRuntime.SaveCategory(payload)
    local key = payload.sectorKey
    local sectorName = payload.sectorName or key or "New Sector"
    local vol = tonumber(payload.sectorVolatility) or 1.0
    local enabled = payload.enabled ~= false

    if (not key) or key == "" then
        -- create a new unique key
        key = string.gsub(string.lower(sectorName), "[^%w_]", "_")
        if StockMarket.Config.Markets[key] then
            key = key .. "_" .. math.random(100,999)
        end
    end

    StockMarket.Config.Markets[key] = StockMarket.Config.Markets[key] or {tickers = {}}
    local ref = StockMarket.Config.Markets[key]
    ref.sectorName = sectorName
    ref.sectorVolatility = vol
    ref.enabled = enabled
    ref.tickers = ref.tickers or {}

    -- DB persist
    sql.Query(string.format([[
        REPLACE INTO stockmarket_cfg_sectors (key, json)
        VALUES (%s, %s)
    ]], sql.SQLStr(key), sql.SQLStr(toJSON({
        sectorName = sectorName,
        sectorVolatility = vol,
        enabled = enabled
    })) ))

    net.Start("StockMarket_ConfigChanged")
    net.Broadcast()

    hook.Run("StockMarket_ConfigChanged")

    print("[StockMarket] Sector saved: " .. key)
end

function StockMarket.AdminRuntime.DeleteCategory(sectorKey)
    local sector = StockMarket.Config.Markets[sectorKey]
    if not sector then return end

    -- Remove from runtime
    StockMarket.Config.Markets[sectorKey] = nil

    -- Remove tickers belonging to this sector from DB
    sql.Query(string.format([[
        DELETE FROM stockmarket_cfg_tickers WHERE sector = %s
    ]], sql.SQLStr(sectorKey)))

    -- Prune positions referencing these tickers
    for _, t in ipairs(sector.tickers or {}) do
        local prefix = t and t.stockPrefix
        if prefix and prefix ~= "" then
            sql.Query(string.format(
                "DELETE FROM stockmarket_positions WHERE ticker = %s",
                sql.SQLStr(prefix)
            ))
        end
    end

    -- Broadcast change
    net.Start("StockMarket_ConfigChanged")
    net.Broadcast()
    hook.Run("StockMarket_ConfigChanged")

    print("[StockMarket] Sector deleted: " .. sectorKey)
end

-- Ticker persistence
function StockMarket.AdminRuntime.SaveTicker(p)
    local sectorKey = p.sectorKey
    if not StockMarket.Config.Markets[sectorKey] then return end

    local t = {
        stockName = p.stockName or "New Stock",
        stockPrefix = p.stockPrefix or "",
        marketStocks = tonumber(p.marketStocks) or 0,
        newStockValue = tonumber(p.newStockValue) or 1,
        minTick = tonumber(p.minTick) or -1,
        maxTick = tonumber(p.maxTick) or 1,
        drift = tonumber(p.drift) or 0,
        volatility = tonumber(p.volatility) or 1,
        stockDifficulty = tonumber(p.stockDifficulty) or 2000,
        circuitBreaker = { dropPercent = 15, haltSeconds = 60 },
        dividend = { enabled = false, yieldPercent = 0.0, periodSeconds = 0 },
        tradeFees = nil,
        stockEvents = {},
        persistence = { key = p.stockPrefix or "", historyRetentionPoints = 2880 },
        enabled = p.enabled ~= false
    }

    -- Handle rename (oldPrefix) or create
    local sector = StockMarket.Config.Markets[sectorKey]
    local existed = false
    if p.oldPrefix and p.oldPrefix ~= t.stockPrefix then
        -- rename: delete old, insert new
        for i = #sector.tickers, 1, -1 do
            if sector.tickers[i].stockPrefix == p.oldPrefix then
                table.remove(sector.tickers, i)
                break
            end
        end
    else
        -- update in place if exists
        for i, ex in ipairs(sector.tickers) do
            if ex.stockPrefix == t.stockPrefix then
                sector.tickers[i] = t
                existed = true
                break
            end
        end
    end
    if not existed then
        table.insert(sector.tickers, t)
    end

    -- DB: upsert ticker row
    sql.Query(string.format([[
        REPLACE INTO stockmarket_cfg_tickers (sector, prefix, json)
        VALUES (%s, %s, %s)
    ]], sql.SQLStr(sectorKey), sql.SQLStr(t.stockPrefix), sql.SQLStr(util.TableToJSON(t or {}, false)) ))

    -- Seed the engine immediately so runtime-added tickers are live
    if StockMarket and StockMarket.StockEngine and StockMarket.StockEngine.EnsureSeeded then
        StockMarket.StockEngine:EnsureSeeded(t.stockPrefix, t.newStockValue)
    end

    net.Start("StockMarket_ConfigChanged")
    net.Broadcast()
    hook.Run("StockMarket_ConfigChanged")

    print(string.format("[StockMarket] Ticker saved: %s/%s", sectorKey, t.stockPrefix))
end

function StockMarket.AdminRuntime.DeleteTicker(sectorKey, prefix)
    local sector = StockMarket.Config.Markets[sectorKey]
    if not sector then return end

    -- Remove from runtime
    for i = #sector.tickers, 1, -1 do
        if sector.tickers[i].stockPrefix == prefix then
            table.remove(sector.tickers, i)
            break
        end
    end

    -- Remove from DB
    sql.Query(string.format([[
        DELETE FROM stockmarket_cfg_tickers WHERE sector = %s AND prefix = %s
    ]], sql.SQLStr(sectorKey), sql.SQLStr(prefix)))

    -- ADD THESE TWO LINES HERE:
    net.Start("StockMarket_ConfigChanged")
    net.Broadcast()

    hook.Run("StockMarket_ConfigChanged")

    print(string.format("[StockMarket] Ticker deleted: %s/%s", sectorKey, prefix))
end

-- Move ticker between sectors
function StockMarket.AdminRuntime.MoveTicker(fromSector, toSector, prefix)
    if not fromSector or not toSector or not prefix then return false, "Invalid parameters" end
    
    local config = StockMarket.Config
    if not config or not config.Markets then return false, "Config not loaded" end
    
    local fromSectorData = config.Markets[fromSector]
    local toSectorData = config.Markets[toSector]
    
    if not fromSectorData or not toSectorData then
        return false, "Source or destination sector not found"
    end
    
    -- Find ticker in source sector
    local tickerIndex = nil
    local ticker = nil
    for i, t in ipairs(fromSectorData.tickers or {}) do
        if t.stockPrefix == prefix then
            tickerIndex = i
            ticker = t
            break
        end
    end
    
    if not ticker or not tickerIndex then
        return false, string.format("Ticker %s not found in sector %s", prefix, fromSector)
    end
    
    -- Remove from source
    table.remove(fromSectorData.tickers, tickerIndex)
    
    -- Add to destination
    table.insert(toSectorData.tickers, ticker)
    
    -- Update database
    sql.Query(string.format([[
        UPDATE stockmarket_cfg_tickers
        SET sector = %s
        WHERE sector = %s AND prefix = %s
    ]], sql.SQLStr(toSector), sql.SQLStr(fromSector), sql.SQLStr(prefix)))
    
    -- Broadcast config change to all clients
    net.Start("StockMarket_ConfigChanged")
    net.Broadcast()
    hook.Run("StockMarket_ConfigChanged")
    
    print(string.format("[StockMarket] Moved ticker %s from %s to %s", prefix, fromSector, toSector))
    
    return true, string.format("Moved %s to %s", prefix, toSector)
end

-- Events CRUD
function StockMarket.AdminRuntime:GetTickerEvents(prefix)
    local rows = sql.Query(string.format([[
        SELECT json FROM stockmarket_cfg_events WHERE prefix = %s
    ]], sql.SQLStr(prefix))) or {}

    local out = {}
    for _, r in ipairs(rows) do
        local e = fromJSON(r.json)
        table.insert(out, e)
    end

    -- Also merge with config base (stockEvents) if not in DB
    local t, sData = StockMarket.Config:GetTickerByPrefix(prefix)
    if t then
        local exists = {}
        for _, e in ipairs(out) do exists[e.handle] = true end
        for _, e in ipairs(t.stockEvents or {}) do
            if not exists[e.handle] then
                table.insert(out, {
                    handle = e.handle, type = e.impact and e.impact.type or "DRIFT",
                    weight = e.weight or 1.0,
                    magnitude = (e.impact and e.impact.magnitude) or 0,
                    duration = (e.impact and e.impact.duration) or 60,
                    preAlertSeconds = e.preAlertSeconds or 0,
                    message = e.message or ""
                })
            end
        end
    end

    return out
end

function StockMarket.AdminRuntime:SaveEvent(e)
    if not e or not e.ticker or not e.handle then return end
    local row = {
        prefix = e.ticker,
        handle = e.handle,
        type = e.type,
        weight = tonumber(e.weight) or 1.0,
        magnitude = tonumber(e.magnitude) or 0,
        duration = tonumber(e.duration) or 60,
        preAlertSeconds = tonumber(e.preAlertSeconds) or 0,
        message = e.message or ""
    }
    sql.Query(string.format([[
        REPLACE INTO stockmarket_cfg_events (prefix, handle, json)
        VALUES (%s, %s, %s)
    ]], sql.SQLStr(row.prefix), sql.SQLStr(row.handle), sql.SQLStr(toJSON(row)) ))
    print("[StockMarket] Event saved: " .. row.prefix .. "/" .. row.handle)
end

function StockMarket.AdminRuntime:DeleteEvent(prefix, handle)
    sql.Query(string.format([[
        DELETE FROM stockmarket_cfg_events WHERE prefix = %s AND handle = %s
    ]], sql.SQLStr(prefix), sql.SQLStr(handle)))
    print("[StockMarket] Event deleted: " .. prefix .. "/" .. handle)
end

function StockMarket.AdminRuntime:TriggerEvent(prefix, handle)
    local t = StockMarket.Config:GetTickerByPrefix(prefix)
    if not t then return end
    -- Find event definition (DB > config)
    local eRow = sql.QueryRow(string.format([[
        SELECT json FROM stockmarket_cfg_events WHERE prefix = %s AND handle = %s
    ]], sql.SQLStr(prefix), sql.SQLStr(handle)))
    local ev
    if eRow and eRow.json then
        ev = fromJSON(eRow.json)
    else
        for _, e in ipairs(t.stockEvents or {}) do
            if e.handle == handle then
                ev = {
                    handle = e.handle, type = e.impact.type, weight = e.weight or 1.0,
                    magnitude = e.impact.magnitude, duration = e.impact.duration,
                    preAlertSeconds = e.preAlertSeconds or 0, message = e.message or ""
                }
                break
            end
        end
    end
    if not ev then return end

    -- Build config-like event to reuse existing TriggerEvent code
    local cfgEvent = {
        handle = ev.handle,
        weight = ev.weight,
        impact = { type = ev.type, magnitude = ev.magnitude, duration = ev.duration },
        message = ev.message,
        preAlertSeconds = ev.preAlertSeconds
    }
    -- Use existing dispatcher:
    timer.Simple(0, function()
        -- Pre-alert
        StockMarket.Events:SendPreAlert(prefix, cfgEvent)
        timer.Simple(cfgEvent.preAlertSeconds or 0, function()
            StockMarket.Events:TriggerEvent(prefix, cfgEvent)
        end)
    end)

    print("[StockMarket] Event triggered via admin: " .. prefix .. "/" .. handle)
end

hook.Add("StockMarket_ConfigChanged", "SM_PruneOrphanPositions_Global", function()
    if StockMarket.AdminRuntime and StockMarket.AdminRuntime.PruneOrphanPositions then
        local removed = StockMarket.AdminRuntime:PruneOrphanPositions(nil)
        if removed > 0 then
            print(string.format("[StockMarket] Pruned %d orphan positions after config change.", removed))
        end
    end
end)

hook.Add("Initialize", "SM_PruneOrphanPositions_OnInit", function()
    timer.Simple(2, function()
        if StockMarket.AdminRuntime and StockMarket.AdminRuntime.PruneOrphanPositions then
            local removed = StockMarket.AdminRuntime:PruneOrphanPositions(nil)
            if removed > 0 then
                print(string.format("[StockMarket] Pruned %d orphan positions at startup.", removed))
            end
        end
    end)
end)