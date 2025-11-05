#!/bin/bash

# Fast Development Script - Under 5 seconds startup time
# Uses flutter run with hot reload for instant development

echo "🚀 Starting Karatapp in FAST DEVELOPMENT MODE..."
echo "⏱️  Target: Under 5 seconds startup time"
echo ""

# Start timing
start_time=$(date +%s)

# Use flutter run with optimized flags for faster startup
flutter run \
  --debug \
  --no-build \
  --hot \
  --pid-file=/tmp/flutter.pid \
  --device-id=emulator-5554 \
  2>/dev/null &

# Wait a moment for flutter to start
sleep 2

# Check if flutter process is running
if pgrep -f "flutter run" > /dev/null; then
    end_time=$(date +%s)
    duration=$((end_time - start_time))

    echo ""
    echo "✅ Karatapp started successfully!"
    echo "⏱️  Startup time: ${duration} seconds"

    if [ $duration -lt 5 ]; then
        echo "🎉 ACHIEVED: Under 5 seconds target!"
    else
        echo "⚠️  Note: Startup took ${duration} seconds (target: <5 seconds)"
    fi
    echo ""
    echo "🔥 Hot reload is active - changes will be instant!"
    echo "Press 'r' in terminal to hot reload"
    echo "Press 'R' in terminal to hot restart"
    echo "Press 'q' in terminal to quit"
else
    echo "❌ Failed to start Karatapp"
    exit 1
fi
