import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/kata_provider.dart';
import '../../utils/image_utils.dart';
import '../../widgets/enhanced_accessible_text.dart';

class HomeScreenAddKataDialog extends ConsumerStatefulWidget {
  const HomeScreenAddKataDialog({super.key});

  @override
  ConsumerState<HomeScreenAddKataDialog> createState() => _HomeScreenAddKataDialogState();
}

class _HomeScreenAddKataDialogState extends ConsumerState<HomeScreenAddKataDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _styleController = TextEditingController();
  final TextEditingController _videoUrlController = TextEditingController();
  
  List<File> selectedImages = [];
  List<String> videoUrls = [];
  bool isProcessing = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _styleController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  void _addVideoUrl() {
    final url = _videoUrlController.text.trim();
    if (url.isNotEmpty && !videoUrls.contains(url)) {
      setState(() {
        videoUrls.add(url);
        _videoUrlController.clear();
      });
    }
  }

  Future<void> _createKata() async {
    setState(() {
      isProcessing = true;
    });

    try {
      await ref.read(kataNotifierProvider.notifier).addKata(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        style: _styleController.text.trim().isNotEmpty
            ? _styleController.text.trim()
            : 'Unknown',
        images: selectedImages.isNotEmpty ? selectedImages : null,
        videoUrls: videoUrls.isNotEmpty ? videoUrls : null,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              selectedImages.isNotEmpty
                  ? 'Kata "${_nameController.text}" created with ${selectedImages.length} image(s)!'
                  : 'Kata "${_nameController.text}" created!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Refresh kata list
      ref.read(kataNotifierProvider.notifier).refreshKatas();
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
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.9,
        maxHeight: MediaQuery.of(context).size.height * 0.8,
        minWidth: 300,
      ),
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Container(
          padding: const EdgeInsets.only(bottom: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: double.infinity,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sports_martial_arts,
                  color: Colors.blue,
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Nieuwe Kata\nToevoegen",
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    textAlign: TextAlign.left,
                  ),
                ),
              ],
            ),
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 8),
                // Basic Information Section
                Text(
                  "Basis Informatie",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 12),
                EnhancedAccessibleTextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Kata Naam",
                    hintText: "Voer kata naam in",
                    prefixIcon: const Icon(
                      Icons.sports_martial_arts,
                      color: Colors.blue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      // Trigger rebuild to update button state
                    });
                  },
                  customTTSLabel: 'Kata naam invoerveld',
                ),
                SizedBox(height: 16),
                EnhancedAccessibleTextField(
                  controller: _styleController,
                  decoration: InputDecoration(
                    labelText: "Stijl",
                    hintText: "Voer karate stijl in (bijv. Wado Ryu)",
                    prefixIcon: const Icon(
                      Icons.style,
                      color: Colors.blue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                  ),
                  customTTSLabel: 'Stijl invoerveld',
                ),
                SizedBox(height: 16),
                EnhancedAccessibleTextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: "Beschrijving",
                    hintText: "Voer kata beschrijving in",
                    prefixIcon: const Icon(
                      Icons.description,
                      color: Colors.blue,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blue,
                        width: 2,
                      ),
                    ),
                  ),
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                  customTTSLabel: 'Beschrijving invoerveld',
                ),
                SizedBox(height: 20),

                // Images section
                Row(
                  children: [
                    const Icon(
                      Icons.photo_library,
                      color: Colors.blue,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Afbeeldingen (${selectedImages.length})",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Image picker buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isProcessing
                            ? null
                            : () async {
                                final images = await ImageUtils.pickMultipleImagesFromGallery();
                                if (images.isNotEmpty) {
                                  setState(() {
                                    selectedImages.addAll(images);
                                  });
                                }
                              },
                        icon: const Icon(Icons.photo_library, size: 18),
                        label: const Text("Galerij"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isProcessing
                            ? null
                            : () async {
                                final image = await ImageUtils.captureImageWithCamera();
                                if (image != null) {
                                  setState(() {
                                    selectedImages.add(image);
                                  });
                                }
                              },
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text("Camera"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),

                // Selected images preview with reordering
                if (selectedImages.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${selectedImages.length} afbeelding(en) geselecteerd',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(height: 8),
                        SizedBox(
                          height: 100,
                          child: ReorderableListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: selectedImages.length,
                            onReorder: (int oldIndex, int newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) {
                                  newIndex -= 1;
                                }
                                final item = selectedImages.removeAt(oldIndex);
                                selectedImages.insert(newIndex, item);
                              });
                            },
                            itemBuilder: (context, index) {
                              return Container(
                                key: ValueKey(selectedImages[index].path),
                                width: 80,
                                height: 80,
                                margin: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.blue,
                                          width: 2,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: Image.file(
                                          selectedImages[index],
                                          fit: BoxFit.cover,
                                          width: 76,
                                          height: 76,
                                        ),
                                      ),
                                    ),
                                    // Position indicator
                                    Positioned(
                                      top: 2,
                                      left: 2,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                    ),
                                    // Remove button
                                    Positioned(
                                      top: 2,
                                      right: 2,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedImages.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Drag handle
                                    Positioned(
                                      bottom: 2,
                                      right: 2,
                                      child: Container(
                                        padding: const EdgeInsets.all(1),
                                        decoration: BoxDecoration(
                                          color: Colors.black54,
                                          borderRadius: BorderRadius.circular(4),
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
                        SizedBox(height: 4),
                        Text(
                          'Houd ingedrukt en sleep om te herordenen',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Video URLs section
                SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(
                      Icons.video_library,
                      color: Colors.purple,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Video URLs (${videoUrls.length})",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Video URL input field
                Row(
                  children: [
                    Expanded(
                      child: EnhancedAccessibleTextField(
                        controller: _videoUrlController,
                        decoration: InputDecoration(
                          labelText: "Voer video URL in",
                          hintText: "https://www.youtube.com/watch?v=...",
                          prefixIcon: const Icon(
                            Icons.link,
                            color: Colors.purple,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.purple,
                              width: 2,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.url,
                        onSubmitted: (_) => _addVideoUrl(),
                        customTTSLabel: 'Video URL invoerveld',
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addVideoUrl,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Toevoegen'),
                    ),
                  ],
                ),

                // Video URLs list
                if (videoUrls.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.purple.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${videoUrls.length} video URL(s) toegevoegd',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Colors.purple,
                          ),
                        ),
                        SizedBox(height: 8),
                        ...videoUrls.asMap().entries.map((entry) {
                          final index = entry.key;
                          final url = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[800]
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.purple.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.purple,
                                  radius: 12,
                                  child: Text(
                                    '${index + 1}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    url,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context).brightness == Brightness.dark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    size: 16,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      videoUrls.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isProcessing ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(
                      color: Colors.grey,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    "Annuleren",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: (isProcessing || _nameController.text.isEmpty)
                      ? null
                      : _createKata,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    minimumSize: const Size(120, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: isProcessing
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              selectedImages.isNotEmpty
                                  ? 'Uploading ${selectedImages.length} image(s)...'
                                  : 'Creating...',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : Text(
                          "Kata\nToevoegen",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
