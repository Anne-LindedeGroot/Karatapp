import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/network_provider.dart';
import 'accessibility_settings_popup.dart';
import 'user_menu_popup.dart';

class HomeAppBarActions extends ConsumerWidget {
  final VoidCallback? onRefresh;
  final VoidCallback? onLogout;
  final VoidCallback? onResetOhyoTab;
  final bool showResetButton;

  const HomeAppBarActions({
    super.key,
    this.onRefresh,
    this.onLogout,
    this.onResetOhyoTab,
    this.showResetButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(isConnectedProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Accessibility quick actions in app bar
        const AccessibilitySettingsPopup(),

        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: isConnected ? onRefresh : null,
          tooltip: isConnected ? 'Kata\'s verversen' : 'Geen verbinding',
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
        ),

        // Reset Ohyo tab button (only shown when there are active filters)
        if (showResetButton)
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: onResetOhyoTab,
            tooltip: 'Terug naar ohyo hoofdpagina',
            color: Theme.of(context).colorScheme.primary,
            constraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
          ),

        IconButton(
          icon: const Icon(Icons.forum),
          onPressed: () {
            context.go('/forum');
          },
          tooltip: 'Community Forum',
          constraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 48,
          ),
        ),

        UserMenuPopup(onLogout: onLogout),
      ],
    );
  }
}
