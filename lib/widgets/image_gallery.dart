import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/offline_media_cache_service.dart';
import '../providers/network_provider.dart';
import '../utils/responsive_utils.dart';
import '../utils/image_utils.dart';

class ImageGallery extends ConsumerStatefulWidget {
  final List<String> imageUrls;
  final String title;
  final int? kataId;
  final int? ohyoId;
  final int initialIndex;

  const ImageGallery({
    super.key,
    required this.imageUrls,
    this.title = 'Afbeeldingen Gallerij',
    this.kataId,
    this.ohyoId,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends ConsumerState<ImageGallery> {
  late PageController _pageController;
  int _currentIndex = 0;
  final Map<int, String> _resolvedUrls = {};
  late List<String> _imageUrls;
  int _resolveGeneration = 0;

  void _setImageUrls(List<String> urls) {
    _resolvedUrls.clear();
    _imageUrls = urls;
    _currentIndex = 0;
    _resolveGeneration += 1;
    _pageController.jumpToPage(0);
  }

  String? _extractFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }
    } catch (_) {}
    return null;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;
    _imageUrls = List<String>.from(widget.imageUrls);
    _initializeImages();
  }

  Future<void> _initializeImages() async {
    final networkState = ref.read(networkProvider);
    final isOffline = !networkState.isConnected;

    if (isOffline) {
      if (widget.kataId != null) {
        final cached = await OfflineMediaCacheService.getCachedKataImageUrls(widget.kataId!);
        if (cached.isNotEmpty && mounted) {
          setState(() {
            _setImageUrls(cached);
          });
        } else if (mounted) {
          final offlineOnly = <String>[];
          for (final url in _imageUrls) {
            final isLocalFile = url.startsWith('/') || url.startsWith('file://');
            if (isLocalFile) {
              offlineOnly.add(url);
              continue;
            }
            final fileName = _extractFileNameFromUrl(url);
            if (fileName != null) {
              final stablePath = OfflineMediaCacheService.getCachedKataImagePath(
                widget.kataId!,
                fileName,
              );
              if (stablePath != null) {
                offlineOnly.add(stablePath);
                continue;
              }
            }
            final cachedPath = OfflineMediaCacheService.getCachedFilePath(url, false);
            if (cachedPath != null) {
              offlineOnly.add(cachedPath);
            }
          }
          if (offlineOnly.isNotEmpty) {
            setState(() {
              _setImageUrls(offlineOnly);
            });
          }
        }
      } else if (widget.ohyoId != null) {
        final cached = await OfflineMediaCacheService.getCachedOhyoImagePaths(widget.ohyoId!);
        if (cached.isNotEmpty && mounted) {
          setState(() {
            _setImageUrls(cached);
          });
        } else if (mounted) {
          final offlineOnly = <String>[];
          for (final url in _imageUrls) {
            final isLocalFile = url.startsWith('/') || url.startsWith('file://');
            if (isLocalFile) {
              offlineOnly.add(url);
              continue;
            }
            final fileName = _extractFileNameFromUrl(url);
            if (fileName != null) {
              final stablePath = OfflineMediaCacheService.getCachedOhyoImagePath(
                widget.ohyoId!,
                fileName,
              );
              if (stablePath != null) {
                offlineOnly.add(stablePath);
                continue;
              }
            }
            final cachedPath = OfflineMediaCacheService.getCachedFilePath(url, false);
            if (cachedPath != null) {
              offlineOnly.add(cachedPath);
            }
          }
          if (offlineOnly.isNotEmpty) {
            setState(() {
              _setImageUrls(offlineOnly);
            });
          }
        }
      }
    }

    if (!isOffline && (widget.kataId != null || widget.ohyoId != null)) {
      try {
        if (widget.kataId != null) {
          final urls = await ImageUtils.fetchKataImagesFromBucket(widget.kataId!, ref: ref);
          if (urls.isNotEmpty && mounted) {
            setState(() {
              _setImageUrls(urls);
            });
          }
        } else if (widget.ohyoId != null) {
          final urls = await ImageUtils.fetchOhyoImagesFromBucket(widget.ohyoId!, ref: ref);
          if (urls.isNotEmpty && mounted) {
            setState(() {
              _setImageUrls(urls);
            });
          }
        }
      } catch (_) {
        // Ignore fetch failures; fall back to existing list
      }
    }

    if (!mounted) return;
    await _resolveImageUrls();
  }

  /// Resolve image URLs - use cached files when available
  Future<void> _resolveImageUrls() async {
    if (!mounted) return;
    final networkState = ref.read(networkProvider);
    final isOffline = !networkState.isConnected;
    final currentGeneration = _resolveGeneration;
    final snapshotUrls = List<String>.from(_imageUrls);

    // For each input URL, resolve it to a cached file if available, or keep the original URL
    for (int i = 0; i < snapshotUrls.length; i++) {
      if (currentGeneration != _resolveGeneration) {
        return;
      }
      final originalUrl = snapshotUrls[i];

      // Check if it's already a local file path
      final isLocalFile = originalUrl.startsWith('/') || originalUrl.startsWith('file://');
      if (isLocalFile) {
        _resolvedUrls[i] = originalUrl;
        continue;
      }

      // Prefer stable ohyo cache keys when ohyoId is provided
      if (widget.ohyoId != null) {
        final fileName = _extractFileNameFromUrl(originalUrl);
        if (fileName != null) {
          final cachedOhyoPath = OfflineMediaCacheService.getCachedOhyoImagePath(
            widget.ohyoId!,
            fileName,
          );
          if (cachedOhyoPath != null) {
            _resolvedUrls[i] = cachedOhyoPath;
            continue;
          }
        }
      }

      // Prefer stable kata cache keys when kataId is provided
      if (widget.kataId != null) {
        final fileName = _extractFileNameFromUrl(originalUrl);
        if (fileName != null) {
          final cachedKataPath = OfflineMediaCacheService.getCachedKataImagePath(
            widget.kataId!,
            fileName,
          );
          if (cachedKataPath != null) {
            _resolvedUrls[i] = cachedKataPath;
            continue;
          }
        }
      }

      // Check generic cache by URL hash (kata images and non-ohyo cache)
      final cachedPath = OfflineMediaCacheService.getCachedFilePath(originalUrl, false);
      if (cachedPath != null) {
        _resolvedUrls[i] = cachedPath;
        continue;
      }

      // Try to get cached version or use original
      if (!isOffline) {
        final resolvedUrl = await OfflineMediaCacheService.getMediaUrl(originalUrl, false, ref);
        if (!mounted) return;
        _resolvedUrls[i] = resolvedUrl;
      } else {
        _resolvedUrls[i] = originalUrl;
      }
    }

    if (!mounted || currentGeneration != _resolveGeneration) return;
    setState(() {});

    // Pre-cache images if online (for future offline use)
    if (networkState.isConnected && widget.kataId != null) {
      debugPrint('🖼️ Online - pre-caching kata ${widget.kataId} images');
      await OfflineMediaCacheService.preCacheMediaFiles(_imageUrls, false, ref);
      // Also cache with stable keys so offline gallery resolves all images
      Future.microtask(() async {
        for (final url in _imageUrls) {
          final fileName = _extractFileNameFromUrl(url);
          if (fileName != null) {
            await OfflineMediaCacheService.cacheKataImage(widget.kataId!, fileName, url, ref);
          }
        }
      });
    } else if (networkState.isConnected && widget.ohyoId != null) {
      debugPrint('🖼️ Online - pre-caching ohyo ${widget.ohyoId} images');
      // Ensure ohyo images are cached with stable keys for offline gallery
      Future.microtask(() async {
        for (final url in _imageUrls) {
          final fileName = _extractFileNameFromUrl(url);
          if (fileName != null) {
            await OfflineMediaCacheService.cacheOhyoImage(widget.ohyoId!, fileName, url, ref);
          }
        }
      });
    }
  }

  /// Build thumbnail image widget - handles both local files and network images
  Widget _buildThumbnailImage(int index, int cacheSize) {
    final imageUrl = _resolvedUrls[index] ?? _imageUrls[index];
    final isLocalFile = imageUrl.startsWith('/') || imageUrl.startsWith('file://');

    if (isLocalFile) {
      final filePath = imageUrl.replaceFirst('file://', '');
      final file = File(filePath);

      if (!file.existsSync()) {
        return const Center(
          child: Icon(
            Icons.error,
            size: 20,
            color: Colors.white,
          ),
        );
      }

      return Image.file(
        file,
        fit: BoxFit.contain,
        cacheWidth: cacheSize,
        cacheHeight: cacheSize,
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
        fit: BoxFit.contain,
        memCacheWidth: cacheSize,
        memCacheHeight: cacheSize,
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
    if (_imageUrls.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: const Center(
          child: Text('Geen afbeeldingen beschikbaar'),
        ),
      );
    }

    final media = MediaQuery.of(context);
    final dpr = media.devicePixelRatio;
    final isMobile = context.isMobile;
    final rawMainCacheWidth = (media.size.width * dpr).round();
    final rawMainCacheHeight = (media.size.height * dpr).round();
    final mainCacheWidth = isMobile && rawMainCacheWidth > 1080
        ? 1080
        : rawMainCacheWidth;
    final mainCacheHeight = isMobile && rawMainCacheHeight > 1920
        ? 1920
        : rawMainCacheHeight;
    final rawThumbnailCacheSize = (80 * dpr).round();
    final thumbnailCacheSize = isMobile && rawThumbnailCacheSize > 120
        ? 120
        : rawThumbnailCacheSize;

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
            itemCount: _imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final imageUrl = _resolvedUrls[index] ?? _imageUrls[index];
                final isLocalFile = imageUrl.startsWith('/') || imageUrl.startsWith('file://');


                return Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: isLocalFile
                        ? Image.file(
                            File(imageUrl.replaceFirst('file://', '')),
                            fit: BoxFit.contain,
                            cacheWidth: mainCacheWidth,
                            cacheHeight: mainCacheHeight,
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
                      memCacheWidth: mainCacheWidth,
                      memCacheHeight: mainCacheHeight,
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
                '${_currentIndex + 1} / ${_imageUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // Next image button
                IconButton(
                  onPressed: _currentIndex < _imageUrls.length - 1 ? () {
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
                itemCount: _imageUrls.length,
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
                      child: _buildThumbnailImage(index, thumbnailCacheSize),
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
