import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/role_provider.dart';
import '../../services/role_service.dart';
import '../../providers/network_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/accessibility_provider.dart';
import '../../widgets/enhanced_accessible_text.dart';

class HomeScreenAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback? onRefresh;
  final VoidCallback? onLogout;
  final VoidCallback? onResetOhyoTab;
  final bool showResetButton;

  const HomeScreenAppBar({
    super.key,
    this.onRefresh,
    this.onLogout,
    this.onResetOhyoTab,
    this.showResetButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  /// Get appropriate icon for font size
  IconData _getFontSizeIcon(AccessibilityFontSize fontSize) {
    switch (fontSize) {
      case AccessibilityFontSize.small:
        return Icons.text_decrease;
      case AccessibilityFontSize.normal:
        return Icons.text_fields;
      case AccessibilityFontSize.large:
        return Icons.text_increase;
      case AccessibilityFontSize.extraLarge:
        return Icons.format_size;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authUserProvider);
    final isConnected = ref.watch(isConnectedProvider);

    // Watch the role at the widget level to ensure rebuilds
    final userRoleAsync = ref.watch(currentUserRoleProvider);
    final isHost = userRoleAsync.when(
      data: (role) {
        return role == UserRole.host || role == UserRole.mediator;
      },
      loading: () {
        return false;
      },
      error: (error, _) {
        return false;
      },
    );

    return AppBar(
      title: const Text("Karatapp"),
      actions: [
        // Accessibility quick actions in app bar
        Consumer(
          builder: (context, ref, child) {
            final accessibilityState = ref.watch(
              accessibilityNotifierProvider,
            );
            final accessibilityNotifier = ref.read(
              accessibilityNotifierProvider.notifier,
            );

            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Combined accessibility settings popup
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.text_fields,
                      color:
                          (accessibilityState.fontSize !=
                                  AccessibilityFontSize.normal ||
                              accessibilityState.isDyslexiaFriendly)
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    tooltip: 'Tekst instellingen',
                    constraints: BoxConstraints(
                      minWidth: accessibilityState.fontSize == AccessibilityFontSize.extraLarge ||
                               accessibilityState.isDyslexiaFriendly
                          ? 320
                          : 280,
                    ),
                    itemBuilder: (context) => [
                      // Font size section
                      PopupMenuItem<String>(
                        enabled: false,
                        child: Text(
                          'Lettergrootte',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                      ...AccessibilityFontSize.values.map((fontSize) {
                        final isSelected =
                            accessibilityState.fontSize == fontSize;
                        return PopupMenuItem<String>(
                          value: 'font_${fontSize.name}',
                          child: Row(
                            children: [
                              Icon(
                                _getFontSizeIcon(fontSize),
                                size: 20,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                fontSize == AccessibilityFontSize.small
                                    ? 'Klein'
                                    : fontSize ==
                                          AccessibilityFontSize.normal
                                    ? 'Normaal'
                                    : fontSize ==
                                          AccessibilityFontSize.large
                                    ? 'Groot'
                                    : 'Extra Groot',
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.primary
                                      : null,
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                ),
                            ],
                          ),
                        );
                      }),
                      const PopupMenuDivider(),
                      // Dyslexia toggle
                      PopupMenuItem<String>(
                        value: 'toggle_dyslexia',
                        child: Row(
                          children: [
                            Icon(
                              accessibilityState.isDyslexiaFriendly
                                  ? Icons.format_line_spacing
                                  : Icons.format_line_spacing_outlined,
                              size: 18,
                              color: accessibilityState.isDyslexiaFriendly
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'dyslexie\nvriendelijk',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Transform.scale(
                              scale: 0.7,
                              child: Switch(
                                value: accessibilityState.isDyslexiaFriendly,
                                onChanged: (value) {
                                  accessibilityNotifier.toggleDyslexiaFriendly();
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (String value) {
                      if (value.startsWith('font_')) {
                        final fontSizeName = value.substring(5);
                        final fontSize = AccessibilityFontSize.values
                            .firstWhere(
                              (size) => size.name == fontSizeName,
                            );
                        accessibilityNotifier.setFontSize(fontSize);
                      } else if (value == 'toggle_dyslexia') {
                        accessibilityNotifier.toggleDyslexiaFriendly();
                      }
                    },
                  ),
                ],
              ),
            );
          },
        ),

        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: isConnected ? onRefresh : null,
          tooltip: isConnected ? 'Kata\'s verversen' : 'Geen verbinding',
        ),

        // Reset Ohyo tab button (only shown when there are active filters)
        if (showResetButton)
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: onResetOhyoTab,
            tooltip: 'Terug naar ohyo hoofdpagina',
            color: Theme.of(context).colorScheme.primary,
          ),
        IconButton(
          icon: const Icon(Icons.forum),
          onPressed: () {
            context.go('/forum');
          },
          tooltip: 'Community Forum',
        ),
        Semantics(
          label: 'Hoofdmenu openen',
          button: true,
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Meer opties',
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 400),
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                // ignore: sort_child_properties_last
                child: Consumer(
                  builder: (context, ref, child) {
                    final accessibilityState = ref.watch(accessibilityNotifierProvider);
                    final maxWidth = accessibilityState.fontSize == AccessibilityFontSize.extraLarge ||
                                    accessibilityState.isDyslexiaFriendly
                        ? 350.0
                        : 250.0;
                    return ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: EnhancedAccessibleText(
                        currentUser?.userMetadata?['full_name'] ??
                            currentUser?.email ??
                            'User',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.visible,
                        maxLines: null, // Allow multiple lines for long names
                        enableTTS: false,
                      ),
                    );
                  },
                ),
                enabled: false,
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.person, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: EnhancedAccessibleText(
                        'Profiel',
                        overflow: TextOverflow.visible,
                        maxLines: null,
                        enableTTS: false,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  // Add a slight delay to ensure the popup menu closes first
                  Future.microtask(() {
                    if (context.mounted) {
                      context.go('/profile');
                    }
                  });
                },
              ),
              PopupMenuItem<String>(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.favorite, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: EnhancedAccessibleText(
                        'Mijn Favorieten',
                        overflow: TextOverflow.visible,
                        maxLines: null, // Allow multiple lines for large fonts
                        enableTTS: false, // Disable TTS for menu items to avoid confusion
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  // Add a slight delay to ensure the popup menu closes first
                  Future.microtask(() {
                    if (context.mounted) {
                      context.go('/favorites');
                    }
                  });
                },
              ),
              // Show admin options for hosts and mediators
              if (isHost)
              PopupMenuItem<String>(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(Icons.admin_panel_settings, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: EnhancedAccessibleText(
                        'Gebruikersbeheer',
                        overflow: TextOverflow.visible,
                        maxLines: null,
                        enableTTS: false,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  // Add a slight delay to ensure the popup menu closes first
                  Future.microtask(() {
                    if (context.mounted) {
                      context.go('/user-management');
                    }
                  });
                },
              ),
              const PopupMenuDivider(),
              // Theme switcher
              PopupMenuItem<String>(
                child: Consumer(
                  builder: (context, ref, child) {
                    final themeState = ref.watch(themeNotifierProvider);
                    final themeNotifier = ref.read(
                      themeNotifierProvider.notifier,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(themeNotifier.themeIcon, size: 20),
                            const SizedBox(width: 12),
                            const Text('Thema'),
                            const Spacer(),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 32),
                          child: DropdownButton<AppThemeMode>(
                            value: themeState.themeMode,
                            underline: const SizedBox(),
                            isExpanded: true,
                            items: AppThemeMode.values.map((mode) {
                              IconData icon;
                              String label;
                              switch (mode) {
                                case AppThemeMode.light:
                                  icon = Icons.light_mode;
                                  label = 'Licht';
                                  break;
                                case AppThemeMode.dark:
                                  icon = Icons.dark_mode;
                                  label = 'Donker';
                                  break;
                                case AppThemeMode.system:
                                  icon = Icons.brightness_auto;
                                  label = 'Systeem';
                                  break;
                              }
                              return DropdownMenuItem(
                                value: mode,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(icon, size: 16),
                                    const SizedBox(width: 8),
                                    Text(label),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (mode) {
                              if (mode != null) {
                                themeNotifier.setThemeMode(mode);
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
                enabled: false, // Disable tap to prevent menu close
              ),
              // High contrast toggle
              PopupMenuItem<String>(
                child: Consumer(
                  builder: (context, ref, child) {
                    final themeState = ref.watch(themeNotifierProvider);
                    final themeNotifier = ref.read(
                      themeNotifierProvider.notifier,
                    );

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.contrast, size: 20),
                        const SizedBox(width: 12),
                        const Flexible(
                          child: Text(
                            'Hoog Contrast',
                            overflow: TextOverflow.visible,
                            maxLines: 1,
                          ),
                        ),
                        Switch(
                          value: themeState.isHighContrast,
                          onChanged: (value) {
                            themeNotifier.setHighContrast(value);
                          },
                        ),
                      ],
                    );
                  },
                ),
                enabled: false, // Disable tap to prevent menu close
              ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.logout, size: 20, color: Colors.red),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: EnhancedAccessibleText(
                        'Uitloggen',
                        style: TextStyle(color: Colors.red),
                        overflow: TextOverflow.visible,
                        maxLines: null,
                        enableTTS: false,
                      ),
                    ),
                  ],
                ),
                onTap: () {
                  onLogout?.call();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
