# Quick Implementation Guide - Stock Market UI Improvements

## 🚀 Fast Track Implementation (30 minutes)

### Step 1: Portfolio View (5 minutes)
**File**: `cl_portfolio_view.lua`

**Find** (around line 18):
```lua
local headerPanel = vgui.Create("DPanel", scroll)
headerPanel:Dock(TOP)
headerPanel:SetTall(120)
```

**Change to**:
```lua
local headerPanel = vgui.Create("DPanel", scroll)
headerPanel:Dock(TOP)
headerPanel:SetTall(80) -- Reduced from 120
```

**Find** (around line 30):
```lua
local padding = 20
```

**Change to**:
```lua
local padding = 15 -- Reduced from 20
```

**Find** (around line 60-120) - Update all card Paint functions:
```lua
-- Change from:
draw.SimpleText(title, "StockMarket_SmallFont", 12, 12, ...)
draw.SimpleText(value, "StockMarket_TitleFont", 12, 35, ...)

-- Change to:
draw.SimpleText(title, "StockMarket_SmallFont", w/2, 8, ..., TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
draw.SimpleText(value, "StockMarket_TitleFont", w/2, h/2 + 8, ..., TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
```

---

### Step 2: Chart White Corners Fix (2 minutes)
**File**: `cl_chart.lua`

**Find** (around line 19):
```lua
draw.RoundedBox(8, 0, 0, w, h, StockMarket.UI.Colors.BackgroundLight)
```

**Replace with**:
```lua
surface.SetDrawColor(StockMarket.UI.Colors.BackgroundLight)
surface.DrawRect(0, 0, w, h)
```

---

### Step 3: Chart Tooltip Fix (3 minutes)
**File**: `cl_chart.lua`

**Find** (around line 107-120) the tooltip section:
```lua
local tx = closestPoint.x + 10
local ty = closestPoint.y - 20
```

**Replace entire tooltip section with**:
```lua
local tx = closestPoint.x + 10
local ty = closestPoint.y - 20

-- FIXED: Smart positioning
if tx + tw + 12 > w then
    tx = closestPoint.x - tw - 22
end
if ty < 0 then
    ty = closestPoint.y + 10
end

draw.RoundedBox(4, tx, ty, tw + 12, th + 8, StockMarket.UI.Colors.Background)
draw.SimpleText(tooltipText, "StockMarket_SmallFont", tx + 6, ty + 4, StockMarket.UI.Colors.TextPrimary, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
```

---

### Step 4: Trading Interface (10 minutes)
**File**: `cl_ticker_view.lua`

**Add helper functions** (before the trading row section):
```lua
local function GetOwnedSharesForTicker(tkr)
    local pf = StockMarket.ClientPortfolio or {}
    for _, p in ipairs(pf.positions or {}) do
        if string.upper(tostring(p.ticker or "")) == string.upper(tostring(tkr or "")) then
            return tonumber(p.shares) or 0
        end
    end
    return 0
end

local function GetCurrentPrice(tkr)
    local pd = StockMarket.StockData:GetPrice(tkr)
    return pd and tonumber(pd.price) or 0
end
```

**Replace the entire trading section** with the improved version from the summary document (Section 2).

---

### Step 5: Admin Stats Cards (5 minutes)
**File**: `cl_admin_stats.lua`

**Find** (around line 85):
```lua
card:SetTall(86)
```

**Change to**:
```lua
card:SetTall(80)
```

**Find the card Paint function** and update text positioning:
```lua
-- Change from:
draw.SimpleText(s[1], "StockMarket_SmallFont", 12, 10, ...)
draw.SimpleText(s[2](), "StockMarket_TitleFont", 12, 35, ...)

-- Change to:
draw.SimpleText(s[1], "StockMarket_SmallFont", w/2, 8, ..., TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP)
draw.SimpleText(s[2](), "StockMarket_TitleFont", w/2, h/2 + 8, ..., TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
```

---

### Step 6: Admin Icon Alignment (5 minutes)
**File**: `cl_admin_stocks.lua`

**Find category header icons** (around line 95):
```lua
btnDel:Dock(RIGHT);  btnDel:DockMargin(6,0,0,0)
btnEdit:Dock(RIGHT); btnEdit:DockMargin(6,0,0,0)
btnAdd:Dock(RIGHT)
```

**Replace with**:
```lua
btnDel:SetPos(88, 0)
btnEdit:SetPos(44, 0)
btnAdd:SetPos(0, 0)
```

**Find stock row icons** (around line 140):
```lua
btnDel:Dock(RIGHT);  btnDel:DockMargin(8,0,0,0)
btnEdit:Dock(RIGHT); btnEdit:DockMargin(8,0,0,0)
btnPrev:Dock(RIGHT)
```

**Replace with**:
```lua
btnDel:SetPos(88, 0)
btnEdit:SetPos(44, 0)
btnPrev:SetPos(0, 0)
```

---

### Step 7: Performance Monitor (Optional - 10 minutes)
**File**: `cl_admin_stocks.lua`

Replace the entire `fr:AddTickerCard` function with the improved version from `performance_monitor_improved.lua`.

---

## ✅ Testing Checklist

After each step, test:

1. **Portfolio View**
   - [ ] Cards are centered
   - [ ] Height is reduced
   - [ ] Spacing looks good

2. **Chart**
   - [ ] No white corners
   - [ ] Tooltips work on right edge

3. **Trading Interface**
   - [ ] BUY/SELL toggle works
   - [ ] Summary updates
   - [ ] All buttons work

4. **Admin Panel**
   - [ ] Stats cards centered
   - [ ] Icons aligned
   - [ ] Everything clickable

5. **Performance Monitor**
   - [ ] Cards look modern
   - [ ] Charts display correctly
   - [ ] Buttons work

---

## 🔧 Troubleshooting

### Console Errors?
- Check you didn't break any `end` statements
- Verify all commas and parentheses match
- Look for typos in variable names

### Looks Wrong?
- Clear your GMod cache
- Restart the server
- Check color variables exist

### Not Working?
- Verify you edited the correct file
- Check file paths are correct
- Make sure you saved the file

---

## 📝 Notes

- **Backup first!** Always keep a copy of original files
- **Test incrementally**: Do one step at a time
- **Check console**: Watch for Lua errors
- **Restart server**: After making changes

---

## 🎯 Priority Order

If short on time, implement in this order:

1. **Chart white corners fix** (2 min) - Most visible issue
2. **Admin icon alignment** (5 min) - Professional appearance
3. **Portfolio cards centering** (5 min) - Better visual balance
4. **Trading interface** (10 min) - Major improvement
5. **Performance monitor** (10 min) - Optional enhancement

**Minimum viable**: Steps 1-3 (12 minutes)
**Recommended**: Steps 1-6 (30 minutes)
**Complete**: All steps (40 minutes)

---

## 📞 Quick Help

**File not found?**
- Check you're in the right addon folder
- Verify file paths match your structure

**Changes not showing?**
- Restart the server
- Clear client cache
- Check file was saved

**Broke something?**
- Restore from backup
- Check console for error line number
- Review the change you just made

---

**Good luck! 🚀**