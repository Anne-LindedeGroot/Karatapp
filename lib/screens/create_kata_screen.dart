import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/kata_provider.dart';
import '../providers/accessibility_provider.dart';
import '../utils/image_utils.dart';
import '../widgets/video_url_input_widget.dart';
import '../widgets/global_tts_overlay.dart';

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

  final List<File> _selectedImages = [];
  final List<String> _videoUrls = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _styleController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _styleController.dispose();
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


  Future<void> _createKata() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(kataNotifierProvider.notifier)
          .addKata(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            style: _styleController.text.trim(),
            images: _selectedImages.isNotEmpty ? _selectedImages : null,
            videoUrls: _videoUrls.isNotEmpty ? _videoUrls : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kata succesvol aangemaakt!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij aanmaken kata: $e'),
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
    final TextEditingController dialogController = TextEditingController(
      text: _descriptionController.text,
    );

    // Build the dialog content text for TTS
    final String dialogContent = _buildDescriptionDialogContent(dialogController.text);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => DialogTTSOverlay(
        child: DescriptionEditDialog(
          controller: dialogController,
          initialContent: dialogContent,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _descriptionController.text = result;
      });
    }
  }

  String _buildDescriptionDialogContent(String currentText) {
    final List<String> contentParts = [];

    contentParts.add('Kata beschrijving bewerken');
    contentParts.add('Dialoog geopend voor het bewerken van de kata beschrijving');

    if (currentText.isNotEmpty) {
      contentParts.add('Huidige beschrijving: $currentText');
    } else {
      contentParts.add('Geen beschrijving ingevuld');
    }

    contentParts.add('Gebruik het tekstveld om de beschrijving te bewerken');
    contentParts.add('Gebruik de Annuleren knop om te annuleren');
    contentParts.add('Gebruik de Opslaan knop om de wijzigingen op te slaan');

    return contentParts.join('. ');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              // Check if user has made any changes
              final hasChanges = _nameController.text.trim().isNotEmpty ||
                                 _descriptionController.text.trim().isNotEmpty ||
                                 _styleController.text.trim().isNotEmpty ||
                                 _selectedImages.isNotEmpty ||
                                 _videoUrls.isNotEmpty;

              if (!hasChanges) {
                if (mounted && GoRouter.of(context).canPop()) {
                  context.pop();
                } else if (mounted) {
                  context.go('/home');
                }
                return;
              }

              // Show confirmation dialog for unsaved changes
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

              if (shouldDiscard == true && mounted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    if (GoRouter.of(context).canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  }
                });
              }
            },
            tooltip: 'Terug',
          ),
          title: const Text('Nieuwe Kata'),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Basic Information Section
              Text(
                'Kata Informatie',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),

              // Kata Name Field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Kata Naam *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sports_martial_arts),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Voer een kata naam in';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Style Field
              TextFormField(
                controller: _styleController,
                decoration: const InputDecoration(
                  labelText: 'Stijl *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.style),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Voer een stijl in';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Description Field
              Text(
                'Beschrijving *',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _openDescriptionDialog(),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.outline
                          : Colors.grey,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      hintText: 'Tik om beschrijving toe te voegen...',
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.description),
                      suffixIcon: Icon(Icons.edit),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 80),
                      width: double.infinity,
                      child: Text(
                        _descriptionController.text.isEmpty
                            ? 'Tik om beschrijving toe te voegen...'
                            : _descriptionController.text,
                        style: TextStyle(
                          color: _descriptionController.text.isEmpty
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ),
                ),
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

              // Video URLs Section - Now positioned under images
              VideoUrlInputWidget(
                videoUrls: _videoUrls,
                onVideoUrlsChanged: (urls) {
                  setState(() {
                    _videoUrls.clear();
                    _videoUrls.addAll(urls);
                  });
                },
                title: 'Video URL\'s Toevoegen',
              ),

              const SizedBox(height: 32),

              // Create Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createKata,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Kata Aanmaken',
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

class DescriptionEditDialog extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String initialContent;

  const DescriptionEditDialog({
    super.key,
    required this.controller,
    required this.initialContent,
  });

  @override
  ConsumerState<DescriptionEditDialog> createState() => _DescriptionEditDialogState();
}

class _DescriptionEditDialogState extends ConsumerState<DescriptionEditDialog> {
  @override
  void initState() {
    super.initState();
    // Automatically speak the dialog content when it opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakDialogContent();
    });
  }

  Future<void> _speakDialogContent() async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);

    // Only speak if TTS is enabled
    if (accessibilityState.isTextToSpeechEnabled && mounted) {
      await accessibilityNotifier.speak(widget.initialContent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                      'Kata Beschrijving',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: SingleChildScrollView(
                  child: TextField(
                    controller: widget.controller,
                    decoration: const InputDecoration(
                      hintText: 'Voer kata beschrijving in...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(16),
                    ),
                    maxLines: 6,
                    minLines: 6,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(fontSize: 16),
                  ),
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
                    onPressed: () => Navigator.pop(context, widget.controller.text),
                    child: const Text('Opslaan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
