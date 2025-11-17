import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/ohyo_provider.dart';
import '../utils/image_utils.dart';
import '../widgets/enhanced_accessible_text.dart';
import '../core/navigation/app_router.dart';

class CreateOhyoScreen extends ConsumerStatefulWidget {
  const CreateOhyoScreen({super.key});

  @override
  ConsumerState<CreateOhyoScreen> createState() => _CreateOhyoScreenState();
}

class _CreateOhyoScreenState extends ConsumerState<CreateOhyoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _styleController;
  late TextEditingController _urlController;
  bool _isLoading = false;

  final List<File> _selectedImages = [];
  final List<String> _videoUrls = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _styleController = TextEditingController();
    _urlController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _styleController.dispose();
    _urlController.dispose();
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

  void _addVideoUrl(String url) {
    final trimmedUrl = url.trim();
    if (trimmedUrl.isNotEmpty && !_videoUrls.contains(trimmedUrl)) {
      setState(() {
        _videoUrls.add(trimmedUrl);
      });
      _urlController.clear();
    }
  }

  void _removeVideoUrl(String url) {
    setState(() {
      _videoUrls.remove(url);
    });
  }

  Future<void> _createOhyo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🚀 Creating ohyo with data:');
      debugPrint('  Name: ${_nameController.text.trim()}');
      debugPrint('  Description: ${_descriptionController.text.trim()}');
      debugPrint('  Style: ${_styleController.text.trim().isNotEmpty ? _styleController.text.trim() : 'Andere'}');
      debugPrint('  Images: ${_selectedImages.length}');
      debugPrint('  Video URLs: ${_videoUrls.length}');

      await ref
          .read(ohyoNotifierProvider.notifier)
          .createOhyo(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            style: _styleController.text.trim().isNotEmpty
                ? _styleController.text.trim()
                : 'Andere',
            images: _selectedImages.isNotEmpty ? _selectedImages : null,
            videoUrls: _videoUrls.isNotEmpty ? _videoUrls : null,
          );

      debugPrint('✅ Ohyo created successfully');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ohyo succesvol aangemaakt!'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to home screen with ohyo tab selected
        context.go('/home?tab=ohyo');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error creating ohyo: $e');
      debugPrint('Stack trace: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij aanmaken ohyo: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _onWillPop() async {
    // Check if user has made any changes
    final hasChanges = _nameController.text.trim().isNotEmpty ||
                       _descriptionController.text.trim().isNotEmpty ||
                       _styleController.text.trim().isNotEmpty ||
                       _selectedImages.isNotEmpty ||
                       _videoUrls.isNotEmpty;

    if (!hasChanges) return true;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Video URL\'s Toevoegen',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Voer een video URL in en druk op Enter:',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _urlController,
          decoration: const InputDecoration(
            hintText: 'https://www.youtube.com/watch?v=...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.link),
          ),
          onFieldSubmitted: _addVideoUrl,
          textInputAction: TextInputAction.done,
        ),
        if (_videoUrls.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.video_library,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Toegevoegde URLs (${_videoUrls.length})',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._videoUrls.map((url) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(minHeight: 48),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8, top: 2),
                              child: Text(
                                url,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  height: 1.4,
                                ),
                                overflow: TextOverflow.visible,
                                maxLines: 3,
                                softWrap: true,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: IconButton(
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                  maxWidth: 32,
                                  maxHeight: 32,
                                ),
                                icon: const Icon(Icons.delete, size: 16),
                                color: Theme.of(context).colorScheme.error,
                                onPressed: () => _removeVideoUrl(url),
                                tooltip: 'Verwijder URL',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Always show the dialog if there are changes
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
                context.goToHomeOhyo();
              }
            },
            tooltip: 'Terug',
          ),
          title: const Text('Nieuwe Ohyo'),
        ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ohyo Information Section
              Text(
                'Ohyo Informatie',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),

              // Ohyo Name Field
              EnhancedAccessibleTextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ohyo Naam *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sports_martial_arts),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Voer een ohyo naam in';
                  }
                  return null;
                },
                customTTSLabel: 'Ohyo naam invoerveld',
              ),
              const SizedBox(height: 20),

              // Style Field - Text Area
              EnhancedAccessibleTextField(
                controller: _styleController,
                decoration: const InputDecoration(
                  labelText: 'Stijl *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.style),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Voer een stijl in';
                  }
                  return null;
                },
                customTTSLabel: 'Stijl invoerveld',
              ),
              const SizedBox(height: 20),

              // Description Field
              EnhancedAccessibleTextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Beschrijving *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Voer een beschrijving in';
                  }
                  return null;
                },
                customTTSLabel: 'Beschrijving invoerveld',
              ),
              const SizedBox(height: 20),

              // Images Section
              if (_selectedImages.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Geselecteerde Afbeeldingen (${_selectedImages.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: _selectedImages.asMap().entries.map((entry) {
                            final index = entry.key;
                            final image = entry.value;
                            return Container(
                              key: ValueKey(image.path),
                              width: 100,
                              height: 100,
                              margin: const EdgeInsets.only(right: 12),
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: Image.file(
                                        image,
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
                                        color: Theme.of(context).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onPrimary,
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
                                          color: Theme.of(context).colorScheme.error,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          color: Theme.of(context).colorScheme.onError,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
              ],

              // Add Images & Videos Section
              const SizedBox(height: 20),
              Text(
                'Afbeeldingen & Video\'s Toevoegen',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Afbeeldingen',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickImagesFromGallery,
                      icon: const Icon(Icons.photo_library, size: 18),
                      label: const Text("Galerij"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        minimumSize: const Size(0, 60),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _captureImageWithCamera,
                      icon: const Icon(Icons.camera_alt, size: 18),
                      label: const Text("Camera"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        minimumSize: const Size(0, 60),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Video URLs Section
              _buildSimpleVideoUrlSection(),

              const SizedBox(height: 32),

              // Create Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createOhyo,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Ohyo Aanmaken',
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
      ),
    );
  }
}
