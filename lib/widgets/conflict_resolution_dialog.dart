import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/interaction_models.dart';
import '../providers/offline_services_provider.dart';

/// Dialog for resolving comment conflicts
class ConflictResolutionDialog extends ConsumerStatefulWidget {
  final CommentConflict conflict;

  const ConflictResolutionDialog({
    super.key,
    required this.conflict,
  });

  @override
  ConsumerState<ConflictResolutionDialog> createState() => _ConflictResolutionDialogState();
}

class _ConflictResolutionDialogState extends ConsumerState<ConflictResolutionDialog> {
  ConflictResolution? _selectedResolution;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            _getConflictIcon(),
            color: _getConflictColor(),
          ),
          const SizedBox(width: 8),
          Text(_getConflictTitle()),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_getConflictDescription()),
            const SizedBox(height: 16),
            _buildConflictDetails(),
            const SizedBox(height: 16),
            Text(
              'Kies hoe u dit conflict wilt oplossen:',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildResolutionOptions(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _selectedResolution == null ? null : _resolveConflict,
          child: const Text('Oplossen'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuleren'),
        ),
      ],
    );
  }

  String _getConflictTitle() {
    switch (widget.conflict.type) {
      case ConflictType.concurrentEdit:
        return 'Gelijktijdige bewerking';
      case ConflictType.deletedByAnother:
        return 'Reactie verwijderd';
      case ConflictType.likeDislikeConflict:
        return 'Like/Dislike conflict';
      case ConflictType.versionMismatch:
        return 'Versie conflict';
    }
  }

  String _getConflictDescription() {
    switch (widget.conflict.type) {
      case ConflictType.concurrentEdit:
        return 'Deze reactie is tegelijkertijd bewerkt door iemand anders. Kies welke versie u wilt behouden.';
      case ConflictType.deletedByAnother:
        return 'Deze reactie is verwijderd door iemand anders terwijl u deze bewerkte.';
      case ConflictType.likeDislikeConflict:
        return 'Er is een conflict ontstaan met likes/dislikes voor deze reactie.';
      case ConflictType.versionMismatch:
        return 'De versie van deze reactie komt niet overeen met de server versie.';
    }
  }

  IconData _getConflictIcon() {
    switch (widget.conflict.type) {
      case ConflictType.concurrentEdit:
        return Icons.warning;
      case ConflictType.deletedByAnother:
        return Icons.delete_forever;
      case ConflictType.likeDislikeConflict:
        return Icons.error_outline;
      case ConflictType.versionMismatch:
        return Icons.sync_problem;
    }
  }

  Color _getConflictColor() {
    switch (widget.conflict.type) {
      case ConflictType.concurrentEdit:
        return Colors.orange;
      case ConflictType.deletedByAnother:
        return Colors.red;
      case ConflictType.likeDislikeConflict:
        return Colors.amber;
      case ConflictType.versionMismatch:
        return Colors.orange;
    }
  }

  Widget _buildConflictDetails() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.conflict.localData.containsKey('content') &&
              widget.conflict.serverData.containsKey('content')) ...[
            Text(
              'Uw versie:',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.conflict.localData['content'] as String? ?? '',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Server versie:',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.conflict.serverData['content'] as String? ?? '',
                style: TextStyle(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontSize: 13,
                ),
              ),
            ),
          ] else ...[
            Text(
              'Conflict details: ${widget.conflict.type}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResolutionOptions() {
    final options = _getAvailableResolutions();

    return RadioGroup<ConflictResolution>(
      groupValue: _selectedResolution,
      onChanged: (value) {
        setState(() {
          _selectedResolution = value;
        });
      },
      child: Column(
        children: options.map((resolution) {
          return RadioListTile<ConflictResolution>(
            title: Text(_getResolutionTitle(resolution)),
            subtitle: Text(_getResolutionDescription(resolution)),
            value: resolution,
            dense: true,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
    );
  }

  List<ConflictResolution> _getAvailableResolutions() {
    switch (widget.conflict.type) {
      case ConflictType.concurrentEdit:
        return [
          ConflictResolution.keepLocal,
          ConflictResolution.keepServer,
          ConflictResolution.merge,
        ];
      case ConflictType.deletedByAnother:
        return [
          ConflictResolution.keepLocal,
          ConflictResolution.keepServer,
        ];
      case ConflictType.likeDislikeConflict:
      case ConflictType.versionMismatch:
        return [
          ConflictResolution.keepServer,
          ConflictResolution.discard,
        ];
    }
  }

  String _getResolutionTitle(ConflictResolution resolution) {
    switch (resolution) {
      case ConflictResolution.keepLocal:
        return 'Mijn versie behouden';
      case ConflictResolution.keepServer:
        return 'Server versie gebruiken';
      case ConflictResolution.merge:
        return 'Versies samenvoegen';
      case ConflictResolution.discard:
        return 'Annuleren';
    }
  }

  String _getResolutionDescription(ConflictResolution resolution) {
    switch (resolution) {
      case ConflictResolution.keepLocal:
        return 'Uw lokale wijzigingen overschrijven de server versie';
      case ConflictResolution.keepServer:
        return 'De server versie wordt gebruikt, uw wijzigingen gaan verloren';
      case ConflictResolution.merge:
        return 'Probeer beide versies intelligent samen te voegen';
      case ConflictResolution.discard:
        return 'Negeer dit conflict en ga verder';
    }
  }

  Future<void> _resolveConflict() async {
    if (_selectedResolution == null) return;

    try {
      final conflictService = ref.read(conflictResolutionServiceProviderOverride);
      await conflictService.resolveConflict(widget.conflict.id, _selectedResolution!);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conflict succesvol opgelost'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij oplossen conflict: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Helper function to show conflict resolution dialog
Future<void> showConflictResolutionDialog(BuildContext context, CommentConflict conflict) {
  return showDialog(
    context: context,
    builder: (context) => ConflictResolutionDialog(conflict: conflict),
  );
}
