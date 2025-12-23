-- ========================================
-- DarkRP Stock Market - Initialization (Aligned, Merged)
-- ========================================

if SERVER then AddCSLuaFile() end

StockMarket = StockMarket or {}
StockMarket.Version = "1.0.0"

local function Log(msg)
    MsgC(Color(100, 200, 255), "[StockMarket] ", Color(255, 255, 255), msg .. "\n")
end

print("[StockMarket] Loading Stock Market System v" .. StockMarket.Version)

-- Load order matters. Keep cl_chart.lua before cl_ticker_view.lua.
-- Admin files added at the end of client section.
local loadOrder = {
    -- Shared
    "stockmarket/core/sh_enums.lua",
    "stockmarket/core/sh_config.lua",
    "stockmarket/networking/sh_net.lua",
    "stockmarket/stocks/sh_stock_data.lua",

    -- Server core
    "stockmarket/core/sv_database.lua",
    "stockmarket/core/sv_persistence.lua",
    "stockmarket/core/sv_player_data.lua",

    -- Stocks/engine
    "stockmarket/stocks/sv_random_walk.lua",
    "stockmarket/stocks/sv_circuit_breaker.lua",
    "stockmarket/stocks/sv_events.lua",
    "stockmarket/stocks/sv_stock_engine.lua",

    -- Trading
    "stockmarket/trading/sv_fees.lua",
    "stockmarket/trading/sv_transactions.lua",
    "stockmarket/trading/sv_portfolio.lua",
    "stockmarket/trading/sv_orders.lua",

    -- Groups (optional features as in your build)
    "stockmarket/groups/sv_investment_groups.lua",
    "stockmarket/groups/sv_group_trading.lua",
    "stockmarket/groups/sv_group_permissions.lua",

    -- Legacy/admin tools (keep for compatibility if you have it)
    "stockmarket/admin/sv_admin_tools.lua",

    -- Client libraries (order critical)
    "stockmarket/ui/lib/cl_colors.lua",
    "stockmarket/ui/lib/cl_animations.lua",
    "stockmarket/ui/lib/cl_ui_library.lua",
    "stockmarket/ui/lib/cl_chart.lua",

    -- Client config hydration
    "stockmarket/ui/cl_config_sync.lua",

    -- Client UI
    "stockmarket/ui/cl_notifications.lua",
    "stockmarket/ui/cl_news_feed.lua",
    "stockmarket/ui/cl_portfolio_view.lua",
    "stockmarket/ui/cl_ticker_view.lua",
    "stockmarket/ui/cl_market_overview.lua",
    "stockmarket/ui/cl_groups_view.lua",
    "stockmarket/ui/cl_main_frame.lua",

    -- Admin UI (merged new admin panel)
    "stockmarket/ui/admin/cl_admin_main.lua",
    "stockmarket/ui/admin/cl_admin_stocks.lua",
    "stockmarket/ui/admin/cl_admin_stats.lua",
    "stockmarket/ui/admin/cl_admin_events.lua",

    -- Admin server-side (new)
    "stockmarket/core/sv_admin_net.lua",
    "stockmarket/core/sv_admin_runtime.lua",
    "stockmarket/core/sv_admin_snapshots.lua",
}

-- Helper to include/send by prefix
local function IncludeByPrefix(path)
    local filename = string.GetFileFromFilename(path) -- e.g. "sv_database.lua"
    local uscore = string.find(filename, "_")
    if not uscore then
        Log("Skipping (no prefix): " .. path)
        return
    end

    local prefix = string.sub(filename, 1, uscore - 1) -- "sv", "cl", "sh"

    if prefix == "sh" then
        if SERVER then AddCSLuaFile(path) end
        include(path)
        Log("Loaded (shared): " .. path)
    elseif prefix == "sv" then
        if SERVER then
            include(path)
            Log("Loaded (server): " .. path)
        end
    elseif prefix == "cl" then
        if SERVER then
            AddCSLuaFile(path)
            Log("Sent to client: " .. path)
        else
            include(path)
            Log("Loaded (client): " .. path)
        end
    else
        Log("Unknown prefix for: " .. path)
    end
end

-- Load modules in order
for _, path in ipairs(loadOrder) do
    IncludeByPrefix(path)
end

-- Optional integrations
local integrations = {
    "stockmarket/integrations/sh_darkrp.lua",
}

for _, path in ipairs(integrations) do
    if SERVER then AddCSLuaFile(path) end
    local ok, err = pcall(function() include(path) end)
    if ok then
        Log("Loaded integration: " .. path)
    else
        Log("Integration skipped or missing: " .. path)
    end
end

-- Initialize server components (guarded)
if SERVER then
    if not ConVarExists("sm_quickbuy_amount") then
        CreateConVar("sm_quickbuy_amount", "1000", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Default $ amount for Quick Buy.")
    end

    hook.Add("Initialize", "StockMarket_Initialize", function()
        print("[StockMarket] Initializing server components...")

        if not StockMarket.Database or not StockMarket.Database.Initialize then
            ErrorNoHalt("[StockMarket] sv_database.lua was not loaded. Check paths/load order.\n")
            return
        end

        StockMarket.Database:Initialize()

        -- Delay start for DB init and any other systems
        timer.Simple(2, function()
            if not StockMarket.StockEngine or not StockMarket.StockEngine.Start then
                ErrorNoHalt("[StockMarket] sv_stock_engine.lua was not loaded. Check paths/load order.\n")
                return
            end

            StockMarket.StockEngine:Start()
            print("[StockMarket] Stock engine started")
        end)
    end)
end

-- Simple client init log
if CLIENT then
    hook.Add("InitPostEntity", "StockMarket_ClientInit", function()
        print("[StockMarket] Client initialized")
    end)
end

-- Convenience console command to open main UI
if CLIENT then
    concommand.Add("sm_open", function()
        if StockMarket and StockMarket.UI and StockMarket.UI.OpenMainFrame then
            StockMarket.UI.OpenMainFrame()
        else
            chat.AddText(Color(255,100,100), "[StockMarket] UI not ready yet. Try again in a second.")
        end
    end)
end

-- Admin: open admin panel (superadmin gate) via console
if CLIENT then
    concommand.Add("sm_admin", function()
        local lp = LocalPlayer()
        if not IsValid(lp) or not lp:IsSuperAdmin() then
            chat.AddText(Color(255,100,100), "[StockMarket] Superadmin only.")
            return
        end
        if StockMarket.UI and StockMarket.UI.Admin and StockMarket.UI.Admin.Open then
            StockMarket.UI.Admin.Open()
        else
            chat.AddText(Color(255,100,100), "[StockMarket] Admin UI not ready. Check that admin client files are included.")
        end
    end)
end

print("[StockMarket] Initialization complete!")
