import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'universal_video_player.dart';
import '../services/offline_media_cache_service.dart';

enum MediaType { image, video }

class MediaItem {
  final String url;
  final MediaType type;
  final int index;

  MediaItem({
    required this.url,
    required this.type,
    required this.index,
  });
}

class MediaGallery extends ConsumerStatefulWidget {
  final List<String> imageUrls;
  final List<String> videoUrls;
  final String title;
  final int? kataId;
  final int initialIndex;
  final MediaType initialType;

  const MediaGallery({
    super.key,
    this.imageUrls = const [],
    this.videoUrls = const [],
    this.title = 'Media Gallery',
    this.kataId,
    this.initialIndex = 0,
    this.initialType = MediaType.image,
  });

  @override
  ConsumerState<MediaGallery> createState() => _MediaGalleryState();

  /// Helper method to build image widget with offline cache support
  static Widget _buildCachedImage(String imageUrl, WidgetRef ref, {
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return FutureBuilder<String>(
      future: OfflineMediaCacheService.getMediaUrl(imageUrl, false, ref),
      builder: (context, snapshot) {
        final resolvedUrl = snapshot.data ?? imageUrl;
        final isLocalFile = resolvedUrl.startsWith('/') || resolvedUrl.startsWith('file://');

        if (isLocalFile) {
          return Image.file(
            File(resolvedUrl.replaceFirst('file://', '')),
            fit: fit,
            errorBuilder: (context, error, stackTrace) =>
                errorWidget ?? const Center(child: Icon(Icons.error, size: 20)),
          );
        } else {
          return CachedNetworkImage(
            imageUrl: resolvedUrl,
            fit: fit,
            placeholder: placeholder != null
                ? (context, url) => placeholder
                : (context, url) => const Center(child: CircularProgressIndicator()),
            errorWidget: errorWidget != null
                ? (context, url, error) => errorWidget
                : (context, url, error) => const Center(child: Icon(Icons.error, size: 20)),
          );
        }
      },
    );
  }
}

class _MediaGalleryState extends ConsumerState<MediaGallery>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _imagePageController;
  late PageController _videoPageController;
  int _currentImageIndex = 0;
  int _currentVideoIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Initialize tab controller
    final hasImages = widget.imageUrls.isNotEmpty;
    final hasVideos = widget.videoUrls.isNotEmpty;
    final tabCount = (hasImages ? 1 : 0) + (hasVideos ? 1 : 0);
    
    _tabController = TabController(
      length: tabCount,
      vsync: this,
      // ALWAYS start with images first (index 0) when images are available
      // Only start with videos if there are NO images
      initialIndex: hasImages ? 0 : (hasVideos ? 0 : 0),
    );
    
    // Initialize page controllers
    _imagePageController = PageController(initialPage: widget.initialIndex);
    _videoPageController = PageController(initialPage: widget.initialIndex);
    _currentImageIndex = widget.initialIndex;
    _currentVideoIndex = widget.initialIndex;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _imagePageController.dispose();
    _videoPageController.dispose();
    super.dispose();
  }

  Widget _buildVideoThumbnail(String videoUrl, double width, double height) {
    // Check if it's a YouTube URL to show YouTube icon
    final isYouTube = videoUrl.contains('youtube.com') || 
                     videoUrl.contains('youtu.be') || 
                     videoUrl.contains('m.youtube.com');
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Stack(
        children: [
          // Background with video icon
          Center(
            child: Icon(
              isYouTube ? Icons.play_circle_filled : Icons.videocam,
              color: Colors.white70,
              size: width * 0.4,
            ),
          ),
          // YouTube logo overlay if it's a YouTube video
          if (isYouTube)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  'YT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          // Play button overlay
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: width * 0.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.imageUrls.isNotEmpty;
    final hasVideos = widget.videoUrls.isNotEmpty;
    
    if (!hasImages && !hasVideos) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: const Center(
          child: Text('Geen media beschikbaar'),
        ),
      );
    }

    // If only images or only videos, show the appropriate gallery
    if (hasImages && !hasVideos) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: _buildImageGallery(),
      );
    }
    
    if (!hasImages && hasVideos) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: _buildVideoGallery(),
      );
    }

    // If both images and videos exist, show tab-based navigation
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            if (hasImages)
              const Tab(
                icon: Icon(Icons.photo),
                text: 'Afbeeldingen',
              ),
            if (hasVideos)
              const Tab(
                icon: Icon(Icons.videocam),
                text: 'Video\'s',
              ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          if (hasImages) _buildImageGallery(),
          if (hasVideos) _buildVideoGallery(),
        ],
      ),
    );
  }

  Widget _buildImageGallery() {
    return Column(
      children: [
        // Main image viewer
        Expanded(
          child: PageView.builder(
            controller: _imagePageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Center(
                child: MediaGallery._buildCachedImage(
                  widget.imageUrls[index],
                  ref,
                  fit: BoxFit.contain,
                  errorWidget: const Center(
                    child: Icon(Icons.error, size: 50),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Image counter and navigation
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous image button
              IconButton(
                onPressed: _currentImageIndex > 0 ? () {
                  _imagePageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } : null,
                icon: const Icon(Icons.skip_previous),
                tooltip: 'Vorige afbeelding',
              ),
              
              // Image counter
              Text(
                '${_currentImageIndex + 1} / ${widget.imageUrls.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              
              // Next image button
              IconButton(
                onPressed: _currentImageIndex < widget.imageUrls.length - 1 ? () {
                  _imagePageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } : null,
                icon: const Icon(Icons.skip_next),
                tooltip: 'Volgende afbeelding',
              ),
            ],
          ),
        ),
        
        // Thumbnail gallery
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  _imagePageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.all(4.0),
                  width: 80,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _currentImageIndex == index
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2.0),
                    child: MediaGallery._buildCachedImage(
                      widget.imageUrls[index],
                      ref,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoGallery() {
    return Column(
      children: [
        // Main video viewer
        Expanded(
          child: PageView.builder(
            controller: _videoPageController,
            itemCount: widget.videoUrls.length,
            onPageChanged: (index) {
              setState(() {
                _currentVideoIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: UniversalVideoPlayer(
                  videoUrl: widget.videoUrls[index],
                  showControls: true,
                  autoPlay: false,
                ),
              );
            },
          ),
        ),
        
        // Video counter and navigation
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous video button
              IconButton(
                onPressed: _currentVideoIndex > 0 ? () {
                  _videoPageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } : null,
                icon: const Icon(Icons.skip_previous),
                tooltip: 'Vorige video',
              ),
              
              // Video counter
              Text(
                '${_currentVideoIndex + 1} / ${widget.videoUrls.length}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              
              // Next video button
              IconButton(
                onPressed: _currentVideoIndex < widget.videoUrls.length - 1 ? () {
                  _videoPageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                } : null,
                icon: const Icon(Icons.skip_next),
                tooltip: 'Volgende video',
              ),
            ],
          ),
        ),
        
        // Video thumbnail gallery
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.videoUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  _videoPageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _currentVideoIndex == index
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                  child: _buildVideoThumbnail(
                    widget.videoUrls[index],
                    80,
                    92,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
