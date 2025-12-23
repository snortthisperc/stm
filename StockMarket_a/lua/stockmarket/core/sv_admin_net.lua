-- ========================================
-- Admin Net Messages & Dispatch
-- ========================================

if not SERVER then return end

util.AddNetworkString("StockMarket_Admin_GetState")
util.AddNetworkString("StockMarket_Admin_State")

util.AddNetworkString("StockMarket_Admin_SaveCategory")
util.AddNetworkString("StockMarket_Admin_DeleteCategory")
util.AddNetworkString("StockMarket_Admin_SaveTicker")
util.AddNetworkString("StockMarket_Admin_DeleteTicker")
util.AddNetworkString("StockMarket_Admin_Reorder")

util.AddNetworkString("StockMarket_Admin_GetServerStats")
util.AddNetworkString("StockMarket_Admin_PlayerList")
util.AddNetworkString("StockMarket_Admin_GetPortfolio")
util.AddNetworkString("StockMarket_Admin_RollbackPlayer")

util.AddNetworkString("StockMarket_Markets_GetState")
util.AddNetworkString("StockMarket_Markets_State")

util.AddNetworkString("StockMarket_Admin_GetEvents")
util.AddNetworkString("StockMarket_Admin_SaveEvent")
util.AddNetworkString("StockMarket_Admin_DeleteEvent")
util.AddNetworkString("StockMarket_Admin_TriggerEvent")

util.AddNetworkString("StockMarket_Admin_AdjustPosition")
util.AddNetworkString("StockMarket_Admin_Action")
util.AddNetworkString("StockMarket_AdminNotify")


local _adminRL = {}
local function AdminLimited(ply, key, burst, refill)
    if not IsValid(ply) then return true end
    local sid = ply:SteamID64()
    key = (key or "gen") .. ":" .. sid
    local now = CurTime()
    local st = _adminRL[key] or { last = now, tokens = burst or 10 }
    local dt = now - st.last
    if dt > 0 then
        st.tokens = math.min(burst or 10, st.tokens + dt * (refill or 2))
        st.last = now
    end
    if st.tokens < 1 then
        _adminRL[key] = st
        return true
    end
    st.tokens = st.tokens - 1
    _adminRL[key] = st
    return false
end

local function NetWriteSectorSnapshot(sectorKey, sector)
    net.WriteString(sectorKey or "")
    net.WriteString(sector.sectorName or sectorKey or "")
    net.WriteFloat(tonumber(sector.sectorVolatility or 1) or 1)
    net.WriteBool(sector.enabled ~= false)

    local tickers = sector.tickers or {}
    net.WriteUInt(#tickers, 16)
    for i = 1, #tickers do
        local t = tickers[i]
        net.WriteString(t.stockName or "")
        net.WriteString(t.stockPrefix or "")
        net.WriteUInt(tonumber(t.marketStocks or 0) or 0, 32)
        net.WriteFloat(tonumber(t.newStockValue or 0) or 0)
        net.WriteFloat(tonumber(t.minTick or 0) or 0)
        net.WriteFloat(tonumber(t.maxTick or 0) or 0)
        net.WriteFloat(tonumber(t.drift or 0) or 0)
        net.WriteFloat(tonumber(t.volatility or 1) or 1)
        net.WriteUInt(tonumber(t.stockDifficulty or 0) or 0, 32)
        net.WriteBool(t.enabled ~= false)
    end
end

-- SaveCategory payload
local function NetReadSaveCategory()
    return {
        sectorKey = net.ReadString(),
        sectorName = net.ReadString(),
        sectorVolatility = net.ReadFloat(),
        enabled = net.ReadBool()
    }
end

-- SaveTicker payload
local function NetReadSaveTicker()
    return {
        sectorKey = net.ReadString(),
        stockName = net.ReadString(),
        stockPrefix = net.ReadString(),
        marketStocks = net.ReadUInt(32),
        newStockValue = net.ReadFloat(),
        minTick = net.ReadFloat(),
        maxTick = net.ReadFloat(),
        drift = net.ReadFloat(),
        volatility = net.ReadFloat(),
        stockDifficulty = net.ReadUInt(32),
        enabled = net.ReadBool(),
        oldPrefix = net.ReadString() -- may be empty string if not a rename
    }
end

-- Server stats (values sent as strings and floats)
local function NetWriteServerStats(stats)
    stats = stats or {}
    net.WriteString(stats.totalValueText or "")
    net.WriteString(stats.onlineDarkRPText or "")
    net.WriteString(stats.avgRealizedText or "")
    net.WriteString(stats.avgUnrealizedText or "")
    net.WriteFloat(tonumber(stats.avgRealizedRaw or 0) or 0)
    net.WriteFloat(tonumber(stats.avgUnrealizedRaw or 0) or 0)
end

-- Player list snapshot
local function NetWritePlayerList(list)
    list = list or {}
    net.WriteUInt(#list, 16)
    for i = 1, #list do
        local p = list[i]
        net.WriteString(p.name or "")
        net.WriteString(p.steamid or "")
        net.WriteString(p.net or "")
    end
end

-- Portfolio snapshot (admin)
local function NetWriteAdminPortfolio(data)
    data = data or {}
    net.WriteString(data.net or "")
    net.WriteFloat(tonumber(data.realized or 0) or 0)
    net.WriteFloat(tonumber(data.unrealized or 0) or 0)
    net.WriteString(data.steamid or "")

    local positions = data.positions or {}
    net.WriteUInt(#positions, 16)
    for i = 1, #positions do
        local pos = positions[i]
        net.WriteString(pos.ticker or "")
        net.WriteInt(tonumber(pos.shares or 0) or 0, 32)
        net.WriteFloat(tonumber(pos.avgCost or 0) or 0)
        net.WriteString(pos.price or "")
        net.WriteFloat(tonumber(pos.marketValue or 0) or 0)
        net.WriteFloat(tonumber(pos.unrealized or 0) or 0)
    end
end

-- Events list used by admin (consistent with cl_admin_events.lua NetReadEvent)
local function NetWriteEventRow(ev)
    net.WriteString(ev.ticker or ev.prefix or "")
    net.WriteString(ev.handle or "")
    net.WriteString(tostring(ev.type or ""))     -- keep as string; client uppercases
    net.WriteString(ev.message or "")
    net.WriteFloat(tonumber(ev.weight or 0) or 0)
    net.WriteFloat(tonumber(ev.magnitude or 0) or 0)
    net.WriteUInt(tonumber(ev.duration or 0) or 0, 32)
    net.WriteUInt(tonumber(ev.preAlertSeconds or 0) or 0, 32)
end

-- Read admin SaveEvent payload (matches client NetWriteEventPayload)
local function NetReadEventPayload()
    return {
        ticker = net.ReadString(),
        handle = net.ReadString(),
        type = net.ReadString(),
        message = net.ReadString(),
        weight = net.ReadFloat(),
        magnitude = net.ReadFloat(),
        duration = net.ReadUInt(32),
        preAlertSeconds = net.ReadUInt(32),
    }
end

local function IsSuper(ply)
    return IsValid(ply) and ply:IsSuperAdmin()
end

net.Receive("StockMarket_Markets_GetState", function(_, ply)
    if AdminLimited(ply, "state", 10, 2) then return end
    local markets = StockMarket.Config.Markets or {}
    local sectorKeys = {}
    for k in pairs(markets) do sectorKeys[#sectorKeys + 1] = k end
    table.sort(sectorKeys, function(a, b) return tostring(a) < tostring(b) end)

    net.Start("StockMarket_Markets_State")
    net.WriteUInt(#sectorKeys, 16)
    for i = 1, #sectorKeys do
        local key = sectorKeys[i]
        NetWriteSectorSnapshot(key, markets[key] or {})
    end
    net.Send(ply)
end)

net.Receive("StockMarket_Admin_GetState", function(_, ply)
    if not IsSuper(ply) then return end
    if AdminLimited(ply, "state", 10, 2) then return end
    
    local markets = StockMarket.Config.Markets or {}
    local sectorKeys = {}
    for k in pairs(markets) do sectorKeys[#sectorKeys + 1] = k end
    table.sort(sectorKeys, function(a, b) return tostring(a) < tostring(b) end)

    net.Start("StockMarket_Admin_State")
    net.WriteUInt(#sectorKeys, 16)
    for i = 1, #sectorKeys do
        local key = sectorKeys[i]
        NetWriteSectorSnapshot(key, markets[key] or {})
    end
    net.Send(ply)
    
    --print("[SM Server] → Admin_State sent; sectors:", #sectorKeys, "to", IsValid(ply) and ply:Nick() or "??")
end)

-- Save/Add/Edit Category
net.Receive("StockMarket_Admin_SaveCategory", function(_, ply)
    if not IsSuper(ply) then return end
    if AdminLimited(ply, "savecat", 6, 1) then return end
    local tbl = NetReadSaveCategory()
    StockMarket.AdminRuntime.SaveCategory(tbl)
end)

net.Receive("StockMarket_Admin_DeleteCategory", function(_, ply)
    if not IsSuper(ply) then return end
    if AdminLimited(ply, "delcat", 6, 1) then return end
    local sectorKey = net.ReadString()
    StockMarket.AdminRuntime.DeleteCategory(sectorKey)
end)

-- Save/Edit Ticker
net.Receive("StockMarket_Admin_SaveTicker", function(_, ply)
    if not IsSuper(ply) then return end
    if AdminLimited(ply, "savetick", 8, 1.5) then return end
    local tbl = NetReadSaveTicker()
    StockMarket.AdminRuntime.SaveTicker(tbl)
end)

net.Receive("StockMarket_Admin_DeleteTicker", function(_, ply)
    if not IsSuper(ply) then return end
    if AdminLimited(ply, "deltick", 8, 1.5) then return end
    local sectorKey = net.ReadString()
    local prefix = net.ReadString()
    StockMarket.AdminRuntime.DeleteTicker(sectorKey, prefix)
end)


-- Reorder / move ticker between sectors
net.Receive("StockMarket_Admin_Reorder", function(_, ply)
    if not IsSuper(ply) then return end
    if AdminLimited(ply, "reorder", 6, 1) then return end
    local fromSector = net.ReadString()
    local toSector   = net.ReadString()
    local prefix     = net.ReadString()
    StockMarket.AdminRuntime.MoveTicker(fromSector, toSector, prefix)
end)

-- Server stats
net.Receive("StockMarket_Admin_GetServerStats", function(_, ply)
    if not IsSuper(ply) then return end
    if AdminLimited(ply, "stats", 6, 1) then return end
    local stats = StockMarket.Persistence:GetServerStats()
    net.Start("StockMarket_Admin_GetServerStats")
    NetWriteServerStats(stats)
    net.Send(ply)
end)

-- Player listing
net.Receive("StockMarket_Admin_PlayerList", function(_, ply)
    if not IsSuper(ply) then return end
    if AdminLimited(ply, "plist", 6, 1) then return end
    local list = StockMarket.Persistence:GetOnlinePlayersSnapshot()
    net.Start("StockMarket_Admin_PlayerList")
    NetWritePlayerList(list)
    net.Send(ply)
end)

-- Portfolio view
net.Receive("StockMarket_Admin_GetPortfolio", function(_, ply)
    if not IsSuper(ply) then return end
    if AdminLimited(ply, "port", 6, 1) then return end
    local sid = net.ReadString() or ""
    if StockMarket.AdminRuntime and StockMarket.AdminRuntime.PruneOrphanPositions then
        StockMarket.AdminRuntime:PruneOrphanPositions(sid)
    end
    local data = StockMarket.Persistence:GetPlayerPortfolioSnapshot(sid)
    net.Start("StockMarket_Admin_GetPortfolio")
    NetWriteAdminPortfolio(data)
    net.Send(ply)
end)

-- Rollback player to last restart snapshot
net.Receive("StockMarket_Admin_RollbackPlayer", function(_, ply)
    if not IsSuper(ply) then return end
    if AdminLimited(ply, "rollback", 3, 0.5) then return end
    local sid = net.ReadString()
    StockMarket.AdminSnapshots:RollbackPlayerToRestart(sid)
end)


-- Events
net.Receive("StockMarket_Admin_GetEvents", function(_, ply)
    if not IsSuper(ply) then return end
    if AdminLimited(ply, "events_get", 10, 2) then return end
    local prefix = net.ReadString()
    local events = StockMarket.AdminRuntime:GetTickerEvents(prefix)
    net.Start("StockMarket_Admin_GetEvents")
    net.WriteUInt(#events, 16)
    for i = 1, #events do
        local ev = events[i]
        NetWriteEventRow(ev)
    end
    net.Send(ply)
end)

net.Receive("StockMarket_Admin_SaveEvent", function(_, ply)
    if not IsSuper(ply) then return end
    if AdminLimited(ply, "events_save", 8, 1.5) then return end
    local e = NetReadEventPayload()
    StockMarket.AdminRuntime:SaveEvent(e)
end)

net.Receive("StockMarket_Admin_DeleteEvent", function(_, ply)
    if not IsSuper(ply) then return end
    if AdminLimited(ply, "events_del", 8, 1.5) then return end
    local prefix = net.ReadString()
    local handle = net.ReadString()
    StockMarket.AdminRuntime:DeleteEvent(prefix, handle)
end)

net.Receive("StockMarket_Admin_TriggerEvent", function(_, ply)
    if not IsSuper(ply) then return end
    if AdminLimited(ply, "events_trigger", 5, 1) then return end
    local prefix = net.ReadString()
    local handle = net.ReadString()
    StockMarket.AdminRuntime:TriggerEvent(prefix, handle)
end)
