# Performance Monitor Redesign - Implementation Checklist

## Pre-Implementation

- [ ] **Backup current file**
  ```bash
  cp lua/stockmarket/ui/admin/cl_admin_stocks.lua lua/stockmarket/ui/admin/cl_admin_stocks_backup.lua
  ```

- [ ] **Review the redesign**
  - Read `PERFORMANCE_MONITOR_REDESIGN_GUIDE.md`
  - Review `VISUAL_COMPARISON.md`
  - Understand the changes

- [ ] **Test environment ready**
  - Server running
  - Admin access available
  - Can access admin panel

## Implementation Steps

### Step 1: File Replacement
- [ ] Copy redesigned file to main location
  ```bash
  cp lua/stockmarket/ui/admin/cl_admin_stocks_redesigned.lua lua/stockmarket/ui/admin/cl_admin_stocks.lua
  ```

### Step 2: Server Restart
- [ ] Restart the server or reload the addon
- [ ] Verify no Lua errors in console
- [ ] Check that all files loaded correctly

### Step 3: Basic Testing
- [ ] Open admin panel with `sm_admin`
- [ ] Navigate to "Stocks" tab
- [ ] Click "📊 Performance Monitor" button
- [ ] Verify monitor window opens

### Step 4: Control Panel Testing
- [ ] **Quick Actions Section**
  - [ ] Click "Monitor All Active" - cards should appear
  - [ ] Click "Clear All Cards" - all cards should disappear
  - [ ] Verify icons display correctly

- [ ] **Prediction Settings Section**
  - [ ] Change Horizon dropdown (30m, 1h, 4h, 24h)
  - [ ] Change Step dropdown (1m, 2m, 5m)
  - [ ] Verify cards update when settings change
  - [ ] Check dropdown styling

- [ ] **Time Travel Section**
  - [ ] Click "+5m" button
  - [ ] Click "+30m" button
  - [ ] Click "+2h" button
  - [ ] Click "+1d" button
  - [ ] Click "Reset All" button
  - [ ] Verify time travel works correctly

### Step 5: Ticker Card Testing
- [ ] **Card Appearance**
  - [ ] Ticker symbol displays large and prominent
  - [ ] Stock name displays below ticker
  - [ ] Risk badge shows in top-right (HIGH/MED/LOW)
  - [ ] Risk badge has correct color
  - [ ] Header has gradient background

- [ ] **Card Buttons**
  - [ ] Close button (×) works
  - [ ] Popout button (⤢) works
  - [ ] Buttons have hover effects
  - [ ] Buttons are positioned correctly

- [ ] **Chart Section**
  - [ ] Chart displays correctly
  - [ ] Chart is 200px tall
  - [ ] Chart updates with settings
  - [ ] No white corners on chart

- [ ] **Info Panel**
  - [ ] Drift value displays (left)
  - [ ] Volatility displays (left)
  - [ ] Current price displays (center, large)
  - [ ] Horizon displays (right)
  - [ ] Step displays (right)
  - [ ] All text is readable

### Step 6: Popout Window Testing
- [ ] Click popout button on a card
- [ ] Verify popout window opens
- [ ] Check header displays correctly
- [ ] Verify chart displays in popout
- [ ] Test closing popout window

### Step 7: Responsive Design Testing
- [ ] **Window at 1600px width**
  - [ ] Should show 3 columns
  - [ ] Cards should be properly sized
  - [ ] No overlap or gaps

- [ ] **Window at 1000px width**
  - [ ] Should show 2 columns
  - [ ] Cards should resize correctly

- [ ] **Window at 800px width**
  - [ ] Should show 1 column
  - [ ] Cards should be full width

- [ ] **Resize window dynamically**
  - [ ] Cards should reflow smoothly
  - [ ] No layout breaks

### Step 8: Visual Polish Testing
- [ ] **Colors**
  - [ ] Primary color used correctly
  - [ ] Background colors consistent
  - [ ] Text colors readable
  - [ ] Risk colors correct (Green/Yellow/Red)

- [ ] **Spacing**
  - [ ] Proper margins between elements
  - [ ] No cramped sections
  - [ ] Consistent padding

- [ ] **Typography**
  - [ ] Title font correct
  - [ ] Subtitle font correct
  - [ ] Body text readable
  - [ ] Small text not too small

- [ ] **Hover Effects**
  - [ ] Buttons change on hover
  - [ ] Smooth transitions
  - [ ] Visual feedback clear

### Step 9: Functionality Testing
- [ ] **Multiple Cards**
  - [ ] Add 5+ cards
  - [ ] Verify scrolling works
  - [ ] Check performance
  - [ ] Test removing cards

- [ ] **Settings Persistence**
  - [ ] Change horizon setting
  - [ ] Add new card
  - [ ] Verify new card uses current settings

- [ ] **Time Travel**
  - [ ] Skip forward multiple times
  - [ ] Verify all cards update
  - [ ] Reset and verify return to current time

### Step 10: Edge Cases
- [ ] **Empty State**
  - [ ] Open monitor with no cards
  - [ ] Verify it looks good empty
  - [ ] Add first card

- [ ] **Many Cards**
  - [ ] Add 10+ cards
  - [ ] Check scrollbar appearance
  - [ ] Verify performance
  - [ ] Test removing all

- [ ] **Long Stock Names**
  - [ ] Test with very long stock names
  - [ ] Verify text doesn't overflow
  - [ ] Check truncation if needed

- [ ] **Extreme Values**
  - [ ] Test with very high prices
  - [ ] Test with very low prices
  - [ ] Test with negative drift
  - [ ] Test with high volatility

## Post-Implementation

### Documentation
- [ ] Update any internal documentation
- [ ] Note any customizations made
- [ ] Document any issues found

### User Feedback
- [ ] Show to team/users
- [ ] Gather feedback
- [ ] Note improvement suggestions

### Performance
- [ ] Monitor server performance
- [ ] Check for memory leaks
- [ ] Verify no lag with many cards

## Rollback Plan (If Needed)

If issues are found:

1. [ ] Stop the server
2. [ ] Restore backup file
   ```bash
   cp lua/stockmarket/ui/admin/cl_admin_stocks_backup.lua lua/stockmarket/ui/admin/cl_admin_stocks.lua
   ```
3. [ ] Restart server
4. [ ] Document issues found
5. [ ] Plan fixes

## Success Criteria

The implementation is successful when:

- ✅ All controls work as expected
- ✅ Visual design matches specifications
- ✅ No Lua errors in console
- ✅ Performance is acceptable
- ✅ Responsive design works correctly
- ✅ User feedback is positive

## Known Issues to Watch For

- [ ] Chart white corners (should be fixed)
- [ ] Tooltip positioning (should be improved)
- [ ] Dropdown text visibility (should be clear)
- [ ] Card sizing on small windows
- [ ] Scrollbar appearance

## Customization Notes

Document any customizations made:

```
Date: ___________
Customization: _________________________________
Reason: ________________________________________
File/Line: _____________________________________
```

## Support Resources

- Original backup: `cl_admin_stocks_backup.lua`
- Redesign guide: `PERFORMANCE_MONITOR_REDESIGN_GUIDE.md`
- Visual comparison: `VISUAL_COMPARISON.md`
- This checklist: `IMPLEMENTATION_CHECKLIST.md`

---

**Implementation Date**: ___________
**Implemented By**: ___________
**Status**: ⬜ Not Started | ⬜ In Progress | ⬜ Complete | ⬜ Rolled Back
**Notes**: ___________________________________________