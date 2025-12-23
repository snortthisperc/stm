-- ========================================
-- Network String Registry (Shared include; server registers)
-- ========================================

if SERVER then
    local netStrings = {
        -- Stock updates
        "StockMarket_PriceUpdate",
        "StockMarket_FullSync",
        "StockMarket_EventAlert",
        "StockMarket_EventPreAlert",

        -- Trading
        "StockMarket_PlaceOrder",
        "StockMarket_OrderFilled",
        "StockMarket_OrderRejected",
        "StockMarket_PortfolioUpdate",

        -- Groups
        "StockMarket_CreateGroup",
        "StockMarket_JoinGroup",
        "StockMarket_LeaveGroup",
        "StockMarket_GroupUpdate",
        "StockMarket_GroupTrade",

        -- UI requests / data
        "StockMarket_RequestHistory",
        "StockMarket_HistoryData",
        "StockMarket_RequestPortfolio",
        "StockMarket_BarSnapshot", -- ADDED: live bar buy/sell/volume snapshot


        -- Admin
        "StockMarket_AdminAction",
        "StockMarket_AdminUpdate",
        "StockMarket_ConfigChanged",
        "StockMarket_Admin_GetState",
        "StockMarket_Admin_State",
        "StockMarket_Markets_GetState",
        "StockMarket_Markets_State",


        -- DarkRP integration
        "StockMarket_DarkRP_Deposit",
        "StockMarket_DarkRP_Withdraw"
    }

    for _, str in ipairs(netStrings) do
        util.AddNetworkString(str)
    end
end

if SERVER then print("[StockMarket] Networking registered") end
