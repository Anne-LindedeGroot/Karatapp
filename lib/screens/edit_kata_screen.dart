import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/kata_model.dart';
import '../providers/kata_provider.dart';
import '../providers/image_provider.dart';
import '../utils/image_utils.dart';
import '../widgets/image_gallery.dart';
import '../widgets/video_url_input_widget.dart';
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
  
  List<String> _currentImageUrls = [];
  final List<File> _newSelectedImages = [];
  final List<String> _videoUrls = [];
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.kata.name);
    _descriptionController = TextEditingController(text: widget.kata.description);
    _styleController = TextEditingController(text: widget.kata.style);
    
    // Load current images and videos
    _loadCurrentImages();
    _loadCurrentVideos();
    
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

  Future<void> _deleteExistingImage(String imageUrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Afbeelding Verwijderen?'),
        content: const Text('Dit zal de afbeelding permanent verwijderen. Dit kan niet ongedaan worden gemaakt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Verwijderen'),
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
                  Text('Afbeelding verwijderen...'),
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
            content: Text('Afbeelding succesvol verwijderd'),
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
              content: Text('Fout bij verwijderen afbeelding: $e'),
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


  Future<void> _saveChanges() async {
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update text fields in database
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
          content: Text('Kata succesvol bijgewerkt!'),
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
          content: Text('Fout bij bijwerken kata: $e'),
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
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            minWidth: 300,
            minHeight: 400,
          ),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Beschrijving Bewerken',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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
                  child: EnhancedAccessibleTextField(
                    controller: dialogController,
                    decoration: const InputDecoration(
                      hintText: 'Voer kata beschrijving in...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(16),
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(fontSize: 16),
                    customTTSLabel: 'Kata beschrijving invoerveld',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuleren'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, dialogController.text),
                      child: const Text('Opslaan'),
                    ),
                  ],
                ),
              ],
            ),
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
                        'Kata Informatie',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                      GestureDetector(
                        onTap: () => _openDescriptionDialog(),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Beschrijving',
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
                                    ? 'Tik om beschrijving te bewerken...' 
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
                                'Huidige Afbeeldingen (${_currentImageUrls.length})',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton.icon(
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
                                'Galerij',
                                style: TextStyle(fontSize: 14),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                backgroundColor: Colors.blue.withOpacity(0.1),
                                foregroundColor: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 140,
                          child: ReorderableListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _currentImageUrls.length,
                            onReorder: _reorderCurrentImages,
                            itemBuilder: (context, index) {
                              return Container(
                                key: ValueKey(_currentImageUrls[index]),
                                width: 120,
                                height: 120,
                                margin: const EdgeInsets.only(right: 12),
                                child: Stack(
                                  children: [
                                    // Main image container with improved styling
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: CachedNetworkImage(
                                          imageUrl: _currentImageUrls[index],
                                          fit: BoxFit.cover,
                                          width: 120,
                                          height: 120,
                                          placeholder: (context, url) => Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: Colors.grey[200],
                                            child: const Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.error_outline,
                                                  color: Colors.red,
                                                  size: 24,
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Fout',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Position indicator with improved styling
                                    Positioned(
                                      top: 6,
                                      left: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Delete button with improved styling
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: GestureDetector(
                                        onTap: () => _deleteExistingImage(_currentImageUrls[index]),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red[600],
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Drag handle with improved styling
                                    Positioned(
                                      bottom: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(6),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.drag_handle,
                                          color: Colors.white,
                                          size: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Houd ingedrukt en sleep om afbeeldingen te herordenen',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
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
                          'Nieuwe Afbeeldingen om Toe te Voegen (${_newSelectedImages.length})',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Houd ingedrukt en sleep om afbeeldingen te herordenen',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 140,
                          child: ReorderableListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _newSelectedImages.length,
                            onReorder: _reorderNewImages,
                            itemBuilder: (context, index) {
                              return Container(
                                key: ValueKey(_newSelectedImages[index].path),
                                width: 120,
                                height: 120,
                                margin: const EdgeInsets.only(right: 12),
                                child: Stack(
                                  children: [
                                    // Main image container with improved styling
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.green.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(
                                          _newSelectedImages[index],
                                          fit: BoxFit.cover,
                                          width: 120,
                                          height: 120,
                                        ),
                                      ),
                                    ),
                                    // Position indicator with improved styling
                                    Positioned(
                                      top: 6,
                                      left: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.green[600],
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Remove button with improved styling
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: GestureDetector(
                                        onTap: () => _removeNewImage(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red[600],
                                            borderRadius: BorderRadius.circular(12),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.2),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Drag handle with improved styling
                                    Positioned(
                                      bottom: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(6),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.drag_handle,
                                          color: Colors.white,
                                          size: 10,
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
                        'Afbeeldingen Toevoegen',
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
                                'Galerij',
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
              VideoUrlInputWidget(
                videoUrls: _videoUrls,
                onVideoUrlsChanged: (urls) {
                  setState(() {
                    _videoUrls.clear();
                    _videoUrls.addAll(urls);
                    _hasChanges = true;
                  });
                },
                title: 'Video URL\'s',
              ),
              const SizedBox(height: 16),

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
                            'Bewerkingstips',
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
                        text: 'Houd ingedrukt en sleep afbeeldingen om ze te herordenen',
                      ),
                      const SizedBox(height: 8),
                      _buildTipItem(
                        icon: Icons.description,
                        text: 'Tik op het beschrijvingsveld om de volledige editor te openen',
                      ),
                      const SizedBox(height: 8),
                      _buildTipItem(
                        icon: Icons.save,
                        text: 'Wijzigingen worden automatisch gedetecteerd en opgeslagen',
                      ),
                      const SizedBox(height: 8),
                      _buildTipItem(
                        icon: Icons.photo_library,
                        text: 'Voeg meerdere afbeeldingen toe vanuit galerij of camera',
                      ),
                      const SizedBox(height: 8),
                      _buildTipItem(
                        icon: Icons.video_library,
                        text: 'Voeg video URL\'s toe van verschillende platforms of bewerk ze',
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
