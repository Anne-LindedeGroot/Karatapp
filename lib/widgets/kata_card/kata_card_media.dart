import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/kata_model.dart';
import '../../providers/image_provider.dart';
import '../../utils/responsive_utils.dart';
import '../../core/theme/app_theme.dart';
import '../image_gallery.dart';
import '../video_gallery.dart';
import '../video_player_widget.dart';
import '../overflow_safe_widgets.dart';

class KataCardMedia extends StatelessWidget {
  final Kata kata;

  const KataCardMedia({
    super.key,
    required this.kata,
  });

  @override
  Widget build(BuildContext context) {
    return _buildMediaSection(context);
  }

  Widget _buildMediaSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final cachedImages = ref.watch(cachedKataImagesProvider(kata.id));
        final imageError = ref.watch(imageErrorProvider);
        final isLoading = ref.watch(imageLoadingProvider);

        // Get video URLs from kata model
        final videoUrls = kata.videoUrls ?? [];
        final hasImages = cachedImages.isNotEmpty;
        final hasVideos = videoUrls.isNotEmpty;

        // Always try to load images if we don't have any cached and not currently loading
        if (!hasImages && !isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            print('🔄 Loading images for kata ${kata.id} (${kata.name})');
            ref.read(imageNotifierProvider.notifier).loadKataImages(kata.id);
          });
        }

        // If no cached images and currently loading, show loading state
        if (!hasImages && !hasVideos && isLoading) {
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

        // Error state
        if (imageError != null && imageError.contains('kata ${kata.id}')) {
          return Container(
            height: context.responsiveValue(mobile: 180.0, tablet: 220.0, desktop: 250.0),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: context.responsiveBorderRadius,
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 50, color: Colors.red.shade400),
                const SizedBox(height: 8),
                Text(
                  'Laden van media mislukt',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getSimplifiedErrorMessage(imageError),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(imageNotifierProvider.notifier).clearError();
                    ref.read(imageNotifierProvider.notifier).forceRefreshKataImages(kata.id);
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Probeer Opnieuw'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
      ),
    );
  }

        // If no media available at all
        if (!hasImages && !hasVideos && !isLoading) {
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
                  const Icon(Icons.photo_library, size: 50, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(
                    'Geen media beschikbaar',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: context.responsiveValue(
                        mobile: 12.0,
                        tablet: 13.0,
                        desktop: 14.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(imageNotifierProvider.notifier).forceRefreshKataImages(kata.id);
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Opnieuw'),
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
                      imageUrls: cachedImages,
                          title: '${kata.name} - Images',
                          kataId: kata.id,
                    ),
                  ),
                ).then((_) {
                      ref.read(imageNotifierProvider.notifier).forceRefreshKataImages(kata.id);
                });
              } else if (hasVideos) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoGallery(
                      videoUrls: videoUrls,
                          title: '${kata.name} - Videos',
                          kataId: kata.id,
                    ),
                  ),
                );
              }
            },
                child: _buildMainMediaDisplay(context, hasImages, hasVideos, cachedImages, videoUrls),
          ),
        
        // Navigation buttons - stacked vertically for full width
        SizedBox(height: context.responsiveSpacing(SpacingSize.sm)),
        Column(
          children: [
            // Images button
            if (hasImages)
                  OverflowSafeButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageGallery(
                          imageUrls: cachedImages,
                            title: '${kata.name} - Images',
                            kataId: kata.id,
                        ),
                      ),
                    ).then((_) {
                        ref.read(imageNotifierProvider.notifier).forceRefreshKataImages(kata.id);
                    });
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
                          'Afbeeldingen (${cachedImages.length})',
                          style: TextStyle(
                            fontSize: context.responsiveValue(
                              mobile: 12.0,
                              tablet: 13.0,
                              desktop: 14.0,
                            ),
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
                  ),

                // Spacing between buttons
                if (hasImages && hasVideos) SizedBox(height: context.responsiveSpacing(SpacingSize.xs)),
            
            // Videos button
                if (hasVideos)
                  OverflowSafeButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoGallery(
                          videoUrls: videoUrls,
                            title: '${kata.name} - Videos',
                            kataId: kata.id,
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
                  ),
              ],
            ),
          ],
        );
      },
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
            // Main media display
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: CachedNetworkImage(
                imageUrl: imageUrls.first,
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
          child: ClipRRect(
            borderRadius: context.responsiveBorderRadius,
            child: VideoPlayerWidget(
              videoUrl: videoUrls.first,
              autoPlay: false,
              showControls: true,
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
              // Video player
              ClipRRect(
                borderRadius: context.responsiveBorderRadius,
                child: VideoPlayerWidget(
                  videoUrl: videoUrls[currentVideoIndex],
                  autoPlay: false,
                  showControls: true,
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

  String _getSimplifiedErrorMessage(String error) {
    if (error.contains('bucket not found')) {
      return 'Storage bucket not configured';
    } else if (error.contains('access denied') || error.contains('Unauthorized')) {
      return 'Access denied - check permissions';
    } else if (error.contains('network') || error.contains('connection')) {
      return 'Network connection issue';
    } else if (error.contains('timeout')) {
      return 'Request timed out';
    } else {
      return 'Unknown error occurred';
    }
  }
}