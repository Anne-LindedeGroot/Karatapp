import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/kata_model.dart';
import '../providers/kata_provider.dart';
import '../providers/image_provider.dart';
import '../utils/image_utils.dart';
import '../widgets/enhanced_accessible_text.dart';

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
    _nameController = TextEditingController(text: widget.kata.name);
    _descriptionController = TextEditingController(text: widget.kata.description);
    _styleController = TextEditingController(text: widget.kata.style);
    _newUrlController = TextEditingController();

    // Load current images and videos
    _loadCurrentImages();
    _loadCurrentVideos();

    _nameController.addListener(_onTextChanged);
    _descriptionController.addListener(_onTextChanged);
    _styleController.addListener(_onTextChanged);
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

  void _removeExistingImage(int index) {
    debugPrint('Removing existing image at index $index, marking _hasChanges = true');
    setState(() {
      _currentImageUrls.removeAt(index);
      _hasChanges = true;
    });
  }

  Future<void> _loadCurrentImages() async {
    try {
      final imageUrls = await ImageUtils.fetchKataImagesFromBucket(widget.kata.id);
      setState(() {
        _currentImageUrls = _sortImagesByChoInSequence(imageUrls);
        _originalImageUrls = List.from(_currentImageUrls); // Store original URLs
      });
    } catch (e) {
      setState(() {
        _currentImageUrls = _sortImagesByChoInSequence(widget.kata.imageUrls ?? []);
        _originalImageUrls = List.from(_currentImageUrls); // Store original URLs
      });
    }
  }

  /// Sort images according to Cho-in no kata sequence
  List<String> _sortImagesByChoInSequence(List<String> imageUrls) {
    // Cho-in no kata sequence (filename patterns to match)
    const List<String> choInSequence = [
      'Buiging.jpg',           // 1. Opening bow
      'Gedan barai rechts.jpg', // 2. Right downward block
      'Jun zuki rechts.jpg',   // 3. Right front punch
      'Gedan barai links.jpg', // 4. Left downward block
      'Jun zuki links.jpg',    // 5. Left front punch
      'Gedan Barai voor.jpg',  // 6. Forward downward block
      'Jodsn uke links.jpg',   // 7. Left upper block (with typo)
      'Jodan uke rehts.jpg',   // 8. Right upper block (with typo)
      'Jodan uke links 2.jpg', // 9. Second left upper block
      'Gedan barai schuin links.jpg',    // 10. Left diagonal downward block
      'Jun zuki schuin link.jpg',        // 11. Left diagonal front punch
      'Gedan barai schuin rechts.jpg',   // 12. Right diagonal downward block
      'Jun zuki schuin rechts.jpg',      // 13. Right diagonal front punch
      'Gedan barai midden rug.jpg',      // 14. Middle back downward block
      'Junzuki midden rechts.jpg',       // 15. Right middle punch from back
      'Junzuki midden links.jpg',        // 16. Left middle punch from back
      'Junzuki midden rechts 2.jpg',     // 17. Second right middle punch
      'Gedan barai schuin rechts voor.jpg', // 18. Right diagonal forward downward block
      'Junzuki schuin rechts voor.jpg',     // 19. Right diagonal forward punch
      'Gedan Barai schuin links voor.jpg',  // 20. Left diagonal forward downward block
      'Junzyuki schuin links voor.jpg',     // 21. Left diagonal forward punch (with typo)
      'Yehoi.jpg',                        // 22. Kiai movement
      'Buiging 2.jpg',                    // 23. Final bow
    ];

    // Also handle variations with different capitalizations and slight typos
    final List<String> alternativePatterns = [
      'buiging.jpg',
      'gedan barai rechts.jpg',
      'jun zuki rechts.jpg',
      'gedan barai links.jpg',
      'jun zuki links.jpg',
      'gedan barai voor.jpg',
      'jodan uke links.jpg',  // corrected spelling
      'jodan uke rechts.jpg', // corrected spelling
      'jodan uke links 2.jpg',
      'gedan barai schuin links.jpg',
      'jun zuki schuin links.jpg', // corrected
      'gedan barai schuin rechts.jpg',
      'jun zuki schuin rechts.jpg', // corrected
      'gedan barai midden rug.jpg',
      'jun zuki midden rechts.jpg', // corrected
      'jun zuki midden links.jpg',  // corrected
      'jun zuki midden rechts 2.jpg', // corrected
      'gedan barai schuin rechts voor.jpg',
      'jun zuki schuin rechts voor.jpg', // corrected
      'gedan barai schuin links voor.jpg',
      'jun zuki schuin links voor.jpg', // corrected
      'yehoi.jpg',
      'buiging 2.jpg',
    ];

    // Create a map for quick lookup
    final Map<String, int> sequenceMap = {};
    for (int i = 0; i < choInSequence.length; i++) {
      sequenceMap[choInSequence[i].toLowerCase()] = i;
      if (i < alternativePatterns.length) {
        sequenceMap[alternativePatterns[i].toLowerCase()] = i;
      }
    }

    // Sort images based on sequence
    final sortedImages = List<String>.from(imageUrls);
    sortedImages.sort((a, b) {
      // Extract filename from URL
      final filenameA = _extractFilename(a).toLowerCase();
      final filenameB = _extractFilename(b).toLowerCase();

      final indexA = sequenceMap[filenameA] ?? 999;
      final indexB = sequenceMap[filenameB] ?? 999;

      return indexA.compareTo(indexB);
    });

    return sortedImages;
  }

  /// Extract filename from URL or path
  String _extractFilename(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
      // If it's just a filename, return as is
      return url.split('/').last;
    } catch (e) {
      // If parsing fails, assume it's just a filename
      return url.split('/').last;
    }
  }

  void _loadCurrentVideos() {
    setState(() {
      _videoUrls.clear();
      if (widget.kata.videoUrls != null) {
        _videoUrls.addAll(widget.kata.videoUrls!);
      }
    });
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

  void _removeNewImage(int index) {
    setState(() {
      _newSelectedImages.removeAt(index);
      _hasChanges = true;
    });
  }

  void _addVideoUrl(String url) {
    if (url.trim().isNotEmpty) {
      setState(() {
        _videoUrls.add(url.trim());
        _hasChanges = true;
        _newUrlController.clear();
      });
    }
  }

  Future<void> _reorderExistingImages(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _currentImageUrls.removeAt(oldIndex);
      _currentImageUrls.insert(newIndex, item);
      // Note: Image reordering saves automatically, so we don't mark _hasChanges
    });

    // Automatically save the new image order
    try {
      await ref.read(imageNotifierProvider.notifier).reorderImages(
        widget.kata.id,
        _currentImageUrls,
      );

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Afbeeldingsvolgorde opgeslagen'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Revert the local change if save failed
      setState(() {
        if (newIndex > oldIndex) {
          newIndex += 1;
        }
        final item = _currentImageUrls.removeAt(newIndex);
        _currentImageUrls.insert(oldIndex, item);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij opslaan volgorde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  Widget _buildDraggableImage({
    required int index,
    required String? imageUrl,
    required File? imageFile,
    required Color borderColor,
    required VoidCallback onRemove,
    required Future<void> Function(int, int) onReorder,
    required int totalItems,
  }) {
    return LongPressDraggable<int>(
      data: index,
      delay: const Duration(milliseconds: 500),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: imageFile != null
                ? Image.file(imageFile, fit: BoxFit.cover)
                : Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
          ),
        ),
      ),
      childWhenDragging: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.withValues(alpha: 0.5), width: 1),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.withValues(alpha: 0.2),
        ),
        child: Icon(Icons.image, color: Colors.grey.withValues(alpha: 0.5)),
      ),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) => true,
        onAcceptWithDetails: (details) async {
          final draggedIndex = details.data;
          if (draggedIndex != index) {
            await onReorder(draggedIndex, index);
          }
        },
        builder: (context, candidateData, rejectedData) {
          final isHovered = candidateData.isNotEmpty;
          return Column(
            children: [
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(right: 12),
                child: Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isHovered ? borderColor.withValues(alpha: 0.8) : borderColor,
                          width: isHovered ? 3 : 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isHovered ? [
                          BoxShadow(
                            color: borderColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ] : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: imageFile != null
                            ? Image.file(imageFile, fit: BoxFit.cover, width: 96, height: 96)
                            : Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                                width: 96,
                                height: 96,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 96,
                                    height: 96,
                                    color: Colors.grey[200],
                                    child: const Center(child: CircularProgressIndicator()),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 96,
                                    height: 96,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image, color: Colors.grey),
                                  );
                                },
                              ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: borderColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
                    // Remove button for both existing and new images
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red[600],
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (totalItems > 1)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.drag_handle,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteVideoUrl(String url) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('URL Verwijderen?'),
        content: Text('Weet je zeker dat je deze URL wilt verwijderen?\n\n$url'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() {
        _videoUrls.remove(url);
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveChanges() async {
    debugPrint('Save button clicked. _hasChanges: $_hasChanges, _isLoading: $_isLoading');

    if (!_hasChanges) {
      debugPrint('No changes detected, popping screen');
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Starting save process...');
      // Update text fields in database
      await ref.read(kataNotifierProvider.notifier).updateKata(
        kataId: widget.kata.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        style: _styleController.text.trim(),
        videoUrls: _videoUrls.isNotEmpty ? _videoUrls : null,
      );

      // Handle image deletions first
      final removedImages = _originalImageUrls.where((url) => !_currentImageUrls.contains(url)).toList();
      if (removedImages.isNotEmpty) {
        await ImageUtils.deleteMultipleImagesFromSupabase(removedImages);
      }

      // Handle image additions
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

      debugPrint('Save completed successfully');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata succesvol bijgewerkt!'),
          backgroundColor: Colors.green,
        ),
        );
        // Small delay to ensure snackbar is visible before popping
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      debugPrint('Save failed with error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij bijwerken kata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      debugPrint('Resetting loading state');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Wijzigingen Verwerpen?'),
        content: const Text('Je hebt niet-opgeslagen wijzigingen. Weet je zeker dat je wilt vertrekken?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Verwerpen'),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  Widget _buildSimpleVideoUrlSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Video URL\'s',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Add new URL field
            Text(
              'Nieuwe URL toevoegen:',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _newUrlController,
              maxLines: 1,
              decoration: const InputDecoration(
                hintText: 'https://www.youtube.com/watch?v=... (druk op Enter om toe te voegen)',
                border: OutlineInputBorder(),
              ),
              onFieldSubmitted: _addVideoUrl,
            ),

            if (_videoUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Toegevoegde URLs (${_videoUrls.length}):',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _videoUrls.map((url) => Container(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: Text(
                              url,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.delete,
                              size: 16,
                              color: Colors.red[600],
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                            onPressed: () => _confirmDeleteVideoUrl(url),
                          ),
                        ],
                      ),
                    ),
                  ),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (GoRouter.of(context).canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            tooltip: 'Terug',
          ),
          title: const Text('Kata Bewerken'),
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
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kata Information Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kata Informatie',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Name Field
                        EnhancedAccessibleTextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Kata Naam',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.sports_martial_arts),
                          ),
                          customTTSLabel: 'Kata naam invoerveld',
                        ),
                        const SizedBox(height: 16),

                        // Style Field
                        EnhancedAccessibleTextField(
                          controller: _styleController,
                          decoration: const InputDecoration(
                            labelText: 'Stijl',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.style),
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
                            prefixIcon: Icon(Icons.description),
                          ),
                          maxLines: 5,
                          customTTSLabel: 'Beschrijving invoerveld',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // New Images Section
                if (_newSelectedImages.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nieuwe Afbeeldingen om Toe te Voegen (${_newSelectedImages.length})',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
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
                             child: ListView.builder(
                               scrollDirection: Axis.horizontal,
                               itemCount: _newSelectedImages.length,
                               itemBuilder: (context, index) {
                                 return _buildDraggableImage(
                                   index: index,
                                   imageUrl: null,
                                   imageFile: _newSelectedImages[index],
                                   borderColor: Colors.green,
                                   onRemove: () => _removeNewImage(index),
                                   onReorder: _reorderNewImages,
                                   totalItems: _newSelectedImages.length,
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
                          'Afbeeldingen Toevoegen',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.visible,
                          maxLines: 2,
                        ),
                        SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _pickImagesFromGallery,
                                icon: Icon(Icons.photo_library, size: 20),
                                label: const Text(
                                  'Galerij',
                                  style: TextStyle(fontSize: 14),
                                  overflow: TextOverflow.visible,
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                  minimumSize: Size(0, 56),
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _captureImageWithCamera,
                                icon: Icon(Icons.camera_alt, size: 20),
                                label: const Text(
                                  'Camera',
                                  style: TextStyle(fontSize: 14),
                                  overflow: TextOverflow.visible,
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                  minimumSize: Size(0, 56),
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

                // Existing Images Gallery
                if (_currentImageUrls.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Huidige Afbeeldingen (${_currentImageUrls.length})',
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
                             child: ListView.builder(
                               scrollDirection: Axis.horizontal,
                               itemCount: _currentImageUrls.length,
                               itemBuilder: (context, index) {
                                 final imageUrl = _currentImageUrls[index];
                                 return _buildDraggableImage(
                                   index: index,
                                   imageUrl: imageUrl,
                                   imageFile: null,
                                   borderColor: Theme.of(context).colorScheme.primary,
                                   onRemove: () => _removeExistingImage(index),
                                   onReorder: _reorderExistingImages,
                                   totalItems: _currentImageUrls.length,
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

                // Video URLs Section
                _buildSimpleVideoUrlSection(),
                const SizedBox(height: 16),

                // Save Button
                if (_hasChanges) ...[
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Wijzigingen Opslaan',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],

                // Additional spacing
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
