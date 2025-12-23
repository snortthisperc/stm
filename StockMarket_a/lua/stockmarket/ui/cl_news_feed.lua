-- ========================================
-- News Feed & Event Alerts
-- ========================================

StockMarket.UI.NewsFeed = {}
StockMarket.UI.NewsFeed.Items = {}
StockMarket.UI.NewsFeed.ActiveAlert = nil
StockMarket.UI.NewsFeed.ActivePanels = StockMarket.UI.NewsFeed.ActivePanels or {}

local SM_IconNews = Material("stockmarket/icons/news.png", "smooth")

function StockMarket.UI.NewsFeed:AddItem(message, ticker, isPreAlert)
    table.insert(self.Items, 1, {
        message = message,
        ticker = ticker,
        timestamp = os.time(),
        isPreAlert = isPreAlert
    })
    if #self.Items > 50 then table.remove(self.Items) end

    for _, pnl in ipairs(self.ActivePanels or {}) do
        if IsValid(pnl) and pnl.Refresh then pnl:Refresh() end
    end
end

function StockMarket.UI.NewsFeed:ShowAlert(message, ticker)
    self.ActiveAlert = {
        message = message,
        ticker = ticker,
        createdAt = CurTime(),
        duration = 8,
        alpha = 0
    }
    
    if StockMarket.Config.EnableSounds then
        surface.PlaySound("stockmarket/news_alert.wav")
    end
end

function StockMarket.UI.NewsFeed:DrawAlert()
    if not self.ActiveAlert then return end
    
    local alert = self.ActiveAlert
    local elapsed = CurTime() - alert.createdAt
    
    if elapsed > alert.duration then
        self.ActiveAlert = nil
        return
    end
    
    -- Fade animation
    if elapsed < 0.5 then
        alert.alpha = Lerp(elapsed / 0.5, 0, 255)
    elseif elapsed > alert.duration - 1 then
        alert.alpha = Lerp((alert.duration - elapsed) / 1, 0, 255)
    else
        alert.alpha = 255
    end
    
    local w = 600
    local h = 120
    local x = ScrW()/2 - w/2
    local y = 100
    
    -- Background with glow
    draw.RoundedBox(12, x - 4, y - 4, w + 8, h + 8, ColorAlpha(StockMarket.UI.Colors.Primary, alert.alpha * 0.3))
    draw.RoundedBox(12, x, y, w, h, ColorAlpha(StockMarket.UI.Colors.BackgroundLight, alert.alpha))

        -- Optional small icon next to title
    if SM_IconNews then
        surface.SetMaterial(SM_IconNews)
        surface.SetDrawColor(255, 255, 255, alert.alpha)
        surface.DrawTexturedRect(x + 18, y + 18, 20, 20)
    end
    
    -- Title
    draw.SimpleText("BREAKING NEWS", "StockMarket_SubtitleFont", x + w/2, y + 20, 
        ColorAlpha(StockMarket.UI.Colors.Primary, alert.alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
    
    -- Message
    draw.DrawText(alert.message, "StockMarket_TextFont", x + 20, y + 55, 
        ColorAlpha(StockMarket.UI.Colors.TextPrimary, alert.alpha), TEXT_ALIGN_LEFT)
    
    -- Ticker badge
    draw.RoundedBox(6, x + w - 90, y + h - 35, 70, 25, ColorAlpha(StockMarket.UI.Colors.Primary, alert.alpha))
    draw.SimpleText(alert.ticker, "StockMarket_SmallFont", x + w - 55, y + h - 22, 
        ColorAlpha(StockMarket.UI.Colors.TextPrimary, alert.alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
    -- Click to view button
    draw.SimpleText("Click to view stock →", "StockMarket_SmallFont", x + 20, y + h - 22, 
        ColorAlpha(StockMarket.UI.Colors.TextSecondary, alert.alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

function StockMarket.UI.NewsFeed:CreatePanel(parent)
    local page = vgui.Create("DPanel", parent)
    page:Dock(FILL)
    page:DockMargin(20, 20, 20, 20)
    page.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, StockMarket.UI.Colors.Background)
    end

    -- Header
    local header = vgui.Create("DPanel", page)
    header:Dock(TOP)
    header:SetTall(50)
    header:DockMargin(0, 0, 0, 10)
    header.Paint = function(self, w, h)
        -- replace your header.Paint with this
        draw.RoundedBox(8, 0, 0, w, h, StockMarket.UI.Colors.BackgroundLight)
        draw.SimpleText("Market News", "StockMarket_SubtitleFont", 15, h/2,
            StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        local count = #StockMarket.UI.NewsFeed.Items
        local badgeText = string.format("Latest %d", count)
        surface.SetFont("StockMarket_SmallFont")
        local tw, th = surface.GetTextSize(badgeText)
        local badgeW, badgeH = tw + 16, th + 8
        local bx, by = w - badgeW - 12, h/2 - badgeH/2

        draw.RoundedBox(6, bx, by, badgeW, badgeH, StockMarket.UI.Colors.Primary)
        draw.SimpleText(badgeText, "StockMarket_SmallFont", bx + badgeW/2, h/2,
            StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Filters (optional)
    local filterPanel = vgui.Create("DPanel", page)
    filterPanel:Dock(TOP)
    filterPanel:SetTall(40)
    filterPanel:DockMargin(0, 0, 0, 10)
    filterPanel.Paint = nil

    local activeFilter = "all" -- "all" | "pre" | "alert"

    local function addFilter(name, key)
        local btn = vgui.Create("DButton", filterPanel)
        btn:Dock(LEFT)
        btn:DockMargin(0, 0, 10, 0)
        btn:SetWide(100)
        btn:SetText("")
        btn.Paint = function(self, w, h)
            local active = (activeFilter == key)
            draw.RoundedBox(6, 0, 0, w, h, active and StockMarket.UI.Colors.Primary or StockMarket.UI.Colors.BackgroundLight)
            draw.SimpleText(name, "StockMarket_SmallFont", w/2, h/2, StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        btn.DoClick = function()
            activeFilter = key
            if list and list.Refresh then list:Refresh() end
        end
        return btn
    end

    addFilter("All", "all")
    addFilter("Alerts", "alert")
    addFilter("Pre-Alerts", "pre")

    -- Scroll list
    local list = StockMarket.UI.Lib:ScrollPanel(page)
    list:Dock(FILL)
    list:DockMargin(0, 0, 0, 0)

    -- Track panel so AddItem can auto-refresh
    table.insert(StockMarket.UI.NewsFeed.ActivePanels, list)
    list.OnRemove = function()
        for i, pnl in ipairs(StockMarket.UI.NewsFeed.ActivePanels) do
            if pnl == list then table.remove(StockMarket.UI.NewsFeed.ActivePanels, i) break end
        end
    end

    -- Empty placeholder
    local function addEmpty()
        local empty = vgui.Create("DPanel", list)
        empty:Dock(TOP)
        empty:SetTall(200)
        empty:DockMargin(0, 10, 0, 0)
        empty.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, StockMarket.UI.Colors.BackgroundLight)
            draw.SimpleText("No news yet", "StockMarket_TextFont", w/2, h/2 - 10, StockMarket.UI.Colors.TextMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Alerts and pre-alerts will appear here when market events happen.", "StockMarket_SmallFont", w/2, h/2 + 18, StockMarket.UI.Colors.TextSecondary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    -- Item row builder
    local function addItemRow(item)
        local row = StockMarket.UI.Lib:Panel(list)
        row:Dock(TOP)
        row:SetTall(80)
        row:DockMargin(0, 0, 0, 10)

        -- Clickable: open ticker
        row:SetCursor("hand")
        row.OnMousePressed = function(self, m)
            if m == MOUSE_LEFT then
                StockMarket.UI.OpenMainFrame(item.ticker)
            end
        end

        row.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, StockMarket.UI.Colors.BackgroundLight)

            local when = os.date("%H:%M", item.timestamp)
            draw.SimpleText(when, "StockMarket_SmallFont", 15, 12, StockMarket.UI.Colors.TextMuted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

            -- Message
            local msg = item.isPreAlert and ("Pre-Alert: " .. item.message) or item.message
            draw.DrawText(msg, "StockMarket_TextFont", 15, 34, StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_LEFT)

            -- Ticker tag
            local ticker = item.ticker or "TICK"
            surface.SetFont("StockMarket_SmallFont")
            local tw, th = surface.GetTextSize(ticker)
            local tagW, tagH = tw + 12, th + 8
            local tx, ty = w - tagW - 12, h - tagH - 12
            draw.RoundedBox(6, tx, ty, tagW, tagH, StockMarket.UI.Colors.Primary)
            draw.SimpleText(ticker, "StockMarket_SmallFont", tx + tagW/2, ty + tagH/2, StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    function list:Refresh()
        self:Clear()

        -- Filter items
        local items = StockMarket.UI.NewsFeed.Items or {}
        local filtered = {}
        if activeFilter == "all" then
            filtered = items
        elseif activeFilter == "alert" then
            for _, it in ipairs(items) do if not it.isPreAlert then table.insert(filtered, it) end end
        elseif activeFilter == "pre" then
            for _, it in ipairs(items) do if it.isPreAlert then table.insert(filtered, it) end end
        end

        if #filtered == 0 then
            addEmpty()
            return
        end

        for _, it in ipairs(filtered) do
            addItemRow(it)
        end
    end

    list:Refresh()
    return page
end

hook.Add("HUDPaint", "StockMarket_DrawNewsAlert", function()
    StockMarket.UI.NewsFeed:DrawAlert()
end)

-- Network receivers
net.Receive("StockMarket_EventAlert", function()
    local message = net.ReadString()
    local ticker = net.ReadString()
    local isHalt = net.ReadBool()
    
    StockMarket.UI.NewsFeed:AddItem(message, ticker, false)
    StockMarket.UI.NewsFeed:ShowAlert(message, ticker)
end)

net.Receive("StockMarket_EventPreAlert", function()
    local message = net.ReadString()
    local ticker = net.ReadString()
    
    StockMarket.UI.NewsFeed:AddItem("PRE-ALERT: " .. message, ticker, true)
    StockMarket.UI.Notifications:Add("Market alert incoming for " .. ticker, "warning", 5)
end)

-- Click alert to open stock
hook.Add("GUIMousePressed", "StockMarket_ClickAlert", function(mouseCode)
    if mouseCode ~= MOUSE_LEFT then return end
    if not StockMarket.UI.NewsFeed.ActiveAlert then return end
    
    local alert = StockMarket.UI.NewsFeed.ActiveAlert
    local w, h = 600, 120
    local x, y = ScrW()/2 - w/2, 100
    local mx, my = gui.MousePos()
    
    if mx >= x and mx <= x + w and my >= y and my <= y + h then
        StockMarket.UI.OpenMainFrame(alert.ticker)
        StockMarket.UI.NewsFeed.ActiveAlert = nil
        return true
    end
end)
