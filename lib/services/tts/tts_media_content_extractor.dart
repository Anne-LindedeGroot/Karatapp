import 'package:flutter/material.dart';

/// TTS Media Content Extractor - Handles extraction of media-related content
class TTSMediaContentExtractor {
  /// Extract media content information (photos, videos, etc.) with enhanced descriptions
  static String extractMediaContent(BuildContext context) {
    final List<String> mediaParts = [];
    
    try {
      if (!context.mounted) {
        debugPrint('TTS: Context no longer mounted in extractMediaContent');
        return '';
      }
      
      // Extract image-related text
      final imageTexts = _extractImageRelatedText(context);
      if (imageTexts.isNotEmpty) {
        mediaParts.add('Afbeeldingen: ${imageTexts.join(', ')}');
      }
      
      // Extract video-related text
      final videoTexts = _extractVideoRelatedText(context);
      if (videoTexts.isNotEmpty) {
        mediaParts.add('Video\'s: ${videoTexts.join(', ')}');
      }
      
      // Extract media-related buttons and controls
      final mediaButtons = _extractMediaButtons(context);
      if (mediaButtons.isNotEmpty) {
        mediaParts.add('Media knoppen: ${mediaButtons.join(', ')}');
      }
      
      // Extract media URLs
      final mediaUrls = _extractMediaUrls(context);
      if (mediaUrls.isNotEmpty) {
        mediaParts.add('Media links: ${mediaUrls.join(', ')}');
      }
      
      // Extract image gallery information
      final imageGallery = _extractImageGalleryInfo(context);
      if (imageGallery.isNotEmpty) {
        mediaParts.add(imageGallery);
      }
      
      // Extract video gallery information
      final videoGallery = _extractVideoGalleryInfo(context);
      if (videoGallery.isNotEmpty) {
        mediaParts.add(videoGallery);
      }
      
      // Extract photo upload information
      final photoUpload = _extractPhotoUploadInfo(context);
      if (photoUpload.isNotEmpty) {
        mediaParts.add(photoUpload);
      }
      
      // Extract video URL input information
      final videoUrlInput = _extractVideoUrlInputInfo(context);
      if (videoUrlInput.isNotEmpty) {
        mediaParts.add(videoUrlInput);
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting media content: $e');
    }
    
    return mediaParts.join('. ');
  }

  /// Extract image-related text from the screen
  static List<String> _extractImageRelatedText(BuildContext context) {
    final List<String> imageTexts = [];
    
    try {
      // This is a simplified implementation
      // In a real implementation, you would traverse the widget tree
      // to find image-related widgets and text
      
    } catch (e) {
      debugPrint('TTS: Error extracting image-related text: $e');
    }
    
    return imageTexts;
  }

  /// Extract video-related text from the screen
  static List<String> _extractVideoRelatedText(BuildContext context) {
    final List<String> videoTexts = [];
    
    try {
      // This is a simplified implementation
      // In a real implementation, you would traverse the widget tree
      // to find video-related widgets and text
      
    } catch (e) {
      debugPrint('TTS: Error extracting video-related text: $e');
    }
    
    return videoTexts;
  }

  /// Extract media-related buttons and controls
  static List<String> _extractMediaButtons(BuildContext context) {
    final List<String> mediaButtons = [];
    
    try {
      // This is a simplified implementation
      // In a real implementation, you would traverse the widget tree
      // to find media control buttons, play/pause buttons, etc.
      
    } catch (e) {
      debugPrint('TTS: Error extracting media buttons: $e');
    }
    
    return mediaButtons;
  }

  /// Extract media URLs from text fields and widgets
  static List<String> _extractMediaUrls(BuildContext context) {
    final List<String> mediaUrls = [];
    
    try {
      // This is a simplified implementation
      // In a real implementation, you would traverse the widget tree
      // to find text fields containing URLs and extract them
      
    } catch (e) {
      debugPrint('TTS: Error extracting media URLs: $e');
    }
    
    return mediaUrls;
  }

  /// Extract image gallery information
  static String _extractImageGalleryInfo(BuildContext context) {
    try {
      // This is a simplified implementation
      // In a real implementation, you would traverse the widget tree
      // to find image galleries and extract information about them
      
    } catch (e) {
      debugPrint('TTS: Error extracting image gallery info: $e');
    }
    return '';
  }

  /// Extract video gallery information
  static String _extractVideoGalleryInfo(BuildContext context) {
    try {
      // This is a simplified implementation
      // In a real implementation, you would traverse the widget tree
      // to find video galleries and extract information about them
      
    } catch (e) {
      debugPrint('TTS: Error extracting video gallery info: $e');
    }
    return '';
  }

  /// Extract photo upload information
  static String _extractPhotoUploadInfo(BuildContext context) {
    try {
      // This is a simplified implementation
      // In a real implementation, you would traverse the widget tree
      // to find photo upload widgets and extract information about them
      
    } catch (e) {
      debugPrint('TTS: Error extracting photo upload info: $e');
    }
    return '';
  }

  /// Extract video URL input information
  static String _extractVideoUrlInputInfo(BuildContext context) {
    try {
      // This is a simplified implementation
      // In a real implementation, you would traverse the widget tree
      // to find video URL input widgets and extract information about them
      
    } catch (e) {
      debugPrint('TTS: Error extracting video URL input info: $e');
    }
    return '';
  }

  /// Check if a string is a valid URL
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Check if a URL is a media URL
  static bool isMediaUrl(String url) {
    if (!isValidUrl(url)) return false;
    
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('.jpg') ||
           lowerUrl.contains('.jpeg') ||
           lowerUrl.contains('.png') ||
           lowerUrl.contains('.gif') ||
           lowerUrl.contains('.webp') ||
           lowerUrl.contains('.svg') ||
           lowerUrl.contains('.mp4') ||
           lowerUrl.contains('.webm') ||
           lowerUrl.contains('.avi') ||
           lowerUrl.contains('.mov') ||
           lowerUrl.contains('youtube.com') ||
           lowerUrl.contains('youtu.be') ||
           lowerUrl.contains('vimeo.com');
  }

  /// Get a readable display name for a URL
  static String getUrlDisplayName(String url) {
    try {
      final uri = Uri.parse(url);
      
      // Check for streaming platforms
      if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
        return 'YouTube video';
      } else if (uri.host.contains('vimeo.com')) {
        return 'Vimeo video';
      } else if (uri.host.contains('dailymotion.com')) {
        return 'Dailymotion video';
      }
      
      // Check for direct media files
      final path = uri.path.toLowerCase();
      if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
        return 'JPEG afbeelding';
      } else if (path.endsWith('.png')) {
        return 'PNG afbeelding';
      } else if (path.endsWith('.gif')) {
        return 'GIF animatie';
      } else if (path.endsWith('.webp')) {
        return 'WebP afbeelding';
      } else if (path.endsWith('.svg')) {
        return 'SVG afbeelding';
      } else if (path.endsWith('.mp4')) {
        return 'MP4 video';
      } else if (path.endsWith('.webm')) {
        return 'WebM video';
      } else if (path.endsWith('.avi')) {
        return 'AVI video';
      } else if (path.endsWith('.mov')) {
        return 'MOV video';
      }
      
      return 'Media bestand';
    } catch (e) {
      return 'Media bestand';
    }
  }
}
