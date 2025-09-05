#!/bin/bash
# Ham - LLM Token Usage Monitor
# Start script for easy launching

echo "🐹 Starting Ham..."

# Kill any existing Ham process
pkill Ham 2>/dev/null

# Rebuild if requested
if [ "$1" = "--rebuild" ] || [ "$1" = "-r" ]; then
    echo "🧼 Cleaning build artifacts..."
    swift build --clean
    echo "🔨 Rebuilding Ham..."
    swift build
    cp ./.build/arm64-apple-macosx/debug/Ham Ham.app/Contents/MacOS/
fi

# Launch Ham.app
open Ham.app

echo "🐹 Ham started! Look for 'HAM' in your menu bar."
