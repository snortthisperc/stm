-- ========================================
-- Admin Panel - Events/Triggers (Compact Builder + List with Controls)
-- ========================================

if not CLIENT then return end

StockMarket.UI.Admin = StockMarket.UI.Admin or {}

-- ==============
-- Safe Notifier
-- ==============
local function Notify(text, kind, dur)
    -- Prefer your Notifications system if present
    if StockMarket.UI and StockMarket.UI.Notifications and StockMarket.UI.Notifications.Add then
        StockMarket.UI.Notifications:Add(tostring(text or ""), tostring(kind or "info"), tonumber(dur or 4))
        return
    end
    -- Fallback to chat
    local col = Color(59,130,246)
    if kind == "success" then col = Color(34,197,94)
    elseif kind == "warning" then col = Color(251,191,36)
    elseif kind == "error" then col = Color(239,68,68) end
    chat.AddText(col, "[StockMarket] ", color_white, tostring(text or ""))
end

-- ========================================
-- Small UI helpers
-- ========================================

local function SmallButton(parent, label, C, onClick, w)
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b:SetTall(28)
    b:SetWide(w or 100)
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

local function GhostButton(parent, label, C, onClick, w)
    local b = vgui.Create("DButton", parent)
    b:SetText("")
    b:SetTall(24)
    b:SetWide(w or 80)
    local hover = false
    b.Paint = function(self, w2, h2)
        draw.RoundedBox(6, 0, 0, w2, h2, hover and Color(255,255,255,15) or Color(255,255,255,8))
        draw.SimpleText(label, "StockMarket_SmallFont", w2/2, h2/2, C.TextPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    b.OnCursorEntered = function() hover = true end
    b.OnCursorExited  = function() hover = false end
    b.DoClick = function() if onClick then onClick() end end
    return b
end

local function LabeledComboRow(parent, label, items, default, C)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:SetTall(36)
    row:DockMargin(0, 4, 0, 4)
    row.Paint = nil

    local lbl = vgui.Create("DLabel", row)
    lbl:Dock(LEFT)
    lbl:SetWide(110)
    lbl:SetText(label or "")
    lbl:SetFont("StockMarket_TextFont")
    lbl:SetTextColor(StockMarket.UI.Colors.TextSecondary)

    local cb = vgui.Create("DComboBox", row)
    cb:Dock(FILL)
    cb:SetSortItems(false)
    cb:SetFont("StockMarket_TextFont")
    cb:SetText("")
    cb:SetTextColor(Color(0,0,0,0))
    cb:SetFGColor(Color(0,0,0,0))

    -- Hide internal TextEntry child
    timer.Simple(0, function()
        if not IsValid(cb) then return end
        local txt = cb.GetTextArea and cb:GetTextArea() or cb.TextEntry
        if IsValid(txt) then
            txt:SetText("")
            txt:SetTextColor(Color(0,0,0,0))
            txt:SetCursorColor(Color(0,0,0,0))
            txt.Paint = function() end
        end
    end)

    cb._displayValue = isstring(default) and default or ""

    cb.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, StockMarket.UI.Colors.BackgroundDark)
        draw.RoundedBox(6, 1, 1, w - 2, h - 2, C.Background)
        draw.SimpleText(self._displayValue or "", "StockMarket_TextFont", 10, math.floor((h - 16) / 2), C.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        -- down arrow
        surface.SetFont("StockMarket_SmallFont")
        local glyph = "▼"
        local _, th = surface.GetTextSize(glyph)
        draw.SimpleText(glyph, "StockMarket_SmallFont", w - 10, math.floor((h - th) / 2), StockMarket.UI.Colors.TextSecondary, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    end

    -- Populate choices
    if istable(items) then
        cb:Clear()
        local initial = nil
        for _, it in ipairs(items) do
            local shown = isstring(it) and it or (it.name or it.label or it.stockPrefix or it.stockName or "Item")
            cb:AddChoice(shown, it, false)
            if not initial then initial = shown end
        end
        cb._displayValue = (default and default ~= "") and default or (initial or "")
        DComboBox.SetValue(cb, cb._displayValue)
    else
        cb._displayValue = tostring(default or "Select...")
        DComboBox.SetValue(cb, cb._displayValue)
    end

    local baseOnSelect = cb.OnSelect
    cb.OnSelect = function(self, idx, value, data)
        self._displayValue = tostring(value or "")
        DComboBox.SetValue(self, self._displayValue)
        if baseOnSelect then baseOnSelect(self, idx, value, data) end
    end

    return cb
end

local function LabeledEntryRow(parent, label, default, C)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:SetTall(36)
    row:DockMargin(0, 4, 0, 4)
    row.Paint = nil

    local lbl = vgui.Create("DLabel", row)
    lbl:Dock(LEFT)
    lbl:SetWide(110)
    lbl:SetText(label or "")
    lbl:SetFont("StockMarket_TextFont")
    lbl:SetTextColor(StockMarket.UI.Colors.TextSecondary)

    local ent = vgui.Create("DTextEntry", row)
    ent:Dock(FILL)
    ent:SetFont("StockMarket_TextFont")
    ent:SetText(default or "")
    ent:SetTextColor(StockMarket.UI.Colors.TextPrimary)
    ent:SetDrawBackground(true)
    ent:SetPaintBackground(true)
    ent.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, StockMarket.UI.Colors.BackgroundDark)
        draw.RoundedBox(6, 1, 1, w-2, h-2, C.Background)
        self:DrawTextEntryText(StockMarket.UI.Colors.TextPrimary, C.Primary, StockMarket.UI.Colors.TextPrimary)
    end

    return ent
end

local function PreviewCard(parent, C)
    local p = vgui.Create("DPanel", parent)
    p:SetTall(140)
    p:Dock(FILL)
    p:DockMargin(0, 8, 0, 8)
    p._ticker = ""
    p._message = ""
    p.Paint = function(self, w, h)
        draw.RoundedBox(8, 0, 0, w, h, C.BackgroundLight)
        draw.SimpleText("Preview", "StockMarket_SmallFont", 12, 8, StockMarket.UI.Colors.TextSecondary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        -- Header
        draw.SimpleText("BREAKING NEWS", "StockMarket_SubtitleFont", 20, 34, C.Primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        -- Message
        draw.DrawText(self._message ~= "" and self._message or "Message will appear here...", "StockMarket_TextFont", 20, 62, StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_LEFT)
        -- Ticker tag
        local tag = self._ticker ~= "" and self._ticker or "TICK"
        surface.SetFont("StockMarket_SmallFont")
        local tw, th = surface.GetTextSize(tag)
        local bx, by, bw, bh = w - (tw + 12) - 12, h - th - 16, tw + 12, th + 8
        draw.RoundedBox(6, bx, by, bw, bh, C.Primary)
        draw.SimpleText(tag, "StockMarket_SmallFont", bx + bw/2, by + bh/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    function p:SetData(ticker, message)
        self._ticker = ticker or ""
        self._message = message or ""
        self:InvalidateLayout(true)
    end
    return p
end

-- ==========================
-- Net payload (write helpers)
-- ==========================

local function NetWriteEventPayload(payload)
    net.WriteString(payload.ticker or "")
    net.WriteString(payload.handle or "")
    net.WriteString(payload.type or "")
    net.WriteString(payload.message or "")
    net.WriteFloat(tonumber(payload.weight or 0) or 0)
    net.WriteFloat(tonumber(payload.magnitude or 0) or 0)
    net.WriteUInt(math.max(0, tonumber(payload.duration or 0) or 0), 32)
    net.WriteUInt(math.max(0, tonumber(payload.preAlertSeconds or 0) or 0), 32)
end

local function NetReadEvent()
    local ev = {}
    ev.ticker = net.ReadString() or ""
    ev.handle = net.ReadString() or ""
    ev.type = net.ReadString() or ""
    ev.message = net.ReadString() or ""
    ev.weight = net.ReadFloat() or 0
    ev.magnitude = net.ReadFloat() or 0
    ev.duration = net.ReadUInt(32) or 0
    ev.preAlertSeconds = net.ReadUInt(32) or 0
    return ev
end

-- Build list of tickers once (and provide a refresh if needed)
local function GetTickersList()
    local out = {}
    if StockMarket and StockMarket.Config and StockMarket.Config.GetAllTickers then
        for _, t in ipairs(StockMarket.Config:GetAllTickers() or {}) do
            table.insert(out, {
                name = string.format("%s (%s)", t.stockName or "Stock", t.stockPrefix or "TICK"),
                stockPrefix = t.stockPrefix or "TICK",
            })
        end
    end
    table.SortByMember(out, "name", true)
    return out
end

-- Helper to extract stockPrefix from a DComboBox selection
local function ResolveTickerPrefixFromCombo(cb, defaultPrefix)
    if not IsValid(cb) then return defaultPrefix end
    local id = cb.GetSelectedID and cb:GetSelectedID()
    if id then
        local data = cb:GetOptionData(id)
        if istable(data) and data.stockPrefix then
            return data.stockPrefix
        end
    end
    return defaultPrefix
end

-- Allowed event types
local EVENT_TYPES = { "JUMP", "DRIFT", "PUMP", "CRASH", "VOLATILITY", "CHAOS" }

-- Build a lookup table to avoid table.HasValue
local EVENT_TYPES_LUT = {}
do
    for _, v in ipairs(EVENT_TYPES) do
        EVENT_TYPES_LUT[v] = true
    end
end

-- ==========================
-- Events Panel (Main entry)
-- ==========================

function StockMarket.UI.Admin.Events(content, C)
    -- Header
    local header = vgui.Create("DPanel", content)
    header:Dock(TOP)
    header:SetTall(56)
    header:DockMargin(0,0,0,8)
    header.Paint = function(self,w,h)
        draw.RoundedBox(8,0,0,w,h,C.BackgroundLight)
        draw.SimpleText("Event & Trigger Manager", "StockMarket_SubtitleFont", 12, h/2, StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Builder container (left form + right preview)
    local builder = vgui.Create("DPanel", content)
    builder:Dock(TOP)
    builder:SetTall(340)
    builder:DockMargin(0, 0, 0, 10)
    builder.Paint = nil

    -- Scrollable left builder
    local leftWrap = vgui.Create("DPanel", builder)
    leftWrap:Dock(LEFT)
    leftWrap:SetWide(math.floor(content:GetWide() * 0.55))
    leftWrap:DockMargin(0,0,8,0)
    leftWrap.Paint = function(self,w,h) draw.RoundedBox(8,0,0,w,h,C.BackgroundLight) end
    leftWrap:DockPadding(8,8,8,52) -- reserve 52 for bottom actions

    local leftScroll = vgui.Create("DScrollPanel", leftWrap)
    leftScroll:Dock(FILL)

    local left = vgui.Create("DPanel", leftScroll)
    left:Dock(TOP)
    left:SetTall(0)
    left.Paint = nil
    function left:PerformLayout(w, h)
        local total = 0
        for _, child in ipairs(self:GetChildren()) do
            if IsValid(child) then
                total = total + child:GetTall()
                local l,t,r,b = child:GetDockMargin()
                total = total + t + b
            end
        end
        self:SetTall(math.max(total + 4, 10))
    end
    function left:OnChildAdded() self:InvalidateLayout(true) end
    function left:OnChildRemoved() self:InvalidateLayout(true) end

    local right = vgui.Create("DPanel", builder)
    right:Dock(FILL)
    right.Paint = function(self,w,h) draw.RoundedBox(8,0,0,w,h,C.BackgroundLight) end
    right:DockPadding(12,10,12,10)

    -- Left: fields
    local tickers = GetTickersList()
    local defaultTicker = (tickers[1] and tickers[1].stockPrefix) or "TICK"

    -- Build the "Ticker" row manually so the label changes visually on selection
    local tickerRow = vgui.Create("DPanel", left)
    tickerRow:Dock(TOP)
    tickerRow:SetTall(36)
    tickerRow:DockMargin(0, 4, 0, 4)
    tickerRow.Paint = nil

    local tickerLbl = vgui.Create("DLabel", tickerRow)
    tickerLbl:Dock(LEFT)
    tickerLbl:SetWide(110)
    tickerLbl:SetText("Ticker")
    tickerLbl:SetFont("StockMarket_TextFont")
    tickerLbl:SetTextColor(StockMarket.UI.Colors.TextSecondary)

    local tickerCombo = vgui.Create("DComboBox", tickerRow)
    tickerCombo:Dock(FILL)
    tickerCombo:SetSortItems(false)
    tickerCombo:SetFont("StockMarket_TextFont")
    tickerCombo:SetText("")
    tickerCombo:SetTextColor(Color(0,0,0,0))
    tickerCombo:SetFGColor(Color(0,0,0,0))

    -- Hide internal text area (prevent double text)
    timer.Simple(0, function()
        if not IsValid(tickerCombo) then return end
        local txt = tickerCombo.GetTextArea and tickerCombo:GetTextArea() or tickerCombo.TextEntry
        if IsValid(txt) then
            txt:SetText("")
            txt:SetTextColor(Color(0,0,0,0))
            txt:SetCursorColor(Color(0,0,0,0))
            txt.Paint = function() end
        end
    end)

    -- Populate choices
    tickerCombo:Clear()
    for _, it in ipairs(tickers) do
        tickerCombo:AddChoice(it.name, it, false)
    end

    -- Shadow visible label
    tickerCombo._displayValue = (tickers[1] and tickers[1].name) or "Select..."
    DComboBox.SetValue(tickerCombo, tickerCombo._displayValue)

    -- Track chosen prefix
    local SelectedTickerPrefix = defaultTicker

    tickerCombo.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, StockMarket.UI.Colors.BackgroundDark)
        draw.RoundedBox(6, 1, 1, w - 2, h - 2, C.Background)
        draw.SimpleText(self._displayValue or "", "StockMarket_TextFont",
            10, math.floor((h - 16) / 2), C.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        surface.SetFont("StockMarket_SmallFont")
        local glyph = "▼"
        local _, th = surface.GetTextSize(glyph)
        draw.SimpleText(glyph, "StockMarket_SmallFont", w - 10, math.floor((h - th) / 2),
            StockMarket.UI.Colors.TextSecondary, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        return true
    end

    local function ResolveFromCombo(cb, fallbackPrefix)
        local id = cb.GetSelectedID and cb:GetSelectedID()
        if id then
            local data = cb:GetOptionData(id)
            if istable(data) and data.stockPrefix then
                return data.stockPrefix
            end
        end
        return fallbackPrefix
    end

    -- Keep both label and prefix in sync
    local baseOnSelect = tickerCombo.OnSelect
    tickerCombo.OnSelect = function(self, index, value, data)
        if baseOnSelect then baseOnSelect(self, index, value, data) end
        self._displayValue = tostring(value or self._displayValue or "")
        DComboBox.SetValue(self, self._displayValue)

        if istable(data) and data.stockPrefix then
            SelectedTickerPrefix = data.stockPrefix
        else
            SelectedTickerPrefix = ResolveFromCombo(self, defaultTicker)
        end

        if IsValid(preview) and preview.SetData then
            preview:SetData(SelectedTickerPrefix, msgEnt:GetValue() or "")
        end
    end

    -- Accessor used by preview/save/trigger
    local function GetCurrentTickerPrefix()
        if SelectedTickerPrefix and SelectedTickerPrefix ~= "" then return SelectedTickerPrefix end
        return ResolveFromCombo(tickerCombo, defaultTicker) or defaultTicker
    end

    local typeCombo   = LabeledComboRow(left, "Type", EVENT_TYPES, "PUMP", C)
    local weightEnt   = LabeledEntryRow(left, "Weight", "1.0", C)
    local magEnt      = LabeledEntryRow(left, "Magnitude", "4", C)
    local durEnt      = LabeledEntryRow(left, "Duration (s)", "300", C)
    local preEnt      = LabeledEntryRow(left, "Pre-Alert (s)", "20", C)
    local msgEnt      = LabeledEntryRow(left, "Message", "Event announcement here...", C)

    -- Right: preview
    local preview = PreviewCard(right, C)
    local function updatePreview()
        local tkr = GetCurrentTickerPrefix()
        preview:SetData(tkr, msgEnt:GetValue() or "")
    end
    msgEnt.OnChange = updatePreview
    timer.Simple(0, updatePreview)

    -- Builder actions (fixed bottom bar inside leftWrap)
    local actions = vgui.Create("DPanel", leftWrap)
    actions:Dock(BOTTOM)
    actions:SetTall(36)
    actions:DockMargin(0, 8, 0, 8)
    actions.Paint = nil

    local btnSave = SmallButton(actions, "Save Event", C, function()
        local tkr = GetCurrentTickerPrefix()
        if not tkr or tkr == "" then
            Notify("Select a ticker", "warning")
            return
        end

        local chosenType = string.upper(typeCombo:GetValue() or "PUMP")
        if not EVENT_TYPES_LUT[chosenType] then chosenType = "PUMP" end

        local handle = string.format("%s_%d", chosenType, math.random(100, 999))

        local payload = {
            ticker = tkr,
            handle = handle,
            type = chosenType,
            weight = tonumber(weightEnt:GetValue()) or 1.0,
            magnitude = tonumber(magEnt:GetValue()) or 0,
            duration = tonumber(durEnt:GetValue()) or 60,
            preAlertSeconds = tonumber(preEnt:GetValue()) or 0,
            message = msgEnt:GetValue() or ""
        }

        net.Start("StockMarket_Admin_SaveEvent")
        NetWriteEventPayload(payload)
        net.SendToServer()

        Notify("Event saved for ".. tkr, "success")
    end, 120)
    btnSave:Dock(LEFT)

    local btnTrigger = GhostButton(actions, "Trigger Now", C, function()
        local tkr = GetCurrentTickerPrefix()
        if not tkr or tkr == "" then
            Notify("Select a ticker", "warning")
            return
        end

        local chosenType = string.upper(typeCombo:GetValue() or "PUMP")
        if not EVENT_TYPES_LUT[chosenType] then chosenType = "PUMP" end

        local handle = "ADMIN_QUICK_" .. math.random(100,999)
        local payload = {
            ticker = tkr,
            handle = handle,
            type = chosenType,
            weight = tonumber(weightEnt:GetValue()) or 1.0,
            magnitude = tonumber(magEnt:GetValue()) or 0,
            duration = tonumber(durEnt:GetValue()) or 60,
            preAlertSeconds = tonumber(preEnt:GetValue()) or 0,
            message = msgEnt:GetValue() or ""
        }

        net.Start("StockMarket_Admin_SaveEvent")
        NetWriteEventPayload(payload)
        net.SendToServer()

        timer.Simple(0.05, function()
            net.Start("StockMarket_Admin_TriggerEvent")
            net.WriteString(tkr)
            net.WriteString(handle)
            net.SendToServer()
        end)

        Notify("Triggered event for " .. tkr, "success")
    end, 110)
    btnTrigger:Dock(LEFT)
    btnTrigger:DockMargin(8,0,0,0)

    -- Fallback: if list was empty at open, retry after short delay
    if (#tickers == 0) then
        timer.Simple(0.2, function()
            local t = GetTickersList()
            if #t == 0 or not IsValid(tickerCombo) then return end
            tickerCombo:Clear()
            for _, it in ipairs(t) do
                tickerCombo:AddChoice(it.name, it, false)
            end
            if t[1] then
                tickerCombo:SetValue(t[1].name)
                defaultTicker = t[1].stockPrefix
            end
            updatePreview()
        end)
    end

    -- Divider
    local divider = vgui.Create("DPanel", content)
    divider:Dock(TOP)
    divider:SetTall(36)
    divider:DockMargin(0, 0, 0, 8)
    divider.Paint = function(self,w,h)
        draw.SimpleText("Existing Events", "StockMarket_SubtitleFont", 0, h-22, StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
        surface.SetDrawColor(StockMarket.UI.Colors.Border)
        surface.DrawLine(0, h-2, w, h-2)
    end

    -- Filter bar
    local bar = vgui.Create("DPanel", content)
    bar:Dock(TOP)
    bar:SetTall(44)
    bar:DockMargin(0,0,0,8)
    bar.Paint = nil

    local filterRow = vgui.Create("DPanel", bar)
    filterRow:Dock(TOP)
    filterRow:SetTall(36)
    filterRow.Paint = nil

    local filterLbl = vgui.Create("DLabel", filterRow)
    filterLbl:Dock(LEFT)
    filterLbl:SetWide(110)
    filterLbl:SetText("Filter Ticker")
    filterLbl:SetFont("StockMarket_TextFont")
    filterLbl:SetTextColor(StockMarket.UI.Colors.TextSecondary)

    local filterTickers = GetTickersList()
    local filterCombo = vgui.Create("DComboBox", filterRow)
    filterCombo:Dock(FILL)
    filterCombo:SetFont("StockMarket_TextFont")
    filterCombo:SetSortItems(false)
    filterCombo:SetText("")
    filterCombo:SetTextColor(Color(0,0,0,0))
    filterCombo:SetFGColor(Color(0,0,0,0))

    -- Hide internal TextEntry to avoid double drawing
    timer.Simple(0, function()
        if not IsValid(filterCombo) then return end
        local txt = filterCombo.GetTextArea and filterCombo:GetTextArea() or filterCombo.TextEntry
        if IsValid(txt) then
            txt:SetText("")
            txt:SetTextColor(Color(0,0,0,0))
            txt:SetCursorColor(Color(0,0,0,0))
            txt.Paint = function() end
        end
    end)

    -- Mirror visible value into a custom display field so only one label is drawn
    filterCombo._displayValue = (filterTickers[1] and filterTickers[1].name) or ""
    filterCombo.Paint = function(self, w, h)
        draw.RoundedBox(6, 0, 0, w, h, StockMarket.UI.Colors.BackgroundDark)
        draw.RoundedBox(6, 1, 1, w - 2, h - 2, C.Background)
        draw.SimpleText(self._displayValue or "", "StockMarket_TextFont", 10, math.floor((h - 16) / 2), C.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

        surface.SetFont("StockMarket_SmallFont")
        local glyph = "▼"
        local _, th = surface.GetTextSize(glyph)
        draw.SimpleText(glyph, "StockMarket_SmallFont", w - 10, math.floor((h - th) / 2), StockMarket.UI.Colors.TextSecondary, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
        return true
    end

    filterCombo:Clear()
    for _, it in ipairs(filterTickers) do
        filterCombo:AddChoice(it.name, it, false)
    end
    if filterTickers[1] then
        filterCombo:SetValue(filterTickers[1].name)
    end

    -- Keep _displayValue in sync on selection
    local filterBaseOnSelect = filterCombo.OnSelect
    filterCombo.OnSelect = function(self, index, value, data)
        if filterBaseOnSelect then filterBaseOnSelect(self, index, value, data) end
        self._displayValue = tostring(value or "")
        DComboBox.SetValue(self, self._displayValue)
    end

    local btnLoad = SmallButton(filterRow, "Load", C, function()
        local tkr = ResolveTickerPrefixFromCombo(filterCombo, defaultTicker)
        if not tkr or tkr == "" then
            Notify("Select a ticker to load", "warning")
            return
        end
        net.Start("StockMarket_Admin_GetEvents")
        net.WriteString(tkr)
        net.SendToServer()
        bar._lastTicker = tkr
    end, 80)
    btnLoad:Dock(RIGHT)
    btnLoad:DockMargin(8,0,0,0)

    -- Events list
    local list = vgui.Create("DScrollPanel", content)
    list:Dock(FILL)

    -- Small action button set for each event row
    local function ActionButtons(parent, ev, tkr, C)
        local panel = vgui.Create("Panel", parent)
        panel:Dock(RIGHT)
        panel:SetWide(320)

        local btnTrigger = GhostButton(panel, "Trigger", C, function()
            net.Start("StockMarket_Admin_TriggerEvent")
            net.WriteString(tkr)
            net.WriteString(ev.handle or "")
            net.SendToServer()
            Notify("Triggered event: " .. (ev.handle or "?"), "success")
        end, 70)
        btnTrigger:Dock(RIGHT); btnTrigger:DockMargin(6,6,0,6)

        local btnDelete = GhostButton(panel, "Delete", C, function()
            Derma_Query("Delete event ".. (ev.handle or "?") .." ?", "Confirm", "Delete", function()
                net.Start("StockMarket_Admin_DeleteEvent")
                net.WriteString(tkr)
                net.WriteString(ev.handle or "")
                net.SendToServer()
                Notify("Deleted event: " .. (ev.handle or "?"), "success")
                -- Reload list
                timer.Simple(0.1, function()
                    net.Start("StockMarket_Admin_GetEvents")
                    net.WriteString(tkr)
                    net.SendToServer()
                end)
            end, "Cancel")
        end, 70)
        btnDelete:Dock(RIGHT); btnDelete:DockMargin(6,6,0,6)

        local btnSave = GhostButton(panel, "Edit", C, function()
            -- Quick edit dialog
            local fr = vgui.Create("DFrame")
            fr:SetSize(520, 380); fr:Center(); fr:SetTitle("Edit Event: " .. (ev.handle or "")); fr:MakePopup()
            local inner = vgui.Create("DPanel", fr)
            inner:Dock(FILL); inner:DockMargin(10,10,10,56); inner.Paint = nil

            local eType = LabeledComboRow(inner, "Type", EVENT_TYPES, (ev.type or "PUMP"):upper(), C)
            local eWeight= LabeledEntryRow(inner, "Weight", tostring(ev.weight or 1.0), C)
            local eMag   = LabeledEntryRow(inner, "Magnitude", tostring(ev.magnitude or 0), C)
            local eDur   = LabeledEntryRow(inner, "Duration (s)", tostring(ev.duration or 60), C)
            local ePre   = LabeledEntryRow(inner, "Pre-Alert (s)", tostring(ev.preAlertSeconds or 0), C)
            local eMsg   = LabeledEntryRow(inner, "Message", ev.message or "", C)

            local save = SmallButton(fr, "Save Changes", C, function()
                local payload = {
                    ticker = tkr,
                    handle = ev.handle or "",
                    type = string.upper(eType:GetValue() or ev.type or "PUMP"),
                    weight = tonumber(eWeight:GetValue()) or ev.weight or 1.0,
                    magnitude = tonumber(eMag:GetValue()) or ev.magnitude or 0,
                    duration = tonumber(eDur:GetValue()) or ev.duration or 60,
                    preAlertSeconds = tonumber(ePre:GetValue()) or ev.preAlertSeconds or 0,
                    message = eMsg:GetValue() or ev.message or ""
                }
                net.Start("StockMarket_Admin_SaveEvent")
                NetWriteEventPayload(payload)
                net.SendToServer()
                Notify("Updated event: " .. payload.handle, "success")
                fr:Close()
                -- Reload list
                timer.Simple(0.1, function()
                    net.Start("StockMarket_Admin_GetEvents")
                    net.WriteString(tkr)
                    net.SendToServer()
                end)
            end, 120)
            save:Dock(BOTTOM); save:DockMargin(10,0,10,10)
        end, 70)
        btnSave:Dock(RIGHT); btnSave:DockMargin(6,6,0,6)

    -- Schedule (supports 90, 90s, 10m, 2h, 1d)
    local btnSchedule = GhostButton(panel, "Schedule", C, function()
        local fr = vgui.Create("DFrame")
        fr:SetSize(380, 200)
        fr:Center()
        fr:SetTitle("Schedule Event")
        fr:MakePopup()

        local inner = vgui.Create("DPanel", fr)
        inner:Dock(FILL)
        inner:DockMargin(10, 10, 10, 56)
        inner.Paint = nil

        local whenEntry = LabeledEntryRow(inner, "When", "60s", C)

        local function parseDuration(str)
            str = tostring(str or ""):Trim():lower()
            if str == "" then return 0 end
            -- pure number => seconds
            if string.match(str, "^%d+$") then
                return tonumber(str) or 0
            end
            -- number + unit (s|m|h|d)
            local n, unit = string.match(str, "^(%d+)%s*([smhd])$")
            n = tonumber(n or 0) or 0
            if n <= 0 then return 0 end
            if unit == "s" then return n end
            if unit == "m" then return n * 60 end
            if unit == "h" then return n * 3600 end
            if unit == "d" then return n * 86400 end
            return 0
        end

        local function humanizeSeconds(sec)
            if sec < 60 then return string.format("%ds", sec) end
            if sec < 3600 then return string.format("%dm %ds", math.floor(sec/60), sec%60) end
            if sec < 86400 then
                local h = math.floor(sec/3600)
                local m = math.floor((sec%3600)/60)
                return string.format("%dh %dm", h, m)
            end
            local d = math.floor(sec/86400)
            local h = math.floor((sec%86400)/3600)
            return string.format("%dd %dh", d, h)
        end

        local sBtn = SmallButton(fr, "Schedule", C, function()
            local raw = whenEntry:GetValue()
            local s = math.max(0, math.floor(parseDuration(raw)))
            if s <= 0 then
                Notify("Enter a valid time like: 90, 90s, 10m, 2h, 1d", "warning")
                return
            end
            local delayText = humanizeSeconds(s)

            timer.Simple(s, function()
                net.Start("StockMarket_Admin_TriggerEvent")
                net.WriteString(tkr)
                net.WriteString(ev.handle or "")
                net.SendToServer()
                Notify("Triggered scheduled event: " .. (ev.handle or "?"), "success")
            end)

            Notify("Event scheduled in " .. delayText, "success")
            fr:Close()
        end, 100)
        sBtn:Dock(BOTTOM)
        sBtn:DockMargin(10, 0, 10, 10)
    end, 70)
    btnSchedule:Dock(RIGHT)
    btnSchedule:DockMargin(6,6,0,6)

        return panel
    end

    -- Build one event card
    local function EventCard(parent, ev, tkr, C)
        local row = vgui.Create("DPanel", parent)
        row:Dock(TOP)
        row:SetTall(84)
        row:DockMargin(0, 0, 0, 6)
        row.Paint = function(self, w, h)
            draw.RoundedBox(8, 0, 0, w, h, C.BackgroundLight)
            draw.SimpleText(string.format("%s [%s]", ev.handle or "Unnamed", (ev.type or "?"):upper()), "StockMarket_TextFont", 12, 8, StockMarket.UI.Colors.TextPrimary)
            local details = string.format("weight %.2f | magnitude %s | duration %ds | pre %ds", ev.weight or 1.0, tostring(ev.magnitude or 0), ev.duration or 0, ev.preAlertSeconds or 0)
            draw.SimpleText(details, "StockMarket_SmallFont", 12, 30, StockMarket.UI.Colors.TextSecondary)
            draw.SimpleText(ev.message or "", "StockMarket_SmallFont", 12, 50, StockMarket.UI.Colors.TextSecondary)
        end

        ActionButtons(row, ev, tkr, C)
        return row
    end

    -- Net receiver: populate events
    net.Receive("StockMarket_Admin_GetEvents", function()
        -- Read rows
        local count = net.ReadUInt(16) or 0
        local data = {}
        for i = 1, count do
            data[i] = NetReadEvent()
        end

        -- Rebuild list
        list:Clear()

        -- Empty state
        if #data == 0 then
            local empty = vgui.Create("DPanel", list)
            empty:Dock(TOP)
            empty:SetTall(120)
            empty:DockMargin(0, 10, 0, 0)
            empty.Paint = function(self, w, h)
                draw.RoundedBox(8, 0, 0, w, h, C.BackgroundLight)
                draw.SimpleText("No events found for this ticker.", "StockMarket_TextFont",
                    w/2, h/2 - 8, StockMarket.UI.Colors.TextMuted, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                draw.SimpleText("Create a new one above or choose a different ticker.", "StockMarket_SmallFont",
                    w/2, h/2 + 16, StockMarket.UI.Colors.TextSecondary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            -- Also reflect filter display if we know the last ticker
            if IsValid(filterCombo) and bar._lastTicker and istable(filterTickers) then
                for _, it in ipairs(filterTickers) do
                    if it.stockPrefix == bar._lastTicker then
                        filterCombo._displayValue = it.name
                        DComboBox.SetValue(filterCombo, it.name)
                        break
                    end
                end
            end

            return
        end

        -- Render event rows for the last requested ticker (fallback to default)
        local tkr = bar._lastTicker or defaultTicker
        for _, ev in ipairs(data) do
            EventCard(list, ev, tkr, C)
        end

        -- Keep "Filter Ticker" combobox display in sync with last loaded ticker
        if IsValid(filterCombo) and bar._lastTicker and istable(filterTickers) then
            for _, it in ipairs(filterTickers) do
                if it.stockPrefix == bar._lastTicker then
                    filterCombo._displayValue = it.name
                    DComboBox.SetValue(filterCombo, it.name)
                    break
                end
            end
        end
    end)
end