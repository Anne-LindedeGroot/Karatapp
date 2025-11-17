import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ohyo_model.dart';
import '../utils/responsive_utils.dart';
import '../core/theme/app_theme.dart';
import 'formatted_text.dart';
import 'responsive_layout.dart';
import 'ohyo_card/ohyo_card_header.dart';
import 'ohyo_card/ohyo_card_media.dart';
import 'ohyo_card/ohyo_card_interactions.dart';
import 'ohyo_card/ohyo_card_utils.dart';

class CollapsibleOhyoCard extends ConsumerStatefulWidget {
  final Ohyo ohyo;
  final VoidCallback onDelete;
  final bool isDragging;
  final bool useAdaptiveWidth;
  final bool showAllInfo;

  const CollapsibleOhyoCard({
    super.key,
    required this.ohyo,
    required this.onDelete,
    this.isDragging = false,
    this.useAdaptiveWidth = true,
    this.showAllInfo = false,
  });

  @override
  ConsumerState<CollapsibleOhyoCard> createState() => _CollapsibleOhyoCardState();
}

class _CollapsibleOhyoCardState extends ConsumerState<CollapsibleOhyoCard> {
  Future<void> _speakOhyoContent() async {
    await OhyoCardUtils.speakOhyoContent(context, ref, widget.ohyo);
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
                  enableSelectiveCollapse: !widget.showAllInfo, // Disable selective collapse when showing all info
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
