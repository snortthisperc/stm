# Performance Monitor Complete Redesign Guide

## Overview
This guide covers the complete redesign of the Performance Monitor interface with a modern, cohesive design that matches your improved ticker card style.

## What's New

### 1. **Modern Frame Design**
- Cleaner header with gradient effect
- Better visual hierarchy
- Improved spacing and padding
- Professional close button with hover effects

### 2. **Organized Control Panel**
The control panel is now divided into three clear sections:

#### Left Section: Quick Actions
- **Monitor All Active**: Adds all enabled stocks to the monitor
- **Clear All Cards**: Removes all ticker cards at once
- Modern button design with icons and hover effects

#### Middle Section: Prediction Settings
- **Horizon Selector**: Choose prediction timeframe (30m, 1h, 4h, 24h)
- **Step Selector**: Choose data point intervals (1m, 2m, 5m)
- Custom-styled combo boxes with better visibility
- Clear labels and intuitive layout

#### Right Section: Time Travel Controls
- **Quick Skip Buttons**: +5m, +30m, +2h, +1d
- **Reset All Button**: Returns all cards to current time
- Organized in a grid layout for easy access

### 3. **Improved Ticker Cards**
Your new ticker card design is fully integrated:
- Large, prominent ticker symbol
- Stock name displayed below
- Risk badge in top-right corner (HIGH/MED/LOW)
- Modern action buttons (close, popout)
- Larger chart area (200px height)
- Better info panel with centered price display
- Left/right columns for additional metrics

### 4. **Better Visual Feedback**
- Hover effects on all interactive elements
- Color-coded risk indicators
- Smooth transitions
- Clear visual hierarchy

### 5. **Responsive Design**
- Automatic column calculation (1-3 columns based on width)
- Cards resize dynamically
- Minimum window size constraints
- Proper scrollbar styling

## Implementation Steps

### Step 1: Backup Current File
```bash
cp lua/stockmarket/ui/admin/cl_admin_stocks.lua lua/stockmarket/ui/admin/cl_admin_stocks_backup.lua
```

### Step 2: Replace with Redesigned Version
```bash
cp lua/stockmarket/ui/admin/cl_admin_stocks_redesigned.lua lua/stockmarket/ui/admin/cl_admin_stocks.lua
```

### Step 3: Test the Interface
1. Open the admin panel with `sm_admin` command
2. Navigate to the "Stocks" tab
3. Click "📊 Performance Monitor" button
4. Test all features:
   - Add ticker cards
   - Change horizon/step settings
   - Use time travel controls
   - Test popout functionality
   - Verify responsive behavior

## Key Features

### Control Panel Sections
```
┌─────────────────────────────────────────────────────────────┐
│  QUICK ACTIONS  │  PREDICTION SETTINGS  │  TIME TRAVEL      │
│                 │                        │                   │
│  ⊕ Monitor All  │  Horizon: [30m ▼]     │  [+5m]  [+30m]   │
│  ⊗ Clear All    │  Step:    [2m  ▼]     │  [+2h]  [+1d]    │
│                 │                        │  [⟲ Reset All]   │
└─────────────────────────────────────────────────────────────┘
```

### Ticker Card Layout
```
┌─────────────────────────────────────┐
│ AAPL              [HIGH RISK] [×][⤢]│
│ Apple Inc.                          │
├─────────────────────────────────────┤
│                                     │
│         [Chart Area - 200px]        │
│                                     │
├─────────────────────────────────────┤
│ Drift: 0.0050    $150.25   Horizon: │
│ Vol: 1.25                   30m     │
└─────────────────────────────────────┘
```

## Color Scheme
The redesign uses your existing color palette:
- **Primary**: Accent color for buttons and highlights
- **Background**: Main dark background
- **BackgroundLight**: Card and panel backgrounds
- **TextPrimary**: Main text color
- **TextSecondary**: Secondary/muted text
- **Success**: Green for positive indicators
- **Warning**: Yellow/orange for medium risk
- **Danger**: Red for high risk

## Customization Options

### Adjust Card Size
In the `AddTickerCard` function:
```lua
card:SetSize(420, 340) -- Width, Height
```

### Modify Chart Height
```lua
chartSection:SetSize(card:GetWide() - 24, 200) -- Adjust 200 to desired height
```

### Change Column Breakpoints
In the `computeColumns` function:
```lua
local function computeColumns(w)
    if w >= 1400 then return 3 end  -- 3 columns at 1400px+
    if w >= 900 then return 2 end   -- 2 columns at 900px+
    return 1                         -- 1 column below 900px
end
```

### Customize Time Skip Intervals
Modify the `TimeButton` calls:
```lua
TimeButton(timeRow1, "+5m", 5)    -- Label, minutes
TimeButton(timeRow1, "+30m", 30)
TimeButton(timeRow2, "+2h", 120)
TimeButton(timeRow2, "+1d", 1440)
```

## Benefits of the Redesign

1. **Better Organization**: Clear sections for different functions
2. **Improved Usability**: Intuitive controls and better visual feedback
3. **Modern Aesthetics**: Clean, professional appearance
4. **Enhanced Functionality**: More features in a cleaner layout
5. **Responsive Design**: Works well at different window sizes
6. **Consistent Design**: Matches your improved ticker card style

## Troubleshooting

### Cards Not Appearing
- Ensure `StockMarket.UI.Admin.BuildPredictionSeries` function exists
- Check that `StockMarket.UI.Lib:Chart` is properly initialized
- Verify network messages are being received

### Settings Not Updating
- Check that `horizon.OnSelect` and `step.OnSelect` callbacks are firing
- Ensure `card:_refresh()` is being called
- Verify `getHorizonMins()` and `getStepSecs()` return correct values

### Layout Issues
- Adjust `DockMargin` values for spacing
- Modify `SetTall` and `SetWide` for component sizes
- Check `PerformLayout` functions for dynamic sizing

## Next Steps

After implementing the redesigned Performance Monitor, you may want to:

1. **Add Stock Management Interface**: Complete the category and stock management views
2. **Implement Drag-and-Drop**: Allow reordering of ticker cards
3. **Add Filters**: Filter cards by risk level, sector, or performance
4. **Export Functionality**: Export predictions to CSV or images
5. **Saved Layouts**: Save and load custom card arrangements

## Support

If you encounter any issues or need customization help, refer to:
- The original backup file for comparison
- GMod Lua documentation for VGUI components
- StockMarket addon documentation for data structures

---

**Note**: This redesign maintains full compatibility with your existing backend code while providing a significantly improved user experience.