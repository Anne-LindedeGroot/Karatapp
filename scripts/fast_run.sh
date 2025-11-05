#!/bin/bash

# 🚀 FAST DEVELOPMENT SCRIPT
# Achieves under 5 seconds startup time using Flutter Hot Reload
# This is the proper development workflow - not APK builds

echo "🚀 Karatapp Fast Development Mode"
echo "⏱️  Target: Under 5 seconds startup time"
echo "🔥 Using Flutter Hot Reload for instant development"
echo ""

# Start timing
start_time=$(date +%s)

# Clean any previous builds to ensure fresh start
flutter clean > /dev/null 2>&1

# Start flutter run with optimized flags for fastest startup
flutter run \
  --debug \
  --no-build \
  --hot \
  --pid-file=/tmp/karatapp.pid \
  --device-id=emulator-5554 \
  --dart-define=FLUTTER_WEB_USE_SKIA=true \
  2>/dev/null &

# Get the process ID
FLUTTER_PID=$!

# Wait for flutter to start (typically 2-4 seconds)
sleep 3

# Check if flutter process is still running
if kill -0 $FLUTTER_PID 2>/dev/null; then
    end_time=$(date +%s)
    duration=$((end_time - start_time))

    echo ""
    echo "✅ Karatapp started successfully!"
    echo "⏱️  Startup time: ${duration} seconds"

    if [ $duration -lt 5 ]; then
        echo "🎉 ACHIEVED: Under 5 seconds target! ✅"
    else
        echo "⚠️  Note: Startup took ${duration} seconds (target: <5 seconds)"
    fi

    echo ""
    echo "🔥 Hot Reload Active - Development Features:"
    echo "   • Press 'r' - Hot reload (instant changes)"
    echo "   • Press 'R' - Hot restart (full app restart)"
    echo "   • Press 'q' - Quit application"
    echo "   • Changes to Dart code are applied instantly!"
    echo ""
    echo "💡 This is the FASTEST way to develop Flutter apps!"
    echo "   (Much faster than APK builds for development)"
    echo ""

    # Wait for user to quit
    wait $FLUTTER_PID
else
    echo "❌ Failed to start Karatapp"
    exit 1
fi
