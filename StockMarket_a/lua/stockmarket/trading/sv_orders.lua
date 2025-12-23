-- ========================================
-- Order Management & Execution (SERVER)
-- ========================================

StockMarket.Orders = StockMarket.Orders or {}

-- Localize modules to minimize global lookups while preserving globals
local SM = StockMarket
local Orders = SM.Orders or {}
SM.Orders = Orders

local Fees = SM.Fees
local PlayerData = SM.PlayerData
local Config = SM.Config
local StockEngine = SM.StockEngine
local CircuitBreaker = SM.CircuitBreaker
local Enums = SM.Enums
local Transactions = SM.Transactions


Orders._rl = Orders._rl or {} -- sid -> { last, tokens, rej }

local RL_BURST = 5           -- allow up to 5 orders instantly
local RL_REFILL = 1          -- refill 1 token per second
local RL_MSG = "Too many orders. Slow down."

local function OrderRateLimited(ply)
    local sid = IsValid(ply) and ply:SteamID64() or "?"
    local now = CurTime()
    local st = Orders._rl[sid] or { last = now, tokens = RL_BURST, rej = 0 }
    local dt = now - st.last
    if dt > 0 then
        st.tokens = math.min(RL_BURST, st.tokens + dt * RL_REFILL)
        st.last = now
    end
    if st.tokens < 1 then
        Orders._rl[sid] = st
        return true
    end
    st.tokens = st.tokens - 1
    Orders._rl[sid] = st
    return false
end

local function ClampShares(shares)
    shares = math.floor(tonumber(shares) or 0)
    if shares < 1 then return 0 end
    if shares > 10^7 then shares = 10^7 end -- hard ceiling
    return shares
end

local function EnforceMaxOrderSize(tickerConfig, shares)
    if not tickerConfig then return true, nil end
    local float = tonumber(tickerConfig.marketStocks or 0) or 0
    if float <= 0 then return true, nil end
    local pct = tonumber(StockMarket.Config.MaxOrderSize or 0.10) or 0.10
    local maxSize = math.floor(float * pct)
    if shares > maxSize then
        return false, string.format("Order exceeds %.0f%% of float (max %s)", pct * 100, string.Comma(maxSize))
    end
    return true, nil
end

-- Helpers for net reads
local function safeReadString() local ok,v=pcall(net.ReadString); return ok and v or nil end
local function safeReadInt(b)  local ok,v=pcall(net.ReadInt,b);   return ok and v or nil end
local function safeReadFloat() local ok,v=pcall(net.ReadFloat);   return ok and v or nil end

-- Execute BUY (market)
function Orders:ExecuteBuy(ply, ticker, shares, price)
    local totalCost = shares * price
    local fee = Fees:Calculate(ticker, shares, price, Enums.OrderType.MARKET)
    local totalRequired = totalCost + fee

    if Config.UseDarkRPWallet and DarkRP and ply.canAfford and ply.addMoney then
        if not ply:canAfford(math.ceil(totalRequired)) then
            return false, "Insufficient funds"
        end
        ply:addMoney(-math.ceil(totalRequired))
    else
        local cash = PlayerData:GetCash(ply)
        if cash < totalRequired then
            return false, "Insufficient funds"
        end
        if not PlayerData:RemoveCash(ply, totalRequired) then
            return false, "Transaction failed"
        end
    end

    PlayerData:AddPosition(ply, ticker, shares, price)
    Transactions:Log(ply, ticker, Enums.TransactionType.BUY, shares, price, fee)

    local bar = StockEngine.CurrentBars[ticker]
    if bar then
        bar.volume = (bar.volume or 0) + shares
        bar.buyVolume = (bar.buyVolume or 0) + shares
    end

    PlayerData:SyncPortfolio(ply)

    net.Start("StockMarket_OrderFilled")
    net.WriteString(ticker)
    net.WriteInt(shares, 32)
    net.WriteFloat(price)
    net.WriteFloat(fee)
    net.WriteBool(true) -- isBuy
    net.Send(ply)

    if Config.EnableSounds then
        ply:EmitSound("stockmarket/buy.wav", 50, 100, 0.5)
    end

    return true, "Order filled"
end

-- Execute SELL (market)
function Orders:ExecuteSell(ply, ticker, shares, price)
    local position = PlayerData:GetPosition(ply, ticker)
    if not position or position.shares < shares then
        return false, "Insufficient shares"
    end

    local totalValue = shares * price
    local fee = Fees:Calculate(ticker, shares, price, Enums.OrderType.MARKET)
    local netProceeds = totalValue - fee

    local success, profit = PlayerData:RemovePosition(ply, ticker, shares, price)
    if not success then
        return false, "Transaction failed"
    end

    if Config.UseDarkRPWallet and DarkRP and ply.addMoney then
        ply:addMoney(math.floor(netProceeds))
    else
        PlayerData:AddCash(ply, netProceeds)
    end

    Transactions:Log(ply, ticker, Enums.TransactionType.SELL, shares, price, fee)

    local bar = StockEngine.CurrentBars[ticker]
    if bar then
        bar.volume = (bar.volume or 0) + shares
        bar.sellVolume = (bar.sellVolume or 0) + shares
    end

    PlayerData:SyncPortfolio(ply)

    net.Start("StockMarket_OrderFilled")
    net.WriteString(ticker)
    net.WriteInt(shares, 32)
    net.WriteFloat(price)
    net.WriteFloat(fee)
    net.WriteBool(false) -- isSell
    net.Send(ply)

    if Config.EnableSounds then
        ply:EmitSound("stockmarket/sell.wav", 50, 100, 0.5)
    end

    return true, string.format("Sold! Profit: %s%.2f", Config.CurrencySymbol, profit)
end

-- Place Order (routes to execute paths)
function Orders:PlaceOrder(ply, ticker, orderType, side, shares, limitPrice)
    if not IsValid(ply) then return false, "Invalid player" end
    shares = ClampShares(shares)
    if shares <= 0 then return false, "Invalid share amount" end

    local tickerConfig = Config:GetTickerByPrefix(ticker)
    if not tickerConfig then return false, "Invalid ticker" end

    local ok, msg = EnforceMaxOrderSize(tickerConfig, shares)
    if not ok then return false, msg or "Order exceeds limit" end

    local currentPrice = StockEngine:GetPrice(ticker)
    if not currentPrice then return false, "Price unavailable" end

    if CircuitBreaker:IsHalted(ticker) then
        return false, "Trading halted for this stock"
    end

    if orderType == Enums.OrderType.MARKET then
        if side == Enums.OrderSide.BUY then
            return self:ExecuteBuy(ply, ticker, shares, currentPrice)
        elseif side == Enums.OrderSide.SELL then
            return self:ExecuteSell(ply, ticker, shares, currentPrice)
        else
            return false, "Invalid side"
        end
    end

    return false, "Limit orders not yet implemented"
end

-- ========================================
-- Receiver: versioned, explicit fields
-- ========================================
net.Receive("StockMarket_PlaceOrder", function(len, ply)
    if OrderRateLimited(ply) then
        net.Start("StockMarket_OrderRejected"); net.WriteString(RL_MSG); net.Send(ply)
        return
    end

    -- [int8 ver=1][string ticker][int8 orderType][int8 side][int32 shares][float limitPrice]
    local ver = safeReadInt(8)
    if ver ~= 1 then
        net.Start("StockMarket_OrderRejected"); net.WriteString("Malformed order payload"); net.Send(ply); return
    end

    local ticker     = safeReadString()
    local orderType  = safeReadInt(8)
    local side       = safeReadInt(8)
    local shares     = safeReadInt(32)
    local limitPrice = safeReadFloat() or 0

    if not ticker or not orderType or not side or not shares then
        net.Start("StockMarket_OrderRejected"); net.WriteString("Malformed order payload"); net.Send(ply); return
    end

    -- Validate enums
    local OT = StockMarket.Enums.OrderType
    local OS = StockMarket.Enums.OrderSide
    if orderType ~= OT.MARKET and orderType ~= OT.LIMIT then
        orderType = OT.MARKET
    end
    if side ~= OS.BUY and side ~= OS.SELL then
        net.Start("StockMarket_OrderRejected"); net.WriteString("Invalid side"); net.Send(ply); return
    end
    shares = ClampShares(shares)
    if shares <= 0 then
        net.Start("StockMarket_OrderRejected"); net.WriteString("Invalid share amount"); net.Send(ply); return
    end

    local ok, msg = StockMarket.Orders:PlaceOrder(ply, ticker, orderType, side, shares, limitPrice)
    if not ok then
        net.Start("StockMarket_OrderRejected"); net.WriteString(msg or "Order rejected"); net.Send(ply)
        return
    end
    -- Success path handled in ExecuteBuy/ExecuteSell
end)

