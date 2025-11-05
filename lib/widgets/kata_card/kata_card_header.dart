import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/kata_model.dart';
import '../../utils/responsive_utils.dart';
import '../../core/navigation/app_router.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/accessibility_provider.dart';
import '../overflow_safe_widgets.dart';
import 'kata_card_tts_toggle.dart';

class KataCardHeader extends StatelessWidget {
  final Kata kata;
  final VoidCallback onDelete;

  const KataCardHeader({
    super.key,
    required this.kata,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return OverflowSafeRow(
          children: [
            // Drag handle with tooltip - Made more compact
            Semantics(
              label: 'Sleep handvat om kata te herordenen',
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
                    label: 'Kata naam: ${kata.name}',
                    child: AccessibleOverflowSafeText(
                      kata.name,
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
                  Consumer(
                    builder: (context, ref, child) {
                      final accessibilityState = ref.watch(accessibilityNotifierProvider);
                      // Allow multiple lines when dyslexia mode is enabled or when font size is extra large
                      final maxLines = (accessibilityState.isDyslexiaFriendly ||
                          accessibilityState.fontSize == AccessibilityFontSize.extraLarge) ? null : 2;

                      return Semantics(
                        label: 'Karate stijl: ${kata.style}',
                        child: AccessibleOverflowSafeText(
                          kata.style,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Colors.blueGrey,
                                fontStyle: FontStyle.italic,
                              ),
                          maxLines: maxLines,
                          overflow: TextOverflow.visible,
                        ),
                      );
                    },
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
                // TTS Toggle with label
                Consumer(
                  builder: (context, ref, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Skip algemene info:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: context.responsiveValue(mobile: 10.0, tablet: 11.0, desktop: 12.0),
                          ),
                        ),
                        SizedBox(width: context.responsiveSpacing(SpacingSize.xs)),
                        CompactKataCardTTSToggle(),
                      ],
                    );
                  },
                ),
                SizedBox(width: context.responsiveSpacing(SpacingSize.xs)),
                // Edit button - Responsive
                Semantics(
                  label: 'Bewerk kata ${kata.name}',
                  button: true,
                  child: SizedBox(
                    width: context.responsiveValue(mobile: 32.0, tablet: 36.0, desktop: 40.0),
                    height: context.responsiveValue(mobile: 32.0, tablet: 36.0, desktop: 40.0),
                    child: IconButton(
                      icon: Icon(
                        Icons.edit,
                        color: Colors.blue,
                        size: AppTheme.getResponsiveIconSize(context, baseSize: 16.0),
                      ),
                      onPressed: () {
                        context.goToEditKata(kata.id.toString());
                      },
                      tooltip: 'Bewerk kata',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
                SizedBox(width: context.responsiveSpacing(SpacingSize.xs)),
                // Delete button - Responsive
                Semantics(
                  label: 'Verwijder kata ${kata.name}',
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
                      tooltip: 'Verwijder kata',
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
