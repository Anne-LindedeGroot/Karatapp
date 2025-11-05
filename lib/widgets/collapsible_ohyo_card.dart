import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ohyo_model.dart';
import '../utils/responsive_utils.dart';
import '../core/theme/app_theme.dart';
import '../services/unified_tts_service.dart';
import 'formatted_text.dart';
import 'responsive_layout.dart';
import 'ohyo_card/ohyo_card_header.dart';
import 'ohyo_card/ohyo_card_media.dart';
import 'ohyo_card/ohyo_card_interactions.dart';

class CollapsibleOhyoCard extends ConsumerStatefulWidget {
  final Ohyo ohyo;
  final VoidCallback onDelete;
  final bool isDragging;
  final bool useAdaptiveWidth;

  const CollapsibleOhyoCard({
    super.key,
    required this.ohyo,
    required this.onDelete,
    this.isDragging = false,
    this.useAdaptiveWidth = true,
  });

  @override
  ConsumerState<CollapsibleOhyoCard> createState() => _CollapsibleOhyoCardState();
}

class _CollapsibleOhyoCardState extends ConsumerState<CollapsibleOhyoCard> {
  Future<void> _speakOhyoContent() async {
    try {
      // Build comprehensive text content for TTS
      final StringBuffer content = StringBuffer();

      // Add ohyo name
      content.write('Ohyo: ${widget.ohyo.name}. ');

      // Add category if available
      if (widget.ohyo.style.isNotEmpty && widget.ohyo.style != 'Andere') {
        content.write('Stijl: ${widget.ohyo.style}. ');
      }

      // Add description
      content.write('Beschrijving: ${widget.ohyo.description}');

      // Speak the content using Unified TTS Service
      await UnifiedTTSService.readText(context, ref, content.toString());

    } catch (e) {
      debugPrint('TTS Error reading ohyo content: $e');
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij voorlezen van ohyo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ohyo = widget.ohyo;

    return Semantics(
      label: 'Ohyo kaart: ${ohyo.name}, stijl: ${ohyo.style}',
      child: GestureDetector(
        onTap: _speakOhyoContent,
        child: ResponsiveCard(
          margin: AppTheme.getResponsiveMargin(context),
          padding: AppTheme.getResponsivePadding(context),
          elevation: AppTheme.getResponsiveElevation(context),
          adaptiveWidth: widget.useAdaptiveWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              OhyoCardHeader(
                ohyo: ohyo,
                onDelete: widget.onDelete,
                onSpeak: _speakOhyoContent,
              ),
              SizedBox(height: context.responsiveSpacing(SpacingSize.sm)),

              // Display description with styling
              Semantics(
                label: 'Ohyo beschrijving: ${ohyo.description.replaceAll('\n', ' ')}',
                child: FormattedText(
                  text: ohyo.description,
                  baseStyle: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey[700]),
                  headingStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  enableSelectiveCollapse: true, // Enable selective collapse for ohyo cards like kata cards
                ),
              ),

              SizedBox(height: context.responsiveSpacing(SpacingSize.md)),

              // Display media (images and videos) with smart preview
              OhyoCardMedia(ohyo: ohyo),

              SizedBox(height: context.responsiveSpacing(SpacingSize.lg)),

              // Interaction section (likes, favorites, comments)
              OhyoCardInteractions(ohyo: ohyo),
            ],
          ),
        ),
      ),
    );
  }

}
