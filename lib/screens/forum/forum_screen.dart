import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/forum_models.dart';
import '../../providers/forum_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/permission_provider.dart';
import '../../providers/interaction_provider.dart';
import '../../providers/accessibility_provider.dart';
import '../../providers/network_provider.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/skeleton_forum_post.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/image_gallery.dart';
import '../../utils/responsive_utils.dart';
import '../../core/navigation/app_router.dart';
import 'forum_post_detail_screen.dart';
import '../create_forum_post_screen.dart';
import '../../widgets/enhanced_accessible_text.dart';
part 'forum_screen_helpers.dart';

class ForumScreen extends ConsumerStatefulWidget {
  const ForumScreen({super.key});

  @override
  ConsumerState<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends ConsumerState<ForumScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _categoryScrollController = ScrollController();
  int? _selectedPostId;
  ForumCategory? _localSelectedCategory; // Local state for category selection

  @override
  void initState() {
    super.initState();
    // Initialize local state with provider state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final providerCategory = ref.read(forumSelectedCategoryProvider);
      final providerSearchQuery = ref.read(forumSearchQueryProvider);
      if (mounted) {
        setState(() {
          _localSelectedCategory = providerCategory;
        });
        // Synchronize search controller with provider state
        _searchController.text = providerSearchQuery;
        // Re-apply search if there was a previous search query
        if (providerSearchQuery.isNotEmpty) {
          _filterPosts(providerSearchQuery);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _categoryScrollController.dispose();
    super.dispose();
  }

  void _setLocalCategory(ForumCategory? category) {
    setState(() {
      _localSelectedCategory = category;
    });
  }









  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(forumPostsProvider);
    final isLoading = ref.watch(forumLoadingProvider);
    final error = ref.watch(forumErrorProvider);

    return GestureDetector(
      onTap: () {
        _searchFocusNode.unfocus();
      },
      child: Scaffold(
      appBar: AppBar(
        title: Consumer(
          builder: (context, ref, child) {
            final accessibilityState = ref.watch(accessibilityNotifierProvider);
            final isExtraLarge = accessibilityState.forumFontSize == AccessibilityFontSize.extraLarge;
            final isDyslexiaFriendly = accessibilityState.isDyslexiaFriendly;
            
            // For dyslexia + extra large: keep Forum text large (don't reduce)
            // For other cases: use default or larger sizes
            double? fontSize;
            if (isDyslexiaFriendly && isExtraLarge) {
              // Keep it large even with dyslexia + extra large
              fontSize = 22.0; // Large font size
            } else if (isExtraLarge) {
              fontSize = 24.0; // Extra large for regular font
            } else if (accessibilityState.forumFontSize == AccessibilityFontSize.large) {
              fontSize = 22.0; // Large size
            } else {
              fontSize = null; // Use default
            }
            
            return Text(
              'Forum',
              style: TextStyle(
                fontSize: fontSize,
              ),
              overflow: TextOverflow.ellipsis, // Show full word, no dots
              maxLines: 1,
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
              onPressed: () => context.goBackOrHome(),
        ),
        actions: [
          // Status indicators (moved from title to actions)
          Consumer(
            builder: (context, ref, child) {
              final isConnected = ref.watch(isConnectedProvider);
              final pendingOperations = ref.watch(forumPendingOperationsProvider);
              final hasPendingOperations = pendingOperations > 0;
              final accessibilityState = ref.watch(accessibilityNotifierProvider);
              final isExtraLarge = accessibilityState.forumFontSize == AccessibilityFontSize.extraLarge;
              final isDyslexiaFriendly = accessibilityState.isDyslexiaFriendly;
              final shouldReduceSize = isExtraLarge && isDyslexiaFriendly;
              
              // Reduce sizes when both extra large and dyslexia are on
              final scaleFactor = shouldReduceSize ? 0.55 : 0.75;
              final iconSize = (10 * scaleFactor).clamp(7.0, 10.0);
              final fontSize = (9 * scaleFactor).clamp(8.0, 9.0);
              final padding = EdgeInsets.symmetric(
                horizontal: (3 * scaleFactor).clamp(2.0, 3.0),
                vertical: (1 * scaleFactor).clamp(0.5, 1.0),
              );

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isConnected) ...[
                    Container(
                      padding: padding,
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off, size: iconSize, color: Colors.orange),
                          SizedBox(width: 2 * scaleFactor),
                          Text(
                            'Offline',
                            style: TextStyle(
                              fontSize: fontSize,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (hasPendingOperations) ...[
                    SizedBox(width: !isConnected ? 2 : 0),
                    Container(
                      padding: padding,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sync, size: iconSize, color: Colors.blue),
                          SizedBox(width: 2 * scaleFactor),
                          Text(
                            '$pendingOperations',
                            style: TextStyle(
                              fontSize: fontSize,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          // Forum accessibility settings
          Consumer(
            builder: (context, ref, child) {
              final accessibilityState = ref.watch(accessibilityNotifierProvider);
              final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
              final isExtraLarge = accessibilityState.forumFontSize == AccessibilityFontSize.extraLarge;
              final isDyslexiaFriendly = accessibilityState.isDyslexiaFriendly;
              final shouldReduceSize = isExtraLarge && isDyslexiaFriendly;
              
              // Reduce icon sizes when both extra large and dyslexia are on
              final iconSize = shouldReduceSize ? 20.0 : 24.0;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Combined accessibility settings popup
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.text_fields,
                      size: iconSize,
                      color: (accessibilityState.forumFontSize != AccessibilityFontSize.normal ||
                             accessibilityState.isDyslexiaFriendly)
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    tooltip: 'Tekst instellingen',
                    padding: EdgeInsets.zero,
                    iconSize: iconSize,
                    constraints: BoxConstraints(
                      minWidth: shouldReduceSize
                          ? 280
                          : (accessibilityState.forumFontSize == AccessibilityFontSize.extraLarge ||
                             accessibilityState.isDyslexiaFriendly
                              ? 320
                              : 280),
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
                        ),
                      ),
                      ...AccessibilityFontSize.values.map((fontSize) {
                        final isSelected = accessibilityState.forumFontSize == fontSize;
                        return PopupMenuItem<String>(
                          value: 'font_${fontSize.name}',
                          child: Row(
                            children: [
                              Icon(
                                _getFontSizeIcon(fontSize),
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
                                overflow: TextOverflow.ellipsis,
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
        ],
      ),
        body: SafeArea(
          child: ResponsiveLayout(
            mobile: _buildForumList(posts, isLoading, error),
            tablet: _buildForumList(posts, isLoading, error),
            desktop: _buildForumList(posts, isLoading, error),
            largeDesktop: _buildForumList(posts, isLoading, error),
          ),
        ),
        floatingActionButton: Consumer(
          builder: (context, ref, child) {
            final isConnected = ref.watch(isConnectedProvider);
            return FloatingActionButton(
              heroTag: "forum_fab",
              onPressed: isConnected ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateForumPostScreen(),
                  ),
                );
              } : null,
              backgroundColor: isConnected ? null : Colors.grey,
              child: Icon(
                isConnected ? Icons.add : Icons.cloud_off,
                color: isConnected ? null : Colors.white70,
              ),
              tooltip: isConnected ? 'Nieuw bericht maken' : 'Niet beschikbaar offline',
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
