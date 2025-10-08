import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/retry_utils.dart';
import '../utils/video_utils.dart';
import '../providers/data_usage_provider.dart';
import '../providers/network_provider.dart';

/// Enhanced video service with data usage controls and offline support
class EnhancedVideoService {
  static final ImagePicker _picker = ImagePicker();
  
  /// Pick a video from gallery with data usage consideration
  static Future<File?> pickVideoFromGallery(Ref ref) async {
    try {
      final dataUsageState = ref.read(dataUsageProvider);
      
      // Check if data usage is allowed
      if (!dataUsageState.shouldAllowDataUsage) {
        throw Exception('Data usage not allowed in current mode');
      }

      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: Duration(seconds: VideoUtils.maxVideoDurationSeconds),
      );
      
      if (video != null) {
        final file = File(video.path);
        
        // Validate the video file
        final validation = VideoUtils.validateVideoForUpload(file);
        if (!validation['isValid']) {
          throw Exception(validation['errors'].join(', '));
        }
        
        // Record data usage for local file access
        final fileSize = await file.length();
        ref.read(dataUsageProvider.notifier).recordDataUsage(fileSize, type: 'video');
        
        return file;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking video from gallery: $e');
      rethrow;
    }
  }
  
  /// Record a video with camera with data usage consideration
  static Future<File?> recordVideoWithCamera(Ref ref) async {
    try {
      final dataUsageState = ref.read(dataUsageProvider);
      
      // Check if data usage is allowed
      if (!dataUsageState.shouldAllowDataUsage) {
        throw Exception('Data usage not allowed in current mode');
      }

      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: Duration(seconds: VideoUtils.maxVideoDurationSeconds),
      );
      
      if (video != null) {
        final file = File(video.path);
        
        // Validate the video file
        final validation = VideoUtils.validateVideoForUpload(file);
        if (!validation['isValid']) {
          throw Exception(validation['errors'].join(', '));
        }
        
        // Record data usage for local file access
        final fileSize = await file.length();
        ref.read(dataUsageProvider.notifier).recordDataUsage(fileSize, type: 'video');
        
        return file;
      }
      return null;
    } catch (e) {
      debugPrint('Error recording video with camera: $e');
      rethrow;
    }
  }
  
  /// Upload video with data usage tracking and quality optimization
  static Future<String?> uploadVideoToSupabase(File videoFile, String fileName, int kataId, Ref ref) async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final dataUsageState = ref.read(dataUsageProvider);
          final networkState = ref.read(networkProvider);
          
          // Check if upload is allowed
          if (!dataUsageState.shouldAllowDataUsage || !networkState.isConnected) {
            throw Exception('Upload not allowed in current network state');
          }

          final supabase = Supabase.instance.client;
          
          // Validate file exists and is readable
          if (!await videoFile.exists()) {
            throw Exception('Video file does not exist: ${videoFile.path}');
          }
          
          // Validate video file
          final validation = VideoUtils.validateVideoForUpload(videoFile);
          if (!validation['isValid']) {
            throw Exception('Video validation failed: ${validation['errors'].join(', ')}');
          }
          
          // Get file size for data usage tracking
          final fileSize = await videoFile.length();
          
          // Check if file size is acceptable for current data usage mode
          if (!_isFileSizeAcceptable(fileSize, dataUsageState)) {
            throw Exception('File size too large for current data usage mode');
          }
          
          // Try to create the bucket if it doesn't exist
          try {
            await supabase.storage.createBucket(
              'kata_videos',
              BucketOptions(
                public: false,
                allowedMimeTypes: ['video/*'],
                fileSizeLimit: VideoUtils.maxVideoSizeBytes.toString(),
              ),
            );
          } catch (e) {
            // Bucket might already exist, which is fine
            debugPrint('Video bucket creation attempt: $e');
          }
          
          // Create a folder structure: kata_videos/{kata_id}/filename
          final filePath = '$kataId/$fileName';
          
          // Read the file as bytes
          final bytes = await videoFile.readAsBytes();
          
          if (bytes.isEmpty) {
            throw Exception('Video file is empty: ${videoFile.path}');
          }
          
          debugPrint('📹 Uploading video: ${VideoUtils.formatFileSize(bytes.length)} - $fileName');
          
          // Upload to Supabase Storage
          await supabase.storage
              .from('kata_videos')
              .uploadBinary(filePath, bytes);
          
          // Get the public URL of the uploaded video
          final publicUrl = supabase.storage
              .from('kata_videos')
              .getPublicUrl(filePath);
          
          // Record data usage
          ref.read(dataUsageProvider.notifier).recordDataUsage(bytes.length, type: 'video');
          
          debugPrint('✅ Video uploaded successfully: $fileName');
          return publicUrl;
        } catch (e) {
          debugPrint('❌ Error uploading video to Supabase: $e');
          rethrow;
        }
      },
      maxRetries: 2,
      initialDelay: const Duration(seconds: 5),
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
        debugPrint('🔄 Retrying upload video (attempt $attempt): $error');
      },
    );
  }
  
  /// Fetch videos with data usage optimization
  static Future<List<String>> fetchKataVideosFromBucket(int kataId, Ref ref) async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final dataUsageState = ref.read(dataUsageProvider);
          final networkState = ref.read(networkProvider);
          
          // Check if fetch is allowed
          if (!dataUsageState.shouldAllowDataUsage || !networkState.isConnected) {
            // Try to get from local cache
            return _getCachedVideos(kataId);
          }

          final supabase = Supabase.instance.client;
          
          // Check if the bucket exists
          try {
            await supabase.storage.getBucket('kata_videos');
          } catch (e) {
            debugPrint('⚠️ kata_videos bucket not found or not accessible: $e');
            return _getCachedVideos(kataId);
          }
          
          // List all files in the kata's folder
          final response = await supabase.storage
              .from('kata_videos')
              .list(path: kataId.toString());
          
          if (response.isEmpty) {
            debugPrint('ℹ️ No videos found for kata $kataId');
            return [];
          }
          
          List<Map<String, String>> videoData = [];
          int totalDataUsage = 0;
          
          for (final file in response) {
            if (file.name.isNotEmpty && !file.name.startsWith('.') && VideoUtils.isVideoFile(file.name)) {
              try {
                // Create signed URL for better security and access control
                final signedUrl = await supabase.storage
                    .from('kata_videos')
                    .createSignedUrl('$kataId/${file.name}', 7200); // 2 hours expiry
                
                videoData.add({
                  'url': signedUrl,
                  'name': file.name,
                });
                
                // Estimate data usage for URL generation
                totalDataUsage += 1024; // ~1KB per URL
                
                debugPrint('✅ Generated signed URL for video ${file.name}');
              } catch (signedUrlError) {
                debugPrint('⚠️ Failed to create signed URL for ${file.name}, falling back to public URL: $signedUrlError');
                // Fallback to public URL if signed URL fails
                final publicUrl = supabase.storage
                    .from('kata_videos')
                    .getPublicUrl('$kataId/${file.name}');
                videoData.add({
                  'url': publicUrl,
                  'name': file.name,
                });
                totalDataUsage += 512; // ~512B per public URL
              }
            }
          }
          
          if (videoData.isEmpty) {
            debugPrint('ℹ️ No valid video files found for kata $kataId');
            return [];
          }
          
          // Sort by filename to maintain order
          videoData.sort((a, b) => a['name']!.compareTo(b['name']!));
          
          // Extract just the URLs in the correct order
          final urls = videoData.map((data) => data['url']!).toList();
          
          // Record data usage
          ref.read(dataUsageProvider.notifier).recordDataUsage(totalDataUsage, type: 'video');
          
          // Cache the URLs locally
          _cacheVideos(kataId, urls);
          
          debugPrint('✅ Successfully fetched ${urls.length} videos for kata $kataId');
          return urls;
        } catch (e) {
          debugPrint('❌ Error fetching kata videos from bucket: $e');
          
          // Fallback to cached videos
          return _getCachedVideos(kataId);
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
        debugPrint('🔄 Retrying fetch kata videos (attempt $attempt): $error');
      },
    );
  }
  
  /// Preload videos for offline access
  static Future<void> preloadVideosForKata(int kataId, Ref ref) async {
    try {
      final dataUsageState = ref.read(dataUsageProvider);
      final networkState = ref.read(networkProvider);
      
      // Only preload if enabled and on Wi-Fi
      if (!dataUsageState.preloadFavorites || 
          !networkState.isConnected ||
          dataUsageState.connectionType != ConnectionType.wifi) {
        return;
      }

      debugPrint('🔄 Preloading videos for kata $kataId...');
      
      // Fetch videos
      final videoUrls = await fetchKataVideosFromBucket(kataId, ref);
      
      if (videoUrls.isNotEmpty) {
        // Cache the videos locally for offline access
        _cacheVideos(kataId, videoUrls);
        
        // Record data usage for preloading
        const estimatedBytes = 1024 * 1024; // 1MB estimate per video
        ref.read(dataUsageProvider.notifier).recordDataUsage(
          estimatedBytes * videoUrls.length, 
          type: 'video'
        );
        
        debugPrint('✅ Preloaded ${videoUrls.length} videos for kata $kataId');
      }
    } catch (e) {
      debugPrint('Error preloading videos for kata $kataId: $e');
    }
  }
  
  /// Get cached videos for offline access
  static List<String> _getCachedVideos(int kataId) {
    try {
      // This would integrate with your local storage system
      // For now, return empty list as placeholder
      debugPrint('📱 Getting cached videos for kata $kataId');
      return [];
    } catch (e) {
      debugPrint('Error getting cached videos: $e');
      return [];
    }
  }
  
  /// Cache videos locally
  static void _cacheVideos(int kataId, List<String> videoUrls) {
    try {
      // This would integrate with your local storage system
      // For now, just log the action
      debugPrint('💾 Caching ${videoUrls.length} videos for kata $kataId');
    } catch (e) {
      debugPrint('Error caching videos: $e');
    }
  }
  
  /// Check if file size is acceptable for current data usage mode
  static bool _isFileSizeAcceptable(int fileSize, dataUsageState) {
    switch (dataUsageState.mode) {
      case DataUsageMode.unlimited:
        return true;
      case DataUsageMode.moderate:
        return fileSize <= 50 * 1024 * 1024; // 50MB limit
      case DataUsageMode.strict:
        return fileSize <= 10 * 1024 * 1024; // 10MB limit
      case DataUsageMode.wifiOnly:
        return dataUsageState.connectionType == ConnectionType.wifi;
      default:
        return false; // Default to false for unknown modes
    }
  }
  
  /// Get video quality based on data usage settings
  static String getVideoQuality(Ref ref) {
    final dataUsageState = ref.read(dataUsageProvider);
    final recommendedQuality = dataUsageState.getRecommendedQuality(dataUsageState.videoQuality);
    
    switch (recommendedQuality) {
      case DataUsageQuality.low:
        return 'low'; // 480p or lower
      case DataUsageQuality.medium:
        return 'medium'; // 720p
      case DataUsageQuality.high:
        return 'high'; // 1080p or higher
      case DataUsageQuality.auto:
        // Auto-adjust based on connection
        if (dataUsageState.connectionType == ConnectionType.cellular) {
          return 'medium';
        } else {
          return 'high';
        }
    }
  }
  
  /// Estimate data usage for video streaming
  static int estimateVideoDataUsage(int durationSeconds, Ref ref) {
    final quality = getVideoQuality(ref);
    
    // Estimate based on quality (bytes per second)
    int bytesPerSecond;
    switch (quality) {
      case 'low':
        bytesPerSecond = 50 * 1024; // ~50KB/s
        break;
      case 'medium':
        bytesPerSecond = 200 * 1024; // ~200KB/s
        break;
      case 'high':
        bytesPerSecond = 500 * 1024; // ~500KB/s
        break;
      default:
        bytesPerSecond = 200 * 1024; // Default to medium
    }
    
    return durationSeconds * bytesPerSecond;
  }
}
