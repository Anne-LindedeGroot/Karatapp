import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/environment.dart';
import '../content/privacy_policy_nl.dart';
import '../providers/accessibility_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/role_provider.dart';
import '../providers/theme_provider.dart';
import '../services/role_service.dart';
import 'enhanced_accessible_text.dart';

class UserMenuPopup extends ConsumerWidget {
  final VoidCallback? onLogout;

  const UserMenuPopup({
    super.key,
    this.onLogout,
  });

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacybeleid'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: SelectableText(
              privacyPolicyNl,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final uri = Uri.tryParse(Environment.privacyPolicyUrl);
              if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Privacy‑URL is ongeldig.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }
              final success = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kon de privacy‑link niet openen.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Open website'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authUserProvider);
    final userRoleAsync = ref.watch(currentUserRoleProvider);
    final isHost = userRoleAsync.when(
      data: (role) => role == UserRole.host || role == UserRole.mediator,
      loading: () => false,
      error: (error, _) => false,
    );

    return Semantics(
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
          PopupMenuItem<String>(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.privacy_tip, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: EnhancedAccessibleText(
                    'Privacybeleid',
                    overflow: TextOverflow.visible,
                    maxLines: null,
                    enableTTS: false,
                  ),
                ),
              ],
            ),
            onTap: () {
              Future.microtask(() {
                if (context.mounted) {
                  _showPrivacyPolicyDialog(context);
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
                final themeNotifier = ref.read(themeNotifierProvider.notifier);

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
                final themeNotifier = ref.read(themeNotifierProvider.notifier);

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.contrast, size: 20),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Hoog Contrast',
                        overflow: TextOverflow.visible,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 50,
                      height: 30,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Switch(
                          value: themeState.isHighContrast,
                          onChanged: (value) async {
                            try {
                              await themeNotifier.setHighContrast(value);
                            } catch (e) {
                              debugPrint('Error setting high contrast: $e');
                            }
                          },
                        ),
                      ),
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
    );
  }
}
