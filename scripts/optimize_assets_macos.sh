#!/bin/bash

# macOS Asset Optimization Script using built-in sips tool
# This script compresses images to reduce build time and app size

echo "🖼️  Starting asset optimization using macOS sips..."

ASSETS_DIR="assets/avatars/photos"
BACKUP_DIR="assets/avatars/photos_backup"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Counters
optimized_count=0
total_size_before=0
total_size_after=0

# Function to get file size in bytes
get_file_size() {
    stat -f%z "$1" 2>/dev/null || echo 0
}

# Function to format file size
format_size() {
    local size=$1
    if [ $size -gt 1048576 ]; then
        echo "$(echo "scale=1; $size/1048576" | bc)MB"
    elif [ $size -gt 1024 ]; then
        echo "$(echo "scale=1; $size/1024" | bc)KB"
    else
        echo "${size}B"
    fi
}

# Process all JPG files
find "$ASSETS_DIR" -name "*.jpg" -type f | while read -r file; do
    original_size=$(get_file_size "$file")
    total_size_before=$((total_size_before + original_size))
    
    # Skip if already small (less than 200KB)
    if [ $original_size -lt 204800 ]; then
        echo "⏭️  Skipping $(basename "$file") (already optimized: $(format_size $original_size))"
        total_size_after=$((total_size_after + original_size))
        continue
    fi
    
    # Create backup
    backup_file="$BACKUP_DIR/$(basename "$file")"
    cp "$file" "$backup_file"
    
    # Optimize using sips (resize to max 800px and compress)
    sips -Z 800 -s format jpeg -s formatOptions 70 "$file" > /dev/null 2>&1
    
    new_size=$(get_file_size "$file")
    total_size_after=$((total_size_after + new_size))
    
    if [ $new_size -lt $original_size ]; then
        optimized_count=$((optimized_count + 1))
        savings=$(echo "scale=1; (($original_size - $new_size) * 100) / $original_size" | bc)
        echo "✅ Optimized $(basename "$file"): $(format_size $original_size) → $(format_size $new_size) (${savings}% saved)"
    else
        # Restore original if no improvement
        cp "$backup_file" "$file"
        echo "⏭️  Skipping $(basename "$file") (no improvement)"
    fi
done

# Calculate total savings
total_savings=$(echo "scale=1; (($total_size_before - $total_size_after) * 100) / $total_size_before" | bc)

echo ""
echo "🎉 Optimization complete!"
echo "📊 Optimized $optimized_count files"
echo "💾 Total size: $(format_size $total_size_before) → $(format_size $total_size_after)"
echo "🚀 Space saved: ${total_savings}%"
echo ""
echo "💡 Backup files saved in: $BACKUP_DIR"
echo "💡 To restore originals: cp $BACKUP_DIR/* $ASSETS_DIR/"
