import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/collapsible_kata_card.dart';
import '../widgets/connection_error_widget.dart';
import '../widgets/skeleton_kata_card.dart';
import '../providers/auth_provider.dart';
import '../providers/kata_provider.dart';
import '../providers/role_provider.dart';
import '../providers/network_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/accessibility_provider.dart';
import '../services/role_service.dart';
import '../utils/image_utils.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

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

  Future<void> _cleanupOrphanedImages() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'Verweesde afbeeldingen opruimen?',
                semanticsLabel: 'Afbeeldingen opruimen bevestiging popup',
              ),
            ),
          ],
        ),
        content: const Text(
          'Dit zal scannen naar en verwijderen van afbeeldingen die niet bij een bestaande kata horen. '
          'Dit omvat afbeeldingen in mappen zoals "0" of "temp_" die mogelijk zijn achtergebleven. '
          'Deze actie kan niet ongedaan worden gemaakt.',
          semanticsLabel: 'Waarschuwing bericht: Dit zal scannen naar en verwijderen van afbeeldingen die niet bij een bestaande kata horen. Dit omvat afbeeldingen in mappen zoals nul of temp die mogelijk zijn achtergebleven. Deze actie kan niet ongedaan worden gemaakt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Annuleren',
              semanticsLabel: 'Annuleren knop om het opruimen te annuleren en terug te gaan',
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text(
              'Opruimen',
              semanticsLabel: 'Opruimen knop om te bevestigen en de verweesde afbeeldingen te verwijderen',
            ),
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
                  Text('Scannen naar verweesde afbeeldingen...'),
                ],
              ),
              duration: Duration(seconds: 30),
            ),
          );
        }

        // Run cleanup using provider
        final deletedPaths = await ref
            .read(kataNotifierProvider.notifier)
            .cleanupOrphanedImages();

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          if (deletedPaths.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${deletedPaths.length} verweesde afbeeldingen succesvol opgeruimd',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Geen verweesde afbeeldingen gevonden - opslag is schoon!'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fout tijdens opruimen: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteKata(int kataId, String kataName) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text('$kataName verwijderen?')),
          ],
        ),
        content: const Text(
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
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Expanded(
              child: Text(
                'Uitloggen',
                semanticsLabel: 'Uitloggen bevestiging popup',
              ),
            ),
          ],
        ),
        content: const Text(
          'Weet je/u zeker dat je uit wilt loggen?',
          semanticsLabel: 'Bevestiging bericht: Weet je zeker dat je uit wilt loggen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              backgroundColor: Colors.lightGreenAccent,
            ),
            child: const Text(
              'Nee dankje makker!',
              semanticsLabel: 'Nee dankje makker! Knop om uitloggen te annuleren en in de app te blijven',
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlueAccent,
            ),
            child: const Text(
              'Ja tuurlijk!',
              semanticsLabel: 'Ja tuurlijk! Knop om te bevestigen en uit te loggen van de applicatie',
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  Widget _buildKataList(List<dynamic> katas) {
    final searchQuery = ref.watch(kataSearchQueryProvider);

    // If search is active, use regular ListView (no reordering during search)
    if (searchQuery.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 80.0), // Add bottom padding for better scrolling
        itemCount: katas.length,
        itemBuilder: (context, index) {
          final kata = katas[index];
          return CollapsibleKataCard(
            kata: kata,
            onDelete: () => _deleteKata(kata.id, kata.name),
          );
        },
      );
    }

    // Use ReorderableListView when not searching
    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: 80.0), // Add bottom padding for better scrolling
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
        return role == UserRole.host;
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
                
                return Row(
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
                              const Text('Dyslexie vriendelijk'),
                              const Spacer(),
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
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            currentUser?.userMetadata?['full_name'] ??
                                currentUser?.email ??
                                'User',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    enabled: false,
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    child: Row(
                      children: [
                        const Icon(Icons.person, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Profiel')),
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
                      children: [
                        const Icon(Icons.favorite, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Mijn Favorieten')),
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
                  // Only show admin options for hosts
                  if (isHost)
                    PopupMenuItem<String>(
                    child: Row(
                      children: [
                        const Icon(Icons.admin_panel_settings, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Gebruikersbeheer')),
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
                  if (isHost)
                    PopupMenuItem<String>(
                      child: Row(
                        children: [
                          const Icon(Icons.cleaning_services, size: 20),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('Afbeeldingen opruimen')),
                        ],
                      ),
                      onTap: () {
                        // Add a slight delay to ensure the popup menu closes first
                        Future.microtask(() {
                          if (context.mounted) {
                            _cleanupOrphanedImages();
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
                          children: [
                            const Icon(Icons.contrast, size: 20),
                            const SizedBox(width: 12),
                            const Expanded(child: Text('Hoog Contrast')),
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
                      children: [
                        const Icon(Icons.logout, size: 20, color: Colors.red),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Uitloggen', style: TextStyle(color: Colors.red))),
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
            // Search bar with connection status
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Semantics(
                    label: 'Zoek kata\'s invoerveld',
                    textField: true,
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: const InputDecoration(
                        hintText: 'Zoek kata\'s...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(25.0)),
                        ),
                      ),
                      onChanged: (value) {
                        _filterKatas(value);
                      },
                    ),
                  ),
                  // Small connection status indicator below search
                  if (!isConnected) ...[
                    const SizedBox(height: 8),
                    const ConnectionStatusIndicator(),
                  ],
                ],
              ),
            ),
            // Centralized connection error widget
            const ConnectionErrorWidget(),
            // Local error display (for non-network errors only)
            if (error != null && !_isNetworkError(error))
              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'Error: $error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(kataNotifierProvider.notifier).clearError();
                      },
                      child: const Text('Dismiss'),
                    ),
                  ],
                ),
              ),
            // Kata list
            Expanded(
              child: isLoading
                  ? const SkeletonKataList(itemCount: 3)
                  : RefreshIndicator(
                      onRefresh: _refreshKatas,
                      child: katas.isEmpty
                          ? const Center(
                              child: Text(
                                'Geen kata\'s gevonden',
                                style: TextStyle(
                                  fontSize: 18,
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
            onPressed: () {
              _showAddKataDialog();
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }


  void _showAddKataDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final styleController = TextEditingController();
    // Simplified: just one list for all selected images
    List<File> selectedImages = [];
    List<String> videoUrls = [];
    bool isProcessing = false;


    // Create a stateful widget for the dialog content to handle image picking
    showDialog(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Expanded(child: Text("Nieuwe Kata Toevoegen")),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Text fields
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Kata Naam",
                          hintText: "Voer kata naam in",
                          prefixIcon: Icon(Icons.sports_martial_arts),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: styleController,
                        decoration: const InputDecoration(
                          labelText: "Stijl",
                          hintText: "Voer karate stijl in (bijv. Wado Ryu)",
                          prefixIcon: Icon(Icons.style),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: "Beschrijving",
                          hintText: "Voer kata beschrijving in",
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        keyboardType: TextInputType.multiline,
                      ),
                      const SizedBox(height: 20),

                      // Images section
                      Row(
                        children: [
                          const Icon(Icons.photo_library, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            "Afbeeldingen (${selectedImages.length})",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Selected images preview with reordering
                      if (selectedImages.isNotEmpty) ...[
                        const SizedBox(height: 16),
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
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 8),
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
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
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
                              const SizedBox(height: 4),
                              const Text(
                                'Houd ingedrukt en sleep om te herordenen',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Video URLs section
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.video_library, color: Colors.purple),
                          const SizedBox(width: 8),
                          Text(
                            "Video URLs (${videoUrls.length})",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Video URL input field
                      TextField(
                        decoration: const InputDecoration(
                          labelText: "Voer video URL in",
                          hintText: "https://www.youtube.com/watch?v=...",
                          prefixIcon: Icon(Icons.link),
                          border: OutlineInputBorder(),
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
                        const SizedBox(height: 16),
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
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.purple,
                                ),
                              ),
                              const SizedBox(height: 8),
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
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          url,
                                          style: TextStyle(
                                            fontSize: 12,
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
                        ),
                        child: const Text("Annuleren"),
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
                            // Show loading indicator
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => AlertDialog(
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const CircularProgressIndicator(),
                                    const SizedBox(height: 16),
                                    Text(
                                      selectedImages.isNotEmpty
                                          ? 'Creating kata and uploading ${selectedImages.length} image(s)...'
                                          : 'Creating kata...',
                                    ),
                                  ],
                                ),
                              ),
                            );

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
                              Navigator.pop(context); // Close loading dialog
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
                              Navigator.pop(context); // Close loading dialog
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
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text("Kata Toevoegen"),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
