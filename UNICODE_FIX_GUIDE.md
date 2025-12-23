# Unicode Character Fix Guide for Garry's Mod

## Problem
Garry's Mod's Lua engine cannot understand Unicode escape sequences like `\u2295`, `\u27f2`, etc. These need to be replaced with ASCII-compatible characters.

## Replacements Required

| Unicode | Character | Description | GMOD Replacement | Lines Affected |
|---------|-----------|-------------|------------------|---------------|
| `\u00d7` | × | Multiplication sign / Close button | `X` | 86, 487 |
| `\u2295` | ⊕ | Circled plus / Add button | `+` | 153 |
| `\u2297` | ⊗ | Circled minus / Remove button | `-` | 165 |
| `\u25bc` | ▼ | Down arrow / Dropdown | `v` | 234 |
| `\u27f2` | ⟲ | Anticlockwise reset arrow | `R` | 333 |
| `\u2922` | ⤢ | Up-right arrow / Popout | `^` | 495 |

## Quick Fix Commands

Replace these in `cl_admin_stocks.lua`:

```bash
# Line 86: Close button in main frame
sed -i '86s/\\u00d7/X/' cl_admin_stocks.lua

# Line 153: Monitor All Active button
sed -i '153s/\\u2295/+/' cl_admin_stocks.lua

# Line 165: Clear All Cards button  
sed -i '165s/\\u2297/-/' cl_admin_stocks.lua

# Line 234: Dropdown arrow
sed -i '234s/\\u25bc/v/' cl_admin_stocks.lua

# Line 333: Reset All button
sed -i '333s/\\u27f2/R/' cl_admin_stocks.lua

# Line 487: Card close button
sed -i '487s/\\u00d7/X/' cl_admin_stocks.lua

# Line 495: Card popout button
sed -i '495s/\\u2922/^/' cl_admin_stocks.lua
```

## What Each Button Does

| Button | Symbol | Location | Function |
|--------|--------|----------|----------|
| Close | `X` | Frame close button | Closes the Performance Monitor window |
| Monitor All | `+` | Quick Actions | Adds all enabled stocks to monitor |
| Clear All | `-` | Quick Actions | Removes all ticker cards |
| Dropdown | `v` | Combo boxes | Shows dropdown options |
| Reset | `R` | Time Travel | Resets all cards to current time |
| Card Close | `X` | Ticker cards | Removes individual card |
| Popout | `^` | Ticker cards | Opens card in separate window |

## Why ASCII is Required

Garry's Mod uses a limited version of Lua that doesn't support Unicode escape sequences. The engine expects:
- ASCII characters (0-127)
- Simple symbols like +, -, X, R, ^, v
- No complex Unicode symbols

## Alternative Symbols

If you prefer different symbols:

| Function | Current | Alternatives |
|----------|---------|--------------|
| Close | `X` | `[X]`, `×` (if supported), `[ ]` |
| Add | `+` | `>`, `+ Add`, `Add` |
| Remove | `-` | `×`, `Clear`, `Remove` |
| Dropdown | `v` | `▼` (if supported), `^`, `▾` |
| Reset | `R` | `⟲` (if supported), `↺`, `Reset` |
| Popout | `^` | `↑`, `↗`, `Pop` |

## Verification

After applying fixes, check these lines:

```lua
-- Line 86 should show: draw.SimpleText("X", "StockMarket_SubtitleFont", ...)
-- Line 153 should show: ModernButton(quickActions, "Monitor All Active", "+", ...)
-- Line 165 should show: ModernButton(quickActions, "Clear All Cards", "-", ...)
-- Line 234 should show: draw.SimpleText("v", "StockMarket_SmallFont", ...)
-- Line 333 should show: draw.SimpleText("R Reset All", "StockMarket_SmallFont", ...)
-- Line 487 should show: card._btnClose = ModernButton(btnContainer, "X", ...)
-- Line 495 should show: card._btnPop = ModernButton(btnContainer, "^", ...)
```

## Testing

1. Start Garry's Mod server
2. Open admin panel with `sm_admin`
3. Navigate to "Stocks" tab
4. Click "Monitor All" button
5. Verify all buttons display correctly
6. Test each button's functionality

## Common Issues

**Issue**: Buttons show empty squares or question marks
**Fix**: Ensure all Unicode characters are replaced with ASCII

**Issue**: Console shows Lua errors about invalid characters
**Fix**: Check for any remaining `\u` sequences in the file

**Issue**: Buttons don't respond to clicks
**Fix**: Verify the replacement didn't break the function calls

## Future Prevention

When adding new UI elements:
1. Use ASCII symbols only
2. Test in Garry's Mod before committing
3. Avoid Unicode escape sequences
4. Use simple, recognizable symbols

## Summary

This fix ensures the Performance Monitor works correctly in Garry's Mod by replacing all Unicode symbols with ASCII-compatible alternatives. The functionality remains exactly the same, just with different visual representations.