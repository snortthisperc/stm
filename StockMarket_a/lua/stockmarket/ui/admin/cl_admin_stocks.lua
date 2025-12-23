-- ========================================
-- Admin Panel - Stocks/Category Manager (Auto-size sections + Stat Pills)
-- ========================================

if not CLIENT then return end

StockMarket.UI = StockMarket.UI or {}
StockMarket.UI.Admin = StockMarket.UI.Admin or {}
StockMarket.UI.AdminMonitor = StockMarket.UI.AdminMonitor or nil

local ICON_SIZE = 18
local ICONS = {
    edit   = Material("stockmarket/icons/edit.png", "smooth"),
    delete = Material("stockmarket/icons/delete.png", "smooth"),
    add    = Material("stockmarket/icons/create.png", "smooth"),
    preview= Material("stockmarket/icons/preview.png", "smooth")
}

-- Constants and quick colors
local ROW_H = 60
local CAT_H = 68
local PAD_X = 14
local PAD_Y = 10
local ACTION_RAIL_W = 120

local function SmallButton(parent, label, C, onClick, w)
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b:SetTall(32)
    b:SetWide(w or 90)
    local hover = false
    b.Paint = function(self, w2, h2)
        draw.RoundedBox(6, 0, 0, w2, h2, hover and C.PrimaryHover or C.Primary)
        draw.SimpleText(label, "StockMarket_ButtonFont", w2/2, h2/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    b.OnCursorEntered = function() hover = true end
    b.OnCursorExited  = function() hover = false end
    b.DoClick = function() if onClick then onClick() end end
    return b
end

local function AdminPredictiveMonitor(C)
    if IsValid(StockMarket.UI.AdminMonitor) then
        local fr = StockMarket.UI.AdminMonitor
        fr:MakePopup(); fr:MoveToFront()
        return fr
    end

    local fr = vgui.Create("DFrame")
    fr:SetSize(math.min(ScrW() * 0.82, 1320), math.min(ScrH() * 0.85, 820))
    fr:Center()
    fr:SetTitle("")
    fr:MakePopup()
    fr:SetSizable(true)
    StockMarket.UI.AdminMonitor = fr

    -- Frame paint: clean, single-pass
    fr.Paint = function(self, w, h)
        surface.SetDrawColor(C.Background or Color(25,28,35))
        surface.DrawRect(0, 0, w, h)
        draw.RoundedBox(8, 8, 8, w - 16, 52, C.BackgroundLight or Color(32,36,45))
        draw.SimpleText("Performance Monitor", "StockMarket_SubtitleFont", 24, 34, C.TextPrimary or color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Toolbar
    local bar = vgui.Create("DPanel", fr)
    bar:Dock(TOP)
    bar:SetTall(56)
    bar:DockMargin(8, 64, 8, 6)
    bar.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, C.BackgroundLight)
    end

    local ctrl = vgui.Create("Panel", bar)
    ctrl:Dock(RIGHT)
    ctrl:SetWide(760)
    ctrl:DockMargin(8, 8, 8, 8)
    ctrl.Paint = nil

    -- Helper: fully hide DComboBox internal text area so no duplicate text
    local function SuppressComboInternalText(combo, fallbackText)
        combo:SetText("")
        combo:SetTextColor(Color(0,0,0,0))
        combo:SetFGColor(Color(0,0,0,0))
        timer.Simple(0, function()
            if not IsValid(combo) then return end
            local txt = combo.GetTextArea and combo:GetTextArea() or combo.TextEntry
            if IsValid(txt) then
                txt:SetText("")
                txt:SetTextColor(Color(0,0,0,0))
                txt:SetCursorColor(Color(0,0,0,0))
                txt.Paint = function() end
            end
        end)
        combo._displayValue = fallbackText
        combo.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, C.BackgroundDark or Color(18,21,28))
            draw.RoundedBox(6, 1, 1, w-2, h-2, C.Background or Color(25,28,35))
            draw.SimpleText(self._displayValue or "", "StockMarket_TextFont", 10, math.floor((h-16)/2), C.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            -- down arrow
            surface.SetFont("StockMarket_SmallFont")
            local glyph = "▼"
            local _, th = surface.GetTextSize(glyph)
            draw.SimpleText(glyph, "StockMarket_SmallFont", w - 10, math.floor((h - th) / 2), C.TextSecondary, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        end
        -- Keep value synced
        local baseOnSelect = combo.OnSelect
        combo.OnSelect = function(self, index, value, data)
            self._displayValue = tostring(value or "")
            if baseOnSelect then baseOnSelect(self, index, value, data) end
        end
    end

    -- Horizon selector
    local horizon = vgui.Create("DComboBox", ctrl)
    horizon:Dock(RIGHT)
    horizon:SetWide(120)
    horizon:AddChoice("30m", 30, true)
    horizon:AddChoice("1h", 60)
    horizon:AddChoice("4h", 240)
    horizon:AddChoice("24h", 1440)
    SuppressComboInternalText(horizon, "30m")

    -- Step selector
    local step = vgui.Create("DComboBox", ctrl)
    step:Dock(RIGHT)
    step:SetWide(110)
    step:DockMargin(8, 0, 0, 0)
    step:AddChoice("1m", 60)
    step:AddChoice("2m", 120, true)
    step:AddChoice("5m", 300)
    SuppressComboInternalText(step, "2m")

    local function getHorizonMins()
        local id = horizon:GetSelectedID() or 1
        return tonumber(horizon:GetOptionData(id)) or 30
    end
    local function getStepSecs()
        local id = step:GetSelectedID() or 2
        return tonumber(step:GetOptionData(id)) or 120
    end

    -- Skip buttons (no duplicate paint)
    local function addSkip(label, mins)
        local b = vgui.Create("DButton", ctrl)
        b:Dock(RIGHT)
        b:SetWide(66)
        b:DockMargin(6, 0, 0, 0)
        b:SetText("")
        local hov = false
        b.Paint = function(self, w, h)
            local col = hov and C.PrimaryHover or C.Primary
            draw.RoundedBox(6, 0, 0, w, h, col)
            draw.SimpleText(label, "StockMarket_ButtonFont", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        b.OnCursorEntered = function() hov = true end
        b.OnCursorExited  = function() hov = false end
        b.DoClick = function()
            if not fr.cards then return end
            for _, card in pairs(fr.cards) do
                if IsValid(card) and card._skip then card:_skip(mins) end
            end
        end
        return b
    end
    addSkip("+5m", 5)
    addSkip("+30m", 30)
    addSkip("+2h", 120)
    addSkip("+1d", 1440)

    -- Reset button
    local btnReset = vgui.Create("DButton", ctrl)
    btnReset:Dock(RIGHT)
    btnReset:SetWide(84)
    btnReset:DockMargin(8, 0, 0, 0)
    btnReset:SetText("")
    local hovR = false
    btnReset.Paint = function(self, w, h)
        local base = C.BackgroundDark or Color(20,22,28)
        local idle = C.Background or Color(25,28,35)
        draw.RoundedBox(6, 0, 0, w, h, hovR and base or idle)
        draw.SimpleText("Reset", "StockMarket_ButtonFont", w/2, h/2, C.TextPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnReset.OnCursorEntered = function() hovR = true end
    btnReset.OnCursorExited  = function() hovR = false end
    btnReset.DoClick = function()
        if not fr.cards then return end
        for _, card in pairs(fr.cards) do
            if IsValid(card) and card._refresh then card:_refresh(true) end
        end
    end

    -- Add All (Monitor all)
    local btnAll = vgui.Create("DButton", bar)
    btnAll:Dock(LEFT)
    btnAll:SetWide(160)
    btnAll:DockMargin(8, 8, 0, 8)
    btnAll:SetText("")
    local hovA = false
    btnAll.Paint = function(self, w, h)
        local col = hovA and C.PrimaryHover or C.Primary
        draw.RoundedBox(6, 0, 0, w, h, col)
        draw.SimpleText("Add All Active", "StockMarket_ButtonFont", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    btnAll.OnCursorEntered = function() hovA = true end
    btnAll.OnCursorExited  = function() hovA = false end
    btnAll.DoClick = function()
        local mon = AdminPredictiveMonitor(C)
        if StockMarket.UI.__LastAdminState then
            for _, sectorData in pairs(StockMarket.UI.__LastAdminState) do
                for _, tk in ipairs(sectorData.tickers or {}) do
                    if tk.enabled ~= false then
                        mon:AddTickerCard(tk)
                    end
                end
            end
        else
            net.Start("StockMarket_Admin_GetState"); net.SendToServer()
            net.Receive("StockMarket_Admin_State", function()
                local count = net.ReadUInt(16) or 0
                local state = {}
                for i = 1, count do
                    local sKey = net.ReadString()
                    local sector = {
                        sectorName = net.ReadString(),
                        sectorVolatility = net.ReadFloat(),
                        enabled = net.ReadBool(),
                        tickers = {}
                    }
                    local tCount = net.ReadUInt(16) or 0
                    for j = 1, tCount do
                        sector.tickers[j] = {
                            stockName = net.ReadString(),
                            stockPrefix = net.ReadString(),
                            marketStocks = net.ReadUInt(32),
                            newStockValue = net.ReadFloat(),
                            minTick = net.ReadFloat(),
                            maxTick = net.ReadFloat(),
                            drift = net.ReadFloat(),
                            volatility = net.ReadFloat(),
                            stockDifficulty = net.ReadUInt(32),
                            enabled = net.ReadBool()
                        }
                    end
                    state[sKey] = sector
                end
                StockMarket.UI.__LastAdminState = state
                for _, data in pairs(state) do
                    for _, tk in ipairs(data.tickers or {}) do
                        mon:AddTickerCard(tk)
                    end
                end
            end)
        end
    end

    -- Scroll grid
    local scroll = vgui.Create("DScrollPanel", fr)
    scroll:Dock(FILL)
    scroll:DockMargin(8, 0, 8, 8)

    local grid = vgui.Create("DIconLayout", scroll)
    grid:Dock(FILL)
    grid:SetSpaceX(8)
    grid:SetSpaceY(8)
    grid:DockMargin(0, 0, 2, 2)

    fr.cards = fr.cards or {}

    local function computeColumns(w)
        if w >= 1180 then return 3 end
        if w >= 820 then return 2 end
        return 1
    end
    local function applyCardWidths()
        if not IsValid(fr) or not IsValid(grid) then return end
        local w = fr:GetWide() - 32
        local cols = computeColumns(w)
        local cw = math.max(360, math.floor((w - (grid:GetSpaceX() * (cols - 1))) / cols))
        for _, card in pairs(fr.cards) do
            if IsValid(card) then card:SetWide(cw) end
        end
    end
    fr.OnSizeChanged = function() timer.Simple(0, applyCardWidths) end

    -- Top bar overlay used by cards
    local function DrawCameraChrome(w, h, tkr, title, pills)
        draw.RoundedBox(6, 8, 8, w - 16, 26, Color(0, 0, 0, 90))
        draw.SimpleText(tostring(tkr or "CAM"), "StockMarket_TickerFont", 16, 21, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        if title and title ~= "" then
            draw.SimpleText(" • " .. title, "StockMarket_SmallFont", 62, 21, Color(220, 220, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        -- Right rail pills, no overlaps
        local railX = w - 12
        local function pill(text, bg, fg)
            surface.SetFont("StockMarket_SmallFont")
            local tw, th = surface.GetTextSize(text or "")
            local pw, ph = tw + 12, th + 6
            railX = railX - pw - 6
            draw.RoundedBox(6, railX, 21 - ph/2, pw, ph, bg or Color(55, 65, 81))
            draw.SimpleText(text or "OK", "StockMarket_SmallFont", railX + pw/2, 21, fg or color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        if pills then
            for i = 1, #pills do
                local p = pills[i]
                pill(p.text or "OK", p.bg or Color(55, 65, 81), p.fg or color_white)
            end
        end
    end

    -- Add ticker card
    function fr:AddTickerCard(t)
        local key = t.stockPrefix or t.stockName or ("CAM_" .. math.random(1000,9999))
        if IsValid(self.cards[key]) then
            self.cards[key]._params = t
            self.cards[key]:_refresh()
            return self.cards[key]
        end

        local card = vgui.Create("DPanel")
        card:SetSize(380, 290)
        grid:Add(card)
        self.cards[key] = card

        card._params = t
        card._offsetMins = 0

        -- Clean card paint: one-pass
        card.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, C.BackgroundLight)
            local p = card._params or {}
            local title = string.format("%s | Drift %.3f • Vol %.2f",
                p.stockName or "Stock",
                tonumber(p.drift or 0) or 0,
                tonumber(p.volatility or 1) or 1
            )
            local riskInfo = StockMarket.UI.Admin.ComputeQuickStats and StockMarket.UI.Admin.ComputeQuickStats(
                tonumber(p.newStockValue or 1) or 1, tonumber(p.drift or 0) or 0, tonumber(p.volatility or 1) or 1, 30
            ) or { riskScore = 0 }
            local risk = riskInfo.riskScore or 0
            local pill
            if risk >= 25 then
                pill = { text = "HIGH", bg = StockMarket.UI.Colors.Danger }
            elseif risk >= 15 then
                pill = { text = "MED", bg = StockMarket.UI.Colors.Warning, fg = Color(30,30,30) }
            else
                pill = { text = "LOW", bg = StockMarket.UI.Colors.Success }
            end
            DrawCameraChrome(w, h, p.stockPrefix or "CAM", title, { pill })

            -- Footer bar background
            draw.RoundedBox(6, 8, h - 30, w - 16, 22, Color(0,0,0,65))
        end

        -- Minimal buttons (top-right)
        local function mkBtn(iconText, tip, onClick, xOff)
            local b = vgui.Create("DButton", card)
            b:SetText("")
            b:SetSize(24, 24)
            b:SetPos(card:GetWide() - xOff, 8)
            b.Paint = function(self, w, h)
                draw.RoundedBox(6, 0, 0, w, h, Color(0,0,0,120))
                draw.SimpleText(iconText, "StockMarket_SmallFont", w/2, h/2, Color(255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            b.DoClick = onClick
            return b
        end

        card._btnClose = mkBtn("×", "Remove", function()
            if IsValid(card) then
                grid:RemoveItem(card)
                fr.cards[t.stockPrefix or t.stockName] = nil
                card:Remove()
            end
        end, 32)

        card._btnPop  = mkBtn("⤢", "Popout", function()
            local pop = vgui.Create("DFrame")
            pop:SetSize(math.min(ScrW() * 0.7, 900), math.min(ScrH() * 0.7, 600))
            pop:Center()
            pop:SetTitle("")
            pop:MakePopup()
            pop.Paint = function(self, w, h)
                draw.RoundedBox(8, 0, 0, w, h, C.Background)
                DrawCameraChrome(w, 60, t.stockPrefix or "CAM", (t.stockName or "Stock"), nil)
            end

            local holder = vgui.Create("DPanel", pop)
            holder:Dock(FILL)
            holder:DockMargin(12, 70, 12, 12)
            local c = StockMarket.UI.Lib:Chart(holder)
            c:Dock(FILL)
            c:SetData(StockMarket.UI.Admin.BuildPredictionSeries({
                startPrice = tonumber(t.newStockValue or 1) or 1,
                drift = tonumber(t.drift or 0) or 0,
                sigma = tonumber(t.volatility or 1) or 1,
                horizonMins = 120,
                stepSecs = 120
            }))
        end, 62)

        card.PerformLayout = function(self, w, h)
            if IsValid(self._btnClose) then self._btnClose:SetPos(w - 32, 8) end
            if IsValid(self._btnPop)   then self._btnPop:SetPos(w - 62, 8) end
        end

        -- Chart holder
        local chartHolder = vgui.Create("DPanel", card)
        chartHolder:SetPos(12, 46)
        chartHolder:SetSize(card:GetWide() - 24, 165)
        chartHolder.Paint = nil
        chartHolder.PerformLayout = function(self, w, h)
            if IsValid(self.chart) then self.chart:SetSize(w, h) end
        end

        local chart = StockMarket.UI.Lib:Chart(chartHolder)
        chart:Dock(FILL)
        chartHolder.chart = chart

        -- Footer
        local footer = vgui.Create("DPanel", card)
        footer:Dock(BOTTOM)
        footer:SetTall(64)
        footer:DockMargin(12, 6, 12, 10)
        footer.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, C.Background)
            local p = card._params
            draw.SimpleText(string.format("Horizon: %dm  • Step: %ds", getHorizonMins(), getStepSecs()), "StockMarket_SmallFont", 10, h - 18, C.TextSecondary)
            draw.SimpleText(tostring(p.stockName or "Stock"), "StockMarket_SmallFont", 10, 10, C.TextSecondary)

            local s = StockMarket.UI.Admin.ComputeQuickStats and StockMarket.UI.Admin.ComputeQuickStats(
                tonumber(p.newStockValue or 1) or 1, tonumber(p.drift or 0) or 0, tonumber(p.volatility or 1) or 1, getHorizonMins()
            ) or { riskScore = 0 }
            local risk = s.riskScore or 0
            local label, col
            if risk >= 25 then label, col = "HIGH", StockMarket.UI.Colors.Danger
            elseif risk >= 15 then label, col = "MED", StockMarket.UI.Colors.Warning
            else label, col = "LOW", StockMarket.UI.Colors.Success end
            surface.SetFont("StockMarket_SmallFont")
            local tw, th = surface.GetTextSize(label)
            local pw, ph = tw + 12, th + 6
            draw.RoundedBox(6, w - pw - 10, 8, pw, ph, col)
            draw.SimpleText(label, "StockMarket_SmallFont", w - pw/2 - 10, 8 + ph/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        function card:_refresh(resetOffset)
            if resetOffset then self._offsetMins = 0 end
            local p = self._params
            local cfg = {
                startPrice  = tonumber(p.newStockValue or 1) or 1,
                drift       = tonumber(p.drift or 0) or 0,
                sigma       = tonumber(p.volatility or 1) or 1,
                minTick     = tonumber(p.minTick or nil),
                maxTick     = tonumber(p.maxTick or nil),
                horizonMins = getHorizonMins() + (self._offsetMins or 0),
                stepSecs    = getStepSecs()
            }
            local series = StockMarket.UI.Admin.BuildPredictionSeries and StockMarket.UI.Admin.BuildPredictionSeries(cfg) or {}
            if chart.SetData then chart:SetData(series) end
            footer:InvalidateLayout(true)
            chartHolder:InvalidateLayout(true)
        end

        function card:_skip(mins)
            self._offsetMins = (self._offsetMins or 0) + mins
            self:_refresh()
        end

        card:_refresh(true)
        applyCardWidths()
        return card
    end

    horizon.OnSelect = function()
        if not fr.cards then return end
        for _, card in pairs(fr.cards) do if IsValid(card) then card:_refresh() end end
    end
    step.OnSelect = function()
        if not fr.cards then return end
        for _, card in pairs(fr.cards) do if IsValid(card) then card:_refresh() end end
    end

    timer.Simple(0, applyCardWidths)
    return fr
end

local function IconButton(parent, iconMat, tip, onClick)
    local btn = vgui.Create("DButton", parent)
    btn:SetText("")
    btn:SetSize(32, 32)
    btn.hovered = false
    btn.icon = iconMat

    btn.Paint = function(self, w, h)
        local alpha = self.hovered and 28 or 0
        draw.RoundedBox(6, 0, 0, w, h, Color(255,255,255, alpha))
        if self.icon then
            surface.SetMaterial(self.icon)
            surface.SetDrawColor(255,255,255, self.hovered and 255 or 220)
            local s = ICON_SIZE
            surface.DrawTexturedRect(math.floor((w - s)/2), math.floor((h - s)/2), s, s)
        end
    end
    btn.OnCursorEntered = function(self) self.hovered = true end
    btn.OnCursorExited  = function(self) self.hovered = false end
    btn.DoClick = function() if onClick then onClick(self) end end

    if tip and StockMarket.UI.Lib and StockMarket.UI.Lib.AddTooltip then
        StockMarket.UI.Lib:AddTooltip(btn, tip)
    end

    return btn
end

local function asColor(c, fallback)
    if istable(c) and c.r and c.g and c.b then return c end
    return fallback or Color(255, 255, 255)
end

local function DrawPill(x, y, text, bg, fg, padX, padY, font)
    text = text or ""
    padX = padX or 10
    padY = padY or 6
    font = font or "StockMarket_SmallFont"

    surface.SetFont(font)
    local tw, th = surface.GetTextSize(text)
    local w, h = tw + padX, th + padY

    local bgCol = asColor(bg, Color(45, 78, 120))
    local fgCol = asColor(fg, color_white)

    draw.RoundedBox(6, x, y, w, h, bgCol)
    draw.SimpleText(text, font, x + w/2, y + h/2, fgCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    return w, h
end

local function CategoryHeader(parent, sectorKey, sectorData, C, onAddTicker, onEditCategory, onDeleteCategory)
    local pnl = vgui.Create("DPanel", parent)
    pnl:Dock(TOP)
    pnl:SetTall(CAT_H)
    pnl:DockMargin(0, 0, 0, 8)
    pnl.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, C.BackgroundLight)
    end

    local left = vgui.Create("DPanel", pnl)
    left:Dock(FILL)
    left:DockMargin(PAD_X, PAD_Y, 4, PAD_Y)
    left.Paint = function(self, w, h)
        local name = (sectorData.sectorName)
        draw.SimpleText(name, "StockMarket_SubtitleFont", 0, 0, C.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local px = 0
        local py = 28

        local vol = tonumber(sectorData.sectorVolatility or 1) or 1
        local volText = string.format("Vol x%.2f", vol)
        local volW = select(1, DrawPill(px, py, volText, Color(45, 78, 120), color_white, 12, 6, "StockMarket_SmallFont"))
        px = px + volW + 8

        local isEnabled = sectorData.enabled ~= false
        local stText = isEnabled and "Enabled" or "Disabled"
        local stBg = isEnabled and Color(34, 197, 94) or Color(239, 68, 68)
        local stW = select(1, DrawPill(px, py, stText, stBg, color_white, 12, 6, "StockMarket_SmallFont"))
        px = px + stW + 8

        local risk = vol * 10
        local opText = risk >= 20 and "DP HIGH" or (risk >= 12 and "DP MED" or "DP LOW")
        local opCol = risk >= 20 and StockMarket.UI.Colors.Danger
                  or (risk >= 12 and StockMarket.UI.Colors.Warning or StockMarket.UI.Colors.Success)
        DrawPill(px, py, opText, opCol, color_white, 12, 6, "StockMarket_SmallFont")
    end

    local rail = vgui.Create("Panel", pnl)
    rail:Dock(RIGHT)
    rail:SetWide(ACTION_RAIL_W)
    rail:DockMargin(4, PAD_Y, PAD_X, PAD_Y)

    local btnAdd  = IconButton(rail, ICONS.add,   "Add Stock", function() onAddTicker(sectorKey) end)
    local btnEdit = IconButton(rail, ICONS.edit,  "Edit Category", function() onEditCategory(sectorKey, sectorData) end)
    local btnDel  = IconButton(rail, ICONS.delete,"Delete Category", function()
        Derma_Query("Delete category ".. (sectorData.sectorName or sectorKey) .." ?", "Confirm",
            "Delete", function()
                net.Start("StockMarket_Admin_DeleteCategory")
                net.WriteString(sectorKey)
                net.SendToServer()
                timer.Simple(0.15, function()
                    net.Start("StockMarket_Admin_GetState"); net.SendToServer()
                end)
            end, "Cancel"
        )
    end)

    btnDel:Dock(RIGHT);  btnDel:DockMargin(6,0,0,0)
    btnEdit:Dock(RIGHT); btnEdit:DockMargin(6,0,0,0)
    btnAdd:Dock(RIGHT)

    return pnl
end

local DRAG_NAME = "SM_Admin_StockRow"
local function StockRow(parent, sectorKey, t, C, onEdit, onDelete)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:SetTall(ROW_H)
    row:DockMargin(0, 0, 0, 6)
    row:SetCursor("sizeall")
    row.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, C.BackgroundLight)
    end

    local left = vgui.Create("DPanel", row)
    left:Dock(FILL)
    left:DockMargin(PAD_X, PAD_Y, 4, PAD_Y)
    left.Paint = function(self, w, h)
        local nameText = (t.stockName or "Stock") .. " (" .. (t.stockPrefix or "TICK") .. ")"
        draw.SimpleText(nameText, "StockMarket_TextFont", 0, 0, C.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        local priceText = string.format("Price: %s%s", StockMarket.Config.CurrencySymbol, tostring(t.newStockValue or 0))
        local drift = tonumber(t.drift or 0) or 0
        local vol = tonumber(t.volatility or 1) or 1

        local driftCol = drift > 0 and StockMarket.UI.Colors.Success
                      or (drift < 0 and StockMarket.UI.Colors.Danger or StockMarket.UI.Colors.TextSecondary)

        local y = 24
        local x = 0

        surface.SetFont("StockMarket_SmallFont")
        draw.SimpleText(priceText, "StockMarket_SmallFont", x, y, StockMarket.UI.Colors.TextSecondary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        local priceW = surface.GetTextSize(priceText)
        x = x + priceW + 12

        local driftText = string.format("• Drift %.3f", drift)
        draw.SimpleText(driftText, "StockMarket_SmallFont", x, y, driftCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        local driftW = surface.GetTextSize(driftText)
        x = x + driftW + 12

        local baseBlue = StockMarket.UI.Colors.Info or Color(59,130,246)
        local alpha = math.Clamp(80 + (vol - 1) * 70, 60, 180)
        local volBg = Color(baseBlue.r, baseBlue.g, baseBlue.b, alpha)
        local volText = string.format("Vol %.2f", vol)

        surface.SetFont("StockMarket_SmallFont")
        local tw, th = surface.GetTextSize(volText)
        local padx, pady = 12, 4
        local pw, ph = tw + padx, th + pady
        draw.RoundedBox(6, x, y - 1, pw, ph, volBg)
        draw.SimpleText(volText, "StockMarket_SmallFont", x + pw/2, y - 1 + ph/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local rail = vgui.Create("Panel", row)
    rail:Dock(RIGHT)
    rail:SetWide(ACTION_RAIL_W)
    rail:DockMargin(4, PAD_Y, PAD_X, PAD_Y)

    local btnDel   = IconButton(rail, ICONS.delete, "Delete", function() onDelete(sectorKey, t) end)
    local btnEdit  = IconButton(rail, ICONS.edit,   "Edit",   function() onEdit(sectorKey, t) end)
    local btnPrev  = IconButton(rail, ICONS.preview,"Open Monitor", function()
        local mon = AdminPredictiveMonitor(C)
        mon:AddTickerCard(t)
    end)

    btnDel:Dock(RIGHT);  btnDel:DockMargin(8,0,0,0)
    btnEdit:Dock(RIGHT); btnEdit:DockMargin(8,0,0,0)
    btnPrev:Dock(RIGHT)

    return row
end

local function SelfSizingList(parent)
    local list = vgui.Create("DPanel", parent)
    list:Dock(TOP)
    list:DockMargin(0, 0, 0, 12)
    list:SetTall(0)
    list.Paint = nil

    function list:PerformLayout(w, h)
        local total = 0
        local children = self:GetChildren() or {}
        for _, child in ipairs(children) do
            if IsValid(child) then
                total = total + child:GetTall()
                local l,t,r,b = child:GetDockMargin()
                total = total + t + b
            end
        end
        self:SetTall(total + 2)
    end

    function list:OnChildAdded() self:InvalidateLayout(true) end
    function list:OnChildRemoved() self:InvalidateLayout(true) end

    return list
end

local function InputRow(form, label, default)
    local row = vgui.Create("DPanel", form)
    row:Dock(TOP)
    row:SetTall(42)
    row:DockMargin(0, 4, 0, 6)
    row.Paint = nil

    local lbl = vgui.Create("DLabel", row)
    lbl:Dock(LEFT)
    lbl:SetWide(170)
    lbl:SetText(label)
    lbl:SetFont("StockMarket_TextFont")
    lbl:SetTextColor(Color(220,220,220))
    lbl:SetContentAlignment(4)

    local ent = vgui.Create("DTextEntry", row)
    ent:Dock(FILL)
    ent:SetFont("StockMarket_TextFont")
    ent:SetText(default or "")
    ent:SetTextColor(Color(255,255,255))
    ent:SetDrawBackground(true)
    ent:SetPaintBackground(true)
    ent.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, Color(35,38,46))
        self:DrawTextEntryText(Color(255,255,255), Color(220,50,50), Color(255,255,255))
    end

    return ent
end

function StockMarket.UI.Admin._OpenCategoryDialog(mode, sectorKey, sectorData, C)
    local fr = vgui.Create("DFrame")
    fr:SetSize(520, 420); fr:Center(); fr:SetTitle(""); fr:MakePopup()
    fr.Paint = function(self,w,h) draw.RoundedBox(8,0,0,w,h, Color(28,31,38)) end

    local form = vgui.Create("DPanel", fr)
    form:Dock(FILL); form:DockMargin(10,10,10,50); form.Paint = nil

    local name = InputRow(form, "Sector Name", sectorData and sectorData.sectorName or "")
    local vol  = InputRow(form, "Sector Volatility (0.1-3.0)", (sectorData and tostring(sectorData.sectorVolatility or 1) or "1.0"))

    local enabled = vgui.Create("DCheckBoxLabel", form)
    enabled:Dock(TOP); enabled:DockMargin(170,6,0,0); enabled:SetText("Enabled")
    enabled:SetChecked(sectorData and sectorData.enabled ~= false or true)
    enabled:SetTextColor(Color(220,220,220)); enabled:SetFont("StockMarket_TextFont")

    local save = SmallButton(fr, "Save", {Primary=Color(220,38,38),PrimaryHover=Color(248,113,113)}, function()
        local payload = {
            sectorKey = sectorKey or "",
            sectorName = name:GetValue(),
            sectorVolatility = tonumber(vol:GetValue()) or 1.0,
            enabled = enabled:GetChecked()
        }
        net.Start("StockMarket_Admin_SaveCategory")
        net.WriteString(payload.sectorKey or "")
        net.WriteString(payload.sectorName or "")
        net.WriteFloat(tonumber(payload.sectorVolatility or 1) or 1)
        net.WriteBool(payload.enabled ~= false)
        net.SendToServer()
        fr:Close()
        timer.Simple(0.15, function()
            net.Start("StockMarket_Admin_GetState")
            net.SendToServer()
        end)
    end)
    save:Dock(BOTTOM); save:DockMargin(10,0,10,10); save:SetTall(38)
end

function StockMarket.UI.Admin.BuildPredictionSeries(params)
    local p0 = math.max(0.01, tonumber(params.startPrice) or 1)
    local mu = tonumber(params.drift) or 0           -- same units you pass in
    local sigma = tonumber(params.sigma) or 1
    local minTickV = tonumber(params.minTick)
    local maxTickV = tonumber(params.maxTick)
    local horizonMins = math.max(1, tonumber(params.horizonMins) or 60)
    local stepSecs = math.max(1, tonumber(params.stepSecs) or 60)

    -- Derive a per-step percent cap from the live engine’s daily cap.
    local dailyCap = tonumber(StockMarket.Config.PriceGen and StockMarket.Config.PriceGen.maxDailyMoveCap) or 0.25
    local stepsPerDay = math.max(1, math.floor((24*60*60) / stepSecs))
    local perStepCap = dailyCap / stepsPerDay  -- approximately distributes the daily cap across steps

    local now = os.time()
    local steps = math.floor((horizonMins * 60) / stepSecs)

    local series = {}
    local price = p0
    table.insert(series, {timestamp = now - steps * stepSecs, open = price, high = price, low = price, close = price, volume = 0})

    for i = 1, steps do
        -- Triangular-ish noise (sum of uniform) like your current preview
        local rand = (math.Rand(-1,1) + math.Rand(-1,1) + math.Rand(-1,1)) / 3

        -- Base move: additive drift + proportional volatility
        local move
        if minTickV and maxTickV then
            -- If explicit ticks are set, keep using them (bounds in absolute price units)
            local tickSpan = (maxTickV - minTickV)
            move = math.Clamp(rand * sigma * tickSpan, minTickV, maxTickV) + (mu * tickSpan)
        else
            -- Otherwise use proportional move to current price (like a % step)
            move = price * ((mu) + (sigma * 0.01) * rand)
        end

        local proposed = price + move

        -- Per-step clamp to emulate daily move cap
        local maxUp = price * (1 + perStepCap)
        local maxDn = price * (1 - perStepCap)
        proposed = math.min(math.max(proposed, maxDn), maxUp)

        -- Enforce minimum price
        proposed = math.max(0.01, proposed)

        local ts = now - (steps - i) * stepSecs
        local hi = math.max(price, proposed)
        local lo = math.min(price, proposed)
        table.insert(series, {timestamp = ts, open = price, high = hi, low = lo, close = proposed, volume = 0})
        price = proposed
    end

    return series
end

function StockMarket.UI.Admin.ComputeQuickStats(startPrice, mu, sigma, horizonMins)
    local driftPer = (tonumber(mu) or 0) * 100
    local sig = tonumber(sigma) or 1
    local riskScore = math.abs(driftPer) + sig * 10
    return {
        driftPer = driftPer,
        sigma = sig,
        riskScore = riskScore,
        horizonMins = horizonMins
    }
end

function StockMarket.UI.Admin._OpenTickerDialog(mode, sectorKey, t, C)
    local fr = vgui.Create("DFrame")
    fr:SetSize(940, 660)
    fr:Center(); fr:SetTitle(""); fr:MakePopup()
    fr.Paint = function(self,w,h) draw.RoundedBox(8,0,0,w,h, Color(28,31,38)) end

    local container = vgui.Create("DPanel", fr)
    container:Dock(FILL)
    container:DockMargin(10,10,10,50)
    container.Paint = nil

    local form = vgui.Create("DPanel", container)
    form:Dock(LEFT)
    form:SetWide(480)
    form.Paint = nil
    form:DockMargin(0,0,10,0)

    local right = vgui.Create("DPanel", container)
    right:Dock(FILL)
    right.Paint = function(self,w,h)
        draw.RoundedBox(8, 0, 0, w, h, C.BackgroundLight)
        draw.SimpleText("Predicted Path (Preview)", "StockMarket_SmallFont", 12, 8, C.TextSecondary)
    end
    right:DockPadding(10, 26, 10, 10)

    local function InputRow(parent, label, default)
        local row = vgui.Create("DPanel", parent)
        row:Dock(TOP); row:SetTall(42); row:DockMargin(0, 4, 0, 6); row.Paint = nil

        local lbl = vgui.Create("DLabel", row)
        lbl:Dock(LEFT); lbl:SetWide(170)
        lbl:SetText(label); lbl:SetFont("StockMarket_TextFont")
        lbl:SetTextColor(Color(220,220,220)); lbl:SetContentAlignment(4)

        local ent = vgui.Create("DTextEntry", row)
        ent:Dock(FILL); ent:SetFont("StockMarket_TextFont")
        ent:SetText(default or ""); ent:SetTextColor(Color(255,255,255))
        ent:SetDrawBackground(true); ent:SetPaintBackground(true)
        ent.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, Color(35,38,46))
            self:DrawTextEntryText(Color(255,255,255), Color(220,50,50), Color(255,255,255))
        end

        return ent
    end

    local name   = InputRow(form, "Stock Name", t and t.stockName or "")
    local prefix = InputRow(form, "Ticker Prefix", t and t.stockPrefix or "")
    local float  = InputRow(form, "Shares Outstanding (float)", t and tostring(t.marketStocks or 0) or "0")
    local start  = InputRow(form, "Starting Price", t and tostring(t.newStockValue or 1) or "1")
    local drift  = InputRow(form, "Drift (e.g., 0.008)", t and tostring(t.drift or 0) or "0")
    local vol    = InputRow(form, "Volatility (e.g., 0.8)", t and tostring(t.volatility or 1) or "1")
    local minT   = InputRow(form, "Min Tick (optional)", t and tostring(t.minTick or "") or "")
    local maxT   = InputRow(form, "Max Tick (optional)", t and tostring(t.maxTick or "") or "")

    local diff   = InputRow(form, "Difficulty", t and tostring(t.stockDifficulty or 2000) or "2000")

    local enabled = vgui.Create("DCheckBoxLabel", form)
    enabled:Dock(TOP); enabled:DockMargin(170,6,0,0); enabled:SetText("Enabled")
    enabled:SetChecked(t and t.enabled ~= false or true)
    enabled:SetTextColor(Color(220,220,220)); enabled:SetFont("StockMarket_TextFont")

    local chartContainer = vgui.Create("DPanel", right)
    chartContainer:Dock(FILL)
    chartContainer.Paint = nil

    local chart = StockMarket.UI.Lib:Chart(chartContainer)
    chart:Dock(FILL)

    local function getNumberOrDefault(str, def)
        local n = tonumber(str)
        if n == nil or n ~= n or n == math.huge or n == -math.huge then return def end
        return n
    end

    local function refreshChart()
        if not IsValid(chart) then return end
        local startV = getNumberOrDefault(start:GetValue(), t and tonumber(t.newStockValue) or 1)
        local driftV = getNumberOrDefault(drift:GetValue(), t and tonumber(t.drift) or 0)
        local volV   = getNumberOrDefault(vol:GetValue(),   t and tonumber(t.volatility) or 1)
        local minTV  = tonumber(minT:GetValue())
        local maxTV  = tonumber(maxT:GetValue())
        local params = {
            startPrice  = math.max(0.01, startV),
            drift       = driftV,
            sigma       = volV,
            minTick     = minTV,
            maxTick     = maxTV,
            horizonMins = 60,
            stepSecs    = 120
        }
        local series = {}
        if StockMarket.UI.Admin.BuildPredictionSeries then
            series = StockMarket.UI.Admin.BuildPredictionSeries(params) or {}
        end
        if chart.SetData then
            chart:SetData(series)
        elseif chart.LoadHistory then
            chart:LoadHistory()
        end
        if chart.RebuildAxes then chart:RebuildAxes() end
    end

    local function bindUpdate(entry)
        entry.OnChange     = refreshChart
        entry.OnEnter      = refreshChart
        entry.OnLoseFocus  = refreshChart
    end
    bindUpdate(start)
    bindUpdate(drift)
    bindUpdate(vol)
    bindUpdate(minT)
    bindUpdate(maxT)

    timer.Simple(0, refreshChart)

    local save = SmallButton(fr, "Save", {Primary=Color(220,38,38),PrimaryHover=Color(248,113,113)}, function()
        local payload = {
            sectorKey = sectorKey,
            stockName = name:GetValue(),
            stockPrefix = prefix:GetValue(),
            marketStocks = tonumber(float:GetValue()) or 0,
            newStockValue = tonumber(start:GetValue()) or 1,
            minTick = tonumber(minT:GetValue()) or (t and t.minTick) or nil,
            maxTick = tonumber(maxT:GetValue()) or (t and t.maxTick) or nil,
            drift = tonumber(drift:GetValue()) or 0,
            volatility = tonumber(vol:GetValue()) or 1,
            stockDifficulty = tonumber(diff:GetValue()) or 2000,
            enabled = enabled:GetChecked()
        }
        if mode == "edit" and t and t.stockPrefix then payload.oldPrefix = t.stockPrefix end

        net.Start("StockMarket_Admin_SaveTicker")
        net.WriteString(payload.sectorKey or "")
        net.WriteString(payload.stockName or "")
        net.WriteString(payload.stockPrefix or "")
        net.WriteUInt(tonumber(payload.marketStocks or 0) or 0, 32)
        net.WriteFloat(tonumber(payload.newStockValue or 0) or 0)
        net.WriteFloat(tonumber(payload.minTick or 0) or 0)
        net.WriteFloat(tonumber(payload.maxTick or 0) or 0)
        net.WriteFloat(tonumber(payload.drift or 0) or 0)
        net.WriteFloat(tonumber(payload.volatility or 0) or 0)
        net.WriteUInt(tonumber(payload.stockDifficulty or 0) or 0, 32)
        net.WriteBool(payload.enabled ~= false)
        net.WriteString(payload.oldPrefix or "")
        net.SendToServer()

        fr:Close()
        timer.Simple(0.15, function()
            net.Start("StockMarket_Admin_GetState")
            net.SendToServer()
        end)
    end)
    save:Dock(BOTTOM); save:DockMargin(10,0,10,10); save:SetTall(38)
end

-- Main
function StockMarket.UI.Admin.Stocks(content, C)
    local top = vgui.Create("DPanel", content)
    top:Dock(TOP)
    top:SetTall(54)
    top:DockMargin(0, 0, 0, 10)
    top.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, C.BackgroundLight)
        draw.SimpleText("Stocks & Categories", "StockMarket_SubtitleFont", 14, h/2, C.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    local topRail = vgui.Create("Panel", top)
    topRail:Dock(RIGHT)
    topRail:SetWide(340)
    topRail:DockMargin(0, 8, 14, 8)

    local btnW, btnH = 160, 38

    local addAll = vgui.Create("DButton", topRail)
    addAll:SetText("")
    addAll:SetSize(btnW, btnH)
    addAll:Dock(RIGHT)
    addAll:DockMargin(8, 0, 0, 0)
    local hovAll = false
    addAll.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, hovAll and C.PrimaryHover or C.Primary)
        draw.SimpleText("Monitor All", "StockMarket_ButtonFont", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    addAll.OnCursorEntered = function() hovAll = true end
    addAll.OnCursorExited  = function() hovAll = false end
    addAll.DoClick = function()
        local mon = AdminPredictiveMonitor(C)
        if StockMarket.UI.__LastAdminState then
            for sectorKey, sectorData in pairs(StockMarket.UI.__LastAdminState) do
                for _, tk in ipairs(sectorData.tickers or {}) do
                    mon:AddTickerCard(tk)
                end
            end
        else
            net.Start("StockMarket_Admin_GetState")
            net.SendToServer()
            local hookId = "SM_AdminState_ToMonitor_" .. tostring(SysTime())
            net.Receive("StockMarket_Admin_State", function()
                local count = net.ReadUInt(16) or 0
                local state = {}
                for i = 1, count do
                    local sectorKey = net.ReadString()
                    local sector = {
                        sectorName = net.ReadString(),
                        sectorVolatility = net.ReadFloat(),
                        enabled = net.ReadBool(),
                        tickers = {}
                    }
                    local tCount = net.ReadUInt(16) or 0
                    for j = 1, tCount do
                        sector.tickers[j] = {
                            stockName = net.ReadString(),
                            stockPrefix = net.ReadString(),
                            marketStocks = net.ReadUInt(32),
                            newStockValue = net.ReadFloat(),
                            minTick = net.ReadFloat(),
                            maxTick = net.ReadFloat(),
                            drift = net.ReadFloat(),
                            volatility = net.ReadFloat(),
                            stockDifficulty = net.ReadUInt(32),
                            enabled = net.ReadBool()
                        }
                    end
                    state[sectorKey] = sector
                end
                StockMarket.UI.__LastAdminState = state
                for _, data in pairs(state) do
                    for _, tk in ipairs(data.tickers or {}) do
                        mon:AddTickerCard(tk)
                    end
                end
            end)
        end
    end

    local addCat = vgui.Create("DButton", topRail)
    addCat:SetText("")
    addCat:SetSize(btnW, btnH)
    addCat:Dock(RIGHT)
    local hovCat = false
    addCat.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, hovCat and C.PrimaryHover or C.Primary)
        draw.SimpleText("+ Create Category", "StockMarket_ButtonFont", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    addCat.OnCursorEntered = function() hovCat = true end
    addCat.OnCursorExited  = function() hovCat = false end
    addCat.DoClick = function()
        StockMarket.UI.Admin._OpenCategoryDialog("create", nil, nil, C)
    end

    local scroll = vgui.Create("DScrollPanel", content)
    scroll:Dock(FILL)

    net.Start("StockMarket_Admin_GetState")
    net.SendToServer()

    net.Receive("StockMarket_Admin_State", function()
        local count = net.ReadUInt(16) or 0
        local state = {}

        for i = 1, count do
            local sectorKey = net.ReadString()
            local sector = {
                sectorName = net.ReadString(),
                sectorVolatility = net.ReadFloat(),
                enabled = net.ReadBool(),
                tickers = {}
            }

            local tickerCount = net.ReadUInt(16) or 0
            for j = 1, tickerCount do
                sector.tickers[j] = {
                    stockName = net.ReadString(),
                    stockPrefix = net.ReadString(),
                    marketStocks = net.ReadUInt(32),
                    newStockValue = net.ReadFloat(),
                    minTick = net.ReadFloat(),
                    maxTick = net.ReadFloat(),
                    drift = net.ReadFloat(),
                    volatility = net.ReadFloat(),
                    stockDifficulty = net.ReadUInt(32),
                    enabled = net.ReadBool()
                }
            end

            state[sectorKey] = sector
        end

        StockMarket.UI.__LastAdminState = state

        if not IsValid(scroll) then return end
        scroll:Clear()

        local ordered = {}
        for key, data in pairs(state) do
            table.insert(ordered, { key = key, name = data.sectorName or key, data = data })
        end
        table.sort(ordered, function(a,b) return string.lower(a.name) < string.lower(b.name) end)

        for _, it in ipairs(ordered) do
            local sectorKey = it.key
            local sectorData = it.data

            if not IsValid(scroll) then return end
            CategoryHeader(scroll, sectorKey, sectorData, C,
                function(sKey) StockMarket.UI.Admin._OpenTickerDialog("create", sKey, nil, C) end,
                function(sKey, data) StockMarket.UI.Admin._OpenCategoryDialog("edit", sKey, data, C) end,
                function(sKey, data)
                    Derma_Query("Delete category ".. (data.sectorName or sKey) .." ?", "Confirm",
                        "Delete", function()
                            net.Start("StockMarket_Admin_DeleteCategory")
                            net.WriteString(sKey)
                            net.SendToServer()
                            timer.Simple(0.15, function()
                                net.Start("StockMarket_Admin_GetState")
                                net.SendToServer()
                            end)
                        end, "Cancel"
                    )
                end
            )

            if not IsValid(scroll) then return end
            local rows = SelfSizingList(scroll)
            if not IsValid(rows) then return end
            rows._sectorKey = sectorKey

            for _, t in ipairs(sectorData.tickers or {}) do
                StockRow(rows, sectorKey, t, C,
                    function(sKey, ticker) StockMarket.UI.Admin._OpenTickerDialog("edit", sKey, ticker, C) end,
                    function(sKey, ticker)
                        Derma_Query("Delete ticker ".. (ticker.stockName or "?") .." (".. (ticker.stockPrefix or "?") ..") ?", "Confirm",
                            "Delete", function()
                                net.Start("StockMarket_Admin_DeleteTicker"); net.WriteString(sKey); net.WriteString(ticker.stockPrefix or ""); net.SendToServer()
                                timer.Simple(0.15, function()
                                    net.Start("StockMarket_Admin_GetState"); net.SendToServer()
                                end)
                            end, "Cancel"
                        )
                    end
                )
            end

            rows:Receiver(DRAG_NAME, function(self, panels, bDoDrop)
                if not bDoDrop or not panels or #panels == 0 then return end
                local dragged = panels[1]
                if not IsValid(dragged) then return end
                local fromSector = dragged._sectorKey
                local prefix     = dragged._tickerPrefix
                local toSector   = self._sectorKey
                if not fromSector or not prefix or fromSector == toSector then return end
                net.Start("StockMarket_Admin_Reorder")
                net.WriteString(fromSector); net.WriteString(toSector); net.WriteString(prefix)
                net.SendToServer()
                timer.Simple(0.15, function()
                    net.Start("StockMarket_Admin_GetState"); net.SendToServer()
                end)
            end)
        end
    end)
end
