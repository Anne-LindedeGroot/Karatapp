import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'universal_video_player.dart';

class VideoGallery extends ConsumerStatefulWidget {
  final List<String> videoUrls;
  final String title;
  final int? kataId;
  final int initialIndex;

  const VideoGallery({
    super.key,
    required this.videoUrls,
    this.title = 'Video Gallery',
    this.kataId,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<VideoGallery> createState() => _VideoGalleryState();
}

class _VideoGalleryState extends ConsumerState<VideoGallery> {
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
    if (widget.videoUrls.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: const Center(
          child: Text('No videos available'),
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
          // Main video viewer
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.videoUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
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
            decoration: const BoxDecoration(
              color: Colors.black87,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous video button
                IconButton(
                  onPressed: _currentIndex > 0 ? () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } : null,
                  icon: const Icon(Icons.skip_previous, color: Colors.white),
                  tooltip: 'Previous video',
                ),
                
                // Video counter
                Text(
                  '${_currentIndex + 1} / ${widget.videoUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                // Next video button
                IconButton(
                  onPressed: _currentIndex < widget.videoUrls.length - 1 ? () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } : null,
                  icon: const Icon(Icons.skip_next, color: Colors.white),
                  tooltip: 'Next video',
                ),
              ],
            ),
          ),
          
          // Video thumbnail gallery
          Container(
            height: 100,
            color: Colors.black87,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              itemCount: widget.videoUrls.length,
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
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _currentIndex == index
                            ? Colors.white
                            : Colors.grey,
                        width: 2.0,
                      ),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: _buildVideoThumbnail(
                      widget.videoUrls[index],
                      80,
                      84,
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
