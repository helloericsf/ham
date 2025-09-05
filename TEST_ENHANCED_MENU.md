# 🧪 Testing Guide: Enhanced Menu System

This guide walks you through testing Ham's new enhanced menu system with rich analytics and visual improvements.

## 🚀 Quick Start Testing

### 1. Build and Launch
```bash
# Navigate to Ham directory
cd "Claude Code 09:25"

# Build the latest version
swift build

# Copy to app bundle
cp .build/arm64-apple-macosx/debug/Ham Ham.app/Contents/MacOS/Ham

# Kill any existing Ham processes
pkill Ham 2>/dev/null || true

# Launch Ham
./Ham.app/Contents/MacOS/Ham &
```

### 2. Initial Verification
- ✅ Look for "HAM" text in your menu bar (top right area)
- ✅ No crash messages in terminal
- ✅ Ham process running in background

## 📋 Enhanced Menu Testing Checklist

### Basic Menu Structure
Click on the Ham menu bar item and verify:

- [ ] **Main Statistics Display**
  ```
  🐹 Today: X tokens 📈/📉/━ (±X%)
  📊 This Week: X tokens 📈/📉/━ (±X%)
  📅 This Month: X tokens 📈/📉/━ (±X%)
  ```

- [ ] **Menu Separators** - Clean visual separation between sections

- [ ] **Provider Submenu**
  ```
  ▶ By Provider → Hover reveals:
    🤖 Anthropic: X% (X tokens)
    🔥 OpenAI: X% (X tokens)  
    🔍 Google AI: X% (X tokens)
    ─────────────────────
    Total: X tokens
  ```

- [ ] **Activity Submenu**
  ```
  ▶ Recent Activity → Hover reveals:
    Last hour: X tokens
    Peak today: X tokens/hr
    Average rate: X tokens/hr
    ─────────────────────
    😴/🚶‍♂️/🏃‍♂️/🏃‍♀️/🔥 Activity: Level
  ```

- [ ] **Action Items**
  ```
  📈 View Detailed Stats... (disabled - future feature)
  ⚙️ Settings...
  ❌ Quit Ham
  ```

### Visual Design Elements

- [ ] **Emojis display correctly** - 🐹, 📊, 📅, 🤖, 🔥, 🔍
- [ ] **Trend indicators show** - 📈 (up), 📉 (down), ━ (stable)
- [ ] **Percentage formatting** - "+12.3%", "-5.1%", "0.0%"
- [ ] **Number formatting** - "1.2K", "24.5K", "1.0M" for large numbers
- [ ] **Menu hierarchy** - Proper indentation and spacing

## 🧪 Functionality Testing

### 1. Initial State Testing
On first launch (no historical data):
- [ ] All usage shows "0 tokens"
- [ ] Trends show "0.0%" or "N/A"
- [ ] Provider breakdown shows "No usage today"
- [ ] Activity level shows "😴 Very Low"

### 2. Settings Integration Test
- [ ] Click "⚙️ Settings..." opens settings window
- [ ] Settings window displays properly
- [ ] Can add/modify API keys
- [ ] Settings save correctly

### 3. Menu Responsiveness
- [ ] Menu opens instantly when clicked
- [ ] Submenus appear on hover
- [ ] No lag or performance issues
- [ ] Menu closes properly when clicking elsewhere

### 4. Error Handling
- [ ] No crashes when menu items are clicked
- [ ] Disabled items ("View Detailed Stats") show as disabled
- [ ] Menu handles missing data gracefully

## 📊 Data Simulation Testing

Since real API usage data may be minimal, let's test the analytics system:

### Method 1: UserDefaults Injection
```bash
# Add some test data to see analytics in action
defaults write com.ham.menubar ham_usage_history '{
  "2024-01-01": [{"timestamp": "2024-01-01T12:00:00Z", "anthropic": 500, "openai": 300, "google": 200, "totalTokens": 1000}],
  "2024-01-02": [{"timestamp": "2024-01-02T12:00:00Z", "anthropic": 600, "openai": 250, "google": 150, "totalTokens": 1000}]
}'
```

### Method 2: Time-based Testing
1. Launch Ham and note initial state
2. Wait 5 minutes
3. Check if menu updates (should show current time data)
4. Create some API activity if possible
5. Verify menu reflects changes

## 🎯 Expected Behaviors

### Number Formatting Examples
- `1000` → "1.0K"
- `1247` → "1.2K"
- `24567` → "24.6K" 
- `1000000` → "1.0M"

### Trend Calculation Logic
- **Significant increase (>5%)**: 📈 "+12.3%"
- **Significant decrease (>5%)**: 📉 "-8.7%"
- **Stable change (±5%)**: ━ "+2.1%" or "0.0%"

### Provider Percentages
- Should add up to 100% when all providers have usage
- Inactive providers show "No usage today"
- Sorted by usage percentage (highest first)

### Activity Levels
- **😴 Very Low**: 0-5 tokens/hr
- **🚶‍♂️ Low**: 5-20 tokens/hr  
- **🏃‍♂️ Moderate**: 20-50 tokens/hr
- **🏃‍♀️ High**: 50-100 tokens/hr
- **🔥 Very High**: 100+ tokens/hr

## 🐛 Common Issues & Troubleshooting

### Menu Not Appearing
```bash
# Check if Ham is running
ps aux | grep Ham

# Check for errors
tail -f ham.log  # if logging to file

# Force quit and restart
pkill -f Ham
./Ham.app/Contents/MacOS/Ham &
```

### Menu Shows "Loading..."
- Wait 30-60 seconds for initial data collection
- Check if API keys are configured
- Verify no crash in terminal

### Submenus Not Working
- Ensure you're hovering over the submenu items
- Check that menu items have proper submenu assignments
- Try clicking instead of hovering

### Data Not Updating
- Check if UsageMonitor is collecting data
- Verify analytics engine is recording usage
- Look for timer-related issues in logs

## 📸 Screenshot Documentation

When testing, document these key views:

1. **Main Menu Expanded** - Full menu with all statistics
2. **Provider Submenu** - Showing breakdown percentages
3. **Activity Submenu** - Showing rates and activity level
4. **Settings Window** - Verify integration still works
5. **Menu Bar Icon** - Confirm "HAM" text is visible

## ✅ Success Criteria

The enhanced menu implementation is successful if:

- [ ] **Rich Information Display** - Shows 15+ data points vs simple counter
- [ ] **Professional Appearance** - Clean design with emojis and formatting
- [ ] **Functional Submenus** - Provider and activity breakdowns work
- [ ] **Trend Indicators** - Shows usage changes with appropriate symbols
- [ ] **No Regressions** - All existing functionality still works
- [ ] **Performance** - Menu opens quickly, no memory leaks
- [ ] **Data Persistence** - Usage history saves and loads correctly

## 🚨 Report Issues

If you find issues, please note:
- **Description**: What doesn't work as expected
- **Steps to reproduce**: How to trigger the issue
- **Expected vs actual**: What should happen vs what happens
- **Console output**: Any error messages
- **System info**: macOS version, hardware

## 🎉 Next Steps

After successful testing:
1. ✅ **Chunk 1 Complete** - Enhanced menu statistics
2. 🎯 **Ready for Chunk 2** - Cost calculations implementation
3. 📊 **Foundation established** - Analytics system proven and working

---

**Testing Time Estimate**: 15-30 minutes for comprehensive testing
**Focus Areas**: Menu structure, visual design, data display, performance
**Success Indicator**: Professional analytics dashboard in menu bar vs simple counter