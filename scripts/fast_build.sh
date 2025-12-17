#!/bin/bash

# 🚀 ULTRA FAST APK BUILD SCRIPT
# Optimized for maximum build speed with minimal compression

echo "⚡ ULTRA FAST APK BUILD - Karatapp"
echo "🎯 Target: Fastest possible APK generation"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Start timing
start_time=$(date +%s)

# Clean build cache for fresh optimized build
echo -e "${BLUE}🧹 Cleaning build cache...${NC}"
flutter clean > /dev/null 2>&1

# Pre-warm pub cache
echo -e "${BLUE}📦 Warming pub cache...${NC}"
flutter pub get --offline > /dev/null 2>&1 || flutter pub get > /dev/null 2>&1

# Build APK with maximum speed optimizations
echo -e "${GREEN}🏗️  Building APK with ultra-fast settings...${NC}"
flutter build apk \
  --debug \
  --no-tree-shake-icons \
  --no-compress \
  --no-shrink \
  --no-optimize-for-size \
  --no-pub \
  --build-number=$(date +%s) \
  --build-name=1.0.0-dev \
  2>/dev/null

build_exit_code=$?

end_time=$(date +%s)
duration=$((end_time - start_time))

if [ $build_exit_code -eq 0 ]; then
    apk_size=$(du -sh build/app/outputs/flutter-apk/app-debug.apk | cut -f1)
    echo ""
    echo -e "${GREEN}✅ ULTRA FAST BUILD COMPLETE!${NC}"
    echo -e "${BLUE}⏱️  Build time: ${duration} seconds${NC}"
    echo -e "${BLUE}📱 APK size: ${apk_size}${NC}"
    echo -e "${BLUE}📍 APK location: build/app/outputs/flutter-apk/app-debug.apk${NC}"

    if [ $duration -lt 30 ]; then
        echo -e "${GREEN}🎉 ACHIEVED: Sub-30 second build! ⚡${NC}"
    elif [ $duration -lt 60 ]; then
        echo -e "${YELLOW}⚡ GOOD: Under 1 minute build!${NC}"
    else
        echo -e "${RED}⏰ Build took ${duration}s (consider optimizations)${NC}"
    fi

    echo ""
    echo -e "${YELLOW}💡 OPTIMIZATION FEATURES USED:${NC}"
    echo -e "   • ${BLUE}No compression${NC}: Faster build, larger APK"
    echo -e "   • ${BLUE}No tree shaking${NC}: Skip icon optimization"
    echo -e "   • ${BLUE}No shrinking${NC}: Keep all code for speed"
    echo -e "   • ${BLUE}Pre-warmed cache${NC}: Reuse dependencies"
    echo -e "   • ${BLUE}Optimized Gradle${NC}: 8GB heap, parallel builds"
    echo ""
    echo -e "${GREEN}🚀 READY FOR TESTING!${NC}"

else
    echo -e "${RED}❌ Build failed after ${duration} seconds${NC}"
    echo -e "${YELLOW}💡 Try running: flutter clean && flutter pub get${NC}"
    exit 1
fi
