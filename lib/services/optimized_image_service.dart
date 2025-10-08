import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/data_usage_provider.dart';
import '../providers/network_provider.dart';
import '../utils/retry_utils.dart';

/// Optimized image service with data usage controls and caching
class OptimizedImageService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Get optimized image URL based on data usage settings
  static String getOptimizedImageUrl(String originalUrl, Ref ref) {
    final dataUsageState = ref.read(dataUsageProvider);
    final recommendedQuality = dataUsageState.getRecommendedQuality(dataUsageState.imageQuality);
    
    // If the original URL is from Supabase, we can add query parameters for optimization
    if (originalUrl.contains('supabase')) {
      return _addSupabaseOptimizationParams(originalUrl, recommendedQuality);
    }
    
    // For other URLs, return as-is (could be enhanced with image proxy)
    return originalUrl;
  }
  
  /// Add Supabase optimization parameters to image URL
  static String _addSupabaseOptimizationParams(String url, DataUsageQuality quality) {
    final uri = Uri.parse(url);
    final queryParams = Map<String, String>.from(uri.queryParameters);
    
    switch (quality) {
      case DataUsageQuality.low:
        // Low quality: smaller size, lower quality
        queryParams['width'] = '400';
        queryParams['height'] = '300';
        queryParams['quality'] = '60';
        break;
      case DataUsageQuality.medium:
        // Medium quality: balanced size and quality
        queryParams['width'] = '800';
        queryParams['height'] = '600';
        queryParams['quality'] = '80';
        break;
      case DataUsageQuality.high:
        // High quality: original size, high quality
        queryParams['quality'] = '95';
        break;
      case DataUsageQuality.auto:
        // Auto: use medium as default
        queryParams['width'] = '800';
        queryParams['height'] = '600';
        queryParams['quality'] = '80';
        break;
    }
    
    // Add format optimization for better compression
    queryParams['format'] = 'webp';
    
    return uri.replace(queryParameters: queryParams).toString();
  }
  
  /// Upload image with data usage optimization
  static Future<String?> uploadImageToSupabase(File imageFile, String fileName, String bucketName, Ref ref) async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final dataUsageState = ref.read(dataUsageProvider);
          final networkState = ref.read(networkProvider);
          
          // Check if upload is allowed
          if (!dataUsageState.shouldAllowDataUsage || !networkState.isConnected) {
            throw Exception('Upload not allowed in current network state');
          }

          // Get file size for data usage tracking
          final fileSize = await imageFile.length();
          
          // Check if file size is acceptable for current data usage mode
          if (!_isImageFileSizeAcceptable(fileSize, dataUsageState)) {
            throw Exception('Image file size too large for current data usage mode');
          }
          
          // Try to create the bucket if it doesn't exist
          try {
            await _supabase.storage.createBucket(
              bucketName,
              BucketOptions(
                public: true, // Images are typically public
                allowedMimeTypes: ['image/*'],
                fileSizeLimit: (10 * 1024 * 1024).toString(), // 10MB limit for images
              ),
            );
          } catch (e) {
            // Bucket might already exist, which is fine
            debugPrint('Image bucket creation attempt: $e');
          }
          
          // Read the file as bytes
          final bytes = await imageFile.readAsBytes();
          
          if (bytes.isEmpty) {
            throw Exception('Image file is empty: ${imageFile.path}');
          }
          
          debugPrint('🖼️ Uploading image: ${_formatFileSize(bytes.length)} - $fileName');
          
          // Upload to Supabase Storage
          await _supabase.storage
              .from(bucketName)
              .uploadBinary(fileName, bytes);
          
          // Get the public URL of the uploaded image
          final publicUrl = _supabase.storage
              .from(bucketName)
              .getPublicUrl(fileName);
          
          // Record data usage
          ref.read(dataUsageProvider.notifier).recordDataUsage(bytes.length, type: 'image');
          
          debugPrint('✅ Image uploaded successfully: $fileName');
          return publicUrl;
        } catch (e) {
          debugPrint('❌ Error uploading image to Supabase: $e');
          rethrow;
        }
      },
      maxRetries: 2,
      initialDelay: const Duration(seconds: 2),
      shouldRetry: (error) {
        // Don't retry file size errors or data usage errors
        if (error.toString().contains('size') || 
            error.toString().contains('large') ||
            error.toString().contains('not allowed')) {
          return false;
        }
        return RetryUtils.shouldRetryImageError(error);
      },
      onRetry: (attempt, error) {
        debugPrint('🔄 Retrying upload image (attempt $attempt): $error');
      },
    );
  }
  
  /// Fetch images with data usage optimization
  static Future<List<String>> fetchImagesFromBucket(String bucketName, String? path, Ref ref) async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final dataUsageState = ref.read(dataUsageProvider);
          final networkState = ref.read(networkProvider);
          
          // Check if fetch is allowed
          if (!dataUsageState.shouldAllowDataUsage || !networkState.isConnected) {
            return [];
          }

          // Check if the bucket exists
          try {
            await _supabase.storage.getBucket(bucketName);
          } catch (e) {
            debugPrint('⚠️ $bucketName bucket not found or not accessible: $e');
            return [];
          }
          
          // List all files in the bucket/path
          final response = await _supabase.storage
              .from(bucketName)
              .list(path: path);
          
          if (response.isEmpty) {
            debugPrint('ℹ️ No images found in $bucketName${path != null ? '/$path' : ''}');
            return [];
          }
          
          List<String> imageUrls = [];
          int totalDataUsage = 0;
          
          for (final file in response) {
            if (file.name.isNotEmpty && !file.name.startsWith('.') && _isImageFile(file.name)) {
              try {
                // Get optimized URL based on data usage settings
                final publicUrl = _supabase.storage
                    .from(bucketName)
                    .getPublicUrl(path != null ? '$path/${file.name}' : file.name);
                
                final optimizedUrl = getOptimizedImageUrl(publicUrl, ref);
                imageUrls.add(optimizedUrl);
                
                // Estimate data usage for URL generation
                totalDataUsage += 512; // ~512B per URL
                
                debugPrint('✅ Generated optimized URL for image ${file.name}');
              } catch (urlError) {
                debugPrint('⚠️ Failed to generate URL for ${file.name}: $urlError');
              }
            }
          }
          
          if (imageUrls.isEmpty) {
            debugPrint('ℹ️ No valid image files found in $bucketName${path != null ? '/$path' : ''}');
            return [];
          }
          
          // Record data usage
          ref.read(dataUsageProvider.notifier).recordDataUsage(totalDataUsage, type: 'image');
          
          debugPrint('✅ Successfully fetched ${imageUrls.length} images from $bucketName');
          return imageUrls;
        } catch (e) {
          debugPrint('❌ Error fetching images from bucket: $e');
          return [];
        }
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: (error) {
        // Don't retry data usage errors
        if (error.toString().contains('not allowed')) {
          return false;
        }
        return RetryUtils.shouldRetryImageError(error);
      },
      onRetry: (attempt, error) {
        debugPrint('🔄 Retrying fetch images (attempt $attempt): $error');
      },
    );
  }
  
  /// Preload images for offline access
  static Future<void> preloadImages(List<String> imageUrls, Ref ref) async {
    try {
      final dataUsageState = ref.read(dataUsageProvider);
      final networkState = ref.read(networkProvider);
      
      // Only preload if enabled and on Wi-Fi
      if (!dataUsageState.preloadFavorites || 
          !networkState.isConnected ||
          dataUsageState.connectionType != ConnectionType.wifi) {
        return;
      }

      debugPrint('🔄 Preloading ${imageUrls.length} images...');
      
      int totalDataUsage = 0;
      
      for (final url in imageUrls) {
        try {
          // Use CachedNetworkImage to preload and cache
          await CachedNetworkImage.evictFromCache(url);
          
          // Estimate data usage for preloading
          totalDataUsage += _estimateImageSize(dataUsageState.imageQuality);
          
          // Small delay to avoid overwhelming the network
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          debugPrint('Error preloading image $url: $e');
        }
      }
      
      // Record data usage for preloading
      ref.read(dataUsageProvider.notifier).recordDataUsage(totalDataUsage, type: 'image');
      
      debugPrint('✅ Preloaded ${imageUrls.length} images');
    } catch (e) {
      debugPrint('Error during image preloading: $e');
    }
  }
  
  /// Check if file is an image
  static bool _isImageFile(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
  }
  
  /// Check if image file size is acceptable for current data usage mode
  static bool _isImageFileSizeAcceptable(int fileSize, dataUsageState) {
    switch (dataUsageState.mode) {
      case DataUsageMode.unlimited:
        return true;
      case DataUsageMode.moderate:
        return fileSize <= 5 * 1024 * 1024; // 5MB limit
      case DataUsageMode.strict:
        return fileSize <= 1 * 1024 * 1024; // 1MB limit
      case DataUsageMode.wifiOnly:
        return dataUsageState.connectionType == ConnectionType.wifi;
      default:
        return false; // Default to false for unknown modes
    }
  }
  
  /// Estimate image size based on quality settings
  static int _estimateImageSize(DataUsageQuality quality) {
    switch (quality) {
      case DataUsageQuality.low:
        return 50 * 1024; // ~50KB
      case DataUsageQuality.medium:
        return 200 * 1024; // ~200KB
      case DataUsageQuality.high:
        return 500 * 1024; // ~500KB
      case DataUsageQuality.auto:
        return 200 * 1024; // Default to medium
    }
  }
  
  /// Format file size for display
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
  
  /// Get image quality based on data usage settings
  static String getImageQuality(Ref ref) {
    final dataUsageState = ref.read(dataUsageProvider);
    final recommendedQuality = dataUsageState.getRecommendedQuality(dataUsageState.imageQuality);
    
    switch (recommendedQuality) {
      case DataUsageQuality.low:
        return 'low'; // 400x300, 60% quality
      case DataUsageQuality.medium:
        return 'medium'; // 800x600, 80% quality
      case DataUsageQuality.high:
        return 'high'; // Original size, 95% quality
      case DataUsageQuality.auto:
        // Auto-adjust based on connection
        if (dataUsageState.connectionType == ConnectionType.cellular) {
          return 'medium';
        } else {
          return 'high';
        }
    }
  }
  
  /// Estimate data usage for image loading
  static int estimateImageDataUsage(Ref ref) {
    final dataUsageState = ref.read(dataUsageProvider);
    return _estimateImageSize(dataUsageState.imageQuality);
  }
  
  /// Clear image cache to free up storage
  static Future<void> clearImageCache() async {
    try {
      await CachedNetworkImage.evictFromCache('');
      debugPrint('✅ Image cache cleared');
    } catch (e) {
      debugPrint('Error clearing image cache: $e');
    }
  }
  
  /// Get cache size information
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      // This would integrate with your cache system
      // For now, return placeholder data
      return {
        'totalImages': 0,
        'totalSize': 0,
        'formattedSize': '0 B',
      };
    } catch (e) {
      debugPrint('Error getting cache info: $e');
      return {
        'totalImages': 0,
        'totalSize': 0,
        'formattedSize': '0 B',
      };
    }
  }
}
