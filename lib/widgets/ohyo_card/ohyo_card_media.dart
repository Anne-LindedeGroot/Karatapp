import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/ohyo_model.dart';
import '../../providers/ohyo_provider.dart';
import '../../utils/responsive_utils.dart';
import '../image_gallery.dart';
import '../video_gallery.dart';
import '../overflow_safe_widgets.dart';

class OhyoCardMedia extends StatelessWidget {
  final Ohyo ohyo;

  const OhyoCardMedia({
    super.key,
    required this.ohyo,
  });

  @override
  Widget build(BuildContext context) {
    return _buildMediaSection(context);
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

        // Lazy load images if ohyo doesn't have them yet
        if (!hasImages) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(ohyoNotifierProvider.notifier).loadOhyoImages(ohyo.id);
          });
        }

        // If no images and no videos, show placeholder (loading or no media)
        if (!hasImages && !hasVideos) {
          return Container(
            height: context.responsiveValue(mobile: 180.0, tablet: 220.0, desktop: 250.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(context.responsiveValue(mobile: 12.0, tablet: 14.0, desktop: 16.0)),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                width: 1.0,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported,
                  size: context.responsiveValue(mobile: 48.0, tablet: 56.0, desktop: 64.0),
                  color: Colors.grey[400],
                ),
                SizedBox(height: context.responsiveValue(mobile: 8.0, tablet: 10.0, desktop: 12.0)),
                OverflowSafeText(
                  'Geen afbeeldingen beschikbaar',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    fontSize: context.responsiveValue(mobile: 14.0, tablet: 15.0, desktop: 16.0),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // If only videos, show video gallery
        if (!hasImages && hasVideos) {
          return Container(
            height: context.responsiveValue(mobile: 180.0, tablet: 220.0, desktop: 250.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(context.responsiveValue(mobile: 12.0, tablet: 14.0, desktop: 16.0)),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                width: 1.0,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(context.responsiveValue(mobile: 12.0, tablet: 14.0, desktop: 16.0)),
              child: VideoGallery(
                videoUrls: videoUrls,
              ),
            ),
          );
        }

        // If only images, show image gallery
        if (hasImages && !hasVideos) {
          return Container(
            height: context.responsiveValue(mobile: 180.0, tablet: 220.0, desktop: 250.0),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(context.responsiveValue(mobile: 12.0, tablet: 14.0, desktop: 16.0)),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                width: 1.0,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(context.responsiveValue(mobile: 12.0, tablet: 14.0, desktop: 16.0)),
              child: ImageGallery(
                imageUrls: ohyoImages,
              ),
            ),
          );
        }

        // If both images and videos, show combined view
        return Container(
          height: context.responsiveValue(mobile: 180.0, tablet: 220.0, desktop: 250.0),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(context.responsiveValue(mobile: 12.0, tablet: 14.0, desktop: 16.0)),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(context.responsiveValue(mobile: 12.0, tablet: 14.0, desktop: 16.0)),
            child: _buildCombinedMediaView(context, ohyoImages, videoUrls),
          ),
        );
      },
    );
  }

  Widget _buildCombinedMediaView(BuildContext context, List<String> imageUrls, List<String> videoUrls) {
    // Create a tab controller for switching between images and videos
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          // Tab bar
          Container(
            height: context.responsiveValue(mobile: 40.0, tablet: 44.0, desktop: 48.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(context.responsiveValue(mobile: 12.0, tablet: 14.0, desktop: 16.0)),
              ),
            ),
            child: TabBar(
              indicatorColor: Theme.of(context).colorScheme.primary,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: TextStyle(
                fontSize: context.responsiveValue(mobile: 12.0, tablet: 13.0, desktop: 14.0),
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(
                  icon: Icon(
                    Icons.image,
                    size: context.responsiveValue(mobile: 16.0, tablet: 18.0, desktop: 20.0),
                  ),
                  text: 'Afbeeldingen',
                ),
                Tab(
                  icon: Icon(
                    Icons.videocam,
                    size: context.responsiveValue(mobile: 16.0, tablet: 18.0, desktop: 20.0),
                  ),
                  text: 'Video\'s',
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              children: [
                // Images tab
                ImageGallery(
                  imageUrls: imageUrls,
                ),

                // Videos tab
                VideoGallery(
                  videoUrls: videoUrls,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
