import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/kata_model.dart';
import '../models/interaction_models.dart';
import '../providers/image_provider.dart';
import '../providers/interaction_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/role_provider.dart';
import '../screens/edit_kata_screen.dart';
import '../utils/responsive_utils.dart';
import '../core/theme/app_theme.dart';
import 'formatted_text.dart';
import 'image_gallery.dart';
import 'video_gallery.dart';
import 'video_player_widget.dart';
import 'avatar_widget.dart';
import 'responsive_layout.dart';

class CollapsibleKataCard extends ConsumerStatefulWidget {
  final Kata kata;
  final VoidCallback onDelete;
  final bool isDragging;

  const CollapsibleKataCard({
    super.key,
    required this.kata,
    required this.onDelete,
    this.isDragging = false,
  });

  @override
  ConsumerState<CollapsibleKataCard> createState() => _CollapsibleKataCardState();
}

class _CollapsibleKataCardState extends ConsumerState<CollapsibleKataCard> {
  bool _isExpanded = false;
  bool _isCommentsExpanded = false;
  static const int _maxCollapsedLines = 3;

  String _getTruncatedDescription(String description) {
    final lines = description.split('\n');
    if (lines.length <= _maxCollapsedLines) {
      return description;
    }
    
    // Take first few lines and add ellipsis
    final truncatedLines = lines.take(_maxCollapsedLines).toList();
    return '${truncatedLines.join('\n')}...';
  }

  bool _shouldShowToggleButton(String description) {
    final lines = description.split('\n');
    return lines.length > _maxCollapsedLines;
  }

  @override
  Widget build(BuildContext context) {
    final kata = widget.kata;
    final shouldShowToggle = _shouldShowToggleButton(kata.description);
    final displayDescription = _isExpanded || !shouldShowToggle 
        ? kata.description 
        : _getTruncatedDescription(kata.description);

    return Semantics(
      label: 'Kata kaart: ${kata.name}, stijl: ${kata.style}',
      child: ResponsiveCard(
        margin: AppTheme.getResponsiveMargin(context),
        padding: AppTheme.getResponsivePadding(context),
        elevation: AppTheme.getResponsiveElevation(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with drag handle, name and action buttons
            Row(
              children: [
                // Drag handle with tooltip - Made more compact
                Semantics(
                  label: 'Sleep handvat om kata te herordenen',
                  child: Container(
                    width: context.responsiveValue(mobile: 32.0, tablet: 36.0, desktop: 40.0),
                    height: context.responsiveValue(mobile: 32.0, tablet: 36.0, desktop: 40.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: AppTheme.getResponsiveBorderRadius(context, multiplier: 0.75),
                    ),
                    child: Icon(
                      Icons.drag_handle,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: AppTheme.getResponsiveIconSize(context, baseSize: 16.0),
                    ),
                  ),
                ),
                SizedBox(width: context.responsiveSpacing(SpacingSize.sm)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display name
                        Semantics(
                          label: 'Kata naam: ${kata.name}',
                          child: Text(
                            kata.name,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                        SizedBox(height: context.responsiveSpacing(SpacingSize.xs)),
                        // Display style
                        Semantics(
                          label: 'Karate stijl: ${kata.style}',
                          child: Text(
                            kata.style,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Colors.blueGrey,
                                  fontStyle: FontStyle.italic,
                                ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Action buttons with flexible width to prevent overflow
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit button - Responsive
                    Semantics(
                      label: 'Bewerk kata ${kata.name}',
                      button: true,
                      child: SizedBox(
                        width: context.responsiveValue(mobile: 32.0, tablet: 36.0, desktop: 40.0),
                        height: context.responsiveValue(mobile: 32.0, tablet: 36.0, desktop: 40.0),
                        child: IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: Colors.blue,
                            size: AppTheme.getResponsiveIconSize(context, baseSize: 16.0),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditKataScreen(kata: kata),
                              ),
                            );
                          },
                          tooltip: 'Bewerk kata',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),
                    SizedBox(width: context.responsiveSpacing(SpacingSize.xs)),
                    // Delete button - Responsive
                    Semantics(
                      label: 'Verwijder kata ${kata.name}',
                      button: true,
                      child: SizedBox(
                        width: context.responsiveValue(mobile: 32.0, tablet: 36.0, desktop: 40.0),
                        height: context.responsiveValue(mobile: 32.0, tablet: 36.0, desktop: 40.0),
                        child: IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: AppTheme.getResponsiveIconSize(context, baseSize: 16.0),
                          ),
                          onPressed: widget.onDelete,
                          tooltip: 'Verwijder kata',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.sm)),
            
            // Display description with styling
            Semantics(
              label: 'Kata beschrijving: ${displayDescription.replaceAll('\n', ' ')}',
              child: FormattedText(
                text: displayDescription,
                baseStyle: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[700]),
                headingStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Toggle button for description
            if (shouldShowToggle)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Semantics(
                    label: _isExpanded ? 'Inklappen beschrijving' : 'Uitklappen volledige beschrijving',
                    button: true,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: AppTheme.getResponsiveIconSize(context, baseSize: 18.0),
                      ),
                      label: Text(
                        _isExpanded ? 'Minder zien' : 'Alles zien',
                        style: TextStyle(
                          fontSize: context.responsiveValue(
                            mobile: 14.0,
                            tablet: 15.0,
                            desktop: 16.0,
                          ),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.responsiveSpacing(SpacingSize.sm),
                          vertical: context.responsiveSpacing(SpacingSize.xs),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ),
              ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
            
            // Display media (images and videos) with smart preview
            _buildMediaSection(kata),
            
            SizedBox(height: context.responsiveSpacing(SpacingSize.lg)),
            
            // Interaction section (likes, favorites, comments)
            _buildInteractionSection(kata),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection(Kata kata) {
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
              borderRadius: context.responsiveBorderRadius,
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
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
              borderRadius: context.responsiveBorderRadius,
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
                child: _buildMainMediaDisplay(hasImages, hasVideos, cachedImages, videoUrls),
              ),
            
            // Navigation buttons - stacked vertically for full width
            SizedBox(height: context.responsiveSpacing(SpacingSize.sm)),
            Column(
              children: [
                // Images button
                if (hasImages)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
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
                      icon: Icon(
                        Icons.photo, 
                        size: AppTheme.getResponsiveIconSize(context, baseSize: 14.0),
                      ),
                      label: Text(
                        'Afbeeldingen (${cachedImages.length})', 
                        style: TextStyle(
                          fontSize: context.responsiveValue(
                            mobile: 12.0,
                            tablet: 13.0,
                            desktop: 14.0,
                          ),
                        ),
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
                  ),
                
                // Spacing between buttons
                if (hasImages && hasVideos) SizedBox(height: context.responsiveSpacing(SpacingSize.xs)),
                
                // Videos button
                if (hasVideos)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
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
                      icon: Icon(
                        Icons.videocam, 
                        size: AppTheme.getResponsiveIconSize(context, baseSize: 14.0),
                      ),
                      label: Text(
                        'Video\'s (${videoUrls.length})', 
                        style: TextStyle(
                          fontSize: context.responsiveValue(
                            mobile: 12.0,
                            tablet: 13.0,
                            desktop: 14.0,
                          ),
                        ),
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
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainMediaDisplay(bool hasImages, bool hasVideos, List<String> imageUrls, List<String> videoUrls) {
    // ALWAYS show images FIRST in the card preview when available
    // Only show video if there are NO images
    if (hasImages) {
      // Show the FIRST image in the card preview
      return Container(
        height: context.responsiveValue(mobile: 180.0, tablet: 220.0, desktop: 250.0),
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: context.responsiveBorderRadius,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Stack(
          children: [
            // Main media display
            ClipRRect(
              borderRadius: context.responsiveBorderRadius,
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
            borderRadius: context.responsiveBorderRadius,
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
        return _buildVideoCarousel(videoUrls);
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

  Widget _buildVideoCarousel(List<String> videoUrls) {
    return StatefulBuilder(
      builder: (context, setState) {
        int currentVideoIndex = 0;
        
        return Container(
          height: context.responsiveValue(mobile: 180.0, tablet: 220.0, desktop: 250.0),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: context.responsiveBorderRadius,
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

  Widget _buildInteractionSection(Kata kata) {
    return Consumer(
      builder: (context, ref, child) {
        final interactionState = ref.watch(kataInteractionProvider(kata.id));
        final isLiked = interactionState.isLiked;
        final isFavorited = interactionState.isFavorited;
        final likeCount = interactionState.likeCount;
        final commentCount = interactionState.commentCount;
        final comments = interactionState.comments;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action buttons row
            Row(
              children: [
                // Like button
                IconButton(
                  onPressed: () async {
                    try {
                      await ref.read(kataInteractionProvider(kata.id).notifier).toggleLike();
                    } catch (e) {
                      if (mounted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey,
                  ),
                ),
                Text('$likeCount'),
                const SizedBox(width: 16),
                
                // Favorite button
                IconButton(
                  onPressed: () async {
                    try {
                      await ref.read(kataInteractionProvider(kata.id).notifier).toggleFavorite();
                      if (mounted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isFavorited 
                                ? 'Removed from favorites' 
                                : 'Added to favorites'
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: Icon(
                    isFavorited ? Icons.bookmark : Icons.bookmark_border,
                    color: isFavorited ? Colors.teal : Colors.grey,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Comment button - Opens comment section
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isCommentsExpanded = !_isCommentsExpanded;
                    });
                  },
                  icon: Icon(
                    _isCommentsExpanded ? Icons.comment : Icons.comment_outlined,
                    color: Colors.blue,
                  ),
                  tooltip: _isCommentsExpanded ? 'Sluit reacties' : 'Open reacties',
                ),
                Text('$commentCount'),
                
                const Spacer(),
              ],
            ),
            
            // Show inline comments section when expanded
            if (_isCommentsExpanded) ...[
              const SizedBox(height: 12),
              _buildInlineCommentSection(kata, comments, interactionState.isLoading),
            ] else if (comments.isNotEmpty) ...[
              // Show first few comments inline if any
              const SizedBox(height: 8),
              ...comments.take(2).map((comment) => _buildClickableCommentPreview(comment, kata)),
              if (comments.length > 2)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isCommentsExpanded = true;
                    });
                  },
                  child: Text('Bekijk alle ${comments.length} reacties'),
                ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildInlineCommentSection(Kata kata, List<KataComment> comments, bool isLoading) {
    final commentController = TextEditingController();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.grey[50],
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: isDark ? theme.colorScheme.outline : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comments header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                const Icon(Icons.comment, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                    'Reacties (${comments.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Spacer(),
                // Collapse button
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isCommentsExpanded = false;
                    });
                  },
                  icon: const Icon(Icons.expand_less, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          // Comments list
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (comments.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'Nog geen reacties. Wees de eerste om te reageren!',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final comment = comments[index];
                  return _buildInlineCommentCard(comment);
                },
              ),
            ),
          
          // Add comment section
          Container(
            decoration: BoxDecoration(
              color: isDark ? theme.colorScheme.surface : Colors.white,
              border: Border(
                top: BorderSide(color: isDark ? theme.colorScheme.outline : Colors.grey.shade300),
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(8.0),
                bottomRight: Radius.circular(8.0),
              ),
            ),
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    hintText: 'Voeg een reactie toe...',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.all(8),
                  ),
                  maxLines: 2,
                  minLines: 1,
                  maxLength: 500,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Consumer(
                      builder: (context, ref, child) {
                        final isSubmitting = ref.watch(kataInteractionProvider(kata.id)).isLoading;
                        
                        return ElevatedButton(
                          onPressed: isSubmitting ? null : () async {
                            if (commentController.text.trim().isNotEmpty) {
                              try {
                                await ref.read(kataInteractionProvider(kata.id).notifier)
                                    .addComment(commentController.text.trim());
                                commentController.clear();
                                if (mounted && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Reactie succesvol toegevoegd!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Fout bij toevoegen reactie: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          },
                          child: isSubmitting 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Plaats'),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineCommentCard(KataComment comment) {
    return Consumer(
      builder: (context, ref, child) {
        final currentUser = ref.watch(authUserProvider);
        
        // Check if user can edit/delete comment
        // User can edit if they are the comment author OR if they are a moderator
        final isCommentAuthor = comment.authorId == currentUser?.id;
        final isModeratorAsync = ref.watch(isCurrentUserModeratorProvider);
        
        final canDeleteComment = isCommentAuthor || isModeratorAsync.when(
          data: (isModerator) => isModerator,
          loading: () => false,
          error: (_, __) => false,
        );

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isDark ? theme.colorScheme.outline : Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AvatarWidget(
                    customAvatarUrl: comment.authorAvatar,
                    userName: comment.authorName,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          comment.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          _formatDate(comment.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditKataCommentDialog(comment);
                          break;
                        case 'delete':
                          _showDeleteKataCommentConfirmation(comment);
                          break;
                      }
                    },
                    itemBuilder: (context) {
                      List<PopupMenuEntry<String>> items = [];
                      
                      // Add edit option if user is the comment author OR has edit permissions (mediator/host)
                      if (comment.authorId == currentUser?.id || canDeleteComment) {
                        items.add(
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.blue, size: 14),
                                SizedBox(width: 8),
                                Text('Bewerk', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      // Add delete option if user has permission
                      if (canDeleteComment) {
                        items.add(
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red, size: 14),
                                SizedBox(width: 8),
                                Text('Verwijder', style: TextStyle(color: Colors.red, fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      }
                      
                      // If no items available, show a disabled "No actions" item
                      if (items.isEmpty) {
                        items.add(
                          const PopupMenuItem(
                            enabled: false,
                            value: 'none',
                            child: Text(
                              'Geen acties beschikbaar',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ),
                        );
                      }
                      
                      return items;
                    },
                    icon: Icon(
                      Icons.more_vert,
                      size: 16,
                      color: isDark ? theme.colorScheme.onSurfaceVariant : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                comment.content,
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClickableCommentPreview(KataComment comment, Kata kata) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isCommentsExpanded = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: Colors.teal.shade400,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.teal.shade300),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvatarWidget(
              customAvatarUrl: comment.authorAvatar,
              userName: comment.authorName,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style.copyWith(
                    color: Colors.white,
                  ),
                  children: [
                    TextSpan(
                      text: '${comment.authorName} ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    TextSpan(
                      text: comment.content.length > 100 
                          ? '${comment.content.substring(0, 100)}...'
                          : comment.content,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _showEditKataCommentDialog(KataComment comment) async {
    final TextEditingController editController = TextEditingController(text: comment.content);
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bewerk Reactie'),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(
              hintText: 'Bewerk je reactie...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            minLines: 1,
            maxLength: 500,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuleren'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            Consumer(
              builder: (context, ref, child) {
                return ElevatedButton(
                  child: const Text('Opslaan'),
                  onPressed: () async {
                    if (editController.text.trim().isNotEmpty) {
                      try {
                        await ref.read(kataInteractionProvider(widget.kata.id).notifier)
                            .updateComment(
                              commentId: comment.id,
                              content: editController.text.trim(),
                            );
                        
                        if (mounted && context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Reactie succesvol bijgewerkt!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Fout bij bijwerken reactie: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteKataCommentConfirmation(KataComment comment) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Verwijder Reactie'),
          content: const Text('Weet je zeker dat je deze reactie wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuleren'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            Consumer(
              builder: (context, ref, child) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Verwijder'),
                  onPressed: () async {
                    try {
                      await ref.read(kataInteractionProvider(widget.kata.id).notifier)
                          .deleteComment(comment.id);
                      
                      if (mounted && context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reactie succesvol verwijderd!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Fout bij verwijderen reactie: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
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
