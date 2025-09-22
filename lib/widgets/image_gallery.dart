import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;
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
                return Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrls[index],
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
                      child: CachedNetworkImage(
                        imageUrl: widget.imageUrls[index],
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
                      ),
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
