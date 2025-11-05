import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/kata_provider.dart';
import '../providers/accessibility_provider.dart';
import '../utils/image_utils.dart';
import '../widgets/video_url_input_widget.dart';
import '../widgets/global_tts_overlay.dart';
import '../widgets/tts_clickable_text.dart';
import '../widgets/enhanced_accessible_text.dart';
import '../widgets/overflow_safe_widgets.dart';

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
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight + 40), // Extra height for large text
        child: AppBar(
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nieuwe Kata',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Maken',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          toolbarHeight: kToolbarHeight + 40,
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: OverflowSafeColumn(
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
              EnhancedAccessibleTextField(
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
                customTTSLabel: 'Kata naam invoerveld',
              ),
              const SizedBox(height: 20),

              // Style Field
              EnhancedAccessibleTextField(
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
                customTTSLabel: 'Stijl invoerveld',
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
                      child: AccessibleOverflowSafeText(
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
              OverflowSafeRow(
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

              // Additional spacing for better scrolling experience
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Check if buttons would fit side by side
              final buttonWidth = (constraints.maxWidth - 16) / 2; // Account for spacing
              const minButtonWidth = 120.0;

              if (buttonWidth >= minButtonWidth) {
                // Buttons fit side by side
                return Row(
                  children: [
                    Expanded(
                      child: OverflowSafeButton(
                        onPressed: () {
                          if (GoRouter.of(context).canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                        child: const Text(
                          'Annuleren',
                          overflow: TextOverflow.visible,
                          maxLines: 2,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: OverflowSafeButton(
                        onPressed: _isLoading ? null : _createKata,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Kata Opslaan',
                                overflow: TextOverflow.visible,
                                maxLines: 2,
                              ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Stack buttons vertically for better accessibility
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OverflowSafeButton(
                      onPressed: _isLoading ? null : _createKata,
                      fullWidth: true,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Kata Opslaan',
                              overflow: TextOverflow.visible,
                              maxLines: 2,
                            ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OverflowSafeButton(
                      onPressed: () => Navigator.of(context).pop(),
                      fullWidth: true,
                      child: const Text(
                        'Annuleren',
                        overflow: TextOverflow.visible,
                        maxLines: 2,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
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
                    child: TTSClickableText(
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
              Expanded(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: 200,
                      maxHeight: 400,
                    ),
                    child: EnhancedAccessibleTextField(
                      controller: widget.controller,
                      decoration: const InputDecoration(
                        hintText: 'Voer kata beschrijving in...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(16),
                      ),
                      maxLines: null,
                      minLines: 6,
                      expands: false,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(fontSize: 16),
                      customTTSLabel: 'Kata beschrijving invoerveld',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TTSClickableWidget(
                    ttsText: 'Annuleren knop',
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuleren'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TTSClickableWidget(
                    ttsText: 'Opslaan knop',
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, widget.controller.text),
                      child: const Text('Opslaan'),
                    ),
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
