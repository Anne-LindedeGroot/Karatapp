import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/kata_model.dart';
import '../../providers/image_provider.dart';
import '../../utils/responsive_utils.dart';
import '../../core/theme/app_theme.dart';
import '../image_gallery.dart';
import '../video_gallery.dart';
import '../video_player_widget.dart';

/// Kata Card Media - Handles media display for kata cards
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

  Widget _buildMainMediaDisplay(bool hasImages, bool hasVideos, List<String> cachedImages, List<String> videoUrls) {
    if (hasImages) {
      return _buildImageDisplay(cachedImages);
    } else if (hasVideos) {
      return _buildVideoDisplay(videoUrls);
    }
    return const SizedBox.shrink();
  }

  Widget _buildImageDisplay(List<String> cachedImages) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: cachedImages.first,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 40),
          ),
        ),
      ),
    );
  }

  Widget _buildVideoDisplay(List<String> videoUrls) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: VideoPlayerWidget(
          videoUrl: videoUrls.first,
          autoPlay: false,
          showControls: true,
        ),
      ),
    );
  }

  Widget _buildMediaSection(BuildContext context) {
    final cachedImages = ref.watch(imageNotifierProvider).kataImages[widget.kata.id] ?? [];
    final videoUrls = widget.kata.videoUrls ?? [];
    final hasImages = cachedImages.isNotEmpty;
    final hasVideos = videoUrls.isNotEmpty;

    if (!hasImages && !hasVideos) {
      return const SizedBox.shrink();
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
                      title: '${widget.kata.name} - Images',
                      kataId: widget.kata.id,
                    ),
                  ),
                ).then((_) {
                  ref.read(imageNotifierProvider.notifier).forceRefreshKataImages(widget.kata.id);
                });
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
                          title: '${widget.kata.name} - Images',
                          kataId: widget.kata.id,
                        ),
                      ),
                    ).then((_) {
                      ref.read(imageNotifierProvider.notifier).forceRefreshKataImages(widget.kata.id);
                    });
                  },
                  icon: const Icon(Icons.photo_library),
                  label: Text('Bekijk ${cachedImages.length} afbeelding${cachedImages.length != 1 ? 'en' : ''}'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: context.responsiveSpacing(SpacingSize.sm),
                    ),
                  ),
                ),
              ),
            
            // Videos button
            if (hasVideos) ...[
              if (hasImages) SizedBox(height: context.responsiveSpacing(SpacingSize.xs)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
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
                  icon: const Icon(Icons.video_library),
                  label: Text('Bekijk ${videoUrls.length} video${videoUrls.length != 1 ? '\'s' : ''}'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: context.responsiveSpacing(SpacingSize.sm),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildMediaSection(context);
  }
}
