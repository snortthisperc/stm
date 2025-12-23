# Performance Monitor Upgrade Guide

## Overview
This guide will help you upgrade the Performance Monitor to a modern, functional design that matches your addon's theme.

## What's Improved

### 1. **Modern Card Design**
- Larger cards (420x340 vs 380x290) for better visibility
- Gradient header section with prominent ticker symbol
- Clean, professional layout with proper spacing
- Better visual hierarchy

### 2. **Enhanced Chart Display**
- Larger chart area (200px vs 165px height)
- Better padding and margins
- Cleaner background styling
- Improved readability

### 3. **Better Information Layout**
- Prominent current price display in center
- Organized info panel with left/right columns
- Drift and volatility on left
- Horizon and step info on right
- Risk badge in header (HIGH/MED/LOW)

### 4. **Modern Action Buttons**
- Cleaner button design with hover effects
- Better positioning in header
- Consistent styling with rest of addon

### 5. **Improved Popout Window**
- Larger default size for better viewing
- Clean header with stock info
- Full-size chart display
- Professional appearance

## Installation Instructions

### Step 1: Locate the File
Open: `StockMarket_a/lua/stockmarket/ui/admin/cl_admin_stocks.lua`

### Step 2: Find the Function
Search for: `function fr:AddTickerCard(t)`
This should be around line 300-470

### Step 3: Replace the Function
Replace the ENTIRE `fr:AddTickerCard` function (from `function fr:AddTickerCard(t)` to the matching `end`) with the improved version from `performance_monitor_improved.lua`

### Step 4: Key Changes Summary

#### Old Design Issues:
- Small cards with cramped layout
- Unclear information hierarchy
- Basic styling
- Small chart area
- Generic appearance

#### New Design Features:
- **Card Size**: 420x340 (was 380x290)
- **Chart Height**: 200px (was 165px)
- **Header**: Gradient background with prominent ticker
- **Info Panel**: Organized 3-column layout
- **Buttons**: Modern hover effects
- **Risk Badge**: Color-coded in header
- **Price Display**: Large, centered, prominent

## Visual Improvements

### Header Section
```
┌─────────────────────────────────────────┐
│ XOM                    [HIGH RISK]  ×  ⤢│
│ ExxonMobil                              │
└─────────────────────────────────────────┘
```

### Chart Section
```
┌─────────────────────────────────────────┐
│                                         │
│         [LARGER CHART AREA]             │
│                                         │
│                                         │
└─────────────────────────────────────────┘
```

### Info Panel
```
┌─────────────────────────────────────────┐
│ Drift: 0.0050      $112.00   Horizon: 30m│
│ Volatility: 1.10              Step: 120s │
└─────────────────────────────────────────┘
```

## Testing

After implementing:
1. Open Admin Panel
2. Go to Stocks & Categories
3. Click the chart icon on any stock
4. Verify the card appears with new design
5. Test the popout button
6. Test the close button
7. Test the time skip buttons (+5m, +30m, etc.)

## Troubleshooting

### If cards don't appear:
- Check console for errors
- Verify you replaced the entire function
- Make sure you didn't break the `end` statement

### If styling looks wrong:
- Verify color variables (C.Background, C.Primary, etc.) are defined
- Check that StockMarket.UI.Colors exists

### If charts don't show:
- Verify BuildPredictionSeries function exists
- Check that chart library is loaded
- Verify getHorizonMins() and getStepSecs() functions exist

## Additional Notes

- The improved design maintains all existing functionality
- Time travel (skip forward) still works
- Popout windows still work
- All calculations remain the same
- Only visual improvements and layout changes

## Compatibility

- Works with existing BuildPredictionSeries function
- Compatible with current chart library
- Uses existing color scheme
- No database changes required
- No server-side changes needed

## Support

If you encounter issues:
1. Check the console for Lua errors
2. Verify all helper functions exist
3. Make sure you replaced the complete function
4. Test with a fresh server restart