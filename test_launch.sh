#!/bin/bash
# Simple Ham Test Launcher
# Tests the enhanced menu system

echo "🐹 Ham Enhanced Menu Test Launcher"
echo "================================="

# Check if we're in the right directory
if [ ! -f "Package.swift" ]; then
    echo "❌ Please run this script from the Ham project directory"
    exit 1
fi

# Build Ham
echo "🔨 Building Ham..."
swift build
if [ $? -ne 0 ]; then
    echo "❌ Build failed. Check for errors above."
    exit 1
fi

# Copy to app bundle
echo "📦 Copying executable to app bundle..."
cp .build/arm64-apple-macosx/debug/Ham Ham.app/Contents/MacOS/Ham

# Kill any existing Ham processes
echo "🛑 Stopping existing Ham processes..."
pkill -f Ham 2>/dev/null || true
sleep 1

# Launch Ham
echo "🚀 Launching Ham with enhanced menu..."
./Ham.app/Contents/MacOS/Ham &
HAM_PID=$!

# Wait for initialization
echo "⏳ Waiting for Ham to initialize..."
sleep 3

# Check if Ham is running
if kill -0 $HAM_PID 2>/dev/null; then
    echo "✅ Ham is running! (PID: $HAM_PID)"
else
    echo "❌ Ham failed to start"
    exit 1
fi

echo ""
echo "🔍 Testing Instructions:"
echo "1. Look for 'HAM' in your menu bar"
echo "2. Click on it to see the enhanced menu"
echo "3. Verify you see:"
echo "   - 🐹 Today: X tokens (with trend)"
echo "   - 📊 This Week: X tokens (with trend)"
echo "   - 📅 This Month: X tokens (with trend)"
echo "   - ▶ By Provider (submenu)"
echo "   - ▶ Recent Activity (submenu)"
echo "   - Settings and Quit options"
echo ""
echo "4. Test submenus by hovering over them"
echo "5. Check that trends show (📈/📉/━)"
echo ""

echo "📊 Expected Enhancements:"
echo "- Rich statistics instead of simple 'Tokens Today: X'"
echo "- Provider breakdown with percentages"
echo "- Activity metrics and rates"
echo "- Professional design with emojis"
echo ""

echo "⌨️  Press ENTER to stop Ham and exit..."
read

echo "🛑 Stopping Ham..."
kill $HAM_PID 2>/dev/null
sleep 2

if kill -0 $HAM_PID 2>/dev/null; then
    echo "🔨 Force stopping..."
    kill -9 $HAM_PID 2>/dev/null
fi

echo "✅ Test session complete!"
echo ""
echo "📋 Quick Checklist:"
echo "- [ ] Ham appeared in menu bar as 'HAM'"
echo "- [ ] Enhanced menu showed rich statistics"
echo "- [ ] Provider submenu worked"
echo "- [ ] Activity submenu worked"
echo "- [ ] Trends displayed correctly"
echo "- [ ] No crashes or errors"
echo ""
echo "🎯 If all checks passed, Chunk 1 is successful!"
