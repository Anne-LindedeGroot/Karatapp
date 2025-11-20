import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/kata_model.dart';
import '../../providers/kata_provider.dart';
import '../../utils/responsive_utils.dart';
import '../../core/theme/app_theme.dart';
import '../image_gallery.dart';
import '../video_gallery.dart';
import '../video_player_widget.dart';
import '../overflow_safe_widgets.dart';
import '../../services/offline_media_cache_service.dart';
import '../../providers/network_provider.dart';

class KataCardMedia extends ConsumerStatefulWidget {
  final Kata kata;

  const KataCardMedia({
    super.key,
    required this.kata,
  });

  @override
  ConsumerState<KataCardMedia> createState() => _KataCardMediaState();
}

class _KataCardMediaState extends ConsumerState<KataCardMedia> {
  bool _imageLoadingAttempted = false;
  bool _imageLoadingFailed = false;
  bool _isOfflineError = false;

  @override
  void initState() {
    super.initState();
    // Try to load images after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && (widget.kata.imageUrls?.isEmpty ?? true)) { // Check if images haven't loaded yet
        _loadImages();
      }
    });
  }

  @override
  void didUpdateWidget(KataCardMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If we previously had offline errors and now we're online, retry
    if (_isOfflineError && _imageLoadingFailed) {
      final networkState = ref.read(networkProvider);
      if (networkState.isConnected) {
        debugPrint('Connection restored, retrying image load for kata ${widget.kata.id}');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _retryLoadImages();
          }
        });
      }
    }
  }

  Future<void> _loadImages() async {
    if (_imageLoadingAttempted) return; // Prevent multiple attempts

    setState(() {
      _imageLoadingAttempted = true;
      _isOfflineError = false;
    });

    try {
      // Check network status before attempting to load
      final networkState = ref.read(networkProvider);
      if (!networkState.isConnected) {
        debugPrint('Offline: Skipping image load for kata ${widget.kata.id}');
        setState(() {
          _imageLoadingFailed = true;
          _isOfflineError = true;
        });
        return;
      }

      await ref.read(kataNotifierProvider.notifier).loadKataImages(widget.kata.id);
      // Check if images actually loaded
      final updatedKata = ref.read(kataNotifierProvider).katas
          .firstWhere((k) => k.id == widget.kata.id, orElse: () => widget.kata);

      if (updatedKata.imageUrls?.isEmpty ?? true) {
        setState(() {
          _imageLoadingFailed = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to load images for kata ${widget.kata.id}: $e');
      final networkState = ref.read(networkProvider);
      setState(() {
        _imageLoadingFailed = true;
        _isOfflineError = !networkState.isConnected;
      });
    }
  }

  Future<void> _retryLoadImages() async {
    setState(() {
      _imageLoadingAttempted = false;
      _imageLoadingFailed = false;
      _isOfflineError = false;
    });
    await _loadImages();
  }

  @override
  Widget build(BuildContext context) {
    return _buildMediaSection(context);
  }

  Widget _buildMediaSection(BuildContext context) {
    // Get images directly from kata model
    final kataImages = widget.kata.imageUrls ?? [];
    final hasImages = kataImages.isNotEmpty;

    // Get video URLs from kata model
    final videoUrls = widget.kata.videoUrls ?? [];
    final hasVideos = videoUrls.isNotEmpty;

    // If no images and no videos, show appropriate state
    if (!hasImages && !hasVideos) {
      // If we haven't attempted to load images yet, show loading
      if (!_imageLoadingAttempted) {
        return Container(
          height: context.responsiveValue(mobile: 180.0, tablet: 220.0, desktop: 250.0),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 12),
                Text(
                  'Media laden...',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: context.responsiveValue(
                      mobile: 12.0,
                      tablet: 13.0,
                      desktop: 14.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // If loading failed, show no media state
      if (_imageLoadingFailed) {
        return Container(
          height: context.responsiveValue(mobile: 180.0, tablet: 220.0, desktop: 250.0),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isOfflineError ? Icons.wifi_off : Icons.photo_library_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  _isOfflineError ? 'Offline - Geen internetverbinding' : 'Geen media beschikbaar',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: context.responsiveValue(
                      mobile: 14.0,
                      tablet: 15.0,
                      desktop: 16.0,
                    ),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _isOfflineError
                        ? 'Media wordt geladen wanneer je weer online bent'
                        : 'Media kon niet worden geladen',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: context.responsiveValue(
                        mobile: 12.0,
                        tablet: 13.0,
                        desktop: 14.0,
                      ),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_isOfflineError)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Consumer(
                      builder: (context, ref, child) {
                        final networkState = ref.watch(networkProvider);
                        return ElevatedButton.icon(
                          onPressed: networkState.isConnected ? _retryLoadImages : null,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: Text(
                            networkState.isConnected ? 'Opnieuw proberen' : 'Wachten op verbinding...',
                            style: TextStyle(
                              fontSize: context.responsiveValue(
                                mobile: 12.0,
                                tablet: 13.0,
                                desktop: 14.0,
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: networkState.isConnected ? Colors.blue : Colors.grey,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: const Size(0, 32),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      }

      // Still loading
      return Container(
        height: context.responsiveValue(mobile: 180.0, tablet: 220.0, desktop: 250.0),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                'Media laden...',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: context.responsiveValue(
                    mobile: 12.0,
                    tablet: 13.0,
                    desktop: 14.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Main media display - show images first, then videos if no images
        if (hasImages || hasVideos)
          GestureDetector(
            onTap: () {
              if (hasImages) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageGallery(
                      imageUrls: kataImages,
                      title: '${widget.kata.name} - Images',
                      kataId: widget.kata.id,
                    ),
                  ),
                );
              } else if (hasVideos) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoGallery(
                      videoUrls: videoUrls,
                      title: '${widget.kata.name} - Videos',
                      kataId: widget.kata.id,
                    ),
                  ),
                );
              }
            },
            child: _buildMainMediaDisplay(context, hasImages, hasVideos, kataImages, videoUrls),
          ),

        // Navigation buttons - stacked vertically for full width
        SizedBox(height: context.responsiveSpacing(SpacingSize.sm)),
        Column(
          children: [
            // Images button
            if (hasImages)
              Consumer(
                builder: (context, ref, child) {
                  // Check offline availability for images
                  final offlineAvailable = kataImages.any((url) =>
                    OfflineMediaCacheService.getCachedFilePath(url, false) != null
                  );

                  return OverflowSafeButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageGallery(
                            imageUrls: kataImages,
                            title: '${widget.kata.name} - Images',
                            kataId: widget.kata.id,
                          ),
                        ),
                      );
                    },
                    isElevated: true,
                    fullWidth: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.photo,
                          size: AppTheme.getResponsiveIconSize(context, baseSize: 14.0),
                        ),
                        SizedBox(width: context.responsiveSpacing(SpacingSize.xs)),
                        OverflowSafeText(
                          'Afbeeldingen (${kataImages.length})',
                          style: TextStyle(
                            fontSize: context.responsiveValue(
                              mobile: 12.0,
                              tablet: 13.0,
                              desktop: 14.0,
                            ),
                          ),
                        ),
                        // Offline indicator
                        if (offlineAvailable)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.offline_pin,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsiveSpacing(SpacingSize.sm),
                        vertical: context.responsiveSpacing(SpacingSize.sm),
                      ),
                      minimumSize: Size(0, context.responsiveValue(mobile: 32.0, tablet: 36.0, desktop: 40.0)),
                    ),
                  );
                },
              ),

            // Spacing between buttons
            if (hasImages && hasVideos) SizedBox(height: context.responsiveSpacing(SpacingSize.xs)),

            // Videos button
            if (hasVideos)
              Consumer(
                builder: (context, ref, child) {
                  // Check offline availability for videos
                  final offlineAvailable = videoUrls.any((url) =>
                    OfflineMediaCacheService.getCachedFilePath(url, true) != null
                  );

                  return OverflowSafeButton(
                    onPressed: () {
                      final networkState = ref.read(networkProvider);
                      if (!networkState.isConnected) {
                        // Show offline message for videos
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Video\'s zijn alleen beschikbaar wanneer je online bent'),
                            backgroundColor: Colors.orange,
                            duration: Duration(seconds: 3),
                          ),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoGallery(
                            videoUrls: videoUrls,
                            title: '${widget.kata.name} - Videos',
                            kataId: widget.kata.id,
                          ),
                        ),
                      );
                    },
                    isElevated: true,
                    fullWidth: true,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.videocam,
                          size: AppTheme.getResponsiveIconSize(context, baseSize: 14.0),
                        ),
                        SizedBox(width: context.responsiveSpacing(SpacingSize.xs)),
                        OverflowSafeText(
                          'Video\'s (${videoUrls.length})',
                          style: TextStyle(
                            fontSize: context.responsiveValue(
                              mobile: 12.0,
                              tablet: 13.0,
                              desktop: 14.0,
                            ),
                          ),
                        ),
                        // Offline indicator
                        if (offlineAvailable)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.offline_pin,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsiveSpacing(SpacingSize.sm),
                        vertical: context.responsiveSpacing(SpacingSize.sm),
                      ),
                      minimumSize: Size(0, context.responsiveValue(mobile: 32.0, tablet: 36.0, desktop: 40.0)),
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainMediaDisplay(BuildContext context, bool hasImages, bool hasVideos, List<String> imageUrls, List<String> videoUrls) {
    // ALWAYS show images FIRST in the card preview when available
    // Only show video if there are NO images
    if (hasImages) {
      // Show the FIRST image in the card preview
      return Container(
        height: context.responsiveValue(mobile: 180.0, tablet: 220.0, desktop: 250.0),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Stack(
          children: [
            // Main media display - use offline cache service to resolve URL
            Consumer(
              builder: (context, ref, child) => FutureBuilder<String>(
                future: OfflineMediaCacheService.getMediaUrl(imageUrls.first, false, ref),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    final networkState = ref.watch(networkProvider);
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.grey[200],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            networkState.isConnected ? Icons.broken_image : Icons.wifi_off,
                            size: 50,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            networkState.isConnected
                                ? 'Afbeelding laden mislukt'
                                : 'Afbeelding niet beschikbaar offline',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final resolvedUrl = snapshot.data ?? imageUrls.first;
                  final isLocalFile = resolvedUrl.startsWith('/') || resolvedUrl.startsWith('file://');

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: isLocalFile
                        ? Image.file(
                            File(resolvedUrl.replaceFirst('file://', '')),
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              print('❌ Image failed to load: $resolvedUrl');
                              print('❌ Error details: $error');
                              return Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.grey[200],
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text(
                                      'Afbeelding laden mislukt',
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                        : CachedNetworkImage(
                            imageUrl: resolvedUrl,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            memCacheWidth: 800,
                            memCacheHeight: 600,
                            progressIndicatorBuilder: (context, url, downloadProgress) {
                              print('🖼️ Loading image: $url - ${(downloadProgress.progress ?? 0) * 100}%');
                              if (downloadProgress.progress == null) {
                                return Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: Colors.white,
                                  ),
                                );
                              }
                              return Center(
                                child: CircularProgressIndicator(
                                  value: downloadProgress.progress,
                                  color: Colors.blue,
                                ),
                              );
                            },
                            errorWidget: (context, url, error) {
                              print('❌ Image failed to load: $url');
                              print('❌ Error details: $error');
                              return Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.grey[200],
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Afbeelding laden mislukt',
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      error.toString().length > 50
                                          ? '${error.toString().substring(0, 50)}...'
                                          : error.toString(),
                                      style: const TextStyle(color: Colors.red, fontSize: 10),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  );
                },
              ),
            ),

            // Media type indicators
            Positioned(
              top: 8,
              left: 8,
              child: Row(
                children: [
                  if (hasImages)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${imageUrls.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  if (hasImages && hasVideos) const SizedBox(width: 4),
                  if (hasVideos)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.videocam, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${videoUrls.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Total count indicator (if multiple items)
            if ((imageUrls.length + videoUrls.length) > 1)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '+${(imageUrls.length + videoUrls.length) - 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
        ),
      );
    } else if (hasVideos) {
      // For videos, show inline player for single video or navigation for multiple videos
      if (videoUrls.length == 1) {
        // Single video - show directly without thumbnail, using offline cache service
        return Container(
          height: context.responsiveValue(mobile: 180.0, tablet: 220.0, desktop: 250.0),
          width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade300),
            ),
          child: Consumer(
            builder: (context, ref, child) {
              final networkState = ref.watch(networkProvider);

              // If offline, show offline message immediately
              if (!networkState.isConnected) {
                return Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Video alleen beschikbaar online',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Ga online om video\'s te bekijken',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return FutureBuilder<String>(
                future: OfflineMediaCacheService.getMediaUrl(videoUrls.first, true, ref),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Video kon niet worden geladen',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final resolvedUrl = snapshot.data ?? videoUrls.first;

                  return ClipRRect(
                    borderRadius: context.responsiveBorderRadius,
                    child: VideoPlayerWidget(
                      videoUrl: resolvedUrl,
                      autoPlay: false,
                      showControls: true,
                      ref: ref,
                    ),
                  );
                },
              );
            },
          ),
        );
      } else {
        // Multiple videos - show with navigation
        return _buildVideoCarousel(context, videoUrls);
      }
    } else {
      // No media at all
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library, size: 50, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'No media available',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildVideoCarousel(BuildContext context, List<String> videoUrls) {
    return StatefulBuilder(
      builder: (context, setState) {
        int currentVideoIndex = 0;

        return Container(
          height: context.responsiveValue(mobile: 180.0, tablet: 220.0, desktop: 250.0),
          width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade300),
            ),
          child: Stack(
            children: [
              // Video player - use offline cache service
              Consumer(
                builder: (context, ref, child) {
                  final networkState = ref.watch(networkProvider);

                  // If offline, show offline message immediately
                  if (!networkState.isConnected) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wifi_off,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Video alleen beschikbaar online',
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Ga online om video\'s te bekijken',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return FutureBuilder<String>(
                    future: OfflineMediaCacheService.getMediaUrl(videoUrls[currentVideoIndex], true, ref),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Video kon niet worden geladen',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final resolvedUrl = snapshot.data ?? videoUrls[currentVideoIndex];

                      return ClipRRect(
                        borderRadius: context.responsiveBorderRadius,
                        child: VideoPlayerWidget(
                          videoUrl: resolvedUrl,
                          autoPlay: false,
                          showControls: true,
                          ref: ref,
                        ),
                      );
                    },
                  );
                },
              ),

              // Navigation arrows (only show if more than 1 video)
              if (videoUrls.length > 1) ...[
                // Previous button
                if (currentVideoIndex > 0)
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              currentVideoIndex = currentVideoIndex - 1;
                            });
                          },
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Next button
                if (currentVideoIndex < videoUrls.length - 1)
                  Positioned(
                    right: 8,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              currentVideoIndex = currentVideoIndex + 1;
                            });
                          },
                          icon: const Icon(
                            Icons.chevron_right,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],

              // Video counter and indicator
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${currentVideoIndex + 1}/${videoUrls.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ),

              // Dots indicator at bottom
              if (videoUrls.length > 1)
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      videoUrls.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: index == currentVideoIndex
                              ? Colors.white
                              : Colors.white54,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}