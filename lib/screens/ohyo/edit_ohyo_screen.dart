import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/ohyo_model.dart';
import '../../providers/ohyo_provider.dart';
import '../../utils/image_utils.dart';
import '../../core/navigation/app_router.dart';
import '../../widgets/enhanced_accessible_text.dart';
import '../../providers/accessibility_provider.dart';
import '../../widgets/media_source_bottom_sheet.dart';
import '../../widgets/overflow_safe_widgets.dart';
part 'edit_ohyo_screen_helpers.dart';

class EditOhyoScreen extends ConsumerStatefulWidget {
  final Ohyo ohyo;

  const EditOhyoScreen({
    super.key,
    required this.ohyo,
  });

  @override
  ConsumerState<EditOhyoScreen> createState() => _EditOhyoScreenState();
}

class _EditOhyoScreenState extends ConsumerState<EditOhyoScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _styleController;
  late TextEditingController _newUrlController;
  bool _isLoading = false;
  bool _hasChanges = false;

  List<String> _currentImageUrls = [];
  List<String> _originalImageUrls = []; // Store original URLs to detect deletions
  final List<File> _newSelectedImages = [];
  final List<String> _videoUrls = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ohyo.name);
    _descriptionController = TextEditingController(text: widget.ohyo.description);
    _styleController = TextEditingController(text: widget.ohyo.style);
    _newUrlController = TextEditingController();

    // Load current images and videos
    _loadCurrentImages();
    _loadCurrentVideos();

    _nameController.addListener(_onTextChanged);
    _descriptionController.addListener(_onTextChanged);
    _styleController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakScreenContent();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _styleController.dispose();
    _newUrlController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    debugPrint('Text changed, marking _hasChanges = true');
    setState(() {
      _hasChanges = true;
    });
  }

  Future<void> _speakScreenContent() async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);

    if (!accessibilityState.isTextToSpeechEnabled || !mounted) {
      return;
    }

    final content = _buildScreenContentText();
    await accessibilityNotifier.speak(content);
  }

  void _removeExistingImage(int index) {
    debugPrint('Removing existing image at index $index, marking _hasChanges = true');
    setState(() {
      _currentImageUrls.removeAt(index);
      _hasChanges = true;
    });
  }


  Future<void> _loadCurrentImages() async {
    try {
      final imageUrls = await ImageUtils.fetchOhyoImagesFromBucket(widget.ohyo.id);
      if (!mounted) return;
      setState(() {
        _currentImageUrls = imageUrls;
        _originalImageUrls = List.from(_currentImageUrls); // Store original URLs
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _currentImageUrls = widget.ohyo.imageUrls ?? [];
        _originalImageUrls = List.from(_currentImageUrls); // Store original URLs
      });
    }
  }

  void _loadCurrentVideos() {
    setState(() {
      _videoUrls.clear();
      if (widget.ohyo.videoUrls != null) {
        _videoUrls.addAll(widget.ohyo.videoUrls!);
      }
    });
  }

  Future<void> _pickImagesFromGallery() async {
    try {
      final images = await ImageUtils.pickMultipleImagesFromGallery();
      if (images.isNotEmpty) {
        setState(() {
          _newSelectedImages.addAll(images);
          _hasChanges = true;
        });
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _captureImageWithCamera() async {
    try {
      final image = await ImageUtils.captureImageWithCamera(context: context);
      if (image != null) {
        setState(() {
          _newSelectedImages.add(image);
          _hasChanges = true;
        });
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error capturing image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MediaSourceBottomSheet(
        title: 'Foto toevoegen',
        onCameraSelected: () {
          Navigator.pop(context);
          _captureImageWithCamera();
        },
        onGallerySelected: () {
          Navigator.pop(context);
          _pickImagesFromGallery();
        },
      ),
    );
  }

  void _removeNewImage(int index) {
    setState(() {
      _newSelectedImages.removeAt(index);
    });
  }

  void _addVideoUrl() {
    final url = _newUrlController.text.trim();
    if (url.isNotEmpty && !_videoUrls.contains(url)) {
      setState(() {
        _videoUrls.add(url);
        _newUrlController.clear();
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

  void _reorderExistingImages(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _currentImageUrls.removeAt(oldIndex);
      _currentImageUrls.insert(newIndex, item);
      _hasChanges = true;
    });
  }

  void _reorderNewImages(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _newSelectedImages.removeAt(oldIndex);
      _newSelectedImages.insert(newIndex, item);
      _hasChanges = true;
    });
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (!mounted) return; // Check mounted before ref usage

      final ohyoNotifier = ref.read(ohyoNotifierProvider.notifier);

      // Capture router before async operation to avoid context issues
      final router = GoRouter.of(context);

      // Identify deleted images
      final deletedImages = _originalImageUrls.where((url) => !_currentImageUrls.contains(url)).toList();
      final removeAllImages = _currentImageUrls.isEmpty && _originalImageUrls.isNotEmpty;
      final hasOrderChanged = _currentImageUrls.length == _originalImageUrls.length &&
          _currentImageUrls.asMap().entries.any((entry) => entry.value != _originalImageUrls[entry.key]);
      final shouldReorder = _currentImageUrls.isNotEmpty && (hasOrderChanged || deletedImages.isNotEmpty);

      // Update ohyo with new data
      debugPrint('Save: Starting ohyo update operation');
      await ohyoNotifier.updateOhyo(
        widget.ohyo.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        style: _styleController.text.trim(),
        newImages: _newSelectedImages,
        videoUrls: _videoUrls,
        removeAllImages: removeAllImages,
        deletedImageUrls: removeAllImages ? [] : deletedImages,
        orderedImageUrls: shouldReorder ? _currentImageUrls : null,
        existingImageCount: _currentImageUrls.length,
      );
      debugPrint('Save: Ohyo update operation completed successfully');

      // Show success message and navigate immediately
      debugPrint('Save: Showing success message and navigating immediately');

      // Show success message
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ohyo succesvol bijgewerkt!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Navigate immediately - use the captured router to avoid context issues
      debugPrint('Navigation: Executing immediate navigation to home ohyo');
      router.go('/home?tab=ohyo');
      debugPrint('Navigation: GoRouter.go() executed successfully');

      // Reset changes flag after successful navigation (only if still mounted)
      if (mounted) {
        setState(() {
          _hasChanges = false; // Reset changes flag after successful save
        });
      }
    } catch (e) {
      debugPrint('Error saving changes: $e');
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving changes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted && context.mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bewerk ${widget.ohyo.name}'),
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
              tooltip: 'Wijzigingen Opslaan',
            ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_hasChanges) {
              showDialog(
                context: context,
                builder: (context) => OverflowSafeDialog(
                  title: 'Niet-opgeslagen wijzigingen',
                  child: Text(
                    'Je hebt niet-opgeslagen wijzigingen. Weet je zeker dat je wilt teruggaan?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Blijven'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        context.goToHomeOhyo(); // Navigate to home ohyo tab
                      },
                      child: Text('Teruggaan'),
                    ),
                  ],
                ),
              );
            } else {
              context.goToHomeOhyo();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name Field
              EnhancedAccessibleTextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ohyo Naam',
                  border: OutlineInputBorder(),
                ),
                customTTSLabel: 'Ohyo naam invoerveld',
              ),
              const SizedBox(height: 16),

              // Style Field
              EnhancedAccessibleTextField(
                controller: _styleController,
                decoration: const InputDecoration(
                  labelText: 'Stijl',
                  border: OutlineInputBorder(),
                ),
                customTTSLabel: 'Stijl invoerveld',
              ),
              const SizedBox(height: 16),

              // Description Field
              EnhancedAccessibleTextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Beschrijving',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                customTTSLabel: 'Beschrijving invoerveld',
              ),
              const SizedBox(height: 16),

              // Image Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Afbeeldingen',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _pickImagesFromGallery,
                              icon: const Icon(Icons.photo_library, size: 20),
                              label: const Text(
                                'Galerij',
                                style: TextStyle(fontSize: 14),
                                overflow: TextOverflow.visible,
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
                              onPressed: _showImageSourceSheet,
                              icon: const Icon(Icons.camera_alt, size: 20),
                              label: const Text(
                                'Camera',
                                style: TextStyle(fontSize: 14),
                                overflow: TextOverflow.visible,
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

              // New Selected Images
              if (_newSelectedImages.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nieuwe Afbeeldingen (${_newSelectedImages.length})',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Houd een afbeelding ingedrukt om te slepen en te herordenen',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ReorderableListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _newSelectedImages.length,
                            itemBuilder: (context, index) {
                              final imageFile = _newSelectedImages[index];
                              return _buildDraggableImage(
                                key: ValueKey(imageFile.path),
                                index: index,
                                imageUrl: '',
                                imageFile: imageFile,
                                borderColor: Colors.green,
                                onRemove: () => _removeNewImage(index),
                                onReorder: _reorderNewImages,
                                totalItems: _newSelectedImages.length,
                              );
                            },
                            onReorder: _reorderNewImages,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Existing Images Gallery
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
                                'Huidige Afbeeldingen (${_currentImageUrls.length})',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Houd een afbeelding ingedrukt om te slepen en te herordenen',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ReorderableListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _currentImageUrls.length,
                            itemBuilder: (context, index) {
                              final imageUrl = _currentImageUrls[index];
                              return _buildDraggableImage(
                                key: ValueKey(imageUrl),
                                index: index,
                                imageUrl: imageUrl,
                                imageFile: null,
                                borderColor: Theme.of(context).colorScheme.primary,
                                onRemove: () => _removeExistingImage(index),
                                onReorder: _reorderExistingImages,
                                totalItems: _currentImageUrls.length,
                              );
                            },
                            onReorder: _reorderExistingImages,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Video URLs Section
              _buildSimpleVideoUrlSection(),
              const SizedBox(height: 16),

              // Save Button - Always visible
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _hasChanges ? Colors.blue : Colors.grey,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text(
                          _hasChanges ? 'Wijzigingen Opslaan' : 'Geen Wijzigingen',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),

              // Additional spacing
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
