-- ========================================
-- Database Management (SQLite)
-- ========================================

StockMarket.Database = StockMarket.Database or {}

function StockMarket.Database:Initialize()
    self:CreateTables()
    MsgC(Color(100, 200, 255), "[StockMarket] Database initialized\n")
end

function StockMarket.Database:CreateTables()
    -- Players table
    sql.Query([[
        CREATE TABLE IF NOT EXISTS stockmarket_players (
            steam_id TEXT PRIMARY KEY,
            cash REAL DEFAULT 0,
            total_invested REAL DEFAULT 0,
            realized_profit REAL DEFAULT 0,
            last_updated INTEGER
        )
    ]])
    
    -- Positions table
    sql.Query([[
        CREATE TABLE IF NOT EXISTS stockmarket_positions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            steam_id TEXT,
            ticker TEXT,
            shares INTEGER,
            avg_cost REAL,
            last_updated INTEGER
        )
    ]])
    
    -- Transactions table
    sql.Query([[
        CREATE TABLE IF NOT EXISTS stockmarket_transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            steam_id TEXT,
            ticker TEXT,
            type INTEGER,
            shares INTEGER,
            price REAL,
            fee REAL,
            timestamp INTEGER
        )
    ]])
    
    -- Price history table
    sql.Query([[
        CREATE TABLE IF NOT EXISTS stockmarket_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ticker TEXT,
            timestamp INTEGER,
            open REAL,
            high REAL,
            low REAL,
            close REAL,
            volume INTEGER
        )
    ]])
    
    -- Stock state table
    sql.Query([[
        CREATE TABLE IF NOT EXISTS stockmarket_stock_state (
            ticker TEXT PRIMARY KEY,
            current_price REAL,
            last_update INTEGER,
            halted INTEGER DEFAULT 0,
            active_event TEXT
        )
    ]])
    
    -- Investment groups table
    sql.Query([[
        CREATE TABLE IF NOT EXISTS stockmarket_groups (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE,
            owner_steam_id TEXT,
            cash REAL DEFAULT 0,
            created INTEGER
        )
    ]])
    
    -- Group members table
    sql.Query([[
        CREATE TABLE IF NOT EXISTS stockmarket_group_members (
            group_id INTEGER,
            steam_id TEXT,
            role INTEGER,
            daily_limit REAL,
            joined INTEGER,
            PRIMARY KEY (group_id, steam_id)
        )
    ]])
    
    -- Group positions table
    sql.Query([[
        CREATE TABLE IF NOT EXISTS stockmarket_group_positions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            group_id INTEGER,
            ticker TEXT,
            shares INTEGER,
            avg_cost REAL
        )
    ]])
    
    -- Orders table
    sql.Query([[
        CREATE TABLE IF NOT EXISTS stockmarket_orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            steam_id TEXT,
            group_id INTEGER DEFAULT 0,
            ticker TEXT,
            order_type INTEGER,
            side INTEGER,
            shares INTEGER,
            price REAL,
            status INTEGER,
            created INTEGER,
            filled INTEGER DEFAULT 0
        )
    ]])
    
    -- Create indices for performance
    sql.Query("CREATE INDEX IF NOT EXISTS idx_positions_steamid ON stockmarket_positions(steam_id)")
    sql.Query("CREATE INDEX IF NOT EXISTS idx_history_ticker ON stockmarket_history(ticker, timestamp)")
    sql.Query("CREATE INDEX IF NOT EXISTS idx_transactions_steamid ON stockmarket_transactions(steam_id)")
    sql.Query("CREATE INDEX IF NOT EXISTS idx_orders_steamid ON stockmarket_orders(steam_id)")
    sql.Query("CREATE INDEX IF NOT EXISTS idx_gpos_gid ON stockmarket_group_positions(group_id)")
    sql.Query("CREATE INDEX IF NOT EXISTS idx_gpos_gid_tkr ON stockmarket_group_positions(group_id, ticker)")
    sql.Query("CREATE INDEX IF NOT EXISTS idx_gmem_gid ON stockmarket_group_members(group_id)")
    sql.Query("CREATE INDEX IF NOT EXISTS idx_gmem_sid ON stockmarket_group_members(steam_id)")
end

function StockMarket.Database:Query(query, ...)
    local formatted = sql.Query(string.format(query, ...))
    if formatted == false then
        ErrorNoHalt("[StockMarket] SQL Error: " .. sql.LastError() .. "\n")
        return nil
    end
    return formatted
end

function StockMarket.Database:Escape(str)
    return sql.SQLStr(str)
end
