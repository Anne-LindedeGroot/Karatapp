import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../models/forum_models.dart';
import '../providers/forum_provider.dart';
import '../providers/accessibility_provider.dart';
import '../widgets/enhanced_accessible_text.dart';
import '../widgets/media_source_bottom_sheet.dart';
import '../utils/image_utils.dart';

class CreateForumPostScreen extends ConsumerStatefulWidget {
  const CreateForumPostScreen({super.key});

  @override
  ConsumerState<CreateForumPostScreen> createState() => _CreateForumPostScreenState();
}

class _CreateForumPostScreenState extends ConsumerState<CreateForumPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  ForumCategory _selectedCategory = ForumCategory.general;
  bool _isSubmitting = false;
  final List<File> _selectedImages = [];
  final List<File> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    // Automatically speak the screen content when it opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakScreenContent();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _speakScreenContent() async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);

    // Only speak if TTS is enabled
    if (accessibilityState.isTextToSpeechEnabled && mounted) {
      final content = _buildScreenContentText();
      await accessibilityNotifier.speak(content);
    }
  }

  String _buildScreenContentText() {
    final List<String> contentParts = [];

    contentParts.add('Nieuw Forum Bericht Maken');
    contentParts.add('Scherm geopend voor het maken van een nieuw forum bericht');

    contentParts.add('Categorie sectie');
    contentParts.add('Selecteer een categorie voor je bericht');
    contentParts.add('Beschikbare categorieën zijn: Algemeen, Kata Verzoeken, Technieken, Evenementen, en Feedback');
    contentParts.add('Momenteel geselecteerd: ${_selectedCategory.displayName}');

    contentParts.add('Titel sectie');
    contentParts.add('Voer een duidelijke beschrijvende titel in voor je bericht');
    contentParts.add('Titel moet minimaal 5 en maximaal 100 karakters zijn');

    contentParts.add('Inhoud sectie');
    contentParts.add('Schrijf de inhoud van je bericht');
    contentParts.add('Inhoud moet minimaal 10 en maximaal 5000 karakters zijn');

    contentParts.add('Community richtlijnen');
    contentParts.add('Wees respectvol en beleefd naar andere leden');
    contentParts.add('Blijf bij het onderwerp en kies de juiste categorie');
    contentParts.add('Gebruik duidelijke en beschrijvende titels');
    contentParts.add('Zoek voordat je post om duplicaten te voorkomen');
    contentParts.add('Volg de juiste karate etiquette en terminologie');

    contentParts.add('Gebruik de Bericht Maken knop onderaan om je bericht te plaatsen');

    return contentParts.join('. ');
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(forumNotifierProvider.notifier).createPost(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        category: _selectedCategory,
        imageFiles: _selectedImages,
        fileFiles: _selectedFiles,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bericht succesvol aangemaakt!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij aanmaken bericht: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _pickImagesFromGallery() async {
    final images = await ImageUtils.pickMultipleImagesFromGallery();
    if (images.isEmpty) return;
    setState(() {
      _selectedImages.addAll(images);
    });
  }

  Future<void> _captureImageWithCamera() async {
    final image = await ImageUtils.captureImageWithCamera(context: context);
    if (image == null) return;
    setState(() {
      _selectedImages.add(image);
    });
  }

  void _removeSelectedImage(File image) {
    setState(() {
      _selectedImages.remove(image);
    });
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'txt',
        'csv',
        'rtf',
        'zip',
        'rar',
        '7z',
        'jpg',
        'jpeg',
        'png',
        'gif',
        'webp',
        'heic',
        'heif',
        'mp4',
        'mov',
        'mp3',
        'wav',
      ],
    );
    if (result == null || result.files.isEmpty) return;
    final files = result.files
        .where((file) => file.path != null)
        .map((file) => File(file.path!))
        .toList();
    if (files.isEmpty) return;
    setState(() {
      _selectedFiles.addAll(files);
    });
  }

  void _removeSelectedFile(File file) {
    setState(() {
      _selectedFiles.remove(file);
    });
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return MediaSourceBottomSheet(
          title: 'Afbeelding toevoegen',
          onCameraSelected: () async {
            Navigator.pop(context);
            await _captureImageWithCamera();
          },
          onGallerySelected: () async {
            Navigator.pop(context);
            await _pickImagesFromGallery();
          },
        );
      },
    );
  }

  Color _getCategoryColor(ForumCategory category) {
    switch (category) {
      case ForumCategory.general:
        return Colors.blue;
      case ForumCategory.kataRequests:
        return Colors.green;
      case ForumCategory.techniques:
        return Colors.orange;
      case ForumCategory.events:
        return Colors.purple;
      case ForumCategory.feedback:
        return Colors.red;
    }
  }

  Color _getCategoryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  String _getCategoryDescription(ForumCategory category) {
    switch (category) {
      case ForumCategory.general:
        return 'Algemene discussies over karate en vechtsporten';
      case ForumCategory.kataRequests:
        return 'Vraag nieuwe kata\'s aan om toe te voegen aan de app';
      case ForumCategory.techniques:
        return 'Deel en bespreek karate technieken en tips';
      case ForumCategory.events:
        return 'Aankondigingen over karate evenementen en competities';
      case ForumCategory.feedback:
        return 'Feedback en suggesties voor de app';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nieuw Bericht Maken'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Main form content
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category selection
                      const Text(
                        'Categorie',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: ForumCategory.values.map((category) {
                            final isSelected = _selectedCategory == category;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _getCategoryColor(category).withValues(alpha: 0.1)
                                      : null,
                                  border: category != ForumCategory.values.last
                                      ? Border(
                                          bottom: BorderSide(color: Colors.grey.shade300),
                                        )
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? _getCategoryColor(category)
                                              : Colors.grey,
                                          width: 2,
                                        ),
                                        color: isSelected
                                            ? _getCategoryColor(category)
                                            : Colors.transparent,
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 14,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: _getCategoryColor(category),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  category.displayName,
                                                  style: TextStyle(
                                                    color: _getCategoryTextColor(context),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _getCategoryDescription(category),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title field
                      const Text(
                        'Titel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      EnhancedAccessibleTextField(
                        controller: _titleController,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Voer een beschrijvende titel in voor je bericht',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Voer een titel in';
                          }
                          if (value.trim().length < 5) {
                            return 'Titel moet minimaal 5 karakters lang zijn';
                          }
                          if (value.trim().length > 100) {
                            return 'Titel moet minder dan 100 karakters zijn';
                          }
                          return null;
                        },
                        maxLength: 100,
                        customTTSLabel: 'Titel invoerveld',
                      ),
                      const SizedBox(height: 16),

                      // Content field
                      const Text(
                        'Inhoud',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      EnhancedAccessibleTextField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          hintText: 'Schrijf hier de inhoud van je bericht...',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 8,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Voer inhoud in';
                          }
                          if (value.trim().length < 10) {
                            return 'Inhoud moet minimaal 10 karakters lang zijn';
                          }
                          if (value.trim().length > 5000) {
                            return 'Inhoud moet minder dan 5000 karakters zijn';
                          }
                          return null;
                        },
                        maxLength: 5000,
                        customTTSLabel: 'Inhoud invoerveld',
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Afbeeldingen (optioneel)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _showImageSourceSheet,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(
                          _selectedImages.isEmpty
                              ? 'Afbeeldingen toevoegen'
                              : 'Meer afbeeldingen toevoegen',
                        ),
                      ),
                      if (_selectedImages.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedImages.map((image) {
                            return Stack(
                              alignment: Alignment.topRight,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    image,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _removeSelectedImage(image),
                                  child: Container(
                                    margin: const EdgeInsets.all(4),
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Text(
                        'Bestanden (pdf/doc) (optioneel)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _pickFiles,
                        icon: const Icon(Icons.attach_file),
                        label: Text(
                          _selectedFiles.isEmpty
                              ? 'Bestanden toevoegen'
                              : 'Meer bestanden toevoegen',
                        ),
                      ),
                      if (_selectedFiles.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Column(
                          children: _selectedFiles.map((file) {
                            final fileName = file.path.split('/').last;
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.description_outlined),
                              title: Text(
                                fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => _removeSelectedFile(file),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Guidelines
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue[700], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Community Richtlijnen',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '• Wees respectvol en beleefd naar andere leden\n'
                              '• Blijf bij het onderwerp en kies de juiste categorie\n'
                              '• Gebruik duidelijke en beschrijvende titels\n'
                              '• Zoek voordat je post om duplicaten te voorkomen\n'
                              '• Volg de juiste karate etiquette en terminologie',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Add bottom padding to ensure content is not hidden
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),

            // Fixed submit button at bottom
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitPost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getCategoryColor(_selectedCategory),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Bericht Aanmaken...'),
                          ],
                        )
                      : const Text(
                          'Bericht Maken',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
