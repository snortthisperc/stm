-- ========================================
-- Stock Market Scoreboard (Client, 3D2D Render)
-- ========================================

include("shared.lua")

-- Fonts (large & legible)
surface.CreateFont("SM_Board_Title",  { font = "Roboto",      size = 64, weight = 900 })
surface.CreateFont("SM_Board_Header", { font = "Roboto",      size = 28, weight = 700 })
surface.CreateFont("SM_Board_Row",    { font = "Roboto",      size = 28, weight = 600 })
surface.CreateFont("SM_Board_Price",  { font = "Roboto Mono", size = 28, weight = 800 })
surface.CreateFont("SM_Board_Footer", { font = "Roboto",      size = 22, weight = 500 })

-- Colors (custom but close to theme)
local C = {
    Back   = Color(18, 21, 28, 240),
    Panel  = Color(26, 30, 39, 255),
    Border = Color(55, 65, 81, 255),
    Title  = Color(59, 130, 246, 255),
    Text   = Color(235, 240, 245, 255),
    Muted  = Color(156, 163, 175, 255),
    Up     = Color(34, 197, 94, 255),
    Down   = Color(239, 68, 68, 255)
}

-- Canvas & scale
local CANVAS_W = 1120
local CANVAS_H = 680
local SCALE    = 0.12

-- Layout (hard separation between sections)
local MARGIN     = 24
local TITLE_H    = 92  -- Title block
local HEAD_H     = 56  -- Header bar
local ROW_H      = 46  -- Row height
local FOOT_H     = 36  -- Footer block
local GAP_Y      = 10  -- Gap between sections
local MAX_ROWS   = 8   -- Upper cap for rows rendered
local HYDRATE_EVERY = 5 -- seconds

-- Centered-canvas helpers and constants
local HALF_W = CANVAS_W * 0.5
local HALF_H = CANVAS_H * 0.5

local function DrawCenteredRect(xCenter, yCenter, w, h, col)
    surface.SetDrawColor(col)
    surface.DrawRect(xCenter - w * 0.5, yCenter - h * 0.5, w, h)
end

local function RoundedBoxCentered(radius, xCenter, yCenter, w, h, col)
    draw.RoundedBox(radius, xCenter - w * 0.5, yCenter - h * 0.5, w, h, col)
end

-- Draw text clamped to a max width; truncates with ellipsis if needed
local function DrawFittedText(txt, font, x, y, col, xalign, yalign, maxW)
    surface.SetFont(font)
    local tw = select(1, surface.GetTextSize(txt or ""))
    if maxW and maxW > 0 and tw > maxW then
        local ell = "…"
        local s = tostring(txt or "")
        local lo, hi = 0, #s
        while lo < hi do
            local mid = math.floor((lo + hi) / 2)
            local cut = string.sub(s, 1, mid) .. ell
            if select(1, surface.GetTextSize(cut)) <= maxW then
                lo = mid + 1
            else
                hi = mid
            end
        end
        txt = string.sub(s, 1, math.max(0, lo - 1)) .. ell
    end
    draw.SimpleText(txt, font, x, y, col, xalign or TEXT_ALIGN_LEFT, yalign or TEXT_ALIGN_TOP)
end

-- Comma formatting
local function safeComma(n)
    local v = tonumber(n) or 0
    return string.Comma(math.Round(v, 2))
end

-- Get all enabled tickers from client hydrated config
local function GetAllTickersClient()
    if not StockMarket or not StockMarket.Config or not StockMarket.Config.GetAllTickers then
        return {}
    end
    local t = StockMarket.Config:GetAllTickers()
    local out = {}
    for _, tk in ipairs(t) do
        if tk.enabled ~= false and tk.stockPrefix then
            out[#out + 1] = tk.stockPrefix
        end
    end
    table.sort(out, function(a, b) return tostring(a) < tostring(b) end)
    return out
end

-- Get price bundle for a ticker prefix
local function GetPriceBundle(prefix)
    local sd = StockMarket and StockMarket.StockData and StockMarket.StockData.Prices
    local pd = sd and sd[prefix]
    if not pd then return nil end
    return {
        price = tonumber(pd.price) or 0,
        change = tonumber(pd.change) or 0,
        changePercent = tonumber(pd.changePercent) or 0
    }
end

-- Build a cached lookup: prefix -> displayName "StockName (PREFIX)"
local _TickerNameCache = {}
local _LastNameCacheRebuild = 0
local NAME_CACHE_INTERVAL = 5 -- seconds

local function RebuildTickerNameCache()
    if not StockMarket or not StockMarket.Config or not StockMarket.Config.GetAllTickers then return end
    local list = StockMarket.Config:GetAllTickers() or {}
    local m = {}
    for _, t in ipairs(list) do
        local prefix = tostring(t.stockPrefix or "")
        local name   = tostring(t.stockName or prefix)
        if prefix ~= "" then
            m[prefix] = string.format("%s (%s)", name, prefix)
        end
    end
    _TickerNameCache = m
    _LastNameCacheRebuild = CurTime()
end

local function GetDisplayNameForPrefix(prefix)
    prefix = tostring(prefix or "")
    if prefix == "" then return "TICK" end
    -- Refresh cache periodically (cheap; list size small)
    if CurTime() - _LastNameCacheRebuild > NAME_CACHE_INTERVAL or not next(_TickerNameCache) then
        RebuildTickerNameCache()
    end
    return _TickerNameCache[prefix] or (prefix .. " (" .. prefix .. ")")
end

-- Local state per entity (clientside)
function ENT:Initialize()
    self._tickers = {}
    self._lastHydrate = 0
    self._cursor = 1
    self._lastAdvance = CurTime()
end

-- Compute fittable rows given our layout
function ENT:_ComputeFittableRows()
    local innerTop    = MARGIN
    local innerBottom = CANVAS_H - MARGIN
    -- Title occupies [innerTop .. innerTop + TITLE_H]
    local headerTop   = innerTop + TITLE_H + GAP_Y
    -- Header occupies [headerTop .. headerTop + HEAD_H]
    local rowsTop     = headerTop + HEAD_H + GAP_Y
    -- Allocate space down to footerTop
    local footerTop   = innerBottom - FOOT_H
    local usable      = math.max(0, footerTop - rowsTop)
    local rows        = math.floor(usable / ROW_H)
    return math.max(1, rows)
end

-- Rows to draw = min(MAX_ROWS, fittableRows, requestedVisibleRows)
function ENT:_RowsToDraw()
    local cap = self:_ComputeFittableRows()
    local rows = math.min(MAX_ROWS, cap)
    return math.max(1, rows)
end

local function ComputeCanvas(self)
    local ang = self:GetAngles()
    local pos = self:GetPos()

    ang:RotateAroundAxis(ang:Right(), 90) -- upright
    ang:RotateAroundAxis(ang:Up(),    90) -- face "front"

    local standoff = -2.5
    local origin = pos + self:GetForward() * standoff

    return origin, ang
end

function ENT:Think()
    -- Refresh tickers periodically (cheap)
    if (CurTime() - (self._lastHydrate or 0)) > HYDRATE_EVERY then
        self._tickers = GetAllTickersClient()
        self._lastHydrate = CurTime()
        if #self._tickers > 0 then
            self._cursor = math.Clamp(self._cursor or 1, 1, #self._tickers)
        else
            self._cursor = 1
        end
    end

    -- Rotate/paginate on a timer
    local rotateS = self:GetRotationSecondsSafe()
    if self:GetEnabledSafe() and #self._tickers > 0 and (CurTime() - (self._lastAdvance or 0)) > rotateS then
        local rowsPerPage = self:_RowsToDraw()
        local total = #self._tickers
        if total > rowsPerPage then
            -- smooth scroll by 1
            self._cursor = self._cursor + 1
            if self._cursor > total then self._cursor = 1 end
        else
            -- show all; keep cursor stable
            self._cursor = 1
        end
        self._lastAdvance = CurTime()
    end
end

function ENT:Draw()
    self:DrawModel()
    if not self:GetEnabledSafe() then return end

    local origin, ang = ComputeCanvas(self)

    cam.Start3D2D(origin, ang, SCALE)
        -- Background (full canvas, centered)
        DrawCenteredRect(0, 0, CANVAS_W, CANVAS_H, C.Back)

        -- Inner panel
        RoundedBoxCentered(8, 0, 0, CANVAS_W - MARGIN * 2, CANVAS_H - MARGIN * 2, C.Panel)

        -- Define a local top-left-like coordinate system relative to center
        local left   = -HALF_W + MARGIN
        local right  =  HALF_W - MARGIN
        local top    = -HALF_H + MARGIN
        local bottom =  HALF_H - MARGIN

        -- Title region
        local titleTop    = top
        local titleBottom = titleTop + TITLE_H
        draw.SimpleText("STOCK MARKET", "SM_Board_Title",
            0, titleTop + 8, C.Title, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)

        -- Header region (bar below title, no overlap)
        local headerTop  = titleBottom + GAP_Y
        DrawCenteredRect(0, headerTop + HEAD_H * 0.5, CANVAS_W - MARGIN * 2, HEAD_H, C.Border)

        local headerMidY = headerTop + HEAD_H * 0.5

        -- Columns (closer to ticker per your layout)
        local COL_TICKER_X = left + 14
        local COL_PRICE_X  = left + 420
        local COL_DELTA_X  = left + 780
        local RIGHT_SAFE   = right - 8

        -- Header labels
        draw.SimpleText("STOCK", "SM_Board_Header", COL_TICKER_X, headerMidY, C.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("PRICE",  "SM_Board_Header", COL_PRICE_X,  headerMidY, C.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText("↑ ↓",      "SM_Board_Header", COL_DELTA_X,  headerMidY, C.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        -- Rows region
        local rowsTop    = headerTop + HEAD_H + GAP_Y
        local rowsToDraw = self:_RowsToDraw()
        local total      = #self._tickers
        local startIndex = self._cursor or 1

        local PRICE_MAX_W = math.max(60, (COL_DELTA_X - 12) - COL_PRICE_X)
        local DELTA_MAX_W = math.max(60, (RIGHT_SAFE) - COL_DELTA_X)

        for i = 0, rowsToDraw - 1 do
            if total == 0 then break end
            local k = startIndex + i
            if k > total then k = ((k - 1) % total) + 1 end

            local rowY = rowsTop + i * ROW_H + ROW_H * 0.5

            -- Striped row background (does not affect layout)
            if (i % 2) == 1 then
                surface.SetDrawColor(0, 0, 0, 18)
                surface.DrawRect(left + 2, rowY - ROW_H * 0.5 + 4, (right - 2) - (left + 2), ROW_H - 8)
            end

            local prefix = self._tickers[k]
            local bundle = prefix and GetPriceBundle(prefix) or nil

            -- Ticker: Full name + prefix, e.g., "Bitcoin (BTC)"
            local displayName = GetDisplayNameForPrefix(prefix)
            draw.SimpleText(displayName, "SM_Board_Row", COL_TICKER_X, rowY, C.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            -- Price / Delta columns (with fitted text)
            if bundle then
                local priceStr = "$" .. safeComma(bundle.price)
                local chg      = bundle.change or 0
                local chgPct   = bundle.changePercent or 0
                local up       = (chg >= 0)
                local col      = up and C.Up or C.Down
                local sign     = up and "+" or ""
                local deltaStr = string.format("%s%.2f (%.2f%%)", sign, math.abs(chg), math.abs(chgPct))

                DrawFittedText(priceStr, "SM_Board_Price", COL_PRICE_X, rowY, C.Text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, PRICE_MAX_W)
                DrawFittedText(deltaStr, "SM_Board_Row",   COL_DELTA_X, rowY, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, DELTA_MAX_W)
            else
                DrawFittedText("—", "SM_Board_Price", COL_PRICE_X, rowY, C.Muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, PRICE_MAX_W)
                DrawFittedText("—", "SM_Board_Row",   COL_DELTA_X, rowY, C.Muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, DELTA_MAX_W)
            end
        end

        -- Footer (never overlaps rows)
        local footerBottom = bottom
        draw.SimpleText(
            string.format("Rotating every %ds • Showing %d", self:GetRotationSecondsSafe(), rowsToDraw),
            "SM_Board_Footer", right - 8, footerBottom - 6, C.Muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM
        )
    cam.End3D2D()
end