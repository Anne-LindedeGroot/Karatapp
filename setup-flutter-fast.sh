#!/bin/bash

# 🚀 SETUP FLUTTER FAST - Intercept 'flutter run'
# Makes 'flutter run' automatically use the fast version

echo "⚡ Setting up Flutter-Fast - Automatic fast run..."
echo ""

PROJECT_ROOT="$(pwd)"
FLUTTER_FAST_SCRIPT="$PROJECT_ROOT/flutter-fast"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if script exists
if [ ! -f "$FLUTTER_FAST_SCRIPT" ]; then
    echo -e "${RED}❌ Error: flutter-fast script not found${NC}"
    exit 1
fi

# Find where flutter is installed
FLUTTER_PATH=$(which flutter 2>/dev/null)
if [ -z "$FLUTTER_PATH" ]; then
    echo -e "${RED}❌ Flutter not found in PATH${NC}"
    echo -e "${YELLOW}Please install Flutter first${NC}"
    exit 1
fi

FLUTTER_DIR=$(dirname "$FLUTTER_PATH")
FLUTTER_BIN_DIR="$FLUTTER_DIR"

echo -e "${BLUE}Found Flutter at: $FLUTTER_PATH${NC}"

# Backup original flutter command
if [ ! -f "$FLUTTER_BIN_DIR/flutter.original" ]; then
    echo -e "${BLUE}📦 Backing up original flutter command...${NC}"
    cp "$FLUTTER_PATH" "$FLUTTER_BIN_DIR/flutter.original"
fi

# Create wrapper
echo -e "${BLUE}🔧 Installing flutter-fast wrapper...${NC}"
cp "$FLUTTER_FAST_SCRIPT" "$FLUTTER_BIN_DIR/flutter"

if [ $? -eq 0 ]; then
    chmod +x "$FLUTTER_BIN_DIR/flutter"
    echo ""
    echo -e "${GREEN}✅ FLUTTER FAST INSTALLED!${NC}"
    echo ""
    echo -e "${GREEN}🎉 Now 'flutter run' automatically uses ultra-fast mode!${NC}"
    echo ""
    echo -e "${BLUE}USAGE:${NC}"
    echo -e "  ${YELLOW}flutter run${NC}                    # 🚀 Ultra fast (automatic)"
    echo -e "  ${YELLOW}flutter run --device-id=iPhone${NC}  # 📱 Specific device"
    echo -e "  ${YELLOW}flutter run --release${NC}          # 📦 Release mode"
    echo -e "  ${YELLOW}flutter run --no-daemon${NC}        # ⚡ Skip build daemon"
    echo ""
    echo -e "${BLUE}OTHER COMMANDS:${NC}"
    echo -e "  ${YELLOW}flutter build${NC}                  # Regular build (unchanged)"
    echo -e "  ${YELLOW}flutter doctor${NC}                 # Regular doctor (unchanged)"
    echo ""
    echo -e "${YELLOW}RESTORE:${NC} To restore original flutter:"
    echo -e "  cp $FLUTTER_BIN_DIR/flutter.original $FLUTTER_BIN_DIR/flutter"
    echo ""
    echo -e "${GREEN}🚀 HAPPY FAST DEVELOPMENT!${NC}"
else
    echo -e "${RED}❌ Installation failed${NC}"
    echo -e "${YELLOW}Try running with sudo if needed${NC}"
    exit 1
fi



