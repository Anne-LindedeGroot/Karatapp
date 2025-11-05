import 'package:flutter/material.dart';
import '../../models/ohyo_model.dart';
import '../../utils/responsive_utils.dart';
import '../../core/theme/app_theme.dart';
import '../overflow_safe_widgets.dart';

class OhyoCardHeader extends StatelessWidget {
  final Ohyo ohyo;
  final VoidCallback onDelete;
  final VoidCallback onSpeak;

  const OhyoCardHeader({
    super.key,
    required this.ohyo,
    required this.onDelete,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return OverflowSafeRow(
          children: [
            // Drag handle with tooltip - Made more compact
            Semantics(
              label: 'Sleep handvat om ohyo te herordenen',
              child: Container(
                width: context.responsiveValue(mobile: 32.0, tablet: 36.0, desktop: 40.0),
                height: context.responsiveValue(mobile: 32.0, tablet: 36.0, desktop: 40.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: AppTheme.getResponsiveBorderRadius(context, multiplier: 0.75),
                ),
                child: Icon(
                  Icons.drag_handle,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: AppTheme.getResponsiveIconSize(context, baseSize: 16.0),
                ),
              ),
            ),
            SizedBox(width: context.responsiveSpacing(SpacingSize.sm)),
            // Use OverflowSafeFlexible to prevent overflow
            OverflowSafeFlexible(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display name with overflow handling
                  Semantics(
                    label: 'Ohyo naam: ${ohyo.name}',
                    child: AccessibleOverflowSafeText(
                      ohyo.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: null,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                  SizedBox(height: context.responsiveSpacing(SpacingSize.xs)),
                  // Display style with overflow handling
                  if (ohyo.style.isNotEmpty && ohyo.style != 'Andere')
                    Semantics(
                      label: 'Ohyo stijl: ${ohyo.style}',
                      child: AccessibleOverflowSafeText(
                        ohyo.style,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Colors.blueGrey,
                              fontStyle: FontStyle.italic,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: context.responsiveSpacing(SpacingSize.sm)),
            // Action buttons with fixed width to prevent overflow
            OverflowSafeRow(
              mainAxisSize: MainAxisSize.min,
              enableWrapping: false,
              children: [
                // Speak button - Responsive
                Semantics(
                  label: 'Lees ohyo ${ohyo.name} voor',
                  button: true,
                  child: SizedBox(
                    width: context.responsiveValue(mobile: 32.0, tablet: 36.0, desktop: 40.0),
                    height: context.responsiveValue(mobile: 32.0, tablet: 36.0, desktop: 40.0),
                    child: IconButton(
                      icon: Icon(
                        Icons.volume_up,
                        color: Theme.of(context).colorScheme.primary,
                        size: AppTheme.getResponsiveIconSize(context, baseSize: 16.0),
                      ),
                      onPressed: onSpeak,
                      tooltip: 'Lees ohyo voor',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
                SizedBox(width: context.responsiveSpacing(SpacingSize.xs)),
                // Delete button - Responsive
                Semantics(
                  label: 'Verwijder ohyo ${ohyo.name}',
                  button: true,
                  child: SizedBox(
                    width: context.responsiveValue(mobile: 32.0, tablet: 36.0, desktop: 40.0),
                    height: context.responsiveValue(mobile: 32.0, tablet: 36.0, desktop: 40.0),
                    child: IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: AppTheme.getResponsiveIconSize(context, baseSize: 16.0),
                      ),
                      onPressed: onDelete,
                      tooltip: 'Verwijder ohyo',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
