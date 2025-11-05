import 'package:flutter/material.dart';
import '../../models/ohyo_model.dart';
import '../../utils/responsive_utils.dart';
import '../../core/theme/app_theme.dart';
import '../formatted_text.dart';
import '../avatar_widget.dart';

/// Ohyo Card Layout - Handles responsive layout for ohyo cards
class OhyoCardLayout {
  static Widget buildHeaderRow({
    required BuildContext context,
    required Ohyo ohyo,
    required bool isExpanded,
    required VoidCallback onToggle,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required VoidCallback onSpeak,
  }) {
    return Row(
      children: [
        // Drag handle (if needed)
        Icon(
          Icons.drag_handle,
          color: Colors.grey[400],
          size: AppTheme.getResponsiveIconSize(context, baseSize: 18.0),
        ),

        // Avatar
        SizedBox(width: context.responsiveSpacing(SpacingSize.xs)),
        AvatarWidget(
          size: AppTheme.getResponsiveIconSize(context, baseSize: 24.0),
        ),
        SizedBox(width: context.responsiveSpacing(SpacingSize.sm)),

        // Ohyo name and category
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ohyo.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: context.responsiveValue(
                    mobile: 16.0,
                    tablet: 17.0,
                    desktop: 18.0,
                  ),
                ),
                // Show full name without truncation
              ),
              if (ohyo.style.isNotEmpty && ohyo.style != 'Andere')
                Text(
                  ohyo.style,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                    fontSize: context.responsiveValue(
                      mobile: 12.0,
                      tablet: 13.0,
                      desktop: 14.0,
                    ),
                  ),
                  // Show full category without truncation
                ),
            ],
          ),
        ),

        // Action buttons
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Speak button
            Semantics(
              label: 'Lees ohyo inhoud voor',
              button: true,
              child: IconButton(
                onPressed: onSpeak,
                icon: Icon(
                  Icons.volume_up,
                  size: AppTheme.getResponsiveIconSize(context, baseSize: 20.0),
                ),
                tooltip: 'Lees voor',
                style: IconButton.styleFrom(
                  padding: EdgeInsets.all(context.responsiveSpacing(SpacingSize.xs)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),

            // Edit button
            Semantics(
              label: 'Bewerk ohyo',
              button: true,
              child: IconButton(
                onPressed: onEdit,
                icon: Icon(
                  Icons.edit,
                  size: AppTheme.getResponsiveIconSize(context, baseSize: 20.0),
                ),
                tooltip: 'Bewerk',
                style: IconButton.styleFrom(
                  padding: EdgeInsets.all(context.responsiveSpacing(SpacingSize.xs)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),

            // Delete button
            Semantics(
              label: 'Verwijder ohyo',
              button: true,
              child: IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete,
                  size: AppTheme.getResponsiveIconSize(context, baseSize: 20.0),
                  color: Colors.red,
                ),
                tooltip: 'Verwijder',
                style: IconButton.styleFrom(
                  padding: EdgeInsets.all(context.responsiveSpacing(SpacingSize.xs)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget buildDescriptionSection({
    required BuildContext context,
    required Ohyo ohyo,
    required bool isExpanded,
    required bool shouldShowToggle,
    required VoidCallback onToggle,
  }) {
    final displayDescription = isExpanded || !shouldShowToggle
        ? ohyo.description
        : _getTruncatedDescription(ohyo.description);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Description text
        FormattedText(
          text: displayDescription,
          baseStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: context.responsiveValue(
              mobile: 14.0,
              tablet: 15.0,
              desktop: 16.0,
            ),
            height: 1.4,
          ),
        ),

        // Toggle button for description
        if (shouldShowToggle)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                label: isExpanded ? 'Inklappen beschrijving' : 'Uitklappen volledige beschrijving',
                button: true,
                child: TextButton.icon(
                  onPressed: onToggle,
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: AppTheme.getResponsiveIconSize(context, baseSize: 18.0),
                  ),
                  label: Text(
                    isExpanded ? 'Minder zien' : 'Alles zien',
                    style: TextStyle(
                      fontSize: context.responsiveValue(
                        mobile: 14.0,
                        tablet: 15.0,
                        desktop: 16.0,
                      ),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsiveSpacing(SpacingSize.sm),
                      vertical: context.responsiveSpacing(SpacingSize.xs),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  static String _getTruncatedDescription(String description) {
    // Always return the full description - no truncation
    return description;
  }

  static bool shouldShowToggleButton(String description) {
    // Always show full description, so no toggle button needed
    return false;
  }
}
