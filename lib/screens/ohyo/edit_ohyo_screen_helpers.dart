part of 'edit_ohyo_screen.dart';

extension _EditOhyoScreenHelpers on _EditOhyoScreenState {
  String _buildScreenContentText() {
    final parts = <String>[
      'Ohyo bewerken',
      'Ohyo naam invoerveld. Huidige waarde: ${_truncateText(_nameController.text)}',
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

  Widget _buildSimpleVideoUrlSection() {
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Video\'s',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 16),
            EnhancedAccessibleTextField(
              controller: _newUrlController,
              decoration: const InputDecoration(
                labelText: 'Video URL',
                hintText: 'https://example.com/video.mp4',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _addVideoUrl(),
              customTTSLabel: 'Video URL invoerveld',
            ),
            if (_videoUrls.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Huidige Video\'s (${_videoUrls.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ..._videoUrls.map(
                (url) => ListTile(
                  title: Text(
                    url,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeVideoUrl(_videoUrls.indexOf(url)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableImage({
    required Key key,
    required int index,
    required String imageUrl,
    required File? imageFile,
    required Color borderColor,
    required VoidCallback onRemove,
    required Function(int, int) onReorder,
    required int totalItems,
  }) {
    return Container(
      key: key,
      width: 120,
      margin: const EdgeInsets.only(right: 8),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 80,
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: imageFile != null
                      ? Image.file(
                          imageFile,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, size: 40),
                            );
                          },
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, size: 40),
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
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: onRemove,
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
            ],
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
      ),
    );
  }
}
