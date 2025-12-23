-- ========================================
-- Chat Commands
-- ========================================

-- CLIENT: UI commands typed by the local player
if CLIENT then
    -- Utility: safe-open UI only if library exists
    local function SafeOpenMain()
        if StockMarket and StockMarket.UI and StockMarket.UI.OpenMainFrame then
            StockMarket.UI.OpenMainFrame()
        else
            chat.AddText(Color(255,100,100), "[StockMarket] UI not ready yet.")
        end
    end

    local function SafeOpenTicker(ticker)
        if StockMarket and StockMarket.UI and StockMarket.UI.OpenTickerView then
            StockMarket.UI.OpenTickerView(ticker)
        else
            chat.AddText(Color(255,100,100), "[StockMarket] UI not ready yet.")
        end
    end

    hook.Add("OnPlayerChat", "StockMarket_Commands", function(ply, text)
        -- Only handle the local player's own message
        if not IsValid(ply) or ply ~= LocalPlayer() then return end

        text = string.Trim(text or "")
        if text == "" then return end

        local lower = string.lower(text)

        -- Open main panel
        if lower == "!stocks" or lower == "/stocks" then
            SafeOpenMain()
            return true -- suppress drawing of your message locally
        end

        -- Open and focus portfolio tab (if implemented)
        if lower == "!portfolio" or lower == "/portfolio" then
            SafeOpenMain()
            timer.Simple(0.05, function()
                if IsValid(StockMarket.UI.MainFrame) and StockMarket.UI.MainFrame.tabButtons and StockMarket.UI.MainFrame.tabButtons["portfolio"] then
                    -- if you implement tab switching, do it here
                end
            end)
            return true
        end

        -- Open specific ticker: "!stock TKR" or "/stock TKR"
        if string.StartWith(lower, "!stock ") or string.StartWith(lower, "/stock ") then
            -- split on first space
            local sp = string.find(text, " ")
            if sp then
                local arg = string.Trim(string.sub(text, sp + 1))
                if arg ~= "" then
                    SafeOpenTicker(string.upper(arg))
                    return true
                end
            end
        end
    end)

    -- Optional: allow server to tell us to open admin UI
    net.Receive("StockMarket_OpenAdminUI", function()
        if not LocalPlayer():IsSuperAdmin() then return end
        if StockMarket and StockMarket.UI and StockMarket.UI.Admin and StockMarket.UI.Admin.Open then
            StockMarket.UI.Admin.Open()
        end
    end)
end

-- SERVER: privileged commands and server-side chat interception
if SERVER then
    util.AddNetworkString("StockMarket_OpenAdminUI")

    hook.Add("PlayerSay", "StockMarket_AdminPanelCommand", function(ply, text)
        text = tostring(text or "")
        local lower = string.lower(string.Trim(text))

        if lower == "!smadmin" or lower == "/smadmin" then
            if IsValid(ply) and ply:IsSuperAdmin() then
                -- Ask client to open admin UI (safer than forcing ConCommand)
                net.Start("StockMarket_OpenAdminUI")
                net.Send(ply)
            else
                ply:ChatPrint("[StockMarket] Superadmin only.")
            end
            return "" -- swallow the message server-wide so others don't see it
        end
    end)
end
