-- ========================================
-- UI Component Library (stable)
-- ========================================

StockMarket.UI = StockMarket.UI or {}
StockMarket.UI.Lib = {}
StockMarket.UI.Icons = StockMarket.UI.Icons or {}
StockMarket.UI.Icons.UpTrend   = StockMarket.UI.Icons.UpTrend   or Material("stockmarket/icons/up_trend.png", "smooth")
StockMarket.UI.Icons.DownTrend = StockMarket.UI.Icons.DownTrend or Material("stockmarket/icons/down_trend.png", "smooth")

StockMarket.UI.Materials = StockMarket.UI.Materials or {}
function StockMarket.UI.GetMat(path)
    if not StockMarket.UI.Materials[path] then
        StockMarket.UI.Materials[path] = Material(path, "smooth")
    end
    return StockMarket.UI.Materials[path]
end

-- ============== Tab Button =================
-- Single, safe implementation used by main and admin frames
function StockMarket.UI.Lib:TabButton(parent, label, iconPathOrMat)
    local btn = vgui.Create("DButton", parent)
    btn:SetText("")
    btn:SetTall(40)

    btn._label  = tostring(label or "Tab")
    btn._active = false
    btn._hover  = false

    -- Optional icon
    if type(iconPathOrMat) == "IMaterial" then
        btn._icon = iconPathOrMat
    elseif isstring(iconPathOrMat) and iconPathOrMat ~= "" then
        btn._icon = StockMarket.UI.GetMat(iconPathOrMat)
    else
        btn._icon = nil
    end

    -- Compute width (explicit, no inline and/or)
    surface.SetFont("StockMarket_ButtonFont")
    local textW = select(1, surface.GetTextSize(btn._label))
    local iconW = btn._icon and 20 or 0
    local gapW  = iconW > 0 and 6 or 0
    local totalW = 16 + iconW + gapW + textW + 16
    if totalW < 120 then totalW = 120 end
    btn:SetWide(totalW)

    btn.Paint = function(self, w, h)
        local bgColor
        if self._active then
            bgColor = StockMarket.UI.Colors.Primary
        elseif self._hover then
            bgColor = StockMarket.UI.Colors.BackgroundLight
        else
            bgColor = Color(0, 0, 0, 0)
        end

        draw.RoundedBox(6, 0, 0, w, h, bgColor)

        local textCol = self._active and StockMarket.UI.Colors.TextPrimary or StockMarket.UI.Colors.TextSecondary
        local x = 12

        if self._icon then
            surface.SetMaterial(self._icon)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(x, h/2 - 10, 20, 20)
            x = x + 26
        end

        draw.SimpleText(self._label, "StockMarket_ButtonFont", x, h/2, textCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    btn.OnCursorEntered = function(self) self._hover = true end
    btn.OnCursorExited  = function(self) self._hover = false end

    function btn:SetActive(active)
        self._active = active and true or false
        self:InvalidateLayout(true)
    end
    function btn:IsActive()
        return self._active
    end

    return btn
end

-- ============== Button =====================
function StockMarket.UI.Lib:Button(parent, text, onClick)
    local btn = vgui.Create("DButton", parent)
    btn:SetText("")
    btn.text = text or ""
    btn.hovered = false

    btn.Paint = function(self, w, h)
        local col = self.hovered and StockMarket.UI.Colors.PrimaryHover or StockMarket.UI.Colors.Primary
        draw.RoundedBox(6, 0, 0, w, h, col)
        draw.SimpleText(self.text, "StockMarket_ButtonFont", w/2, h/2, StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    btn.OnCursorEntered = function(self) self.hovered = true end
    btn.OnCursorExited  = function(self) self.hovered = false end
    if onClick then btn.DoClick = onClick end
    return btn
end

-- ============== TextEntry ==================
function StockMarket.UI.Lib:TextEntry(parent, placeholder)
    local entry = vgui.Create("DTextEntry", parent)
    entry:SetPlaceholderText(placeholder or "")
    entry:SetFont("StockMarket_TextFont")
    entry:SetTextColor(StockMarket.UI.Colors.TextPrimary)
    entry:SetCursorColor(StockMarket.UI.Colors.Primary)

    entry.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, StockMarket.UI.Colors.BackgroundDark)
        draw.RoundedBox(6, 1, 1, w - 2, h - 2, StockMarket.UI.Colors.BackgroundLight)
        self:DrawTextEntryText(self:GetTextColor(), self:GetHighlightColor(), self:GetCursorColor())
    end

    return entry
end

-- ============== Panel ======================
function StockMarket.UI.Lib:Panel(parent, color)
    local panel = vgui.Create("DPanel", parent)
    panel.bgColor = color or StockMarket.UI.Colors.BackgroundLight
    panel.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, self.bgColor)
    end
    return panel
end

-- ============== ScrollPanel =================
function StockMarket.UI.Lib:ScrollPanel(parent)
    local scroll = vgui.Create("DScrollPanel", parent)
    local sbar = scroll:GetVBar()
    sbar:SetWide(8)
    sbar.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, StockMarket.UI.Colors.BackgroundDark)
    end
    sbar.btnGrip.Paint = function(self, w, h)
        draw.RoundedBox(4, 0, 0, w, h, StockMarket.UI.Colors.Primary)
    end
    sbar.btnUp.Paint = function() end
    sbar.btnDown.Paint = function() end
    return scroll
end

-- ============== PriceLabel ==================
function StockMarket.UI.Lib:PriceLabel(parent, ticker)
    local label = vgui.Create("DPanel", parent)
    label.ticker = ticker
    label.price = 0
    label.change = 0
    label.changePercent = 0

    label.Paint = function(self, w, h)
        local priceData = StockMarket.StockData:GetPrice(self.ticker)
        if priceData then
            self.price = priceData.price
            self.change = priceData.change
            self.changePercent = priceData.changePercent
        end

        draw.SimpleText(
            StockMarket.Config.CurrencySymbol .. string.Comma(math.Round(self.price, 2)),
            "StockMarket_PriceFont", 0, 0,
            StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP
        )

        local up = (self.change or 0) >= 0
        local col = up and StockMarket.UI.Colors.Positive or StockMarket.UI.Colors.Negative
        local icon = up and StockMarket.UI.Icons.UpTrend or StockMarket.UI.Icons.DownTrend

        local iy = 28
        surface.SetMaterial(icon)
        surface.SetDrawColor(col.r, col.g, col.b, 255)
        surface.DrawTexturedRect(0, iy + 1, 14, 14)

        local ctext = string.format("%s%.2f (%.2f%%)", up and "+" or "", math.abs(self.change or 0), math.abs(self.changePercent or 0))
        draw.SimpleText(ctext, "StockMarket_SmallFont", 18, iy, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    return label
end

-- ============== InfoCard ====================
function StockMarket.UI.Lib:InfoCard(parent, title, value, icon)
    local card = self:Panel(parent)

    card.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, StockMarket.UI.Colors.BackgroundLight)
        draw.SimpleText(title or "", "StockMarket_SmallFont", 12, 12, StockMarket.UI.Colors.TextSecondary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(value or "", "StockMarket_TitleFont", 12, 35, StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    return card
end

-- ============== Chart Wrapper ===============
function StockMarket.UI.Lib:Chart(parent)
    if not StockMarket.UI.Chart or not StockMarket.UI.Chart.Create then
        ErrorNoHalt("[StockMarket] Chart library not loaded before Lib:Chart call.\n")
        local fallback = vgui.Create("DPanel", parent)
        fallback.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, StockMarket.UI.Colors.BackgroundLight)
            draw.SimpleText("Chart not loaded (load order)", "StockMarket_TextFont", w/2, h/2, StockMarket.UI.Colors.Danger, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        function fallback:LoadHistory() end
        function fallback:SetData() end
        return fallback
    end
    return StockMarket.UI.Chart:Create(parent)
end

-- ============== ComboBox ====================
-- Styled dropdown that draws text once (suppresses internal TextEntry)
function StockMarket.UI.Lib:ComboBox(parent, defaultOrChoices)
    local combo = vgui.Create("DComboBox", parent)
    combo:SetTall(32)
    combo:SetFont("StockMarket_TextFont")
    combo:SetSortItems(false)

    combo:SetText("")
    combo:SetTextColor(Color(0,0,0,0))
    combo:SetFGColor(Color(0,0,0,0))

    -- Hide internal TextEntry to prevent double draw
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

    combo._displayValue = tostring(defaultOrChoices or "Select...")

    combo.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, StockMarket.UI.Colors.BackgroundDark)
        draw.RoundedBox(6, 1, 1, w - 2, h - 2, StockMarket.UI.Colors.BackgroundLight)

        draw.SimpleText(self._displayValue or "", "StockMarket_TextFont",
            10, math.floor((h - 16) / 2), StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        surface.SetFont("StockMarket_SmallFont")
        local glyph = "▼"
        local _, th = surface.GetTextSize(glyph)
        draw.SimpleText(glyph, "StockMarket_SmallFont", w - 10, math.floor((h - th) / 2),
            StockMarket.UI.Colors.TextSecondary, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        return true
    end

    local function safeSetValue(v)
        combo._displayValue = tostring(v or "")
        DComboBox.SetValue(combo, combo._displayValue)
    end

    if istable(defaultOrChoices) then
        local choices = defaultOrChoices
        combo:Clear()
        for _, ch in ipairs(choices) do
            combo:AddChoice(tostring(ch))
        end
        if #choices > 0 then
            safeSetValue(choices[1])
        else
            safeSetValue("Select...")
        end
    else
        safeSetValue(defaultOrChoices or "Select...")
    end

    local baseOnSelect = combo.OnSelect
    combo.OnSelect = function(self, index, value, data)
        safeSetValue(value)
        if baseOnSelect then baseOnSelect(self, index, value, data) end
    end

    function combo:GetSelected()
        return self._displayValue
    end

    return combo
end

-- ============== Fonts =======================
surface.CreateFont("StockMarket_TitleFont", {
    font = "Roboto",
    size = 28,
    weight = 700
})

surface.CreateFont("StockMarket_SubtitleFont", {
    font = "Roboto",
    size = 20,
    weight = 600
})

surface.CreateFont("StockMarket_ButtonFont", {
    font = "Roboto",
    size = 16,
    weight = 600
})

surface.CreateFont("StockMarket_TextFont", {
    font = "Roboto",
    size = 16,
    weight = 400
})

surface.CreateFont("StockMarket_SmallFont", {
    font = "Roboto",
    size = 14,
    weight = 400
})

surface.CreateFont("StockMarket_TabFont", {
    font = "Roboto",
    size = 15,
    weight = 500
})

surface.CreateFont("StockMarket_PriceFont", {
    font = "Roboto",
    size = 24,
    weight = 700
})

surface.CreateFont("StockMarket_TickerFont", {
    font = "Roboto Mono",
    size = 18,
    weight = 700
})
