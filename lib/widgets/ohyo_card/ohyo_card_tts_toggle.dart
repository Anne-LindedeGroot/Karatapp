import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/accessibility_provider.dart';
import '../../utils/responsive_utils.dart';

/// Toggle widget for controlling TTS general information skipping in ohyo cards
class OhyoCardTTSToggle extends ConsumerWidget {
  final bool showLabel;
  final EdgeInsets? margin;

  const OhyoCardTTSToggle({
    super.key,
    this.showLabel = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skipGeneralInfo = ref.watch(skipGeneralInfoInTTSOhyoProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);

    return Container(
      margin: margin ?? EdgeInsets.symmetric(
        horizontal: context.responsiveSpacing(SpacingSize.xs),
        vertical: context.responsiveSpacing(SpacingSize.xs),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toggle switch
          Semantics(
            label: skipGeneralInfo
                ? 'TTS: Algemene informatie wordt overgeslagen. Tik om algemene informatie weer te geven.'
                : 'TTS: Algemene informatie wordt voorgelezen. Tik om algemene informatie over te slaan.',
            child: Switch(
              value: skipGeneralInfo,
              onChanged: (value) async {
                await accessibilityNotifier.toggleSkipGeneralInfoInTTSOhyo();
              },
              activeThumbColor: Theme.of(context).colorScheme.primary,
              activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              inactiveThumbColor: Theme.of(context).colorScheme.onSurfaceVariant,
              inactiveTrackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),

          // Label (optional)
          if (showLabel) ...[
            SizedBox(height: context.responsiveSpacing(SpacingSize.xs)),
            Text(
              'Skip algemene informatie bij voorlezen',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: context.responsiveValue(mobile: 10.0, tablet: 11.0, desktop: 12.0),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact version of the toggle for use in tight spaces
class CompactOhyoCardTTSToggle extends ConsumerWidget {
  const CompactOhyoCardTTSToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skipGeneralInfo = ref.watch(skipGeneralInfoInTTSOhyoProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);

    return Semantics(
      label: skipGeneralInfo
          ? 'TTS: Algemene informatie wordt overgeslagen. Tik om algemene informatie weer te geven.'
          : 'TTS: Algemene informatie wordt voorgelezen. Tik om algemene informatie over te slaan.',
      child: Transform.scale(
        scale: 0.8, // Make the switch smaller for compact version
        child: Switch(
          value: skipGeneralInfo,
          onChanged: (value) async {
            await accessibilityNotifier.toggleSkipGeneralInfoInTTSOhyo();
          },
          activeThumbColor: Theme.of(context).colorScheme.primary,
          activeTrackColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          inactiveThumbColor: Theme.of(context).colorScheme.onSurfaceVariant,
          inactiveTrackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}
