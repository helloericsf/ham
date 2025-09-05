#!/bin/bash

echo "🐹 Starting Ham..."
cd "$(dirname "$0")"

# Run Ham in the background and redirect output
exec ./.build/arm64-apple-macosx/debug/Ham > ham.log 2>&1
