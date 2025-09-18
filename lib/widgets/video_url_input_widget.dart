import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VideoUrlInputWidget extends StatefulWidget {
  final List<String> videoUrls;
  final Function(List<String>) onVideoUrlsChanged;
  final String title;

  const VideoUrlInputWidget({
    super.key,
    required this.videoUrls,
    required this.onVideoUrlsChanged,
    this.title = 'Video URLs',
  });

  @override
  State<VideoUrlInputWidget> createState() => _VideoUrlInputWidgetState();
}

class _VideoUrlInputWidgetState extends State<VideoUrlInputWidget> {
  late TextEditingController _urlController;
  late List<String> _currentUrls;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _currentUrls = List<String>.from(widget.videoUrls);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  bool _isValidUrl(String url) {
    if (url.trim().isEmpty) return false;
    
    // Basic URL validation
    final urlPattern = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
      caseSensitive: false,
    );
    
    return urlPattern.hasMatch(url.trim());
  }

  bool _isSupportedMediaUrl(String url) {
    final lowerUrl = url.toLowerCase();
    
    // Video platforms
    if (lowerUrl.contains('youtube.com') || 
        lowerUrl.contains('youtu.be') ||
        lowerUrl.contains('vimeo.com') ||
        lowerUrl.contains('dailymotion.com') ||
        lowerUrl.contains('twitch.tv')) {
      return true;
    }
    
    // Direct video file extensions
    final videoExtensions = ['.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm', '.mkv', '.m4v'];
    if (videoExtensions.any((ext) => lowerUrl.endsWith(ext))) {
      return true;
    }
    
    // Audio file extensions
    final audioExtensions = ['.mp3', '.wav', '.aac', '.ogg', '.flac', '.m4a'];
    if (audioExtensions.any((ext) => lowerUrl.endsWith(ext))) {
      return true;
    }
    
    // Image file extensions
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg'];
    if (imageExtensions.any((ext) => lowerUrl.endsWith(ext))) {
      return true;
    }
    
    // Generic media URLs (might be streaming or other formats)
    return true; // Allow all valid URLs as they might be media
  }

  void _addUrl() {
    final url = _urlController.text.trim();
    
    if (!_isValidUrl(url)) {
      _showErrorSnackBar('Please enter a valid URL');
      return;
    }
    
    if (!_isSupportedMediaUrl(url)) {
      _showErrorSnackBar('URL does not appear to be a supported media format');
      return;
    }
    
    if (_currentUrls.contains(url)) {
      _showErrorSnackBar('This URL has already been added');
      return;
    }
    
    setState(() {
      _currentUrls.add(url);
      _urlController.clear();
    });
    
    widget.onVideoUrlsChanged(_currentUrls);
    
    _showSuccessSnackBar('Video URL added successfully');
  }

  void _removeUrl(int index) {
    setState(() {
      _currentUrls.removeAt(index);
    });
    widget.onVideoUrlsChanged(_currentUrls);
  }

  void _reorderUrls(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _currentUrls.removeAt(oldIndex);
      _currentUrls.insert(newIndex, item);
    });
    widget.onVideoUrlsChanged(_currentUrls);
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _getUrlDisplayName(String url) {
    // Extract a readable name from the URL
    try {
      final uri = Uri.parse(url);
      
      // YouTube
      if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
        return 'YouTube Video';
      }
      
      // Vimeo
      if (uri.host.contains('vimeo.com')) {
        return 'Vimeo Video';
      }
      
      // Dailymotion
      if (uri.host.contains('dailymotion.com')) {
        return 'Dailymotion Video';
      }
      
      // Twitch
      if (uri.host.contains('twitch.tv')) {
        return 'Twitch Video';
      }
      
      // Direct file
      final path = uri.path.toLowerCase();
      if (path.endsWith('.mp4')) return 'MP4 Video';
      if (path.endsWith('.avi')) return 'AVI Video';
      if (path.endsWith('.mov')) return 'MOV Video';
      if (path.endsWith('.wmv')) return 'WMV Video';
      if (path.endsWith('.flv')) return 'FLV Video';
      if (path.endsWith('.webm')) return 'WebM Video';
      if (path.endsWith('.mkv')) return 'MKV Video';
      if (path.endsWith('.m4v')) return 'M4V Video';
      
      if (path.endsWith('.mp3')) return 'MP3 Audio';
      if (path.endsWith('.wav')) return 'WAV Audio';
      if (path.endsWith('.aac')) return 'AAC Audio';
      if (path.endsWith('.ogg')) return 'OGG Audio';
      if (path.endsWith('.flac')) return 'FLAC Audio';
      if (path.endsWith('.m4a')) return 'M4A Audio';
      
      if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'JPEG Image';
      if (path.endsWith('.png')) return 'PNG Image';
      if (path.endsWith('.gif')) return 'GIF Image';
      if (path.endsWith('.bmp')) return 'BMP Image';
      if (path.endsWith('.webp')) return 'WebP Image';
      if (path.endsWith('.svg')) return 'SVG Image';
      
      // Generic
      return uri.host.isNotEmpty ? uri.host : 'Media URL';
    } catch (e) {
      return 'Media URL';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // URL Input Field
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Enter video/media URL',
                hintText: 'https://www.youtube.com/watch?v=...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _addUrl(),
            ),
            
            const SizedBox(height: 16),
            
            // Help Text
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.surfaceContainerHighest
                    : Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.outline
                      : Colors.blue[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Supported Media',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Video platforms: YouTube, Vimeo, Dailymotion, Twitch\n'
                    '• Video files: MP4, AVI, MOV, WMV, FLV, WebM, MKV\n'
                    '• Press Enter or Done on keyboard to add URL',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // Current URLs List
            if (_currentUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Added URLs (${_currentUrls.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Long press and drag to reorder URLs',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 8),
              
              // Reorderable List
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _currentUrls.length,
                onReorder: _reorderUrls,
                itemBuilder: (context, index) {
                  final url = _currentUrls[index];
                  return Container(
                    key: ValueKey(url),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          radius: 16,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          _getUrlDisplayName(url),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.copy, size: 18),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: url));
                                _showSuccessSnackBar('URL copied to clipboard');
                              },
                              tooltip: 'Copy URL',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 18),
                              onPressed: () => _removeUrl(index),
                              tooltip: 'Remove URL',
                              color: Colors.red,
                            ),
                            const Icon(
                              Icons.drag_handle,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
