import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/kata_provider.dart';
import '../utils/image_utils.dart';

class CreateKataScreen extends ConsumerStatefulWidget {
  const CreateKataScreen({super.key});

  @override
  ConsumerState<CreateKataScreen> createState() => _CreateKataScreenState();
}

class _CreateKataScreenState extends ConsumerState<CreateKataScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _styleController;
  late TextEditingController _videoUrlController;
  
  final List<File> _selectedImages = [];
  List<String> _videoUrls = [];
  bool _isLoading = false;
  bool _isPrivate = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _styleController = TextEditingController();
    _videoUrlController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _styleController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImagesFromGallery() async {
    final images = await ImageUtils.pickMultipleImagesFromGallery();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
    }
  }

  Future<void> _captureImageWithCamera() async {
    final image = await ImageUtils.captureImageWithCamera();
    if (image != null) {
      setState(() {
        _selectedImages.add(image);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _selectedImages.removeAt(oldIndex);
      _selectedImages.insert(newIndex, item);
    });
  }

  void _addVideoUrl() {
    final url = _videoUrlController.text.trim();
    if (url.isNotEmpty && !_videoUrls.contains(url)) {
      setState(() {
        _videoUrls.add(url);
        _videoUrlController.clear();
      });
    }
  }

  void _removeVideoUrl(int index) {
    setState(() {
      _videoUrls.removeAt(index);
    });
  }

  void _reorderVideoUrls(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _videoUrls.removeAt(oldIndex);
      _videoUrls.insert(newIndex, item);
    });
  }


  Future<void> _createKata() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(kataNotifierProvider.notifier).addKata(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        style: _styleController.text.trim(),
        images: _selectedImages.isNotEmpty ? _selectedImages : null,
        videoUrls: _videoUrls.isNotEmpty ? _videoUrls : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kata created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating kata: $e'),
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
                    'Kata Description',
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

    if (result != null) {
      setState(() {
        _descriptionController.text = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Kata'),
        actions: [
          IconButton(
            icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _isLoading ? null : _createKata,
            tooltip: 'Create Kata',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
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
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Kata Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.sports_martial_arts),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a kata name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _styleController,
                        decoration: const InputDecoration(
                          labelText: 'Style *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.style),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a style';
                          }
                          return null;
                        },
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
                              labelText: 'Description *',
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
                                    ? 'Tap to add description...' 
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
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Private Kata'),
                        subtitle: const Text('Only you can see this kata'),
                        value: _isPrivate,
                        onChanged: (value) {
                          setState(() {
                            _isPrivate = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Images Section
              if (_selectedImages.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected Images (${_selectedImages.length})',
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
                            itemCount: _selectedImages.length,
                            onReorder: _reorderImages,
                            itemBuilder: (context, index) {
                              return Container(
                                key: ValueKey(_selectedImages[index].path),
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
                                          _selectedImages[index],
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
                                        onTap: () => _removeImage(index),
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
                      TextField(
                        controller: _videoUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Video URL',
                          hintText: 'https://youtube.com/watch?v=... (Press Enter to add)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.video_library),
                          suffixIcon: Icon(Icons.keyboard_return, color: Colors.grey),
                        ),
                        onSubmitted: (_) => _addVideoUrl(),
                        onChanged: (value) {
                          // Auto-add when user pastes a complete URL and stops typing
                          if (value.trim().isNotEmpty && 
                              (value.contains('youtube.com') || 
                               value.contains('youtu.be') || 
                               value.contains('vimeo.com') ||
                               value.contains('http'))) {
                            // Add a small delay to allow user to finish typing
                            Future.delayed(const Duration(milliseconds: 1500), () {
                              if (_videoUrlController.text.trim() == value.trim() && 
                                  value.trim().isNotEmpty) {
                                _addVideoUrl();
                              }
                            });
                          }
                        },
                      ),
                      
                      // Current Video URLs List
                      if (_videoUrls.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Videos (${_videoUrls.length})',
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
                            'Creation Tips',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTipItem(
                        icon: Icons.sports_martial_arts,
                        text: 'Name and style are required fields',
                      ),
                      const SizedBox(height: 8),
                      _buildTipItem(
                        icon: Icons.description,
                        text: 'Tap the description field to open the full editor',
                      ),
                      const SizedBox(height: 8),
                      _buildTipItem(
                        icon: Icons.video_library,
                        text: 'Add YouTube or Vimeo URLs for video demonstrations',
                      ),
                      const SizedBox(height: 8),
                      _buildTipItem(
                        icon: Icons.photo_library,
                        text: 'Add multiple images from gallery or camera',
                      ),
                      const SizedBox(height: 8),
                      _buildTipItem(
                        icon: Icons.lock,
                        text: 'Private katas are only visible to you',
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
