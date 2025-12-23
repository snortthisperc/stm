-- ========================================
-- Enums & Constants
-- ========================================

StockMarket.Enums = StockMarket.Enums or {}

StockMarket.Enums.EventType = {
    JUMP = 1,      -- Instant price jump
    DRIFT = 2,     -- Sustained trend
    PUMP = 3,      -- Volatile uptrend
    CRASH = 4,     -- Volatile downtrend
    VOLATILITY = 5 -- Pure volatility spike
}

StockMarket.Enums.OrderType = {
    MARKET = 1,
    LIMIT = 2,
    STOP_LOSS = 3
}

StockMarket.Enums.OrderSide = {
    BUY = 1,
    SELL = 2
}

StockMarket.Enums.OrderStatus = {
    PENDING = 1,
    FILLED = 2,
    CANCELLED = 3,
    REJECTED = 4
}

StockMarket.Enums.GroupRole = {
    OWNER = 4,
    MANAGER = 3,
    TRADER = 2,
    VIEWER = 1
}

StockMarket.Enums.TransactionType = {
    BUY = 1,
    SELL = 2,
    DIVIDEND = 3,
    FEE = 4
}

-- Sectors
StockMarket.Sectors = {
    "Tech",
    "Energy",
    "Finance",
    "Healthcare",
    "Consumer Goods",
    "Industrials",
    "Utilities",
    "Real Estate",
    "Telecommunications",
    "Transportation",
    "Materials",
    "Crypto"
}
