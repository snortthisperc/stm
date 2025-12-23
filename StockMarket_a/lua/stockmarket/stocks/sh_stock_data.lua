-- ========================================
-- Stock Data (Shared)
-- ========================================

StockMarket.StockData = StockMarket.StockData or {}

if SERVER then
    StockMarket.StockData.Prices = {}
    StockMarket.StockData.History = {}
    StockMarket.StockData.Events = {}
end

if CLIENT then
    StockMarket.StockData.Bar = StockMarket.StockData.Bar or {}
    net.Receive("StockMarket_BarSnapshot", function()
        local ticker = net.ReadString()
        local vol = net.ReadUInt(32)
        local buyVol = net.ReadUInt(32)
        local sellVol = net.ReadUInt(32)
        StockMarket.StockData.Bar[ticker] = {
            volume = vol,
            buyVolume = buyVol,
            sellVolume = sellVol
        }
        hook.Run("StockMarket_BarUpdated", ticker, vol, buyVol, sellVol)
    end)

    StockMarket.StockData.Prices = {}
    StockMarket.StockData.History = {}
end

function StockMarket.StockData:GetPrice(ticker)
    return self.Prices[ticker]
end

function StockMarket.StockData:GetHistory(ticker)
    return self.History[ticker] or {}
end

if CLIENT then
    net.Receive("StockMarket_PriceUpdate", function()
        local ticker = net.ReadString()
        local price = net.ReadFloat()
        local change = net.ReadFloat()
        local changePercent = net.ReadFloat()
        
        StockMarket.StockData.Prices[ticker] = {
            price = price,
            change = change,
            changePercent = changePercent,
            timestamp = CurTime()
        }
        
        hook.Run("StockMarket_PriceUpdated", ticker, price, change, changePercent)
    end)
    
    net.Receive("StockMarket_FullSync", function()
        local count = net.ReadUInt(16) or 0
        local data = {}
        for i = 1, count do
            local ticker = net.ReadString()
            data[ticker] = {
                price = net.ReadFloat(),
                change = net.ReadFloat(),
                changePercent = net.ReadFloat()
            }
        end
        StockMarket.StockData.Prices = data
    end)
    
    net.Receive("StockMarket_HistoryData", function()
        local ticker = net.ReadString()
        local count = net.ReadUInt(16) or 0
        local history = {}
        for i = 1, count do
            history[i] = {
                timestamp = net.ReadUInt(32),
                open = net.ReadFloat(),
                high = net.ReadFloat(),
                low  = net.ReadFloat(),
                close = net.ReadFloat(),
                volume = net.ReadUInt(32)
            }
        end
        StockMarket.StockData.History[ticker] = history
        hook.Run("StockMarket_HistoryUpdated", ticker, history)
    end)
end
