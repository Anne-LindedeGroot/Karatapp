import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../utils/video_utils.dart';

class UniversalVideoPlayer extends StatefulWidget {
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
  State<UniversalVideoPlayer> createState() => _UniversalVideoPlayerState();
}

class _UniversalVideoPlayerState extends State<UniversalVideoPlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubeController;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  bool _isYouTubeVideo = false;

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
        await _initializeRegularVideoPlayer();
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
        setState(() {
          _isInitialized = true;
          _hasError = false;
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

      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      // Set up error listener
      _videoPlayerController!.addListener(() {
        if (_videoPlayerController!.value.hasError && mounted) {
          final error = _videoPlayerController!.value.errorDescription;
          setState(() {
            _hasError = true;
            _errorMessage = _getReadableErrorMessage(error ?? 'Unknown video error');
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

        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (e) {
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
    if (_hasError) {
      return SizedBox(
        height: 200,
        child: _buildErrorWidget(_errorMessage ?? 'Unknown error'),
      );
    }

    if (!_isInitialized) {
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
