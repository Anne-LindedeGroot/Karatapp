part of 'edit_kata_screen.dart';

extension _EditKataScreenHelpers on _EditKataScreenState {
  String _buildScreenContentText() {
    final parts = <String>[
      'Kata bewerken',
      'Kata naam invoerveld. Huidige waarde: ${_truncateText(_nameController.text)}',
      'Stijl invoerveld. Huidige waarde: ${_truncateText(_styleController.text)}',
      'Beschrijving invoerveld. Huidige waarde: ${_truncateText(_descriptionController.text)}',
      'Afbeeldingen beheren en volgorde aanpassen',
      'Video URLs beheren. Aantal URLs: ${_videoUrls.length}',
      'Gebruik de opslaan knop om wijzigingen op te slaan',
    ];

    return parts.join('. ');
  }

  String _truncateText(String text, [int max = 100]) {
    if (text.trim().isEmpty) return 'leeg';
    final trimmed = text.trim();
    if (trimmed.length <= max) return trimmed;
    return '${trimmed.substring(0, max)}...';
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
                    Consumer(
                      builder: (context, ref, child) {
                        final accessibilityNotifier =
                            ref.read(accessibilityNotifierProvider.notifier);

                        return GestureDetector(
                          onTap: () async {
                            final accessibilityState =
                                ref.read(accessibilityNotifierProvider);
                            if (accessibilityState.isTextToSpeechEnabled) {
                              final imageType = imageFile != null
                                  ? 'nieuwe afbeelding'
                                  : 'huidige afbeelding';
                              await accessibilityNotifier.speak(
                                'Afbeelding ${index + 1} van $totalItems, $imageType',
                              );
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isHovered
                                    ? borderColor.withValues(alpha: 0.8)
                                    : borderColor,
                                width: isHovered ? 3 : 2,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isHovered
                                  ? [
                                      BoxShadow(
                                        color: borderColor.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Semantics(
                              label: 'Afbeelding ${index + 1} van $totalItems',
                              hint: 'Tik om te horen welke afbeelding dit is',
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: imageFile != null
                                    ? Image.file(imageFile,
                                        fit: BoxFit.cover, width: 96, height: 96)
                                    : Image.network(
                                        imageUrl!,
                                        fit: BoxFit.cover,
                                        width: 96,
                                        height: 96,
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Container(
                                            width: 96,
                                            height: 96,
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: CircularProgressIndicator(),
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 96,
                                            height: 96,
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.broken_image,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
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

  Widget _buildSimpleVideoUrlSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EnhancedAccessibleText(
              'Video URL\'s',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              customTTSText: 'Sectie voor het beheren van video URL\'s',
            ),
            const SizedBox(height: 16),

            // Add new URL field
            EnhancedAccessibleText(
              'Nieuwe URL toevoegen:',
              style: Theme.of(context).textTheme.bodyMedium,
              customTTSText: 'Veld voor het toevoegen van een nieuwe video URL',
            ),
            const SizedBox(height: 8),
            EnhancedAccessibleTextField(
              controller: _newUrlController,
              maxLines: 1,
              decoration: const InputDecoration(
                hintText:
                    'https://www.youtube.com/watch?v=... (druk op Enter om toe te voegen)',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _addVideoUrl,
              customTTSLabel: 'Video URL invoerveld',
            ),

            if (_videoUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              EnhancedAccessibleText(
                '${_videoUrls.length} ${_videoUrls.length == 1 ? 'URL' : 'URLs'} toegevoegd',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                customTTSText:
                    '${_videoUrls.length} ${_videoUrls.length == 1 ? 'video URL toegevoegd' : 'video URLs toegevoegd'}',
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _videoUrls
                    .map(
                      (url) => Container(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: Text(
                                    url,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
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
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
