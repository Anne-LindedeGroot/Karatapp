import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/kata_model.dart';
import '../providers/kata_provider.dart';
import '../providers/image_provider.dart';
import '../utils/image_utils.dart';
import '../widgets/image_gallery.dart';

class EditKataScreen extends ConsumerStatefulWidget {
  final Kata kata;

  const EditKataScreen({
    super.key,
    required this.kata,
  });

  @override
  ConsumerState<EditKataScreen> createState() => _EditKataScreenState();
}

class _EditKataScreenState extends ConsumerState<EditKataScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _styleController;
  late TextEditingController _videoUrlController;
  
  List<String> _currentImageUrls = [];
  final List<File> _newSelectedImages = [];
  List<String> _videoUrls = [];
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.kata.name);
    _descriptionController = TextEditingController(text: widget.kata.description);
    _styleController = TextEditingController(text: widget.kata.style);
    _videoUrlController = TextEditingController();
    
    // Load current images and video URLs
    _loadCurrentImages();
    _videoUrls = List<String>.from(widget.kata.videoUrls ?? []);
    
    // Add listeners to detect changes
    _nameController.addListener(_onTextChanged);
    _descriptionController.addListener(_onTextChanged);
    _styleController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _styleController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _loadCurrentImages() async {
    try {
      final imageUrls = await ImageUtils.fetchKataImagesFromBucket(widget.kata.id);
      setState(() {
        _currentImageUrls = imageUrls;
      });
    } catch (e) {
      // Handle error silently or show a message
      setState(() {
        _currentImageUrls = widget.kata.imageUrls ?? [];
      });
    }
  }

  Future<void> _pickImagesFromGallery() async {
    final images = await ImageUtils.pickMultipleImagesFromGallery();
    if (images.isNotEmpty) {
      setState(() {
        _newSelectedImages.addAll(images);
        _hasChanges = true;
      });
    }
  }

  Future<void> _captureImageWithCamera() async {
    final image = await ImageUtils.captureImageWithCamera();
    if (image != null) {
      setState(() {
        _newSelectedImages.add(image);
        _hasChanges = true;
      });
    }
  }

  Future<void> _deleteExistingImage(String imageUrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image?'),
        content: const Text('This will permanently delete the image. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Deleting image...'),
                ],
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }

        // Delete the image from storage
        await ref.read(imageNotifierProvider.notifier).deleteImage(
          imageUrl,
          widget.kata.id,
        );

        // Update local state
        setState(() {
          _currentImageUrls.remove(imageUrl);
          _hasChanges = true;
        });

        if (mounted) {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.hideCurrentSnackBar();
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Image deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          scaffoldMessenger.hideCurrentSnackBar();
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error deleting image: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newSelectedImages.removeAt(index);
      _hasChanges = true;
    });
  }

  Future<void> _reorderCurrentImages(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _currentImageUrls.removeAt(oldIndex);
      _currentImageUrls.insert(newIndex, item);
      _hasChanges = true;
    });
  }

  Future<void> _reorderNewImages(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _newSelectedImages.removeAt(oldIndex);
      _newSelectedImages.insert(newIndex, item);
      _hasChanges = true;
    });
  }

  void _addVideoUrl() {
    final url = _videoUrlController.text.trim();
    if (url.isNotEmpty && !_videoUrls.contains(url)) {
      setState(() {
        _videoUrls.add(url);
        _videoUrlController.clear();
        _hasChanges = true;
      });
    }
  }

  void _removeVideoUrl(int index) {
    setState(() {
      _videoUrls.removeAt(index);
      _hasChanges = true;
    });
  }

  void _reorderVideoUrls(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _videoUrls.removeAt(oldIndex);
      _videoUrls.insert(newIndex, item);
      _hasChanges = true;
    });
  }


  Future<void> _saveChanges() async {
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update text fields and video URLs in database
      await ref.read(kataNotifierProvider.notifier).updateKata(
        kataId: widget.kata.id,
        name: _nameController.text,
        description: _descriptionController.text,
        style: _styleController.text,
        videoUrls: _videoUrls.isNotEmpty ? _videoUrls : null,
      );

      // Handle image changes
      if (_newSelectedImages.isNotEmpty) {
        // Upload new images
        final newImageUrls = await ImageUtils.uploadMultipleImagesToSupabase(
          _newSelectedImages,
          widget.kata.id,
        );
        _currentImageUrls.addAll(newImageUrls);
      }

      // Update image order if needed
      if (_currentImageUrls.isNotEmpty) {
        await ref.read(imageNotifierProvider.notifier).reorderImages(
          widget.kata.id,
          _currentImageUrls,
        );
      }

      // Refresh kata data
      await ref.read(kataNotifierProvider.notifier).refreshKatas();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kata updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error updating kata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openDescriptionDialog() async {
    final TextEditingController dialogController = TextEditingController(text: _descriptionController.text);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Description',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TextField(
                  controller: dialogController,
                  decoration: const InputDecoration(
                    hintText: 'Enter kata description...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(16),
                  ),
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, dialogController.text),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result != null && result != _descriptionController.text) {
      setState(() {
        _descriptionController.text = result;
        _hasChanges = true;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text('You have unsaved changes. Are you sure you want to leave?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          navigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Kata'),
          actions: [
            if (_hasChanges)
              IconButton(
                icon: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                onPressed: _isLoading ? null : _saveChanges,
                tooltip: 'Save Changes',
              ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text Fields
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kata Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Kata Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.sports_martial_arts),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _styleController,
                        decoration: const InputDecoration(
                          labelText: 'Style',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.style),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _openDescriptionDialog(),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.description),
                              suffixIcon: Icon(Icons.edit),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 120),
                              width: double.infinity,
                              child: Text(
                                _descriptionController.text.isEmpty 
                                    ? 'Tap to edit description...' 
                                    : _descriptionController.text,
                                style: TextStyle(
                                  color: _descriptionController.text.isEmpty 
                                      ? Colors.grey[600] 
                                      : null,
                                  fontSize: 16,
                                ),
                                maxLines: 5,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Current Images Section
              if (_currentImageUrls.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Current Images (${_currentImageUrls.length})',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ImageGallery(
                                        imageUrls: _currentImageUrls,
                                        title: widget.kata.name,
                                        kataId: widget.kata.id,
                                      ),
                                    ),
                                  ).then((_) => _loadCurrentImages());
                                },
                                icon: const Icon(Icons.fullscreen, size: 18),
                                label: const Text(
                                  'Gallery',
                                  style: TextStyle(fontSize: 14),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Long press and drag to reorder images',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ReorderableListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _currentImageUrls.length,
                            onReorder: _reorderCurrentImages,
                            itemBuilder: (context, index) {
                              return Container(
                                key: ValueKey(_currentImageUrls[index]),
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.blue, width: 2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: CachedNetworkImage(
                                          imageUrl: _currentImageUrls[index],
                                          fit: BoxFit.cover,
                                          width: 96,
                                          height: 96,
                                          placeholder: (context, url) => const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                          errorWidget: (context, url, error) => const Icon(Icons.error),
                                        ),
                                      ),
                                    ),
                                    // Position indicator
                                    Positioned(
                                      top: 4,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Delete button
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _deleteExistingImage(_currentImageUrls[index]),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Drag handle
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Icon(
                                          Icons.drag_handle,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // New Images Section
              if (_newSelectedImages.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Images to Add (${_newSelectedImages.length})',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Long press and drag to reorder images',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ReorderableListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _newSelectedImages.length,
                            onReorder: _reorderNewImages,
                            itemBuilder: (context, index) {
                              return Container(
                                key: ValueKey(_newSelectedImages[index].path),
                                width: 100,
                                height: 100,
                                margin: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.green, width: 2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.file(
                                          _newSelectedImages[index],
                                          fit: BoxFit.cover,
                                          width: 96,
                                          height: 96,
                                        ),
                                      ),
                                    ),
                                    // Position indicator
                                    Positioned(
                                      top: 4,
                                      left: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Remove button
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removeNewImage(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Drag handle
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Icon(
                                          Icons.drag_handle,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Add Images Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Images',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _pickImagesFromGallery,
                              icon: const Icon(Icons.photo_library, size: 20),
                              label: const Text(
                                'Gallery',
                                style: TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                minimumSize: const Size(0, 56),
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                elevation: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _captureImageWithCamera,
                              icon: const Icon(Icons.camera_alt, size: 20),
                              label: const Text(
                                'Camera',
                                style: TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                minimumSize: const Size(0, 56),
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Video URLs Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Video URLs',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add YouTube, Vimeo, or other video URLs to demonstrate this kata',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Add Video URL Input
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _videoUrlController,
                              decoration: const InputDecoration(
                                labelText: 'Video URL',
                                hintText: 'https://youtube.com/watch?v=...',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.video_library),
                              ),
                              onSubmitted: (_) => _addVideoUrl(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _addVideoUrl,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                      
                      // Current Video URLs List
                      if (_videoUrls.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Current Videos (${_videoUrls.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Long press and drag to reorder videos',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _videoUrls.length,
                          onReorder: _reorderVideoUrls,
                          itemBuilder: (context, index) {
                            final url = _videoUrls[index];
                            return Container(
                              key: ValueKey(url),
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.orange.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.orange.shade50,
                              ),
                              child: ListTile(
                                leading: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.video_library,
                                      color: Colors.orange.shade700,
                                    ),
                                  ],
                                ),
                                title: Text(
                                  url,
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _removeVideoUrl(index),
                                      tooltip: 'Remove video',
                                    ),
                                    const Icon(
                                      Icons.drag_handle,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Footer Section with helpful information
              const SizedBox(height: 32),
              Card(
                color: Colors.grey[50],
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Editing Tips',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTipItem(
                        icon: Icons.drag_handle,
                        text: 'Long press and drag images to reorder them',
                      ),
                      const SizedBox(height: 8),
                      _buildTipItem(
                        icon: Icons.description,
                        text: 'Tap the description field to open the full editor',
                      ),
                      const SizedBox(height: 8),
                      _buildTipItem(
                        icon: Icons.save,
                        text: 'Changes are automatically detected and saved',
                      ),
                      const SizedBox(height: 8),
                      _buildTipItem(
                        icon: Icons.photo_library,
                        text: 'Add multiple images from gallery or camera',
                      ),
                    ],
                  ),
                ),
              ),

              // Additional spacing for better scrolling experience
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}
