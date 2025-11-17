import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kata_model.dart';
import '../utils/responsive_utils.dart';
import '../core/theme/app_theme.dart';
import 'formatted_text.dart';
import 'responsive_layout.dart';
import 'kata_card/kata_card_header.dart';
import 'kata_card/kata_card_media.dart';
import 'kata_card/kata_card_interactions.dart';
import 'kata_card/kata_card_utils.dart';

class CollapsibleKataCard extends ConsumerStatefulWidget {
  final Kata kata;
  final VoidCallback onDelete;
  final bool isDragging;
  final bool useAdaptiveWidth;
  final bool showAllInfo;

  const CollapsibleKataCard({
    super.key,
    required this.kata,
    required this.onDelete,
    this.isDragging = false,
    this.useAdaptiveWidth = true,
    this.showAllInfo = false,
  });

  @override
  ConsumerState<CollapsibleKataCard> createState() => _CollapsibleKataCardState();
}

class _CollapsibleKataCardState extends ConsumerState<CollapsibleKataCard> {
  Future<void> _speakKataContent() async {
    await KataCardUtils.speakKataContent(context, ref, widget.kata);
  }

  @override
  Widget build(BuildContext context) {
    final kata = widget.kata;

    return Semantics(
      label: 'Kata kaart: ${kata.name}, stijl: ${kata.style}',
      child: GestureDetector(
        onTap: _speakKataContent,
        child: ResponsiveCard(
          margin: AppTheme.getResponsiveMargin(context),
          padding: AppTheme.getResponsivePadding(context),
          elevation: AppTheme.getResponsiveElevation(context),
          adaptiveWidth: widget.useAdaptiveWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              KataCardHeader(
                kata: kata,
                onDelete: widget.onDelete,
              ),
              SizedBox(height: context.responsiveSpacing(SpacingSize.sm)),

              // Display description with styling
              Semantics(
                label: 'Kata beschrijving: ${kata.description.replaceAll('\n', ' ')}',
                child: FormattedText(
                  text: kata.description,
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
              KataCardMedia(kata: kata),

              SizedBox(height: context.responsiveSpacing(SpacingSize.lg)),

              // Interaction section (likes, favorites, comments)
              KataCardInteractions(kata: kata),
            ],
          ),
        ),
      ),
    );
  }
}
