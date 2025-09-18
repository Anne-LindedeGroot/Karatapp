import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../utils/video_utils.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final double? aspectRatio;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = false,
    this.showControls = true,
    this.aspectRatio,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // Check if this is a YouTube URL or other unsupported external URL
      if (_isYouTubeUrl(widget.videoUrl) || _isUnsupportedExternalUrl(widget.videoUrl)) {
        throw Exception('YouTube and external video URLs are not supported. Please use direct video file URLs (MP4, MOV, etc.)');
      }

      // Validate URL before attempting to load
      if (!VideoUtils.isValidVideoUrl(widget.videoUrl)) {
        throw Exception('Invalid video URL format');
      }

      // Debug video information
      VideoUtils.debugVideoInfo(widget.videoUrl, additionalInfo: 'Initializing player');

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      // Set up error listener
      _videoPlayerController.addListener(() {
        if (_videoPlayerController.value.hasError && mounted) {
          final error = _videoPlayerController.value.errorDescription;
          setState(() {
            _hasError = true;
            _errorMessage = _getReadableErrorMessage(error ?? 'Unknown video error');
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
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
          errorBuilder: (context, errorMessage) {
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
                      onPressed: () {
                        _retryInitialization();
                      },
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
          },
          materialProgressColors: ChewieProgressColors(
            playedColor: Theme.of(context).primaryColor,
            handleColor: Theme.of(context).primaryColor,
            backgroundColor: Colors.grey,
            bufferedColor: Colors.grey.shade300,
          ),
        );

        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = _getReadableErrorMessage(e.toString());
        });
      }
    }
  }

  Future<void> _retryInitialization() async {
    setState(() {
      _hasError = false;
      _isInitialized = false;
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
    _chewieController?.dispose();
    await _videoPlayerController.dispose();
    _chewieController = null;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        height: 200,
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
                _errorMessage ?? 'Unknown error',
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

    if (!_isInitialized || _chewieController == null) {
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
                'Loading video...',
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
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
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
              const Center(
                child: Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 24,
                ),
              )
            else
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
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
