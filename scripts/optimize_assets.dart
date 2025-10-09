#!/usr/bin/env dart

import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Script to optimize image assets for faster build times
/// This reduces image file sizes while maintaining quality
void main() async {
  print('🖼️  Starting asset optimization...');
  
  final assetsDir = Directory('assets/avatars/photos');
  if (!assetsDir.existsSync()) {
    print('❌ Assets directory not found');
    return;
  }
  
  int optimizedCount = 0;
  int totalSizeBefore = 0;
  int totalSizeAfter = 0;
  
  await for (final entity in assetsDir.list(recursive: true)) {
    if (entity is File && entity.path.toLowerCase().endsWith('.jpg')) {
      final originalSize = await entity.length();
      totalSizeBefore += originalSize;
      
      // Skip if already optimized (less than 200KB)
      if (originalSize < 200 * 1024) {
        print('⏭️  Skipping ${entity.path} (already optimized)');
        continue;
      }
      
      try {
        final bytes = await entity.readAsBytes();
        final image = img.decodeJpg(bytes);
        
        if (image != null) {
          // Resize if too large (max 800px on longest side)
          img.Image resizedImage = image;
          if (image.width > 800 || image.height > 800) {
            final ratio = 800 / (image.width > image.height ? image.width : image.height);
            resizedImage = img.copyResize(
              image,
              width: (image.width * ratio).round(),
              height: (image.height * ratio).round(),
            );
          }
          
          // Compress with quality 85
          final optimizedBytes = img.encodeJpg(resizedImage, quality: 85);
          
          if (optimizedBytes.length < originalSize) {
            // Create backup
            final backupPath = '${entity.path}.backup';
            await entity.copy(backupPath);
            
            // Write optimized version
            await entity.writeAsBytes(optimizedBytes);
            
            final newSize = optimizedBytes.length;
            totalSizeAfter += newSize;
            optimizedCount++;
            
            final savings = ((originalSize - newSize) / originalSize * 100).toStringAsFixed(1);
            print('✅ Optimized ${entity.path}: ${(originalSize / 1024).toStringAsFixed(1)}KB → ${(newSize / 1024).toStringAsFixed(1)}KB (${savings}% saved)');
          } else {
            print('⏭️  Skipping ${entity.path} (no improvement)');
            totalSizeAfter += originalSize;
          }
        }
      } catch (e) {
        print('❌ Error optimizing ${entity.path}: $e');
        totalSizeAfter += originalSize;
      }
    }
  }
  
  final totalSavings = ((totalSizeBefore - totalSizeAfter) / totalSizeBefore * 100).toStringAsFixed(1);
  print('\n🎉 Optimization complete!');
  print('📊 Optimized $optimizedCount files');
  print('💾 Total size: ${(totalSizeBefore / 1024 / 1024).toStringAsFixed(1)}MB → ${(totalSizeAfter / 1024 / 1024).toStringAsFixed(1)}MB');
  print('🚀 Space saved: $totalSavings%');
  print('\n💡 Run "dart scripts/optimize_assets.dart" to optimize assets');
}
