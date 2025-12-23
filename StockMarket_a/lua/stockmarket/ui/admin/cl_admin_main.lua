-- ========================================
-- Admin Panel - Reuse Main Shell
-- ========================================
if not CLIENT then return end

StockMarket.UI = StockMarket.UI or {}
StockMarket.UI.Admin = StockMarket.UI.Admin or {}

-- Console command for superadmin
concommand.Add("sm_admin", function()
    local lp = LocalPlayer()
    if not IsValid(lp) or not lp:IsSuperAdmin() then
        chat.AddText(Color(255,100,100), "[StockMarket] Superadmin only.")
        return
    end
    StockMarket.UI.Admin.Open()
end)

function StockMarket.UI.Admin.Open()
    if IsValid(StockMarket.UI.Admin.Frame) then
        StockMarket.UI.Admin.Frame:Close()
    end

    local frame = vgui.Create("DFrame")
    frame:SetSize(ScrW() * 0.85, ScrH() * 0.85)
    frame:Center()
    frame:SetTitle("")
    frame:SetDraggable(true)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    StockMarket.UI.Admin.Frame = frame

    -- Exact same paint as main shell + small ADMIN badge
    frame.Paint = function(self, w, h)
        draw.RoundedBox(12, 0, 0, w, h, StockMarket.UI.Colors.Background)
        draw.RoundedBoxEx(12, 0, 0, w, 60, StockMarket.UI.Colors.BackgroundLight, true, true, false, false)
        draw.SimpleText("Stock Market Terminal", "StockMarket_TitleFont", 20, 30,
            StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- ADMIN pill
        local badge = "ADMIN"
        surface.SetFont("StockMarket_SmallFont")
        local tw, th = surface.GetTextSize(badge)
        local bx, by = 260, 30 - (th + 8)/2
        draw.RoundedBox(6, bx, by, tw + 16, th + 8, StockMarket.UI.Colors.Danger)
        draw.SimpleText(badge, "StockMarket_SmallFont", bx + (tw + 16)/2, by + (th + 8)/2,
            StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Close button (same as main)
    local closeBtn = vgui.Create("DButton", frame)
    closeBtn:SetSize(40, 40)
    closeBtn:SetPos(frame:GetWide() - 50, 10)
    closeBtn:SetText("")
    closeBtn.hovered = false
    closeBtn.Paint = function(self, w, h)
        local col = self.hovered and StockMarket.UI.Colors.Danger or StockMarket.UI.Colors.BackgroundDark
        draw.RoundedBox(6, 0, 0, w, h, col)
        draw.SimpleText("X", "StockMarket_SubtitleFont", w/2, h/2, StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    closeBtn.OnCursorEntered = function(self) self.hovered = true end
    closeBtn.OnCursorExited = function(self) self.hovered = false end
    closeBtn.DoClick = function() frame:Close() end

    -- Navigation panel (same as main)
    local navPanel = vgui.Create("DPanel", frame)
    navPanel:SetSize(200, frame:GetTall() - 80)
    navPanel:SetPos(10, 70)
    navPanel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, StockMarket.UI.Colors.BackgroundLight)
    end

    -- Content panel (same as main)
    local contentPanel = vgui.Create("DPanel", frame)
    contentPanel:SetSize(frame:GetWide() - 230, frame:GetTall() - 80)
    contentPanel:SetPos(220, 70)
    contentPanel.Paint = nil

    -- Admin tabs reuse TabButton and icon paths
    local tabs = {
        {name = "Stocks",   icon = "stockmarket/icons/statistics.png", view = "admin_stocks"},
        {name = "Stats",    icon = "stockmarket/icons/portfolio.png",  view = "admin_stats"},
        {name = "Events",   icon = "stockmarket/icons/news.png",       view = "admin_events"},
    }

    local tabButtons = {}
    local function ShowView(viewName)
        contentPanel:Clear()
        if viewName == "admin_stocks" then
            if StockMarket.UI.Admin.Stocks then
                StockMarket.UI.Admin.Stocks(contentPanel, {
                    Background = StockMarket.UI.Colors.Background,
                    BackgroundLight = StockMarket.UI.Colors.BackgroundLight,
                    Primary = StockMarket.UI.Colors.Primary,
                    PrimaryHover = StockMarket.UI.Colors.PrimaryHover,
                    TextPrimary = StockMarket.UI.Colors.TextPrimary,
                    TextSecondary = StockMarket.UI.Colors.TextSecondary
                })
            end
        elseif viewName == "admin_stats" then
            if StockMarket.UI.Admin.Stats then
                StockMarket.UI.Admin.Stats(contentPanel, {
                    Background = StockMarket.UI.Colors.Background,
                    BackgroundLight = StockMarket.UI.Colors.BackgroundLight,
                    Primary = StockMarket.UI.Colors.Primary,
                    PrimaryHover = StockMarket.UI.Colors.PrimaryHover,
                    TextPrimary = StockMarket.UI.Colors.TextPrimary,
                    TextSecondary = StockMarket.UI.Colors.TextSecondary
                })
            end
        elseif viewName == "admin_events" then
            if StockMarket.UI.Admin.Events then
                StockMarket.UI.Admin.Events(contentPanel, {
                    Background = StockMarket.UI.Colors.Background,
                    BackgroundLight = StockMarket.UI.Colors.BackgroundLight,
                    Primary = StockMarket.UI.Colors.Primary,
                    PrimaryHover = StockMarket.UI.Colors.PrimaryHover,
                    TextPrimary = StockMarket.UI.Colors.TextPrimary,
                    TextSecondary = StockMarket.UI.Colors.TextSecondary
                })
            end
        end
        for _, b in pairs(tabButtons) do b.active = false end
    end

    for i, tab in ipairs(tabs) do
        local btn = StockMarket.UI.Lib:TabButton(navPanel, tab.name, tab.icon)
        btn:SetSize(180, 50)
        btn:SetPos(10, 10 + (i - 1) * 60)
        btn.viewName = tab.view
        btn.DoClick = function(self)
            ShowView(self.viewName)
            for _, b in pairs(tabButtons) do b.active = false end
            self.active = true
        end
        tabButtons[tab.view] = btn
    end

    -- Default open
    tabButtons["admin_stocks"].active = true
    ShowView("admin_stocks")
end
