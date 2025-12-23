-- ========================================
-- Configuration
-- ========================================

StockMarket.Config = StockMarket.Config or {}

-- General
StockMarket.Config.UseDarkRPWallet = true
StockMarket.Config.TickRateSeconds = 10
StockMarket.Config.Currency = "USD"
StockMarket.Config.CurrencySymbol = "$"
StockMarket.Config.StartingCash = 0
StockMarket.Config.EnableSounds = true
StockMarket.Config.EnableNotifications = true

StockMarket.Config.Notifications = {
    enabled = true,
    position = "top_right", -- top_right, top_left, bottom_right, bottom_left, center_top, center_bottom
    maxVisible = 6,         -- maximum notifications on screen
    spacing = 10,           -- vertical space between items
    width = 340,            -- notification width
    life = 5,               -- default seconds an item lives
    showProgress = true,    -- show a subtle progress bar
    shadow = true,          -- draw soft drop-shadow
    cornerRadius = 8,       -- rounded corners radius
    iconSet = "default",    -- reserved for future icon packs
    styles = {
        info =    { bg = Color(32, 36, 45),  accent = Color(59, 130, 246), text = Color(235,240,245) },
        success = { bg = Color(32, 45, 36),  accent = Color(34, 197, 94),  text = Color(235,240,245) },
        warning = { bg = Color(45, 41, 32),  accent = Color(251, 191, 36), text = Color(235,240,245) },
        error =   { bg = Color(45, 32, 32),  accent = Color(239, 68, 68),  text = Color(235,240,245) },
    }
}

-- Trading
StockMarket.Config.DefaultFees = {
    makerPercent = 0.0,   -- No fee for limit orders
    takerPercent = 0.005, -- 0.5% for market orders
    flatFee = 0           -- Flat fee per trade
}

StockMarket.Config.QuickBuy = {
    Amount = 100000,
    EnableCVarOverride = true,
    CVarName = "sm_quickbuy_amount"
}

StockMarket.Config.MaxOrderSize = 0.10 -- 10% of float
StockMarket.Config.TradeSnipeBuffer = 3 -- seconds after news alert before trading allowed

-- Groups
StockMarket.Config.Groups = {
    maxMembers = 10,
    defaultTraderDailyLimit = 0.20, -- 20% of group equity
    requireWithdrawalApproval = true,
    withdrawalThreshold = 10000 -- Require approval above this amount
}

-- Persistence
StockMarket.Config.Persistence = {
    adapter = "sqlite",
    autosaveSeconds = 60,
    history = {
        primaryBar = "1m",
        retention = {
            ["1m"] = 2880,  -- 48 hours
            ["15m"] = 1344  -- ~14 days
        }
    }
}

-- Circuit Breakers
StockMarket.Config.CircuitBreaker = {
    enabled = true,
    dropPercentTrigger = 15, -- Halt if drops 15% in window
    windowSeconds = 300,     -- 5 minute window
    haltDurationSeconds = 60
}

-- Price Generation
StockMarket.Config.PriceGen = {
    K = 50,          -- Difficulty scaling constant
    minSigma = 0.1,
    maxSigma = 5.0,
    minPrice = 0.01,
    maxDailyMoveCap = 0.25 -- 25% unless event overrides
}

-- Admin
StockMarket.Config.AdminGroups = {
    "superadmin",
    "admin"
}

-- ========================================
-- Stock Market Definitions
-- ========================================

StockMarket.Config.Markets = {}

-- TECH SECTOR
StockMarket.Config.Markets.Tech = {
    sectorName = "Tech",
    sectorVolatility = 1.0,
    enabled = true,
    tickers = {
        {
            stockName = "Steam",
            stockPrefix = "STM",
            marketStocks = 800000000,
            stockDifficulty = 2000,
            newStockValue = 807,
            minTick = -3,
            maxTick = 3,
            drift = 0.01,
            volatility = 1.0,
            circuitBreaker = { dropPercent = 15, haltSeconds = 60 },
            dividend = { enabled = false, yieldPercent = 0.0, periodSeconds = 0 },
            tradeFees = nil, -- nil = use defaults
            stockEvents = {
                {
                    handle = "Steam_Console_Launch",
                    weight = 1.0,
                    impact = { type = "JUMP", magnitude = 4, duration = 120 },
                    message = "Steam announces revolutionary Console news!",
                    preAlertSeconds = 15
                },
                {
                    handle = "Steam_Lawsuit",
                    weight = 0.6,
                    impact = { type = "DRIFT", magnitude = -2, duration = 300 },
                    message = "Steam Lawsuit filed over Privacy concerns",
                    preAlertSeconds = 20
                },
                {
                    handle = "Game_Sale",
                    weight = 0.9,
                    impact = { type = "PUMP", magnitude = 3, duration = 180 },
                    message = "Steams new sale has caused over 10,000 new users to join!",
                    preAlertSeconds = 10
                }
            },
            persistence = { key = "STM", historyRetentionPoints = 2880 },
            enabled = true
        },
        {
            stockName = "Apple",
            stockPrefix = "AAPL",
            marketStocks = 900000000,
            stockDifficulty = 1800,
            newStockValue = 1050,
            minTick = -4,
            maxTick = 4,
            drift = 0.015,
            volatility = 0.9,
            circuitBreaker = { dropPercent = 15, haltSeconds = 60 },
            dividend = { enabled = true, yieldPercent = 0.5, periodSeconds = 3600 },
            tradeFees = nil,
            stockEvents = {
                {
                    handle = "iPhone_Release",
                    weight = 1.0,
                    impact = { type = "PUMP", magnitude = 5, duration = 240 },
                    message = "New iPhone breaks pre-order records!",
                    preAlertSeconds = 15
                },
                {
                    handle = "Battery_Scandal",
                    weight = 0.5,
                    impact = { type = "CRASH", magnitude = -4, duration = 300 },
                    message = "iPhones catching fire - recall announced!",
                    preAlertSeconds = 20
                }
            },
            persistence = { key = "AAPL", historyRetentionPoints = 2880 },
            enabled = true
        },
        {
            stockName = "NVIDIA",
            stockPrefix = "NVDA",
            marketStocks = 500000000,
            stockDifficulty = 1500,
            newStockValue = 1420,
            minTick = -5,
            maxTick = 5,
            drift = 0.02,
            volatility = 1.3,
            circuitBreaker = { dropPercent = 20, haltSeconds = 90 },
            dividend = { enabled = false, yieldPercent = 0.0, periodSeconds = 0 },
            tradeFees = nil,
            stockEvents = {
                {
                    handle = "GPU_Shortage",
                    weight = 0.8,
                    impact = { type = "PUMP", magnitude = 6, duration = 300 },
                    message = "GPU shortage drives NVIDIA demand sky-high!",
                    preAlertSeconds = 12
                },
                {
                    handle = "AI_Boom",
                    weight = 1.0,
                    impact = { type = "JUMP", magnitude = 7, duration = 180 },
                    message = "AI revolution boosts NVIDIA chip sales!",
                    preAlertSeconds = 15
                }
            },
            persistence = { key = "NVDA", historyRetentionPoints = 2880 },
            enabled = true
        }
    }
}

-- ENERGY SECTOR
StockMarket.Config.Markets.Energy = {
    sectorName = "Energy",
    sectorVolatility = 1.2,
    enabled = true,
    tickers = {
        {
            stockName = "ExxonMobil",
            stockPrefix = "XOM",
            marketStocks = 1000000000,
            stockDifficulty = 2500,
            newStockValue = 112,
            minTick = -2,
            maxTick = 2,
            drift = 0.005,
            volatility = 1.1,
            circuitBreaker = { dropPercent = 12, haltSeconds = 60 },
            dividend = { enabled = true, yieldPercent = 3.5, periodSeconds = 7200 },
            tradeFees = nil,
            stockEvents = {
                {
                    handle = "Oil_Crisis",
                    weight = 0.7,
                    impact = { type = "PUMP", magnitude = 5, duration = 400 },
                    message = "Global oil shortage sends prices soaring!",
                    preAlertSeconds = 25
                },
                {
                    handle = "Green_Energy_Push",
                    weight = 0.6,
                    impact = { type = "DRIFT", magnitude = -3, duration = 500 },
                    message = "Government pushes green energy regulations",
                    preAlertSeconds = 30
                }
            },
            persistence = { key = "XOM", historyRetentionPoints = 2880 },
            enabled = true
        },
        {
            stockName = "Solar Inc",
            stockPrefix = "SOLR",
            marketStocks = 300000000,
            stockDifficulty = 1200,
            newStockValue = 45,
            minTick = -3,
            maxTick = 4,
            drift = 0.03,
            volatility = 1.5,
            circuitBreaker = { dropPercent = 18, haltSeconds = 60 },
            dividend = { enabled = false, yieldPercent = 0.0, periodSeconds = 0 },
            tradeFees = nil,
            stockEvents = {
                {
                    handle = "Solar_Subsidy",
                    weight = 0.9,
                    impact = { type = "JUMP", magnitude = 6, duration = 200 },
                    message = "Massive solar subsidies announced!",
                    preAlertSeconds = 15
                }
            },
            persistence = { key = "SOLR", historyRetentionPoints = 2880 },
            enabled = true
        }
    }
}

-- FINANCE SECTOR
StockMarket.Config.Markets.Marketing = {
    sectorName = "Marketing",
    sectorVolatility = 0.3,
    enabled = true,
    tickers = {
        {
            stockName = "Enzos Gun Shop",
            stockPrefix = "EGS",
            marketStocks = 600000000,
            stockDifficulty = 2200,
            newStockValue = 425,
            minTick = -3,
            maxTick = 3,
            drift = 0.008,
            volatility = 0.8,
            circuitBreaker = { dropPercent = 15, haltSeconds = 60 },
            dividend = { enabled = true, yieldPercent = 2.0, periodSeconds = 5400 },
            tradeFees = nil,
            stockEvents = {
                {
                    handle = "MRDM_Crisis",
                    weight = 0.5,
                    impact = { type = "CRASH", magnitude = -6, duration = 400 },
                    message = "MRDM Crisis: Illegal weapon flooding crashes gun market!",
                    preAlertSeconds = 30
                },
                {
                    handle = "Epic_Gun_Sale",
                    weight = 0.8,
                    impact = { type = "PUMP", magnitude = 4, duration = 300 },
                    message = "Enzo has announced a HUGE weapons sale",
                    preAlertSeconds = 20
                },
                {
                    handle = "Police_Raid",
                    weight = 0.6,
                    impact = { type = "CHAOS", magnitude = 5, duration = 180 },
                    message = "Police raid on gun shop! Market in chaos!",
                    preAlertSeconds = 15
                },

            },
            persistence = { key = "EGS", historyRetentionPoints = 2880 },
            enabled = true
        },
    }
}

-- FINANCE SECTOR
StockMarket.Config.Markets.Finance = {
    sectorName = "Finance",
    sectorVolatility = 0.9,
    enabled = true,
    tickers = {
        {
            stockName = "JPMorgan Chase",
            stockPrefix = "JPM",
            marketStocks = 700000000,
            stockDifficulty = 2400,
            newStockValue = 380,
            minTick = -2,
            maxTick = 3,
            drift = 0.01,
            volatility = 0.75,
            circuitBreaker = { dropPercent = 15, haltSeconds = 60 },
            dividend = { enabled = true, yieldPercent = 2.5, periodSeconds = 5400 },
            tradeFees = nil,
            stockEvents = {
                {
                    handle = "Earnings_Beat",
                    weight = 0.9,
                    impact = { type = "JUMP", magnitude = 3, duration = 180 },
                    message = "JPMorgan crushes earnings expectations!",
                    preAlertSeconds = 15
                }
            },
            persistence = { key = "JPM", historyRetentionPoints = 2880 },
            enabled = true
        }
    }
}

-- CRYPTO SECTOR
StockMarket.Config.Markets.Crypto = {
    sectorName = "Crypto",
    sectorVolatility = 2.5,
    enabled = true,
    tickers = {
        {
            stockName = "Bitcoin",
            stockPrefix = "BTC",
            marketStocks = 21000000,
            stockDifficulty = 800,
            newStockValue = 45000,
            minTick = -500,
            maxTick = 500,
            drift = 0.0,
            volatility = 2.0,
            circuitBreaker = { dropPercent = 25, haltSeconds = 120 },
            dividend = { enabled = false, yieldPercent = 0.0, periodSeconds = 0 },
            tradeFees = { makerPercent = 0.001, takerPercent = 0.002, flatFee = 0 },
            stockEvents = {
                {
                    handle = "Elon_Tweet",
                    weight = 1.0,
                    impact = { type = "VOLATILITY", magnitude = 10, duration = 120 },
                    message = "Elon tweets about Bitcoin again!",
                    preAlertSeconds = 5
                },
                {
                    handle = "China_Ban",
                    weight = 0.6,
                    impact = { type = "CRASH", magnitude = -8, duration = 300 },
                    message = "China announces crypto crackdown!",
                    preAlertSeconds = 25
                },
                {
                    handle = "ETF_Approval",
                    weight = 0.8,
                    impact = { type = "PUMP", magnitude = 9, duration = 400 },
                    message = "Bitcoin ETF approved by SEC!",
                    preAlertSeconds = 30
                }
            },
            persistence = { key = "BTC", historyRetentionPoints = 2880 },
            enabled = true
        },
        {
            stockName = "Ethereum",
            stockPrefix = "ETH",
            marketStocks = 120000000,
            stockDifficulty = 900,
            newStockValue = 3200,
            minTick = -80,
            maxTick = 80,
            drift = 0.01,
            volatility = 1.8,
            circuitBreaker = { dropPercent = 25, haltSeconds = 120 },
            dividend = { enabled = false, yieldPercent = 0.0, periodSeconds = 0 },
            tradeFees = { makerPercent = 0.001, takerPercent = 0.002, flatFee = 0 },
            stockEvents = {
                {
                    handle = "ETH_2_0",
                    weight = 1.0,
                    impact = { type = "JUMP", magnitude = 7, duration = 300 },
                    message = "Ethereum 2.0 upgrade goes live!",
                    preAlertSeconds = 20
                }
            },
            persistence = { key = "ETH", historyRetentionPoints = 2880 },
            enabled = true
        }
    }
}

-- Add more sectors (Healthcare, Consumer Goods, etc.) following the same pattern
StockMarket.Config.Markets.Healthcare = {
    sectorName = "Healthcare",
    sectorVolatility = 0.85,
    enabled = true,
    tickers = {
        {
            stockName = "Pfizer",
            stockPrefix = "PFE",
            marketStocks = 550000000,
            stockDifficulty = 2100,
            newStockValue = 52,
            minTick = -2,
            maxTick = 2,
            drift = 0.007,
            volatility = 0.9,
            circuitBreaker = { dropPercent = 15, haltSeconds = 60 },
            dividend = { enabled = true, yieldPercent = 3.2, periodSeconds = 7200 },
            tradeFees = nil,
            stockEvents = {
                {
                    handle = "Vaccine_Approval",
                    weight = 1.0,
                    impact = { type = "JUMP", magnitude = 8, duration = 250 },
                    message = "New vaccine receives emergency approval!",
                    preAlertSeconds = 20
                },
                {
                    handle = "Patent_Loss",
                    weight = 0.6,
                    impact = { type = "DRIFT", magnitude = -3, duration = 350 },
                    message = "Pfizer loses key drug patent lawsuit",
                    preAlertSeconds = 25
                }
            },
            persistence = { key = "PFE", historyRetentionPoints = 2880 },
            enabled = true
        }
    }
}

-- Utility function to get all tickers
function StockMarket.Config:GetAllTickers()
    local tickers = {}
    for sectorKey, data in pairs(self.Markets) do
        if data.enabled then
            for _, t in ipairs(data.tickers) do
                if t.enabled then
                    t.sectorName = data.sectorName or sectorKey
                    table.insert(tickers, t)
                end
            end
        end
    end
    return tickers
end

function StockMarket.Config:GetTickerByPrefix(prefix)
    for sector, data in pairs(self.Markets) do
        if data.enabled then
            for _, ticker in ipairs(data.tickers) do
                if ticker.enabled and ticker.stockPrefix == prefix then
                    return ticker, data
                end
            end
        end
    end
    return nil
end
