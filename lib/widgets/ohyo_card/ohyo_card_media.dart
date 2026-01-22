import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/ohyo_model.dart';
import '../../providers/ohyo_provider.dart';
import '../../utils/responsive_utils.dart';
import '../../core/theme/app_theme.dart';
import '../image_gallery.dart';
import '../video_gallery.dart';
import '../video_player_widget.dart';
import '../overflow_safe_widgets.dart';
import '../../services/offline_media_cache_service.dart';
import '../../providers/network_provider.dart';

class OhyoCardMedia extends StatelessWidget {
  final Ohyo ohyo;

  const OhyoCardMedia({
    super.key,
    required this.ohyo,
  });

  int _getPreviewCacheWidth(BuildContext context) {
    return context.isMobile ? 600 : 800;
  }

  int _getPreviewCacheHeight(BuildContext context) {
    return context.isMobile ? 450 : 600;
  }

  @override
  Widget build(BuildContext context) {
    return _buildMediaSection(context);
  }

  /// Check if ohyo images are available offline
  Future<bool> _checkOhyoImagesOfflineAvailability(int ohyoId, List<String> imageUrls) async {
    try {
      final cachedPaths = await OfflineMediaCacheService.getCachedOhyoImagePaths(ohyoId);
      return cachedPaths.isNotEmpty;
    } catch (e) {
      // Fallback to checking individual URLs
      return imageUrls.any((url) =>
        OfflineMediaCacheService.getCachedFilePath(url, false) != null
      );
    }
  }

  String? _getCachedOhyoImagePath(String url, int ohyoId) {
    if (url.startsWith('/') || url.startsWith('file://')) {
      return url;
    }
    final cachedPath = OfflineMediaCacheService.getCachedFilePath(url, false);
    if (cachedPath != null) {
      return cachedPath;
    }
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty) {
        final fileName = uri.pathSegments.last;
        final stablePath = OfflineMediaCacheService.getCachedOhyoImagePath(ohyoId, fileName);
        if (stablePath != null) {
          return stablePath;
        }
      }
    } catch (_) {}
    return null;
  }

  Widget _buildOfflineImagesPlaceholder(BuildContext context) {
    return Container(
      height: context.responsiveValue(mobile: 180.0, tablet: 220.0, desktop: 250.0),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo, size: 36, color: Colors.grey),
            SizedBox(height: 8),
            Text('Afbeeldingen zijn offline nog niet beschikbaar'),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        // Get images directly from ohyo model (lazy loaded)
        final ohyoImages = ohyo.imageUrls ?? [];
        final hasImages = ohyoImages.isNotEmpty;

        // Get video URLs from ohyo model
        final videoUrls = ohyo.videoUrls ?? [];
        final hasVideos = videoUrls.isNotEmpty;

        final networkState = ref.read(networkProvider);
        final isOffline = !networkState.isConnected;
        final hasCachedImages = isOffline
            ? ohyoImages.any((url) => _getCachedOhyoImagePath(url, ohyo.id) != null)
            : hasImages;
        final previewCachedPath = isOffline
            ? ohyoImages
                .map((url) => _getCachedOhyoImagePath(url, ohyo.id))
                .firstWhere((path) => path != null, orElse: () => null)
            : null;

        // Load images if needed - immediately for offline support
        if (!hasImages) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(ohyoNotifierProvider.notifier).loadOhyoImages(ohyo.id, ref: ref);
          });
        } else {
          // If we have images but might be offline, check if we need to load cached versions
          final hasNetworkUrls = ohyoImages.any((url) => !url.startsWith('/') && !url.startsWith('file://'));
          if (!networkState.isConnected && hasNetworkUrls) {
            // We're offline and have network URLs - try to load cached versions immediately
            debugPrint('📱 Offline ohyo ${ohyo.id} has network URLs, loading cached versions');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(ohyoNotifierProvider.notifier).loadOhyoImages(ohyo.id, ref: ref);
            });
          }
        }

        final showImages = isOffline ? hasCachedImages : hasImages;
        final showVideos = isOffline ? false : hasVideos;

        // Always show image gallery, even if only videos are available (since videos can be viewed offline)
        // Only show loading placeholder if no media at all
        if (!showImages && !showVideos) {
          if (isOffline) {
            return _buildOfflineImagesPlaceholder(context);
          }
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
        // Main media display - always prioritize images over videos for better offline experience
        if (showImages || showVideos)
          GestureDetector(
            onTap: () {
              // Always open image gallery if images are available, otherwise videos
              if (isOffline) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageGallery(
                      imageUrls: ohyoImages,
                      title: '${ohyo.name} - Images',
                      ohyoId: ohyo.id,
                    ),
                  ),
                );
              } else if (showImages) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageGallery(
                      imageUrls: ohyoImages,
                      title: '${ohyo.name} - Images',
                      ohyoId: ohyo.id,
                    ),
                  ),
                );
              } else if (showVideos) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoGallery(
                videoUrls: videoUrls,
                          title: '${ohyo.name} - Videos',
                          kataId: ohyo.id,
                    ),
                  ),
                );
              }
            },
                child: _buildMainMediaDisplay(
                  context,
                  showImages,
                  showVideos,
                  ohyoImages,
                  videoUrls,
                  isOffline: isOffline,
                  offlinePreviewPath: previewCachedPath,
                ),
          ),

        // Navigation buttons - stacked vertically for full width
        SizedBox(height: context.responsiveSpacing(SpacingSize.sm)),
        Column(
          children: [
            // Images button
            if (hasImages)
              Consumer(
                builder: (context, ref, child) {
                  return FutureBuilder<bool>(
                    future: _checkOhyoImagesOfflineAvailability(ohyo.id, ohyoImages),
                    builder: (context, snapshot) {
                      final offlineAvailable = snapshot.data ?? false;

                      return OverflowSafeButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageGallery(
                            imageUrls: ohyoImages,
                            title: '${ohyo.name} - Images',
                            ohyoId: ohyo.id,
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
                          'Afbeeldingen (${ohyoImages.length})',
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
                  );
                },
              ),

                // Spacing between buttons
                if (hasImages && hasVideos) SizedBox(height: context.responsiveSpacing(SpacingSize.xs)),

            // Videos button
            if (showVideos)
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
                                title: '${ohyo.name} - Videos',
                                kataId: ohyo.id,
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
      },
    );
  }

  Widget _buildMainMediaDisplay(
    BuildContext context,
    bool hasImages,
    bool hasVideos,
    List<String> imageUrls,
    List<String> videoUrls, {
    required bool isOffline,
    String? offlinePreviewPath,
  }) {
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
            if (isOffline && offlinePreviewPath == null)
              _buildOfflineImagesPlaceholder(context)
            else
              Consumer(
                builder: (context, ref, child) {
                  final previewPath = offlinePreviewPath;
                  return FutureBuilder<String>(
                    future: isOffline && previewPath != null
                        ? Future.value(previewPath)
                        : OfflineMediaCacheService.getMediaUrl(imageUrls.first, false, ref),
                    builder: (context, snapshot) {
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
                              memCacheWidth: _getPreviewCacheWidth(context),
                              memCacheHeight: _getPreviewCacheHeight(context),
                              progressIndicatorBuilder: (context, url, downloadProgress) {
                                // Silent: Image loading progress not logged
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
                  );
                },
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
        // Single video - show directly without thumbnail
        return Container(
          height: context.responsiveValue(mobile: 180.0, tablet: 220.0, desktop: 250.0),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Consumer(
            builder: (context, ref, child) => FutureBuilder<String>(
              future: OfflineMediaCacheService.getMediaUrl(videoUrls.first, true, ref),
              builder: (context, snapshot) {
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
            ),
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
                builder: (context, ref, child) => FutureBuilder<String>(
                  future: OfflineMediaCacheService.getMediaUrl(videoUrls[currentVideoIndex], true, ref),
                  builder: (context, snapshot) {
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
                ),
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
