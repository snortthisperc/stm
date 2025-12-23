-- ========================================
-- UI Color Palette
-- ========================================

StockMarket.UI = StockMarket.UI or {}
StockMarket.UI.Colors = {
    -- Base
    Background = Color(25, 28, 35),
    BackgroundLight = Color(32, 36, 45),
    BackgroundDark = Color(18, 21, 28),

    -- Primary
    Primary = Color(59, 130, 246),
    PrimaryHover = Color(96, 165, 250),
    PrimaryDark = Color(37, 99, 235),

    -- Text
    TextPrimary = Color(255, 255, 255),
    TextSecondary = Color(156, 163, 175),
    TextMuted = Color(107, 114, 128),

    -- Status
    Success = Color(34, 197, 94),
    SuccessHover = Color(74, 222, 128),
    Danger = Color(239, 68, 68),
    DangerHover = Color(248, 113, 113),
    Warning = Color(251, 191, 36),
    Info = Color(59, 130, 246),

    -- Market
    Positive = Color(34, 197, 94),
    Negative = Color(239, 68, 68),
    Neutral = Color(156, 163, 175),

    -- Borders
    Border = Color(55, 65, 81),
    BorderLight = Color(75, 85, 99),

    -- Overlay
    Overlay = Color(0, 0, 0, 180),

    -- Chart
    ChartGrid = Color(55, 65, 81, 100),
    ChartLine = Color(59, 130, 246),
    ChartFill = Color(59, 130, 246, 30),
}

-- Admin variant colors
StockMarket.UI.AdminColors = {
    Background = Color(20, 22, 28),
    BackgroundLight = Color(28, 31, 38),
    BackgroundDark = Color(14, 16, 21),

    Primary = Color(220, 38, 38),
    PrimaryHover = Color(248, 113, 113),

    TextPrimary = Color(255,255,255),
    TextSecondary = Color(180,185,195),
    Border = Color(60, 70, 80)
}
