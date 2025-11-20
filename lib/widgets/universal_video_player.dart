import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../utils/video_utils.dart';
import '../services/offline_media_cache_service.dart';
import '../providers/network_provider.dart';

class UniversalVideoPlayer extends ConsumerWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final double? aspectRatio;

  const UniversalVideoPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = false,
    this.showControls = true,
    this.aspectRatio,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _UniversalVideoPlayerWidget(
      videoUrl: videoUrl,
      autoPlay: autoPlay,
      looping: looping,
      showControls: showControls,
      aspectRatio: aspectRatio,
      ref: ref,
    );
  }
}

class _UniversalVideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final double? aspectRatio;
  final WidgetRef ref;

  const _UniversalVideoPlayerWidget({
    required this.videoUrl,
    required this.autoPlay,
    required this.looping,
    required this.showControls,
    required this.aspectRatio,
    required this.ref,
  });

  @override
  State<_UniversalVideoPlayerWidget> createState() => _UniversalVideoPlayerState();
}

class _UniversalVideoPlayerState extends State<_UniversalVideoPlayerWidget> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isYouTubeVideo = false;
  bool _showError = false; // New flag to control error visibility
  Timer? _errorDelayTimer; // Timer for delayed error showing
  bool _isOfflineMode = false;
  bool _isCachedLocally = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // Check if this is a YouTube URL
      if (_isYouTubeUrl(widget.videoUrl)) {
        _isYouTubeVideo = true;
        await _initializeYouTubePlayer();
      } else {
        _isYouTubeVideo = false;

        // Check if we're offline and if video is cached
        await _checkOfflineAvailability();

        if (_isOfflineMode && !_isCachedLocally) {
          // Show offline message for non-cached videos
          _hasError = true;
          _errorMessage = 'Video is not available offline. Connect to internet to watch this video.';
          setState(() {
            _showError = true;
          });
          return;
        }

        await _initializeRegularVideoPlayer();
      }
    } catch (e) {
      if (mounted) {
        _hasError = true;
        _errorMessage = _getReadableErrorMessage(e.toString());

        // Only show error after a delay to prevent flashing errors
        _errorDelayTimer?.cancel();
        _errorDelayTimer = Timer(const Duration(seconds: 2), () {
          if (mounted && _hasError && !_isInitialized) {
            setState(() {
              _showError = true;
            });
          }
        });
      }
    }
  }

  Future<void> _checkOfflineAvailability() async {
    try {
      // Check network state
      final networkState = widget.ref.read(networkProvider);
      _isOfflineMode = !networkState.isConnected;

      // Check if video is cached locally
      _isCachedLocally = OfflineMediaCacheService.getCachedFilePath(widget.videoUrl, true) != null;

      debugPrint('Video offline check: offline=$_isOfflineMode, cached=$_isCachedLocally, url=${widget.videoUrl}');
    } catch (e) {
      // If network provider not available, assume online
      _isOfflineMode = false;
      _isCachedLocally = false;
      debugPrint('Failed to check offline availability: $e');
    }
  }

  Future<void> _initializeYouTubePlayer() async {
    try {
      final videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);
      if (videoId == null) {
        throw Exception('Invalid YouTube URL');
      }

      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: YoutubePlayerFlags(
          autoPlay: widget.autoPlay,
          loop: widget.looping,
          mute: false,
          enableCaption: true,
          captionLanguage: 'en',
          controlsVisibleAtStart: widget.showControls,
        ),
      );

      if (mounted) {
        // Cancel error timer since initialization succeeded
        _errorDelayTimer?.cancel();
        setState(() {
          _isInitialized = true;
          _hasError = false;
          _showError = false;
        });
      }
    } catch (e) {
      throw Exception('Failed to load YouTube video: ${e.toString()}');
    }
  }

  Future<void> _initializeRegularVideoPlayer() async {
    try {
      // Check for unsupported external URLs
      if (_isUnsupportedExternalUrl(widget.videoUrl)) {
        throw Exception('This video platform is not supported. Please use YouTube URLs or direct video file URLs (MP4, MOV, etc.)');
      }

      // Validate URL before attempting to load
      if (!VideoUtils.isValidVideoUrl(widget.videoUrl)) {
        throw Exception('Invalid video URL format');
      }

      // Debug video information
      VideoUtils.debugVideoInfo(widget.videoUrl, additionalInfo: 'Initializing regular video player');

      // Use cached URL if available, otherwise use original URL
      final videoUrl = _isCachedLocally
          ? OfflineMediaCacheService.getCachedFilePath(widget.videoUrl, true) ?? widget.videoUrl
          : widget.videoUrl;

      debugPrint('Using video URL: $videoUrl (cached: $_isCachedLocally)');

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );

      // Set up error listener with delayed error showing
      _videoPlayerController!.addListener(() {
        if (_videoPlayerController!.value.hasError && mounted) {
          final error = _videoPlayerController!.value.errorDescription;
          _hasError = true;

          // Provide more specific error messages for offline scenarios
          if (_isOfflineMode && !_isCachedLocally) {
            _errorMessage = 'Video is not available offline. Connect to internet to watch this video.';
          } else {
            _errorMessage = _getReadableErrorMessage(error ?? 'Unknown video error');
          }

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

      await _videoPlayerController!.initialize();

      if (mounted) {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: widget.autoPlay,
          looping: widget.looping,
          showControls: widget.showControls,
          aspectRatio: widget.aspectRatio ?? _videoPlayerController!.value.aspectRatio,
          placeholder: Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
          errorBuilder: (context, errorMessage) {
            return _buildErrorWidget(errorMessage);
          },
          materialProgressColors: ChewieProgressColors(
            playedColor: Theme.of(context).primaryColor,
            handleColor: Theme.of(context).primaryColor,
            backgroundColor: Colors.grey,
            bufferedColor: Colors.grey.shade300,
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
      throw Exception('Failed to load video: ${e.toString()}');
    }
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Video failed to load',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: const TextStyle(
                color: Colors.white70,
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
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _retryInitialization() async {
    _errorDelayTimer?.cancel();
    setState(() {
      _hasError = false;
      _isInitialized = false;
      _showError = false;
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
    // Convert technical errors to user-friendly messages
    if (error.contains('Invalid YouTube URL')) {
      return 'Invalid YouTube URL. Please check the video link.';
    } else if (error.contains('Failed to load YouTube video')) {
      return 'Unable to load YouTube video. Please check your internet connection.';
    } else if (error.contains('This video platform is not supported')) {
      return 'This video platform is not supported. Please use YouTube URLs or upload videos directly.';
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
    _videoPlayerController?.dispose();
    _youtubeController?.dispose();
    _chewieController = null;
    _videoPlayerController = null;
    _youtubeController = null;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show immediate offline message for non-cached videos when offline
    if (_isOfflineMode && !_isCachedLocally) {
      return Container(
        height: 200,
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                color: Colors.white,
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Video alleen beschikbaar online',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Ga online om video\'s te bekijken',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Only show error if the flag is set (after delay)
    if (_hasError && _showError) {
      return SizedBox(
        height: 200,
        child: _buildErrorWidget(_errorMessage ?? 'Unknown error'),
      );
    }

    if (!_isInitialized) {
      return Container(
        height: 200,
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                _isOfflineMode && !_isCachedLocally
                    ? 'Video niet beschikbaar offline'
                    : 'Laden video...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              if (_isOfflineMode && _isCachedLocally)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Offline versie beschikbaar',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (_isOfflineMode && !_isCachedLocally)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Maak verbinding met internet',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (_isYouTubeVideo && _youtubeController != null) {
      return YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Theme.of(context).primaryColor,
        progressColors: ProgressBarColors(
          playedColor: Theme.of(context).primaryColor,
          handleColor: Theme.of(context).primaryColor,
        ),
        onReady: () {
          // Video is ready to play
        },
        onEnded: (data) {
          // Video ended
        },
      );
    } else if (!_isYouTubeVideo && _chewieController != null) {
      return Chewie(
        controller: _chewieController!,
      );
    }

    return Container(
      height: 200,
      color: Colors.black,
      child: const Center(
        child: Text(
          'Video player not initialized',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
