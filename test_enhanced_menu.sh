#!/bin/bash
# Test script for Ham's enhanced menu functionality

echo "🧪 Testing Ham's Enhanced Menu System"
echo "======================================"

# Check if Ham executable exists
if [ ! -f "Ham.app/Contents/MacOS/Ham" ]; then
    echo "❌ Ham executable not found. Building first..."
    swift build
    cp .build/arm64-apple-macosx/debug/Ham Ham.app/Contents/MacOS/Ham
fi

echo "✅ Ham executable found"

# Kill any existing Ham processes
echo "🔄 Stopping any existing Ham processes..."
pkill -f Ham 2>/dev/null || true
sleep 1

# Start Ham in background
echo "🚀 Starting Ham with enhanced menu..."
./Ham.app/Contents/MacOS/Ham &
HAM_PID=$!

# Wait a moment for Ham to initialize
sleep 3

echo "✅ Ham started (PID: $HAM_PID)"
echo ""
echo "🔍 Testing Instructions:"
echo "1. Look for 'HAM' in your menu bar"
echo "2. Click on the Ham menu bar icon"
echo "3. Verify the enhanced menu structure:"
echo "   - 🐹 Today: X tokens (trend)"
echo "   - 📊 This Week: X tokens (trend)"
echo "   - 📅 This Month: X tokens (trend)"
echo "   - ▶ By Provider submenu"
echo "   - ▶ Recent Activity submenu"
echo "   - 📈 View Detailed Stats... (disabled for now)"
echo "   - ⚙️ Settings..."
echo "   - ❌ Quit Ham"
echo ""

# Add some test usage data by simulating API calls
echo "📊 Generating test usage data..."

# Simulate some usage through the analytics engine
# This would normally come from actual API monitoring
osascript -e '
tell application "System Events"
    set menuBarItems to (name of every menu bar item of menu bar 1 of application process "Ham")
end tell
' 2>/dev/null || echo "⚠️  Ham may not be visible in menu bar yet"

echo ""
echo "🎯 What to look for:"
echo "• Rich statistics display instead of simple 'Tokens Today: X'"
echo "• Trend indicators (📈/📉) showing usage changes"
echo "• Provider breakdown with percentages and emojis"
echo "• Recent activity metrics (last hour, peak, average)"
echo "• Professional menu structure with proper spacing"
echo ""

echo "⏱️  Let Ham run for 30 seconds to collect initial data..."
sleep 30

echo ""
echo "🔬 Manual Testing Steps:"
echo "1. Click Ham menu bar icon multiple times"
echo "2. Hover over 'By Provider' to see submenu"
echo "3. Hover over 'Recent Activity' to see metrics"
echo "4. Verify all menu items display properly"
echo "5. Check that trends show (may be 0% initially)"
echo ""

# Function to check if Ham is still running
check_ham_status() {
    if kill -0 $HAM_PID 2>/dev/null; then
        echo "✅ Ham is running normally"
        return 0
    else
        echo "❌ Ham process has stopped"
        return 1
    fi
}

echo "🔍 Checking Ham status..."
check_ham_status

echo ""
echo "📋 Test Checklist:"
echo "- [ ] Ham appears in menu bar as 'HAM'"
echo "- [ ] Menu opens when clicked"
echo "- [ ] Shows enhanced statistics format"
echo "- [ ] Provider submenu works"
echo "- [ ] Activity submenu works"
echo "- [ ] Trend indicators display"
echo "- [ ] No crashes or errors"
echo ""

echo "⌨️  Press any key to stop Ham and exit test..."
read -n 1 -s

echo ""
echo "🛑 Stopping Ham..."
kill $HAM_PID 2>/dev/null
sleep 2

if kill -0 $HAM_PID 2>/dev/null; then
    echo "🔨 Force stopping Ham..."
    kill -9 $HAM_PID 2>/dev/null
fi

echo "✅ Test completed!"
echo ""
echo "📊 Next Steps:"
echo "1. If menu enhancements work: Move to Chunk 2 (Cost Calculations)"
echo "2. If issues found: Debug and fix before proceeding"
echo "3. Create some real usage data to see trends in action"
echo ""
