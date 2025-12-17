#!/bin/bash

# 🚀 FAST FLUTTER RUN - Simple & Reliable
# Optimized flutter run without complex build_daemon

echo "⚡ FAST FLUTTER RUN - Karatapp"
echo "🎯 Optimized for speed and reliability"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
DEVICE_ID=""
FLUTTER_ARGS=""

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

# Auto-detect device if not specified
if [ -z "$DEVICE_ID" ]; then
    echo -e "${BLUE}🔍 Detecting device...${NC}"
    DEVICES_JSON=$(flutter devices --machine 2>/dev/null)
    if echo "$DEVICES_JSON" | grep -q '^\['; then
        FIRST_DEVICE=$(echo "$DEVICES_JSON" | grep -o '"id": *"[^"]*"' | head -1 | sed 's/"id": *"\([^"]*\)"/\1/')
        if [ -n "$FIRST_DEVICE" ]; then
            DEVICE_ID="$FIRST_DEVICE"
            DEVICE_NAME=$(echo "$DEVICES_JSON" | grep -A 5 -B 5 "$FIRST_DEVICE" | grep '"name"' | head -1 | sed 's/.*"name": *"\([^"]*\)".*/\1/')
            echo -e "${GREEN}📱 Using: $DEVICE_NAME ($DEVICE_ID)${NC}"
        fi
    fi
fi

if [ -z "$DEVICE_ID" ]; then
    echo -e "${RED}❌ No devices found!${NC}"
    flutter devices
    exit 1
fi

echo -e "${BLUE}🚀 Starting Flutter with optimizations...${NC}"

# Use optimized flutter run command with only valid flags
flutter run \
  --debug \
  --hot \
  --device-id="$DEVICE_ID" \
  --dart-define=FLUTTER_WEB_USE_SKIA=true \
  $FLUTTER_ARGS
