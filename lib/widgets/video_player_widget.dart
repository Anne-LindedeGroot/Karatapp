import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../utils/video_utils.dart';
import '../services/offline_media_cache_service.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final double? aspectRatio;
  final dynamic ref; // Add ref parameter for offline cache access

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = false,
    this.showControls = true,
    this.aspectRatio,
    this.ref, // Optional ref for offline functionality
  });

  // Static method to resolve video URL based on network state
  static Future<String> _resolveVideoUrl(String originalUrl, dynamic ref) async {
    // Check if this is a local file path (already cached)
    if (originalUrl.startsWith('/') || originalUrl.startsWith('file://')) {
      return originalUrl;
    }

    // For online/offline handling, use the offline cache service
    if (ref != null) {
      return await OfflineMediaCacheService.getMediaUrl(originalUrl, true, ref);
    }

    return originalUrl;
  }

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _showError = false; // New flag to control error visibility
  Timer? _errorDelayTimer; // Timer for delayed error showing
  bool _isOfflineVideoError = false; // Flag for offline video informational message

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // Get the resolved URL (cached file when offline, original URL when online)
      final resolvedUrl = await VideoPlayerWidget._resolveVideoUrl(widget.videoUrl, widget.ref);

      // Check if we're dealing with a cached file vs original URL
      final isCachedFile = resolvedUrl.startsWith('/') || resolvedUrl.startsWith('file://');
      final isYouTubeUrl = _isYouTubeUrl(resolvedUrl);
      final isUnsupportedExternalUrl = _isUnsupportedExternalUrl(resolvedUrl);

      // When offline (using cached file), only allow direct video files
      if (isCachedFile) {
        if (!VideoUtils.isVideoFile(resolvedUrl)) {
          _isOfflineVideoError = true;
          throw Exception('Cached video file is not a valid video format. Only MP4, MOV, and other direct video files work offline.');
        }
      } else {
        // Check if we're offline (no cached file available but should be using cache)
        final shouldBeCached = widget.ref != null && OfflineMediaCacheService.shouldUseCache(widget.ref!);

        if (shouldBeCached && (isYouTubeUrl || isUnsupportedExternalUrl)) {
          // We're offline and this is a YouTube/social media video - show peaceful message
          _isOfflineVideoError = true;
          throw Exception('OFFLINE_VIDEO_INFO');
        }

        // When online, allow YouTube URLs but warn user they won't work offline
        if (isYouTubeUrl || isUnsupportedExternalUrl) {
          // Show a warning but don't prevent playback
          debugPrint('⚠️ YouTube/social media videos work online but cannot be cached for offline use');
        }

        // Validate the URL format
        if (!VideoUtils.isValidVideoUrl(resolvedUrl)) {
          throw Exception('Invalid video URL format');
        }
      }

      // Debug video information
      VideoUtils.debugVideoInfo(resolvedUrl, additionalInfo: 'Initializing player with resolved URL');

      // Create the appropriate controller based on URL type
      if (isCachedFile) {
        _videoPlayerController = VideoPlayerController.file(File(resolvedUrl));
      } else {
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(resolvedUrl));
      }

      // Set up error listener with delayed error showing
      _videoPlayerController.addListener(() {
        if (_videoPlayerController.value.hasError && mounted) {
          final error = _videoPlayerController.value.errorDescription;
          _hasError = true;
          _errorMessage = _getReadableErrorMessage(error ?? 'Unknown video error');
          
          // Only show error after a longer delay to prevent startup errors from showing
          // and only if the error persists for a significant time
          _errorDelayTimer?.cancel();
          _errorDelayTimer = Timer(const Duration(seconds: 5), () {
            if (mounted && _hasError && !_isInitialized) {
              // Check if this is a temporary network error that might resolve itself
              final errorStr = error?.toLowerCase() ?? '';
              final isTemporaryError = errorStr.contains('network') || 
                                     errorStr.contains('connection') ||
                                     errorStr.contains('timeout') ||
                                     errorStr.contains('exoplaybackexception') ||
                                     errorStr.contains('sourceerror');
              
              // For temporary errors, wait even longer before showing
              if (isTemporaryError) {
                _errorDelayTimer = Timer(const Duration(seconds: 3), () {
                  if (mounted && _hasError && !_isInitialized) {
                    setState(() {
                      _showError = true;
                    });
                  }
                });
              } else {
                setState(() {
                  _showError = true;
                });
              }
            }
          });
        }
      });

      await _videoPlayerController.initialize();

      if (mounted) {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          autoPlay: widget.autoPlay,
          looping: widget.looping,
          showControls: widget.showControls,
          aspectRatio: widget.aspectRatio ?? _videoPlayerController.value.aspectRatio,
          placeholder: Container(
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surface
                : Colors.black,
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
              ),
            ),
          ),
          errorBuilder: (context, errorMessage) {
            // Don't show error immediately - let the delayed timer handle it
            return Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.surface
                  : Colors.black,
              child: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white,
                ),
              ),
            );
          },
          materialProgressColors: ChewieProgressColors(
            playedColor: Theme.of(context).colorScheme.primary,
            handleColor: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.outline
                : Colors.grey,
            bufferedColor: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.outlineVariant
                : Colors.grey.shade300,
          ),
        );

        // Cancel error timer since initialization succeeded
        _errorDelayTimer?.cancel();
        setState(() {
          _isInitialized = true;
          _hasError = false;
          _showError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _hasError = true;
        _errorMessage = _getReadableErrorMessage(e.toString());
        
        // Only show error after a longer delay to prevent startup errors from showing
        _errorDelayTimer?.cancel();
        _errorDelayTimer = Timer(const Duration(seconds: 5), () {
          if (mounted && _hasError && !_isInitialized) {
            // Check if this is a temporary network error that might resolve itself
            final errorStr = e.toString().toLowerCase();
            final isTemporaryError = errorStr.contains('network') || 
                                   errorStr.contains('connection') ||
                                   errorStr.contains('timeout') ||
                                   errorStr.contains('exoplaybackexception') ||
                                   errorStr.contains('sourceerror');
            
            // For temporary errors, wait even longer before showing
            if (isTemporaryError) {
              _errorDelayTimer = Timer(const Duration(seconds: 3), () {
                if (mounted && _hasError && !_isInitialized) {
                  setState(() {
                    _showError = true;
                  });
                }
              });
            } else {
              setState(() {
                _showError = true;
              });
            }
          }
        });
      }
    }
  }

  Future<void> _retryInitialization() async {
    _errorDelayTimer?.cancel();
    setState(() {
      _hasError = false;
      _isInitialized = false;
      _showError = false;
      _isOfflineVideoError = false;
    });

    await _disposeControllers();
    await _initializePlayer();
  }

  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || 
           url.contains('youtu.be') || 
           url.contains('m.youtube.com');
  }

  bool _isUnsupportedExternalUrl(String url) {
    // Check for common video platforms that don't provide direct video URLs
    final unsupportedDomains = [
      'vimeo.com',
      'dailymotion.com',
      'twitch.tv',
      'facebook.com',
      'instagram.com',
      'tiktok.com',
      'twitter.com',
      'x.com',
    ];
    
    return unsupportedDomains.any((domain) => url.contains(domain));
  }

  String _getReadableErrorMessage(String error) {
    // Handle special offline video informational message
    if (error.contains('OFFLINE_VIDEO_INFO')) {
      return 'OFFLINE_VIDEO_INFO'; // Special marker for peaceful offline message
    }

    // Convert technical ExoPlayer errors to user-friendly messages
    if (error.contains('YouTube and external video URLs are not supported')) {
      return 'YouTube and social media videos are not supported. Please use direct video file URLs (MP4, MOV, etc.) or upload videos to your storage.';
    } else if (error.contains('ExoPlaybackException') || error.contains('sourceerror')) {
      return 'Unable to load video. Please check your internet connection and try again.';
    } else if (error.contains('network') || error.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    } else if (error.contains('format') || error.contains('codec')) {
      return 'Video format not supported. Please try a different video.';
    } else if (error.contains('permission') || error.contains('access')) {
      return 'Access denied. Please check video permissions.';
    } else if (error.contains('timeout')) {
      return 'Video loading timed out. Please try again.';
    } else if (error.contains('Invalid video URL format')) {
      return 'Invalid video URL. Please check the video link.';
    }

    // Return a generic message for unknown errors
    return 'Unable to play video. Please try again later.';
  }

  Future<void> _disposeControllers() async {
    _errorDelayTimer?.cancel();
    _chewieController?.dispose();
    if (_isInitialized) {
      await _videoPlayerController.dispose();
    }
    _chewieController = null;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Show peaceful offline info message instead of error for offline videos
    if (_hasError && _showError && _isOfflineVideoError && _errorMessage == 'OFFLINE_VIDEO_INFO') {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? theme.colorScheme.outline : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_outlined,
                color: isDark ? theme.colorScheme.primary : Colors.blue[600],
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Video niet beschikbaar offline',
                style: TextStyle(
                  color: isDark ? theme.colorScheme.onSurface : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Deze video is alleen beschikbaar met internetverbinding. Maak verbinding met internet om deze video te bekijken.',
                  style: TextStyle(
                    color: isDark ? theme.colorScheme.onSurfaceVariant : Colors.black54,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.primaryContainer : Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: isDark ? theme.colorScheme.primary : Colors.blue[600],
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Online beschikbaar',
                      style: TextStyle(
                        color: isDark ? theme.colorScheme.primary : Colors.blue[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Only show error if the flag is set (after delay) and it's not an offline info message
    if (_hasError && _showError) {
      return Container(
        height: 200,
        color: isDark ? theme.colorScheme.surface : Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: isDark ? theme.colorScheme.error : Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Video failed to load',
                style: TextStyle(
                  color: isDark ? theme.colorScheme.onSurface : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error',
                style: TextStyle(
                  color: isDark ? theme.colorScheme.onSurfaceVariant : Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _retryInitialization,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _chewieController == null) {
      // Show loading indicator instead of error for the first few seconds
      if (!_hasError || !_showError) {
        return Container(
          height: 200,
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Colors.white,
                ),
                SizedBox(height: 16),
                Text(
                  'Laden video...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return Container(
        height: 200,
        color: isDark ? theme.colorScheme.surface : Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: isDark ? theme.colorScheme.primary : Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                'Laden video...',
                style: TextStyle(
                  color: isDark ? theme.colorScheme.onSurface : Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Chewie(
      controller: _chewieController!,
    );
  }
}

class VideoThumbnail extends StatefulWidget {
  final String videoUrl;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const VideoThumbnail({
    super.key,
    required this.videoUrl,
    this.width = 100,
    this.height = 100,
    this.onTap,
  });

  @override
  State<VideoThumbnail> createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeThumbnail();
  }

  Future<void> _initializeThumbnail() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      
      await _controller!.initialize();
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? theme.colorScheme.outline : Colors.grey.shade300,
          ),
        ),
        child: Stack(
          children: [
            if (_isInitialized && _controller != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: SizedBox(
                  width: widget.width,
                  height: widget.height,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  ),
                ),
              )
            else if (_hasError)
              Center(
                child: Icon(
                  Icons.error_outline,
                  color: isDark ? theme.colorScheme.error : Colors.white,
                  size: 24,
                ),
              )
            else
              Center(
                child: CircularProgressIndicator(
                  color: isDark ? theme.colorScheme.primary : Colors.white,
                  strokeWidth: 2,
                ),
              ),
            
            // Play button overlay
            Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            
            // Video indicator
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.videocam,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
