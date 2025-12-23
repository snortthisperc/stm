-- ========================================
-- Notification System (Polished, Configurable)
-- ========================================

local CFG = function()
    return (StockMarket.Config and StockMarket.Config.Notifications) or {}
end

StockMarket.UI = StockMarket.UI or {}
StockMarket.UI.Notifications = StockMarket.UI.Notifications or {}
local Notif = StockMarket.UI.Notifications

Notif.Queue = Notif.Queue or {} -- live notifications (visible or fading)
Notif._lastLayout = 0

-- Internal glyphs (simple, always available)
local GLYPHS = {
    info    = "",  -- requires FontAwesome to look best; falls back to text if missing
    success = "",
    warning = "",
    error   = ""
}

-- Pick a font that exists; you can add a FontAwesome font if desired
surface.CreateFont("SM_Notif_Title", { font = "Roboto", size = 16, weight = 700 })
surface.CreateFont("SM_Notif_Text",  { font = "Roboto", size = 15, weight = 500 })
surface.CreateFont("SM_Notif_Icon",  { font = "Marlett", size = 18, weight = 500 }) -- fallback icon font

-- Helpers
local function LerpEaseOutCubic(t) return 1 - (1 - t) ^ 3 end

local function getStyle(kind)
    kind = tostring(kind or "info"):lower()
    local s = (CFG().styles and CFG().styles[kind]) or {
        bg = Color(32, 36, 45),
        accent = Color(59, 130, 246),
        text = Color(235, 240, 245)
    }
    return s
end

local function computeAnchor(w, h, idx, total)
    local cfg = CFG()
    local pos = (cfg.position or "top_right"):lower()
    local spacing = cfg.spacing or 10
    local screenW, screenH = ScrW(), ScrH()

    local marginX, marginY = 20, 20
    local totalH = (h * total) + (spacing * (total - 1))

    local x, y

    if pos == "top_right" then
        x = screenW - marginX - w
        y = marginY + (idx - 1) * (h + spacing)
    elseif pos == "top_left" then
        x = marginX
        y = marginY + (idx - 1) * (h + spacing)
    elseif pos == "bottom_right" then
        x = screenW - marginX - w
        y = screenH - marginY - (h * (total - idx + 1)) - (spacing * (total - idx))
    elseif pos == "bottom_left" then
        x = marginX
        y = screenH - marginY - (h * (total - idx + 1)) - (spacing * (total - idx))
    elseif pos == "center_top" then
        x = math.floor((screenW - w) / 2)
        y = marginY + (idx - 1) * (h + spacing)
    elseif pos == "center_bottom" then
        x = math.floor((screenW - w) / 2)
        y = screenH - marginY - totalH + (idx - 1) * (h + spacing)
    else
        -- default
        x = screenW - marginX - w
        y = marginY + (idx - 1) * (h + spacing)
    end

    return x, y
end

local function drawShadow(x, y, w, h)
    surface.SetDrawColor(0, 0, 0, 80)
    surface.DrawRect(x + 4, y + 4, w, h)
end

-- API: Add(message, type, duration, title)
function Notif:Add(message, kind, duration, title)
    if CFG().enabled == false then return end

    local now = CurTime()
    local life = tonumber(duration) or CFG().life or 5
    local w = math.max(240, CFG().width or 340)
    local h = 70

    local item = {
        id = "smnf_" .. tostring(SysTime()) .. "_" .. math.random(1000, 9999),
        title = title or "",
        message = tostring(message or ""),
        kind = tostring(kind or "info"),
        createdAt = now,
        duration = life,
        alpha = 0,
        w = w,
        h = h,
        -- animation state
        _fadeIn = 0,
        _fadeOut = 0,
        _yOffset = 0, -- could be used for stacking transitions later
    }

    -- Sound (optional)
    if StockMarket.Config and StockMarket.Config.EnableSounds then
        surface.PlaySound("stockmarket/notification.wav")
    end

    table.insert(self.Queue, item)

    -- Cap max visible
    local maxVis = CFG().maxVisible or 6
    if #self.Queue > maxVis then
        -- remove oldest visible
        table.remove(self.Queue, 1)
    end
end

local function drawProgressBar(x, y, w, h, item, style)
    if CFG().showProgress == false then return end

    local elapsed = CurTime() - item.createdAt
    local t = math.Clamp(elapsed / (item.duration > 0 and item.duration or 1), 0, 1)
    local remW = w * (1 - t)

    surface.SetDrawColor(style.accent.r, style.accent.g, style.accent.b, 160)
    surface.DrawRect(x, y + h - 4, remW, 3)
end

local function drawNotification(index, total, item)
    local cfg = CFG()
    local radius = cfg.cornerRadius or 8
    local style = getStyle(item.kind)

    -- time & alpha
    local now = CurTime()
    local elapsed = now - item.createdAt

    local dying = elapsed >= item.duration
    if not dying then
        -- fade in
        item._fadeIn = math.min((item._fadeIn or 0) + FrameTime() * 6, 1)
        item.alpha = LerpEaseOutCubic(item._fadeIn) * 255
    else
        -- fade out
        item._fadeOut = (item._fadeOut or 0) + FrameTime() * 6
        local out = 1 - math.Clamp(item._fadeOut, 0, 1)
        item.alpha = out * 255
    end

    -- positions
    local w, h = item.w, item.h
    local x, y = computeAnchor(w, h, index, total)

    -- shadow
    if cfg.shadow ~= false then
        drawShadow(x, y, w, h)
    end

    -- background
    draw.RoundedBox(radius, x, y, w, h, ColorAlpha(style.bg, item.alpha))

    -- accent bar
    draw.RoundedBox(radius, x, y, 6, h, ColorAlpha(style.accent, item.alpha))

    -- icon + text paddings
    local iconW = 18
    local pad = 12
    local tx = x + 6 + pad
    local ty = y + 10

    -- icon (use glyph)
    surface.SetFont("SM_Notif_Icon")
    local glyph = GLYPHS[item.kind] or "!"
    local gw, gh = surface.GetTextSize(glyph)
    draw.SimpleText(glyph, "SM_Notif_Icon", tx, ty + 3, ColorAlpha(style.accent, item.alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    local textX = tx + iconW + 8

    -- title (optional)
    if item.title and item.title ~= "" then
        draw.SimpleText(item.title, "SM_Notif_Title", textX, ty, ColorAlpha(style.text, item.alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        draw.SimpleText(item.message, "SM_Notif_Text", textX, ty + 20, ColorAlpha(style.text, item.alpha * 0.95), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    else
        draw.SimpleText(item.message, "SM_Notif_Text", textX, ty + 8, ColorAlpha(style.text, item.alpha), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    end

    -- progress bar
    drawProgressBar(x + 6, y, w - 12, h, item, style)

    -- return whether finished and fully faded
    return (dying and item.alpha <= 1)
end

function Notif:Draw()
    if CFG().enabled == false then return end
    if #self.Queue == 0 then return end

    -- draw in stacking order
    local toRemove = {}
    for i = 1, #self.Queue do
        local finished = drawNotification(i, #self.Queue, self.Queue[i])
        if finished then table.insert(toRemove, 1, i) end
    end

    -- cleanup from end to start
    for _, idx in ipairs(toRemove) do
        table.remove(self.Queue, idx)
    end
end

-- Draw hook
hook.Add("HUDPaint", "StockMarket_DrawNotifications", function()
    Notif:Draw()
end)

hook.Add("GUIMousePressed", "SM_Notif_ClickDismiss", function(mc)
    if mc ~= MOUSE_LEFT then return end
    local cfg = CFG()
    if cfg.enabled == false then return end
    if #Notif.Queue == 0 then return end

    -- compute current rects and remove the top-most hit
    for i = #Notif.Queue, 1, -1 do
        local item = Notif.Queue[i]
        local w, h = item.w, item.h
        local x, y = computeAnchor(w, h, i, #Notif.Queue)
        local mx, my = gui.MousePos()
        if mx >= x and mx <= (x + w) and my >= y and my <= (y + h) then
            table.remove(Notif.Queue, i)
            break
        end
    end
end)
