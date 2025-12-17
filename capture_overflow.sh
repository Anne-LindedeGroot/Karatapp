#!/bin/bash
echo "🔍 Capturing Flutter Overflow Information..."
echo "Run this script, then navigate to a forum post and enable big font + dyslexia mode"
echo ""

# Start Flutter with overflow detection
flutter run --device-id=RZCW40J7Y5P 2>&1 | while read line; do
    echo "$line"
    # Look for overflow messages
    if echo "$line" | grep -q -i "overflow"; then
        echo "🎯 OVERFLOW DETECTED: $line" >&2
        echo "🎯 OVERFLOW DETECTED: $line" >> overflow_detected.log
    fi
    if echo "$line" | grep -q "A RenderFlex overflowed by"; then
        echo "🚨 BOTTOM OVERFLOW FOUND: $line" >&2
        echo "🚨 BOTTOM OVERFLOW FOUND: $line" >> overflow_detected.log
    fi
done

echo ""
echo "Check overflow_detected.log for captured overflow messages"
