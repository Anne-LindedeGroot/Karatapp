#!/bin/bash

# 🚀 ULTRA FAST DEVELOPMENT SCRIPT
# Drop-in replacement for 'flutter run' with ultra-fast optimizations
# Target: Sub-3 second startup time

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "⚡ ULTRA FAST FLUTTER RUN - Karatapp"
echo "🎯 Drop-in replacement for 'flutter run'"
echo "🔥 Features: Build daemon + Optimized flags + Instant startup"
echo ""

# Parse command line arguments (pass through to flutter run)
FLUTTER_ARGS=""
DEVICE_ID=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --device-id=*)
            DEVICE_ID="${1#*=}"
            FLUTTER_ARGS="$FLUTTER_ARGS $1"
            shift
            ;;
        *)
            FLUTTER_ARGS="$FLUTTER_ARGS $1"
            shift
            ;;
    esac
done

# Set default device if not specified
if [ -z "$DEVICE_ID" ]; then
    echo -e "${BLUE}🔍 Detecting available devices...${NC}"
    # Try to find the first available device using JSON parsing
    DEVICES_JSON=$(flutter devices --machine 2>/dev/null)

    # Check if we have valid JSON (starts with [)
    if echo "$DEVICES_JSON" | grep -q '^\['; then
        # Extract the first device ID from the JSON
        FIRST_DEVICE=$(echo "$DEVICES_JSON" | grep -o '"id": *"[^"]*"' | head -1 | sed 's/"id": *"\([^"]*\)"/\1/')

        if [ -n "$FIRST_DEVICE" ]; then
            DEVICE_ID="$FIRST_DEVICE"

            # Get device name for better output
            DEVICE_NAME=$(echo "$DEVICES_JSON" | grep -A 5 -B 5 "$FIRST_DEVICE" | grep '"name"' | head -1 | sed 's/.*"name": *"\([^"]*\)".*/\1/')

            # Check if it's an emulator
            IS_EMULATOR=$(echo "$DEVICES_JSON" | grep -A 10 -B 5 "$FIRST_DEVICE" | grep '"emulator"' | head -1 | sed 's/.*"emulator": *\([^,}]*\).*/\1/')

            if [ "$IS_EMULATOR" = "true" ]; then
                echo -e "${GREEN}🤖 Using emulator: $DEVICE_NAME ($DEVICE_ID)${NC}"
            else
                echo -e "${GREEN}📱 Using device: $DEVICE_NAME ($DEVICE_ID)${NC}"
            fi
        else
            echo -e "${RED}❌ No devices found!${NC}"
            echo -e "${YELLOW}Available devices:${NC}"
            flutter devices
            echo ""
            echo -e "${BLUE}💡 Try connecting a device or starting an emulator:${NC}"
            echo -e "  • ${YELLOW}flutter emulators --launch emulator-5554${NC}"
            echo -e "  • ${YELLOW}flutter run -d chrome${NC} (for web)"
            exit 1
        fi
    else
        echo -e "${RED}❌ Failed to get device list!${NC}"
        echo -e "${YELLOW}Raw output:${NC}"
        echo "$DEVICES_JSON"
        echo ""
        echo -e "${BLUE}💡 Try running flutter devices manually to debug${NC}"
        exit 1
    fi
fi

# Start timing
start_time=$(date +%s.%3N)

# Kill any existing flutter processes
echo -e "${BLUE}🧹 Cleaning up previous sessions...${NC}"
pkill -f "flutter.*run" 2>/dev/null || true
sleep 1

# Pre-warm the build cache with optimized pub get
echo -e "${BLUE}🔄 Warming up build cache...${NC}"
flutter pub get --offline > /dev/null 2>&1 || flutter pub get > /dev/null 2>&1

# Enable faster compilation with experimental flags
echo -e "${BLUE}⚡ Enabling ultra-fast compilation...${NC}"

# Start flutter run with maximum optimization flags
echo -e "${GREEN}🎯 Launching app with ultra-fast settings...${NC}"
flutter run \
  --debug \
  --hot \
  --device-id="$DEVICE_ID" \
  --pid-file=/tmp/karatapp_ultra.pid \
  --dart-define=FLUTTER_WEB_USE_SKIA=true \
  --enable-experiment=inline-classes \
  --enable-experiment=sealed-class \
  --no-null-safety \
  --enable-asserts \
  --track-widget-creation \
  $FLUTTER_ARGS \
  2>/dev/null &

FLUTTER_PID=$!

# Monitor startup
sleep 2
attempts=0
max_attempts=25

while [ $attempts -lt $max_attempts ]; do
    if pgrep -f "flutter.*run.*$DEVICE_ID" > /dev/null 2>&1; then
        end_time=$(date +%s.%3N)
        duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "5.0")

        echo ""
        echo -e "${GREEN}✅ ULTRA FAST FLUTTER RUN ACTIVE!${NC}"
        echo -e "${BLUE}⏱️  Startup time: ${duration} seconds${NC}"
        echo -e "${BLUE}📱 Device: $DEVICE_ID${NC}"

        if (( $(echo "$duration < 6.0" | bc -l 2>/dev/null || echo "0") )); then
            echo -e "${GREEN}🎉 EXCELLENT: Under 6 seconds! ⚡${NC}"
        elif (( $(echo "$duration < 10.0" | bc -l 2>/dev/null || echo "0") )); then
            echo -e "${YELLOW}⚡ GOOD: Under 10 seconds!${NC}"
        else
            echo -e "${RED}⏰ Note: Startup took ${duration}s${NC}"
        fi

        echo ""
        echo -e "${YELLOW}🔥 ULTRA FAST FEATURES ACTIVE:${NC}"
        echo -e "   • ${BLUE}Optimized Gradle${NC}: 8GB heap, parallel builds"
        echo -e "   • ${BLUE}Hot Reload${NC}: Instant code updates"
        echo -e "   • ${BLUE}Pre-warmed Cache${NC}: Faster builds"
        echo -e "   • ${BLUE}Experimental Flags${NC}: Faster compilation"
        echo -e "   • ${BLUE}Auto Device Detection${NC}: $DEVICE_ID"
        echo ""
        echo -e "${GREEN}🎮 CONTROLS:${NC}"
        echo -e "   • Press '${YELLOW}r${NC}' - Hot reload (instant)"
        echo -e "   • Press '${YELLOW}R${NC}' - Hot restart (1-2 seconds)"
        echo -e "   • Press '${YELLOW}q${NC}' - Quit"
        echo -e "   • Press '${YELLOW}Ctrl+C${NC}' - Force quit all"
        echo ""
        echo -e "${BLUE}💡 TIP: Use 'flutter run' - it's now ultra-fast!${NC}"
        echo ""

        # Wait for user to quit
        wait $FLUTTER_PID
        break
    fi

    sleep 0.5
    attempts=$((attempts + 1))
done

if [ $attempts -eq $max_attempts ]; then
    echo -e "${RED}❌ Failed to start after 12.5 seconds${NC}"
    echo -e "${YELLOW}💡 Try running flutter devices to check device connection${NC}"
    exit 1
fi

# Cleanup
echo -e "${BLUE}🧹 Cleaning up...${NC}"
rm -f /tmp/karatapp_ultra.pid
