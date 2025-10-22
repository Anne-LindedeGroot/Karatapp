import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/collapsible_kata_card.dart';
import '../widgets/connection_error_widget.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/modern_loading_widget.dart';
import '../widgets/overflow_safe_widgets.dart';
import '../providers/auth_provider.dart';
import '../providers/kata_provider.dart';
import '../providers/role_provider.dart';
import '../providers/network_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/accessibility_provider.dart';
import '../services/role_service.dart';
import '../utils/image_utils.dart';
import '../utils/responsive_utils.dart';
import '../core/theme/app_theme.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // TTS announcement disabled - only speak when user clicks TTS button
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _announcePageLoad();
    // });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }



  Future<void> _refreshKatas() async {
    // Clear search when refreshing
    _searchController.clear();
    ref.read(kataNotifierProvider.notifier).searchKatas('');

    // Refresh kata data
    await ref.read(kataNotifierProvider.notifier).refreshKatas();
  }


  Future<void> _deleteKata(int kataId, String kataName) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: '$kataName verwijderen?',
        child: const Text(
          'Dit zal de kata en alle afbeeldingen permanent verwijderen. Dit kan niet ongedaan worden gemaakt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Kata en afbeeldingen verwijderen...'),
                ],
              ),
              duration: Duration(seconds: 10),
            ),
          );
        }

        // Delete kata using provider
        await ref.read(kataNotifierProvider.notifier).deleteKata(kataId);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$kataName succesvol verwijderd'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fout bij verwijderen kata: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _filterKatas(String query) {
    ref.read(kataNotifierProvider.notifier).searchKatas(query);
  }


  Future<void> _showLogoutConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => TTSResponsiveDialog(
        title: 'Uitloggen',
        child: const Text(
          'Weet je/u zeker dat je uit wilt loggen?',
          semanticsLabel: 'Bevestiging bericht: Weet je zeker dat je uit wilt loggen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              backgroundColor: Colors.lightGreenAccent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text(
              'Nee dankje makker!',
              semanticsLabel: 'Nee dankje makker! Knop om uitloggen te annuleren en in de app te blijven',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text(
              'Ja tuurlijk!',
              semanticsLabel: 'Ja tuurlijk! Knop om te bevestigen en uit te loggen van de applicatie',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
        autoReadContent: true, // Explicitly enable auto-read
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(authNotifierProvider.notifier).signOut();
        if (mounted) {
          // Use a post-frame callback to ensure navigation happens after the widget tree is stable
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.go('/login');
            }
          });
        }
      } catch (e) {
        // Handle logout errors gracefully
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Uitloggen mislukt: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildKataList(List<dynamic> katas) {
    final searchQuery = ref.watch(kataSearchQueryProvider);

    // If search is active, use responsive layout (no reordering during search)
    if (searchQuery.isNotEmpty) {
      return ResponsiveLayout(
        mobile: ListView.builder(
          padding: EdgeInsets.only(
            bottom: ResponsiveUtils.responsiveButtonHeight(context) + 
                    context.responsiveSpacing(SpacingSize.lg),
          ),
          itemCount: katas.length,
          itemBuilder: (context, index) {
            final kata = katas[index];
            return CollapsibleKataCard(
              kata: kata,
              onDelete: () => _deleteKata(kata.id, kata.name),
            );
          },
        ),
        tablet: ResponsiveGrid(
          maxColumns: 2,
          padding: EdgeInsets.only(
            bottom: ResponsiveUtils.responsiveButtonHeight(context) + 
                    context.responsiveSpacing(SpacingSize.lg),
          ),
          mainAxisSpacing: context.responsiveSpacing(SpacingSize.md),
          crossAxisSpacing: context.responsiveSpacing(SpacingSize.md),
          childAspectRatio: 0.8,
          shrinkWrap: false,
          physics: const AlwaysScrollableScrollPhysics(),
          children: katas.map((kata) => CollapsibleKataCard(
            kata: kata,
            onDelete: () => _deleteKata(kata.id, kata.name),
            useAdaptiveWidth: false,
          )).toList(),
        ),
        foldable: ResponsiveGrid(
          maxColumns: 2,
          padding: EdgeInsets.only(
            bottom: ResponsiveUtils.responsiveButtonHeight(context) + 
                    context.responsiveSpacing(SpacingSize.lg),
          ),
          mainAxisSpacing: context.responsiveSpacing(SpacingSize.sm),
          crossAxisSpacing: context.responsiveSpacing(SpacingSize.sm),
          childAspectRatio: 0.85,
          shrinkWrap: false,
          physics: const AlwaysScrollableScrollPhysics(),
          children: katas.map((kata) => CollapsibleKataCard(
            kata: kata,
            onDelete: () => _deleteKata(kata.id, kata.name),
            useAdaptiveWidth: false,
          )).toList(),
        ),
        largeFoldable: ResponsiveGrid(
          maxColumns: 3,
          padding: EdgeInsets.only(
            bottom: ResponsiveUtils.responsiveButtonHeight(context) + 
                    context.responsiveSpacing(SpacingSize.lg),
          ),
          mainAxisSpacing: context.responsiveSpacing(SpacingSize.md),
          crossAxisSpacing: context.responsiveSpacing(SpacingSize.md),
          childAspectRatio: 0.9,
          shrinkWrap: false,
          physics: const AlwaysScrollableScrollPhysics(),
          children: katas.map((kata) => CollapsibleKataCard(
            kata: kata,
            onDelete: () => _deleteKata(kata.id, kata.name),
            useAdaptiveWidth: false,
          )).toList(),
        ),
        desktop: ResponsiveGrid(
          maxColumns: 3,
          padding: EdgeInsets.only(
            bottom: ResponsiveUtils.responsiveButtonHeight(context) + 
                    context.responsiveSpacing(SpacingSize.lg),
          ),
          mainAxisSpacing: context.responsiveSpacing(SpacingSize.md),
          crossAxisSpacing: context.responsiveSpacing(SpacingSize.md),
          childAspectRatio: 0.9,
          shrinkWrap: false,
          physics: const AlwaysScrollableScrollPhysics(),
          children: katas.map((kata) => CollapsibleKataCard(
            kata: kata,
            onDelete: () => _deleteKata(kata.id, kata.name),
            useAdaptiveWidth: false,
          )).toList(),
        ),
      );
    }

    // Use ReorderableListView when not searching (mobile only for drag-and-drop)
    if (context.isMobile) {
      return ReorderableListView.builder(
        padding: EdgeInsets.only(
          bottom: ResponsiveUtils.responsiveButtonHeight(context) + 
                  context.responsiveSpacing(SpacingSize.lg),
        ),
        itemCount: katas.length,
        onReorder: (int oldIndex, int newIndex) {
          ref
              .read(kataNotifierProvider.notifier)
              .reorderKatas(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final kata = katas[index];
          return Container(
            key: ValueKey(kata.id),
            child: CollapsibleKataCard(
              kata: kata,
              onDelete: () => _deleteKata(kata.id, kata.name),
            ),
          );
        },
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              final double animValue = Curves.easeInOut.transform(
                animation.value,
              );
              final double elevation = lerpDouble(0, 6, animValue)!;
              final double scale = lerpDouble(1, 1.02, animValue)!;
              return Transform.scale(
                scale: scale,
                child: Card(elevation: elevation, child: child),
              );
            },
            child: child,
          );
        },
      );
    }

    // For larger screens, use grid layout without reordering
    return ResponsiveLayout(
      mobile: ResponsiveGrid(
        maxColumns: 1,
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: 16,
        ),
        shrinkWrap: false,
        physics: const AlwaysScrollableScrollPhysics(),
        children: katas.map((kata) => CollapsibleKataCard(
          kata: kata,
          onDelete: () => _deleteKata(kata.id, kata.name),
        )).toList(),
      ),
      tablet: ResponsiveGrid(
        maxColumns: 2,
        padding: EdgeInsets.only(
          bottom: ResponsiveUtils.responsiveButtonHeight(context) + 
                  context.responsiveSpacing(SpacingSize.lg),
        ),
        mainAxisSpacing: context.responsiveSpacing(SpacingSize.md),
        crossAxisSpacing: context.responsiveSpacing(SpacingSize.md),
        childAspectRatio: 0.8,
        shrinkWrap: false,
        physics: const AlwaysScrollableScrollPhysics(),
        children: katas.map((kata) => CollapsibleKataCard(
          kata: kata,
          onDelete: () => _deleteKata(kata.id, kata.name),
          useAdaptiveWidth: false,
        )).toList(),
      ),
      foldable: ResponsiveGrid(
        maxColumns: 2,
        padding: EdgeInsets.only(
          bottom: ResponsiveUtils.responsiveButtonHeight(context) + 
                  context.responsiveSpacing(SpacingSize.lg),
        ),
        mainAxisSpacing: context.responsiveSpacing(SpacingSize.sm),
        crossAxisSpacing: context.responsiveSpacing(SpacingSize.sm),
        childAspectRatio: 0.85,
        shrinkWrap: false,
        physics: const AlwaysScrollableScrollPhysics(),
        children: katas.map((kata) => CollapsibleKataCard(
          kata: kata,
          onDelete: () => _deleteKata(kata.id, kata.name),
          useAdaptiveWidth: false,
        )).toList(),
      ),
      largeFoldable: ResponsiveGrid(
        maxColumns: 3,
        padding: EdgeInsets.only(
          bottom: ResponsiveUtils.responsiveButtonHeight(context) + 
                  context.responsiveSpacing(SpacingSize.lg),
        ),
        mainAxisSpacing: context.responsiveSpacing(SpacingSize.md),
        crossAxisSpacing: context.responsiveSpacing(SpacingSize.md),
        childAspectRatio: 0.9,
        shrinkWrap: false,
        physics: const AlwaysScrollableScrollPhysics(),
        children: katas.map((kata) => CollapsibleKataCard(
          kata: kata,
          onDelete: () => _deleteKata(kata.id, kata.name),
          useAdaptiveWidth: false,
        )).toList(),
      ),
      desktop: ResponsiveGrid(
        maxColumns: 3,
        padding: EdgeInsets.only(
          bottom: ResponsiveUtils.responsiveButtonHeight(context) + 
                  context.responsiveSpacing(SpacingSize.lg),
        ),
        mainAxisSpacing: context.responsiveSpacing(SpacingSize.md),
        crossAxisSpacing: context.responsiveSpacing(SpacingSize.md),
        childAspectRatio: 0.9,
        shrinkWrap: false,
        physics: const AlwaysScrollableScrollPhysics(),
        children: katas.map((kata) => CollapsibleKataCard(
          kata: kata,
          onDelete: () => _deleteKata(kata.id, kata.name),
          useAdaptiveWidth: false,
        )).toList(),
      ),
    );
  }

  Widget _buildSearchSection(bool isConnected) {
    return ResponsiveLayout(
      mobile: Column(
        children: [
          _buildSearchBar(),
          if (!isConnected) ...[
            SizedBox(height: context.responsiveSpacing(SpacingSize.sm)),
            const ConnectionStatusIndicator(),
          ],
        ],
      ),
      desktop: Row(
        children: [
          Expanded(flex: 2, child: _buildSearchBar()),
          SizedBox(width: context.responsiveSpacing(SpacingSize.md)),
          if (!isConnected) const ConnectionStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Semantics(
      label: 'Zoek kata\'s invoerveld',
      textField: true,
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Zoek kata\'s...',
          prefixIcon: Icon(
            Icons.search,
            size: AppTheme.getResponsiveIconSize(context),
          ),
          border: OutlineInputBorder(
            borderRadius: context.responsiveBorderRadius,
          ),
        ),
        onChanged: (value) {
          _filterKatas(value);
        },
      ),
    );
  }


  bool _isNetworkError(String? error) {
    if (error == null) return false;
    final errorLower = error.toLowerCase();
    return errorLower.contains('network') ||
           errorLower.contains('connection') ||
           errorLower.contains('timeout') ||
           errorLower.contains('socket') ||
           errorLower.contains('dns') ||
           errorLower.contains('host') ||
           errorLower.contains('no internet');
  }


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
  Widget build(BuildContext context) {
    final kataState = ref.watch(kataNotifierProvider);
    final katas = kataState.filteredKatas;
    final isLoading = kataState.isLoading;
    final error = kataState.error;
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

    return GestureDetector(
      onTap: () {
        // Remove focus from search field when tapping outside
        _searchFocusNode.unfocus();
      },
      child: Scaffold(
          appBar: AppBar(
            title: const Text("Karatapp"),
          actions: [
            // Accessibility quick actions in app bar
            Consumer(
              builder: (context, ref, child) {
                final accessibilityState = ref.watch(accessibilityNotifierProvider);
                final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
                
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    
                    // Combined accessibility settings popup
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.text_fields,
                        color: (accessibilityState.fontSize != AccessibilityFontSize.normal || 
                               accessibilityState.isDyslexiaFriendly)
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      tooltip: 'Tekst instellingen',
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
                          ),
                        ),
                        ...AccessibilityFontSize.values.map((fontSize) {
                          final isSelected = accessibilityState.fontSize == fontSize;
                          return PopupMenuItem<String>(
                            value: 'font_${fontSize.name}',
                            child: Row(
                              children: [
                                Icon(
                                  _getFontSizeIcon(fontSize),
                                  size: 20,
                                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  fontSize == AccessibilityFontSize.small ? 'Klein' :
                                  fontSize == AccessibilityFontSize.normal ? 'Normaal' :
                                  fontSize == AccessibilityFontSize.large ? 'Groot' : 'Extra Groot',
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Theme.of(context).colorScheme.primary : null,
                                  ),
                                ),
                                const Spacer(),
                                if (isSelected)
                                  Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                accessibilityState.isDyslexiaFriendly 
                                    ? Icons.format_line_spacing 
                                    : Icons.format_line_spacing_outlined,
                                size: 20,
                                color: accessibilityState.isDyslexiaFriendly
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              const Flexible(
                                child: Text('Dyslexie vriendelijk'),
                              ),
                              Switch(
                                value: accessibilityState.isDyslexiaFriendly,
                                onChanged: (value) {
                                  accessibilityNotifier.toggleDyslexiaFriendly();
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (String value) {
                        if (value.startsWith('font_')) {
                          final fontSizeName = value.substring(5);
                          final fontSize = AccessibilityFontSize.values.firstWhere(
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
              onPressed: isConnected ? _refreshKatas : null,
              tooltip: isConnected ? 'Kata\'s verversen' : 'Geen verbinding',
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
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    // ignore: sort_child_properties_last
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        currentUser?.userMetadata?['full_name'] ??
                            currentUser?.email ??
                            'User',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    enabled: false,
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person, size: 20),
                        const SizedBox(width: 12),
                        const Flexible(
                          child: Text(
                            'Profiel',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, size: 20),
                        const SizedBox(width: 12),
                        const Flexible(
                          child: Text(
                            'Mijn Favorieten',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.admin_panel_settings, size: 20),
                        const SizedBox(width: 12),
                        const Flexible(
                          child: Text(
                            'Gebruikersbeheer',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
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
                            const Flexible(
                              child: Text(
                                'Hoog Contrast',
                                overflow: TextOverflow.ellipsis,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.logout, size: 20, color: Colors.red),
                        const SizedBox(width: 12),
                        const Flexible(
                          child: Text(
                            'Uitloggen', 
                            style: TextStyle(color: Colors.red),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      _showLogoutConfirmationDialog();
                    },
                  ),
                ],
            ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Enhanced responsive search bar
            ResponsiveContainer(
              padding: context.responsivePadding,
              child: _buildSearchSection(isConnected),
            ),
            // Centralized connection error widget
            const ConnectionErrorWidget(),
            // Local error display (for non-network errors only)
            if (error != null && !_isNetworkError(error))
              ResponsiveContainer(
                margin: context.responsiveMargin,
                padding: context.responsivePadding,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: context.responsiveBorderRadius,
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: double.infinity),
                  child: OverflowSafeRow(
                    children: [
                      Icon(
                        Icons.error, 
                        color: Colors.red,
                        size: AppTheme.getResponsiveIconSize(context),
                      ),
                      SizedBox(width: context.responsiveSpacing(SpacingSize.sm)),
                      OverflowSafeExpanded(
                        child: OverflowSafeText(
                          'Fout: $error',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.red,
                          ),
                          maxLines: 2,
                        ),
                      ),
                      OverflowSafeButton(
                        onPressed: () {
                          ref.read(kataNotifierProvider.notifier).clearError();
                        },
                        isElevated: false,
                        child: const Text('Sluiten'),
                      ),
                    ],
                  ),
                ),
              ),
            // Responsive kata list with flexible height - use Expanded instead of OverflowSafeExpanded
            Expanded(
              child: isLoading
                  ? const ModernKataLoadingList(itemCount: 3, useGrid: true)
                  : RefreshIndicator(
                      onRefresh: _refreshKatas,
                      child: katas.isEmpty
                          ? Center(
                              child: OverflowSafeText(
                                'Geen kata\'s gevonden',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : _buildKataList(katas),
                    ),
            ),
          ],
        ),
        floatingActionButton: Semantics(
          label: 'Nieuwe kata toevoegen',
          button: true,
          child: FloatingActionButton(
            heroTag: "home_fab",
            onPressed: () {
              _showAddKataDialog();
            },
            child: const Icon(Icons.add),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      ),
    );
  }

  Future<void> _showAddKataDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final styleController = TextEditingController();
    // Simplified: just one list for all selected images
    List<File> selectedImages = [];
    List<String> videoUrls = [];
    bool isProcessing = false;


    // Create a stateful widget for the dialog content to handle image picking
    await showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                minWidth: 300,
              ),
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              title: Container(
                padding: const EdgeInsets.only(bottom: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey, width: 0.5),
                  ),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: double.infinity),
                  child: Row(
                    children: [
                      Icon(Icons.sports_martial_arts, color: Colors.blue, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Nieuwe Kata\nToevoegen",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 8),
                      // Basic Information Section
                      Text(
                        "Basis Informatie",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(height: 12),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: "Kata Naam",
                          hintText: "Voer kata naam in",
                          prefixIcon: const Icon(Icons.sports_martial_arts, color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            // Trigger rebuild to update button state
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: styleController,
                        decoration: InputDecoration(
                          labelText: "Stijl",
                          hintText: "Voer karate stijl in (bijv. Wado Ryu)",
                          prefixIcon: const Icon(Icons.style, color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: "Beschrijving",
                          hintText: "Voer kata beschrijving in",
                          prefixIcon: const Icon(Icons.description, color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                        ),
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                      ),
                      SizedBox(height: 20),

                      // Images section
                      Row(
                        children: [
                          const Icon(Icons.photo_library, color: Colors.blue, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            "Afbeeldingen (${selectedImages.length})",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Image picker buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isProcessing
                                  ? null
                                  : () async {
                                      final images =
                                          await ImageUtils.pickMultipleImagesFromGallery();
                                      if (images.isNotEmpty) {
                                        setState(() {
                                          selectedImages.addAll(images);
                                        });
                                      }
                                    },
                              icon: const Icon(Icons.photo_library, size: 18),
                              label: const Text("Galerij"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: isProcessing
                                  ? null
                                  : () async {
                                      final image =
                                          await ImageUtils.captureImageWithCamera();
                                      if (image != null) {
                                        setState(() {
                                          selectedImages.add(image);
                                        });
                                      }
                                    },
                              icon: const Icon(Icons.camera_alt, size: 18),
                              label: const Text("Camera"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Selected images preview with reordering
                      if (selectedImages.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${selectedImages.length} afbeelding(en) geselecteerd',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue,
                                ),
                              ),
                              SizedBox(height: 8),
                              SizedBox(
                                height: 100,
                                child: ReorderableListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: selectedImages.length,
                                  onReorder: (int oldIndex, int newIndex) {
                                    setState(() {
                                      if (newIndex > oldIndex) {
                                        newIndex -= 1;
                                      }
                                      final item = selectedImages.removeAt(
                                        oldIndex,
                                      );
                                      selectedImages.insert(newIndex, item);
                                    });
                                  },
                                  itemBuilder: (context, index) {
                                    return Container(
                                      key: ValueKey(selectedImages[index].path),
                                      width: 80,
                                      height: 80,
                                      margin: const EdgeInsets.only(right: 8),
                                      child: Stack(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.blue,
                                                width: 2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: Image.file(
                                                selectedImages[index],
                                                fit: BoxFit.cover,
                                                width: 76,
                                                height: 76,
                                              ),
                                            ),
                                          ),
                                          // Position indicator
                                          Positioned(
                                            top: 2,
                                            left: 2,
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: Colors.blue,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                '${index + 1}',
                                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Remove button
                                          Positioned(
                                            top: 2,
                                            right: 2,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  selectedImages.removeAt(
                                                    index,
                                                  );
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Drag handle
                                          Positioned(
                                            bottom: 2,
                                            right: 2,
                                            child: Container(
                                              padding: const EdgeInsets.all(1),
                                              decoration: BoxDecoration(
                                                color: Colors.black54,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: const Icon(
                                                Icons.drag_handle,
                                                color: Colors.white,
                                                size: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Houd ingedrukt en sleep om te herordenen',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Video URLs section
                      SizedBox(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.video_library, color: Colors.purple, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            "Video URLs (${videoUrls.length})",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),

                      // Video URL input field
                      TextField(
                        decoration: InputDecoration(
                          labelText: "Voer video URL in",
                          hintText: "https://www.youtube.com/watch?v=...",
                          prefixIcon: const Icon(Icons.link, color: Colors.purple),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.purple, width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.url,
                        onSubmitted: (url) {
                          if (url.trim().isNotEmpty && !videoUrls.contains(url.trim())) {
                            setState(() {
                              videoUrls.add(url.trim());
                            });
                          }
                        },
                      ),

                      // Video URLs list
                      if (videoUrls.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.purple.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${videoUrls.length} video URL(s) toegevoegd',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.purple,
                                ),
                              ),
                              SizedBox(height: 8),
                              ...videoUrls.asMap().entries.map((entry) {
                                final index = entry.key;
                                final url = entry.value;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey[800]
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.purple,
                                        radius: 12,
                                        child: Text(
                                          '${index + 1}',
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          url,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context).brightness == Brightness.dark
                                                ? Colors.white
                                                : Colors.black,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            videoUrls.removeAt(index);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],

                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isProcessing
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Colors.grey, width: 1.5),
                        ),
                        child: Text(
                          "Annuleren",
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (isProcessing || nameController.text.isEmpty)
                            ? null
                            : () async {
                          setState(() {
                            isProcessing = true;
                          });

                          try {
                            // Use the kata provider to create the kata
                            await ref.read(kataNotifierProvider.notifier).addKata(
                              name: nameController.text.trim(),
                              description: descriptionController.text.trim(),
                              style: styleController.text.trim().isNotEmpty 
                                  ? styleController.text.trim() 
                                  : 'Unknown',
                              images: selectedImages.isNotEmpty ? selectedImages : null,
                              videoUrls: videoUrls.isNotEmpty ? videoUrls : null,
                            );

                            if (context.mounted) {
                              Navigator.pop(context); // Close add kata dialog

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    selectedImages.isNotEmpty
                                        ? 'Kata "${nameController.text}" created with ${selectedImages.length} image(s)!'
                                        : 'Kata "${nameController.text}" created!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }

                            // Refresh kata list
                            ref
                                .read(kataNotifierProvider.notifier)
                                .refreshKatas();
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error creating kata: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            setState(() {
                              isProcessing = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    minimumSize: const Size(120, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: isProcessing
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              selectedImages.isNotEmpty
                                  ? 'Uploading ${selectedImages.length} image(s)...'
                                  : 'Creating...',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : Text(
                          "Kata\nToevoegen",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            );
          },
        );
      },
    );
  }
}
