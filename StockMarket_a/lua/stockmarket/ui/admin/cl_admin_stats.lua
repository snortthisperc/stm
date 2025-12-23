-- ========================================
-- Admin Panel - Server Stats & Player Portfolios (Enhanced, Polished)
-- ========================================

if not CLIENT then return end

StockMarket.UI.Admin = StockMarket.UI.Admin or {}

-- Cache trend icons
local MatUp   = Material("stockmarket/icons/up_trend.png", "smooth")
local MatDown = Material("stockmarket/icons/down_trend.png", "smooth")

-- Pill utility (kept for other uses)
local function DrawPill(x, y, text, bg, fg, padX, padY, font)
    font = font or "StockMarket_SmallFont"
    padX = padX or 10
    padY = padY or 6
    surface.SetFont(font)
    local tw, th = surface.GetTextSize(text or "")
    local w, h = tw + padX, th + padY
    draw.RoundedBox(6, x, y, w, h, bg or Color(55, 65, 81))
    draw.SimpleText(text or "", font, x + w/2, y + h/2, fg or color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    return w, h
end

-- StatCard draws a top-right accent. Now supports icon accent (up/down).
-- Accent function may return:
--  - nil to draw nothing
--  - { sign = 1|-1, color = Color } to draw icon
--  - or legacy: { label = "txt", color = Color } to draw pill text (fallback)
local function StatCard(parent, label, value, C, accentFn)
    local card = vgui.Create("DPanel", parent)
    card:SetTall(86)
    card:Dock(LEFT)
    card:DockMargin(0, 0, 12, 0)
    card.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, C.BackgroundLight)
        draw.SimpleText(label, "StockMarket_SmallFont", 12, 10, C.TextSecondary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(value(), "StockMarket_TitleFont", 12, 35, C.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        if accentFn then
            local a = accentFn()
            if a then
                -- New icon mode
                if a.sign and (a.sign == 1 or a.sign == -1) then
                    local ic = (a.sign == 1) and MatUp or MatDown
                    local col = a.color or color_white
                    local s = 18
                    surface.SetMaterial(ic)
                    surface.SetDrawColor(col.r or 255, col.g or 255, col.b or 255, 255)
                    surface.DrawTexturedRect(w - s - 10, 10, s, s)
                -- Legacy text mode fallback
                elseif a.label then
                    local txt = tostring(a.label)
                    local bg = a.color or C.Primary
                    surface.SetFont("StockMarket_SmallFont")
                    local tw, th = surface.GetTextSize(txt)
                    local pw, ph = tw + 12, th + 6
                    DrawPill(w - pw - 10, 10, txt, bg, color_white, 12, 6, "StockMarket_SmallFont")
                end
            end
        end
    end
    return card
end

function StockMarket.UI.Admin.Stats(content, C)
    -- THEME short-hands
    local BG       = C.Background or StockMarket.UI.Colors.Background
    local BG_L     = C.BackgroundLight or StockMarket.UI.Colors.BackgroundLight
    local TEXT     = C.TextPrimary or StockMarket.UI.Colors.TextPrimary
    local TEXT2    = C.TextSecondary or StockMarket.UI.Colors.TextSecondary
    local PRIMARY  = C.Primary or StockMarket.UI.Colors.Primary
    local SUCCESS  = StockMarket.UI.Colors.Success
    local DANGER   = StockMarket.UI.Colors.Danger

    -- Top row: server stats
    local top = vgui.Create("DPanel", content)
    top:Dock(TOP)
    top:SetTall(100)
    top:DockMargin(0,0,0,10)
    top.Paint = nil

    local stats = {
        { "Total Server Value",
          function() return (StockMarket.UI._AdminStats and StockMarket.UI._AdminStats.totalValueText) or "$0" end },

        { "Online DarkRP Money",
          function() return (StockMarket.UI._AdminStats and StockMarket.UI._AdminStats.onlineDarkRPText) or "$0" end,
          function() return { label = "LIVE", color = Color(59,130,246) } end },

        { "Avg Realized P/L",
          function() return (StockMarket.UI._AdminStats and StockMarket.UI._AdminStats.avgRealizedText) or "$0" end,
          function()
              if not StockMarket.UI._AdminStats then return end
              local v = (StockMarket.UI._AdminStats.avgRealizedRaw or 0)
              return {
                  sign = (v >= 0) and 1 or -1,
                  color = (v >= 0) and Color(34,197,94) or Color(239,68,68)
              }
          end },

        { "Avg Unrealized P/L",
          function() return (StockMarket.UI._AdminStats and StockMarket.UI._AdminStats.avgUnrealizedText) or "$0" end,
          function()
              if not StockMarket.UI._AdminStats then return end
              local v = (StockMarket.UI._AdminStats.avgUnrealizedRaw or 0)
              return {
                  sign = (v >= 0) and 1 or -1,
                  color = (v >= 0) and Color(34,197,94) or Color(239,68,68)
              }
          end },
    }

    for _, s in ipairs(stats) do
        local card = vgui.Create("DPanel", top)
        card:SetTall(86)
        card:Dock(LEFT)
        card:DockMargin(0, 0, 12, 0)
        card.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, C.BackgroundLight)
            draw.SimpleText(s[1], "StockMarket_SmallFont", 12, 10, C.TextSecondary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(s[2](), "StockMarket_TitleFont", 12, 35, C.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            local accentFn = s[3]
            if accentFn then
                local a = accentFn()
                if a then
                    if a.sign and (a.sign == 1 or a.sign == -1) then
                        local ic = (a.sign == 1) and Material("stockmarket/icons/up_trend.png", "smooth")
                                                    or Material("stockmarket/icons/down_trend.png", "smooth")
                        local col = a.color or color_white
                        local sz = 18
                        surface.SetMaterial(ic)
                        surface.SetDrawColor(col.r or 255, col.g or 255, col.b or 255, 255)
                        surface.DrawTexturedRect(w - sz - 10, 10, sz, sz)
                    elseif a.label then
                        local txt = tostring(a.label)
                        local bg = a.color or C.Primary
                        surface.SetFont("StockMarket_SmallFont")
                        local tw, th = surface.GetTextSize(txt)
                        local pw, ph = tw + 12, th + 6
                        draw.RoundedBox(6, w - pw - 10, 10, pw, ph, bg)
                        draw.SimpleText(txt, "StockMarket_SmallFont", w - pw/2 - 10, 10 + ph/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                end
            end
        end
        card:SetWide((content:GetWide() - 36) / 4)
    end

    -- Main list area for online players (safe reference to avoid NULL panel on async net)
    local list = vgui.Create("DScrollPanel", content)
    list:Dock(FILL)
    content._playersList = list -- keep ref on content to validate in net callbacks

    -- Request server stats & online players
    net.Start("StockMarket_Admin_GetServerStats")
    net.SendToServer()

    net.Start("StockMarket_Admin_PlayerList")
    net.SendToServer()

    -- Apply stats (top counters)
    net.Receive("StockMarket_Admin_GetServerStats", function()
        local t = {
            totalValueText = net.ReadString(),
            onlineDarkRPText = net.ReadString(),
            avgRealizedText = net.ReadString(),
            avgUnrealizedText = net.ReadString(),
            avgRealizedRaw = net.ReadFloat(),
            avgUnrealizedRaw = net.ReadFloat(),
        }
        StockMarket.UI._AdminStats = t

        if StockMarket.UI._AdminStatsPanel and IsValid(StockMarket.UI._AdminStatsPanel) then
            StockMarket.UI._AdminStatsPanel:_refresh(t)
        end
    end)

    -- Player list (safe against view switches)
    net.Receive("StockMarket_Admin_PlayerList", function()
        local count = net.ReadUInt(16) or 0
        local players = {}
        for i = 1, count do
            players[i] = {
                name = net.ReadString(),
                steamid = net.ReadString(),
                net = net.ReadString()
            }
        end

        -- Resolve the current list safely
        local host = content
        local targetList = IsValid(host) and host._playersList
        if not IsValid(targetList) then return end

        targetList:Clear()

        for _, p in ipairs(players) do
            local row = vgui.Create("DPanel", targetList)
            row:SetTall(78)
            row:Dock(TOP)
            row:DockMargin(0,0,0,8)
            row.Paint = function(self, w, h)
                draw.RoundedBox(8, 0, 0, w, h, C.BackgroundLight)
                draw.SimpleText(p.name .. " (".. p.steamid ..")", "StockMarket_TextFont", 12, 10, C.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                draw.SimpleText("Net Worth: ".. p.net, "StockMarket_SmallFont", 12, 40, C.TextSecondary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            end

            local view = vgui.Create("DButton", row)
            view:SetText("")
            view:SetWide(80)
            view:Dock(RIGHT)
            local hov = false
            view.Paint = function(self,w,h)
                draw.RoundedBox(6, 0, 0, w, h, hov and C.PrimaryHover or C.Primary)
                draw.SimpleText("View", "StockMarket_ButtonFont", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            view.OnCursorEntered = function() hov = true end
            view.OnCursorExited = function() hov = false end
            view.DoClick = function()
                net.Start("StockMarket_Admin_GetPortfolio")
                net.WriteString(p.steamid)
                net.SendToServer()
            end

            local rollback = vgui.Create("DButton", row)
            rollback:SetText("")
            rollback:SetWide(120)
            rollback:Dock(RIGHT)
            rollback:DockMargin(6,0,0,0)
            local hov2 = false
            rollback.Paint = function(self,w,h)
                draw.RoundedBox(6, 0, 0, w, h, hov2 and C.PrimaryHover or C.Primary)
                draw.SimpleText("Rollback", "StockMarket_ButtonFont", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            rollback.OnCursorEntered = function() hov2 = true end
            rollback.OnCursorExited = function() hov2 = false end
            rollback.DoClick = function()
                Derma_Query("Rollback this player's portfolio to the last restart snapshot?", "Confirm", "Rollback", function()
                    net.Start("StockMarket_Admin_RollbackPlayer")
                    net.WriteString(p.steamid)
                    net.SendToServer()
                end, "Cancel")
            end
        end
    end)

    -- ============================
    -- Player Portfolio Modal (final polished)
    -- ============================
    net.Receive("StockMarket_Admin_GetPortfolio", function()
        local pdata = {
            net        = net.ReadString(),
            realized   = net.ReadFloat(),
            unrealized = net.ReadFloat(),
            steamid    = net.ReadString()
        }

        local positions = {}
        local pcount = net.ReadUInt(16) or 0
        for i = 1, pcount do
            positions[i] = {
                ticker      = net.ReadString(),
                shares      = net.ReadInt(32),
                avgCost     = net.ReadFloat(),
                price       = net.ReadString(),
                marketValue = net.ReadFloat(),
                unrealized  = net.ReadFloat()
            }
        end
        pdata.positions = positions

        -- THEME short-hands
        local BG       = (C and C.Background)      or StockMarket.UI.Colors.Background
        local BG_L     = (C and C.BackgroundLight) or StockMarket.UI.Colors.BackgroundLight
        local BG_D     = StockMarket.UI.Colors.BackgroundDark
        local TEXT     = (C and C.TextPrimary)     or StockMarket.UI.Colors.TextPrimary
        local TEXT2    = (C and C.TextSecondary)   or StockMarket.UI.Colors.TextSecondary
        local PRIMARY  = (C and C.Primary)         or StockMarket.UI.Colors.Primary
        local SUCCESS  = StockMarket.UI.Colors.Success
        local DANGER   = StockMarket.UI.Colors.Danger

        local function Num(n) return StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(tonumber(n) or 0, 2)) end

        -- Window
        local win = vgui.Create("DFrame")
        local W = math.Clamp(ScrW() * 0.86, 1100, 1600)
        local H = math.Clamp(ScrH() * 0.88, 720, 960)
        win:SetSize(W, H)
        win:Center()
        win:SetTitle("")
        win:MakePopup()
        win.Paint = function(self, w, h)
            draw.RoundedBox(12, 0, 0, w, h, BG)

            -- Header bar: title only (no summary here)
            local headerH = 64
            draw.RoundedBoxEx(12, 0, 0, w, headerH, BG_L, true, true, false, false)
            draw.SimpleText("Player Portfolio", "StockMarket_SubtitleFont", 16, headerH / 2, TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            -- SteamID/Player badge (right)
            surface.SetFont("StockMarket_SmallFont")
            local idText = tostring(pdata.steamid or "N/A")
            local tw, th = surface.GetTextSize(idText)
            local pad = 8
            local bx, by, bw, bh = w - (tw + pad*3), (headerH/2) - (th + pad)/2, tw + pad*2, th + pad
            draw.RoundedBox(6, bx, by, bw, bh, PRIMARY)
            draw.SimpleText(idText, "StockMarket_SmallFont", bx + bw/2, by + bh/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local spacer = vgui.Create("DPanel", win)
        spacer:Dock(TOP)
        spacer:SetTall(50)                   -- small but guarantees separation
        spacer:DockMargin(0, 0, 0, 0)
        spacer.Paint = nil

        -- Summary (separate row below header, preventing overlap)
        local summary = vgui.Create("DPanel", win)
        summary:Dock(TOP)
        summary:SetTall(90)
        summary:DockMargin(12, 6, 12, 0)    -- 6 px top margin after spacer ensures clean separation
        summary.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, BG_L)

            -- Left: Net Worth
            draw.SimpleText("Net Worth", "StockMarket_SmallFont", 16, 10, TEXT2)
            draw.SimpleText(pdata.net or "$0", "StockMarket_TitleFont", 16, 30, TEXT)

            -- Right: pills (Positions, Realized, Unrealized)
            local px = w - 12
            local function pillRight(text, col)
                surface.SetFont("StockMarket_SmallFont")
                local tw, th = surface.GetTextSize(text or "")
                local pw, ph = tw + 12, th + 6
                px = px - pw
                draw.RoundedBox(6, px, h - ph - 12, pw, ph, col or Color(55,65,81))
                draw.SimpleText(text, "StockMarket_SmallFont", px + pw/2, h - ph - 12 + ph/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                px = px - 8
            end

            local rv = tonumber(pdata.realized) or 0
            local uv = tonumber(pdata.unrealized) or 0
            pillRight("Unrealized " .. (StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(uv, 2))), uv >= 0 and SUCCESS or DANGER)
            pillRight("Realized " .. (StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(rv, 2))), rv >= 0 and SUCCESS or DANGER)
            pillRight(("Positions %d"):format(#pdata.positions), Color(55,65,81))
        end

        -- Scroll container (leave space for footer)
        local scroll = vgui.Create("DScrollPanel", win)
        scroll:Dock(FILL)
        scroll:DockMargin(12, 8, 12, 60)
        local sbar = scroll:GetVBar()
        sbar:SetWide(8)
        sbar.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, BG_D) end
        sbar.btnGrip.Paint = function(self, w, h) draw.RoundedBox(4, 0, 0, w, h, PRIMARY) end
        sbar.btnUp.Paint = function() end
        sbar.btnDown.Paint = function() end

        -- Stack container recalculates own height
        local stack = vgui.Create("DPanel", scroll)
        stack:Dock(TOP)
        stack:DockMargin(0, 0, 0, 0)
        stack:SetTall(0)
        stack.Paint = nil
        function stack:PerformLayout()
            local total = 0
            for _, child in ipairs(self:GetChildren()) do
                if IsValid(child) then
                    total = total + child:GetTall()
                    local l,t,r,b = child:GetDockMargin()
                    total = total + t + b
                end
            end
            self:SetTall(total)
        end
        function stack:OnChildAdded() self:InvalidateLayout(true) end
        function stack:OnChildRemoved() self:InvalidateLayout(true) end

        -- Action helpers (kebab menu)
        local function OpenAdjustDialog(kind, steamid, ticker)
            local title = (kind == "set_shares") and "Set Shares" or "Set Avg Cost"
            local dlg = vgui.Create("DFrame")
            dlg:SetSize(360, 180); dlg:Center(); dlg:SetTitle(title); dlg:MakePopup()
            local entry = vgui.Create("DTextEntry", dlg)
            entry:Dock(FILL); entry:DockMargin(12, 12, 12, 50); entry:SetText("")
            local ok = vgui.Create("DButton", dlg)
            ok:Dock(BOTTOM); ok:SetTall(30); ok:SetText("Apply")
            ok.DoClick = function()
                local val = tonumber(entry:GetValue())
                if not val then chat.AddText(Color(255,100,100), "[StockMarket] Enter a number"); return end
                net.Start("StockMarket_Admin_AdjustPosition")
                net.WriteString(steamid or "")
                net.WriteString(ticker or "")
                net.WriteString(kind)
                net.WriteFloat(val)
                net.SendToServer()
                dlg:Close()
                timer.Simple(0.15, function()
                    net.Start("StockMarket_Admin_GetPortfolio")
                    net.WriteString(steamid or "")
                    net.SendToServer()
                end)
            end
        end

        local function DoForceSell(steamid, ticker)
            Derma_Query("Force sell ALL shares of ".. (ticker or "?") .." ?", "Confirm", "Sell All", function()
                net.Start("StockMarket_Admin_AdjustPosition")
                net.WriteString(steamid or "")
                net.WriteString(ticker or "")
                net.WriteString("sell_all")
                net.WriteFloat(0)
                net.SendToServer()
                timer.Simple(0.15, function()
                    net.Start("StockMarket_Admin_GetPortfolio")
                    net.WriteString(steamid or "")
                    net.SendToServer()
                end)
            end, "Cancel")
        end

        local function DoRemovePos(steamid, ticker)
            Derma_Query("Remove position ".. (ticker or "?") .." ?", "Confirm", "Remove", function()
                net.Start("StockMarket_Admin_AdjustPosition")
                net.WriteString(steamid or "")
                net.WriteString(ticker or "")
                net.WriteString("remove")
                net.WriteFloat(0)
                net.SendToServer()
                timer.Simple(0.15, function()
                    net.Start("StockMarket_Admin_GetPortfolio")
                    net.WriteString(steamid or "")
                    net.SendToServer()
                end)
            end, "Cancel")
        end

        local function KebabMenu(kebabButton, steamid, pos)
            if not IsValid(kebabButton) then return end

            local menu = DermaMenu(false, kebabButton)

            -- We do NOT set icons here to avoid DImage nil material crashes.
            -- If you want icons later, only do so with valid materials (guarded).
            menu:AddOption("Set Shares", function()
                OpenAdjustDialog("set_shares", steamid, pos.ticker)
            end)

            menu:AddOption("Set Avg Cost", function()
                OpenAdjustDialog("set_avg", steamid, pos.ticker)
            end)

            menu:AddSpacer()

            menu:AddOption("Force Sell", function()
                DoForceSell(steamid, pos.ticker)
            end)

            menu:AddOption("Remove Position", function()
                DoRemovePos(steamid, pos.ticker)
            end)

            -- Compute a safe on-screen position for the menu
            local sx, sy = kebabButton:LocalToScreen(0, kebabButton:GetTall())  -- open just below the button
            menu:Open()

            -- After creation, clamp to screen if needed
            timer.Simple(0, function()
                if not IsValid(menu) then return end
                local mw, mh = menu:GetWide(), menu:GetTall()
                local scrW, scrH = ScrW(), ScrH()

                local x = sx
                local y = sy

                if (x + mw) > scrW - 8 then
                    x = math.max(8, scrW - mw - 8)
                end
                if (y + mh) > scrH - 8 then
                    -- open above the kebab if below would clip
                    local kbX, kbY = kebabButton:LocalToScreen(0, 0)
                    y = math.max(8, kbY - mh - 6)
                end

                menu:SetPos(x, y)
            end)

            return menu
        end

        -- Build compact cards (thin row with kebab menu)
        for _, pos in SortedPairsByMemberValue(pdata.positions, "ticker", true) do
            local currentPrice = pos.price or (StockMarket.Config.CurrencySymbol .. "0.00")
            local mv = tonumber(pos.marketValue or 0) or 0
            local pnl = tonumber(pos.unrealized or 0) or 0
            local pnlSign = pnl >= 0 and "+" or ""

            local card = vgui.Create("DPanel", stack)
            card:Dock(TOP)
            card:SetTall(68)              -- compact row
            card:DockMargin(0, 8, 0, 0)
            card.Paint = function(self, w, h)
                draw.RoundedBox(8, 0, 0, w, h, BG_L)
            end

            -- Left: ticker + shares
            local left = vgui.Create("DPanel", card)
            left:Dock(LEFT)
            left:SetWide(320)
            left:DockMargin(12, 8, 0, 8)
            left.Paint = nil

            local l1 = vgui.Create("DLabel", left)
            l1:Dock(TOP)
            l1:SetTall(22)
            l1:SetFont("StockMarket_TickerFont")
            l1:SetTextColor(PRIMARY)
            l1:SetText(tostring(pos.ticker or "TICK"))

            local l2 = vgui.Create("DLabel", left)
            l2:Dock(TOP)
            l2:SetTall(18)
            l2:SetFont("StockMarket_SmallFont")
            l2:SetTextColor(TEXT2)
            l2:SetText(string.format("%s sh @ %s", string.Comma(tonumber(pos.shares or 0) or 0), Num(pos.avgCost)))

            -- Middle: current and value
            local mid = vgui.Create("DPanel", card)
            mid:Dock(FILL)
            mid:DockMargin(12, 8, 0, 8)
            mid.Paint = nil

            local m1 = vgui.Create("DLabel", mid)
            m1:Dock(TOP)
            m1:SetTall(20)
            m1:SetFont("StockMarket_TextFont")
            m1:SetTextColor(TEXT)
            m1:SetText("Current: " .. currentPrice)

            local m2 = vgui.Create("DLabel", mid)
            m2:Dock(TOP)
            m2:SetTall(20)
            m2:SetFont("StockMarket_TextFont")
            m2:SetTextColor(TEXT)
            m2:SetText("Value: " .. Num(mv))

            -- PnL pill (right of middle)
            local pill = vgui.Create("DPanel", mid)
            pill:Dock(RIGHT)
            pill:SetWide(140)
            pill.Paint = function(self, w, h)
                local txt = pnlSign .. Num(pnl)
                surface.SetFont("StockMarket_SmallFont")
                local tw, th = surface.GetTextSize(txt)
                local pw, ph = tw + 12, th + 6
                local x = w - pw
                local y = (h - ph) / 2
                draw.RoundedBox(6, x, y, pw, ph, pnl >= 0 and SUCCESS or DANGER)
                draw.SimpleText(txt, "StockMarket_SmallFont", x + pw/2, y + ph/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            -- Right: kebab menu button
            local right = vgui.Create("DPanel", card)
            right:Dock(RIGHT)
            right:SetWide(60)
            right:DockMargin(0, 8, 8, 8)
            right.Paint = nil

            local kebab = vgui.Create("DButton", right)
            kebab:Dock(FILL)
            kebab:SetText("")
            kebab.Paint = function(self, w, h)
                -- 3 dots icon
                local cx, cy = w/2, h/2
                surface.SetDrawColor(255,255,255,220)
                surface.DrawRect(cx - 8, cy - 2, 4, 4)
                surface.DrawRect(cx - 2, cy - 2, 4, 4)
                surface.DrawRect(cx + 4, cy - 2, 4, 4)
            end
            kebab.DoClick = function()
                KebabMenu(kebab, pdata.steamid, pos)
            end
        end

        -- Sticky footer (Copy SteamID / Refresh)
        local footer = vgui.Create("DPanel", win)
        footer:Dock(BOTTOM)
        footer:SetTall(52)
        footer:DockMargin(12, 8, 12, 12)
        footer.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, BG_L)
        end

        local function FooterButton(parent, label, onClick, w)
            local b = vgui.Create("DButton", parent)
            b:SetText("")
            b:SetWide(w or 140)
            b:Dock(RIGHT)
            b:DockMargin(8, 8, 8, 8)
            b.Paint = function(self, ww, hh)
                draw.RoundedBox(6, 0, 0, ww, hh, PRIMARY)
                draw.SimpleText(label, "StockMarket_ButtonFont", ww/2, hh/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            b.DoClick = onClick
            return b
        end

        FooterButton(footer, "Refresh", function()
            net.Start("StockMarket_Admin_GetPortfolio")
            net.WriteString(pdata.steamid or "")
            net.SendToServer()
        end, 120)

        FooterButton(footer, "Copy SteamID", function()
            if pdata.steamid and pdata.steamid ~= "" then
                SetClipboardText(pdata.steamid)
                chat.AddText(Color(100,200,255), "[StockMarket] ", color_white, "SteamID copied.")
            end
        end, 140)
    end)
end
