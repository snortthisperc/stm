if not CLIENT then return end

local function RequestMarkets()
    if not net then return end
    --print("[SM Client] → Requesting Markets_GetState")
    net.Start("StockMarket_Markets_GetState")
    net.SendToServer()
end

function StockMarket.Config:GetAllTickers()
    local out = {}
    local src = StockMarket.ClientMarkets or self.Markets or {}
    for sectorKey, data in pairs(src) do
        if data.enabled ~= false then
            for _, t in ipairs(data.tickers or {}) do
                if t.enabled ~= false then
                    t.sectorKey = sectorKey
                    t.sectorName = data.sectorName or sectorKey
                    table.insert(out, t)
                end
            end
        end
    end
    --print("[SM Client] GetAllTickers called; returning", #out, "tickers")
    return out
end

net.Receive("StockMarket_Markets_State", function()
    --print("[SM Client] ← Markets_State received; parsing...")
    local sectorCount = net.ReadUInt(16) or 0
    --print("[SM Client]   Sector count:", sectorCount)

    local markets = {}

    for i = 1, sectorCount do
        local sectorKey = net.ReadString()
        local sector = {
            sectorName = net.ReadString(),
            sectorVolatility = net.ReadFloat(),
            enabled = net.ReadBool(),
            tickers = {}
        }
        local tickerCount = net.ReadUInt(16) or 0
        for j = 1, tickerCount do
            sector.tickers[j] = {
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
            }
        end
        markets[sectorKey] = sector
    end

    StockMarket.ClientMarkets = markets
    --print("[SM Client] ✓ ClientMarkets hydrated; total sectors:", table.Count(StockMarket.ClientMarkets))

    hook.Run("StockMarket_ClientMarketsHydrated")

    if IsValid(StockMarket.UI.MainFrame) and StockMarket.UI.MainFrame.currentView and StockMarket.UI.MainFrame.currentView.Refresh then
        print("[SM Client] ✓ Main frame is open; scheduling Refresh()")
        timer.Simple(0, function()
            if IsValid(StockMarket.UI.MainFrame) and StockMarket.UI.MainFrame.currentView and StockMarket.UI.MainFrame.currentView.Refresh then
                print("[SM Client] ✓ Calling currentView:Refresh()")
                StockMarket.UI.MainFrame.currentView:Refresh("")
            end
        end)
    else
        --print("[SM Client] Main frame not open or no currentView; skipping immediate refresh")
    end
end)

net.Receive("StockMarket_ConfigChanged", function()
    --print("[SM Client] ← Received StockMarket_ConfigChanged")
    RequestMarkets()
end)

hook.Add("InitPostEntity", "StockMarket_ClientHydrateMarkets", function()
    --print("[SM Client] InitPostEntity; scheduling initial market request")
    timer.Simple(0.5, RequestMarkets)
end)
