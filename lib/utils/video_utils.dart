import 'dart:io';
import 'package:flutter/foundation.dart';

class VideoUtils {
  /// Supported video formats for the app
  static const List<String> supportedVideoFormats = [
    'mp4',
    'mov',
    'avi',
    'mkv',
    'webm',
    'm4v',
  ];

  /// Maximum video file size in bytes (50MB)
  static const int maxVideoSizeBytes = 50 * 1024 * 1024;

  /// Maximum video duration in seconds (10 minutes)
  static const int maxVideoDurationSeconds = 600;

  /// Check if a file extension is a supported video format
  static bool isSupportedVideoFormat(String extension) {
    return supportedVideoFormats.contains(extension.toLowerCase());
  }

  /// Extract file extension from a file path or URL
  static String? getFileExtension(String path) {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1) return null;
    return path.substring(lastDot + 1).toLowerCase();
  }

  /// Check if a file is a valid video file
  static bool isVideoFile(String path) {
    final extension = getFileExtension(path);
    return extension != null && isSupportedVideoFormat(extension);
  }

  /// Validate video file size
  static bool isValidVideoSize(int sizeInBytes) {
    return sizeInBytes <= maxVideoSizeBytes;
  }

  /// Get human-readable file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Get human-readable duration
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Extract filename from URL or path
  static String extractFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        return segments.last;
      }
      return 'video';
    } catch (e) {
      return 'video';
    }
  }

  /// Generate video thumbnail URL (if using a service that provides thumbnails)
  static String? generateThumbnailUrl(String videoUrl) {
    // This would depend on your video storage service
    // For example, if using Supabase Storage, you might have a thumbnail generation service
    // For now, return null as this would be service-specific
    return null;
  }

  /// Validate video URL format
  static bool isValidVideoUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Get video quality based on file size (rough estimation)
  static String getVideoQuality(int sizeInBytes) {
    if (sizeInBytes < 5 * 1024 * 1024) return 'Low';
    if (sizeInBytes < 25 * 1024 * 1024) return 'Medium';
    if (sizeInBytes < 50 * 1024 * 1024) return 'High';
    return 'Very High';
  }

  /// Create a video file name with kata ID and timestamp
  static String createVideoFileName(int kataId, String originalFileName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = getFileExtension(originalFileName) ?? 'mp4';
    return '${kataId}_video_$timestamp.$extension';
  }

  /// Create ordered video file name (for multiple videos)
  static String createOrderedVideoFileName(int kataId, int order, String originalFileName) {
    final extension = getFileExtension(originalFileName) ?? 'mp4';
    final orderPrefix = order.toString().padLeft(3, '0');
    return '${kataId}_${orderPrefix}_video.$extension';
  }

  /// Validate video for kata upload
  static Map<String, dynamic> validateVideoForUpload(File videoFile) {
    final result = <String, dynamic>{
      'isValid': false,
      'errors': <String>[],
      'warnings': <String>[],
    };

    // Check if file exists
    if (!videoFile.existsSync()) {
      result['errors'].add('Video file does not exist');
      return result;
    }

    // Check file extension
    final extension = getFileExtension(videoFile.path);
    if (extension == null || !isSupportedVideoFormat(extension)) {
      result['errors'].add('Unsupported video format. Supported formats: ${supportedVideoFormats.join(', ')}');
      return result;
    }

    // Check file size
    final sizeInBytes = videoFile.lengthSync();
    if (!isValidVideoSize(sizeInBytes)) {
      result['errors'].add('Video file is too large. Maximum size: ${formatFileSize(maxVideoSizeBytes)}');
      return result;
    }

    // Add warnings for large files
    if (sizeInBytes > 50 * 1024 * 1024) {
      result['warnings'].add('Large video file may take longer to upload and load');
    }

    result['isValid'] = true;
    result['fileSize'] = sizeInBytes;
    result['fileSizeFormatted'] = formatFileSize(sizeInBytes);
    result['quality'] = getVideoQuality(sizeInBytes);

    return result;
  }

  /// Get video aspect ratio category
  static String getAspectRatioCategory(double aspectRatio) {
    if (aspectRatio < 0.75) return 'Portrait';
    if (aspectRatio > 1.33) return 'Landscape';
    return 'Square';
  }

  /// Check if video is in portrait orientation
  static bool isPortraitVideo(double aspectRatio) {
    return aspectRatio < 1.0;
  }

  /// Check if video is in landscape orientation
  static bool isLandscapeVideo(double aspectRatio) {
    return aspectRatio > 1.0;
  }

  /// Get recommended video settings for kata uploads
  static Map<String, dynamic> getRecommendedVideoSettings() {
    return {
      'maxDuration': maxVideoDurationSeconds,
      'maxSize': maxVideoSizeBytes,
      'recommendedFormats': ['mp4', 'mov'],
      'recommendedResolution': '1080p or lower',
      'recommendedAspectRatio': '16:9 or 4:3',
      'tips': [
        'Keep videos under 10 minutes for better user experience',
        'Use MP4 format for best compatibility',
        'Ensure good lighting and clear demonstration of techniques',
        'Consider adding captions or voice-over for better accessibility',
      ],
    };
  }

  /// Debug video information (for development)
  static void debugVideoInfo(String videoUrl, {String? additionalInfo}) {
    if (kDebugMode) {
      print('=== Video Debug Info ===');
      print('URL: $videoUrl');
      print('Is Valid URL: ${isValidVideoUrl(videoUrl)}');
      print('File Extension: ${getFileExtension(videoUrl)}');
      print('Is Video File: ${isVideoFile(videoUrl)}');
      print('File Name: ${extractFileNameFromUrl(videoUrl)}');
      if (additionalInfo != null) {
        print('Additional Info: $additionalInfo');
      }
      print('========================');
    }
  }
}

/// Video compression quality levels
enum VideoQuality {
  low(240),
  medium(480),
  high(720),
  veryHigh(1080);

  const VideoQuality(this.height);
  final int height;

  String get displayName {
    switch (this) {
      case VideoQuality.low:
        return 'Low (240p)';
      case VideoQuality.medium:
        return 'Medium (480p)';
      case VideoQuality.high:
        return 'High (720p)';
      case VideoQuality.veryHigh:
        return 'Very High (1080p)';
    }
  }
}

/// Video orientation types
enum VideoOrientation {
  portrait,
  landscape,
  square;

  static VideoOrientation fromAspectRatio(double aspectRatio) {
    if (aspectRatio < 0.9) return VideoOrientation.portrait;
    if (aspectRatio > 1.1) return VideoOrientation.landscape;
    return VideoOrientation.square;
  }
}
