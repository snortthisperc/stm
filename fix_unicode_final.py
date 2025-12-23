#!/usr/bin/env python3

# Read the original file
with open('/workspace/stm/StockMarket_a/lua/stockmarket/ui/admin/cl_admin_stocks.lua', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Fix specific lines with Unicode characters
fixes = {
    86: '           draw.SimpleText("X", "StockMarket_SubtitleFont", w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)\n',
    153: '    ModernButton(quickActions, "Monitor All Active", "+", function()\n',
    165: '    ModernButton(quickActions, "Clear All Cards", "-", function()\n',
    234: '            draw.SimpleText("v", "StockMarket_SmallFont", w - 10, h/2, C.TextSecondary, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)\n',
    333: '        draw.SimpleText("R Reset All", "StockMarket_SmallFont", w/2, h/2, C.TextPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)\n',
    487: '        card._btnClose = ModernButton(btnContainer, "X", "Remove", function()\n',
    495: '        card._btnPop = ModernButton(btnContainer, "^", "Popout", function()\n'
}

# Apply fixes (convert to 0-based indexing)
for line_num, replacement in fixes.items():
    if line_num <= len(lines):
        lines[line_num - 1] = replacement

# Write the fixed file
with open('/workspace/stm/StockMarket_a/lua/stockmarket/ui/admin/cl_admin_stocks.lua', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("Fixed all Unicode characters with ASCII alternatives")
print("Lines fixed: " + ", ".join(map(str, fixes.keys())))