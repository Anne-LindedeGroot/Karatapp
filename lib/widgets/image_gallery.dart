import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/offline_media_cache_service.dart';
import '../providers/network_provider.dart';

class ImageGallery extends ConsumerStatefulWidget {
  final List<String> imageUrls;
  final String title;
  final int? kataId;
  final int initialIndex;

  const ImageGallery({
    super.key,
    required this.imageUrls,
    this.title = 'Afbeeldingen Gallerij',
    this.kataId,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends ConsumerState<ImageGallery> {
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<int, String> _resolvedUrls = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;
    _resolveImageUrls();
  }

  /// Resolve image URLs - use cached files when offline
  Future<void> _resolveImageUrls() async {
    // First, proactively cache all images if online
    final networkState = ref.read(networkProvider);
    if (networkState.isConnected) {
      debugPrint('🖼️ Gallery opened online - pre-caching ${widget.imageUrls.length} images');
      await OfflineMediaCacheService.preCacheMediaFiles(widget.imageUrls, false, ref);
    }

    // Then resolve URLs (will use cached files if available)
    for (int i = 0; i < widget.imageUrls.length; i++) {
      final originalUrl = widget.imageUrls[i];
      final resolvedUrl = await OfflineMediaCacheService.getMediaUrl(originalUrl, false, ref);
      setState(() {
        _resolvedUrls[i] = resolvedUrl;
      });
    }
  }

  /// Build thumbnail image widget - handles both local files and network images
  Widget _buildThumbnailImage(int index) {
    final imageUrl = _resolvedUrls[index] ?? widget.imageUrls[index];
    final isLocalFile = imageUrl.startsWith('/') || imageUrl.startsWith('file://');

    if (isLocalFile) {
      return Image.file(
        File(imageUrl.replaceFirst('file://', '')),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(
            Icons.error,
            size: 20,
            color: Colors.white,
          ),
        ),
      );
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(
            Icons.error,
            size: 20,
            color: Colors.white,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: const Center(
          child: Text('Geen afbeeldingen beschikbaar'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Main image viewer
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final imageUrl = _resolvedUrls[index] ?? widget.imageUrls[index];
                final isLocalFile = imageUrl.startsWith('/') || imageUrl.startsWith('file://');

                return Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: isLocalFile
                        ? Image.file(
                            File(imageUrl.replaceFirst('file://', '')),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Afbeelding laden mislukt',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error,
                              size: 50,
                              color: Colors.white,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Afbeelding laden mislukt',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Image counter and navigation
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              color: Colors.black87,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous image button
                IconButton(
                  onPressed: _currentIndex > 0 ? () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } : null,
                  icon: const Icon(Icons.skip_previous, color: Colors.white),
                  tooltip: 'Vorige afbeelding',
                ),
                
                // Image counter
                Text(
                  '${_currentIndex + 1} / ${widget.imageUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // Next image button
                IconButton(
                  onPressed: _currentIndex < widget.imageUrls.length - 1 ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } : null,
                  icon: const Icon(Icons.skip_next, color: Colors.white),
                  tooltip: 'Volgende afbeelding',
                ),
              ],
            ),
          ),
          
          // Thumbnail gallery
          Container(
            height: 100,
            color: Colors.black87,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: widget.imageUrls.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    width: 80,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _currentIndex == index
                            ? Colors.white
                            : Colors.grey,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2.0),
                      child: _buildThumbnailImage(index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
