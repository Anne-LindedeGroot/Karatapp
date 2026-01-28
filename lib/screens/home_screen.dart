import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/connection_error_widget.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/modern_loading_widget.dart';
import '../widgets/overflow_safe_widgets.dart';
import '../providers/auth_provider.dart';
import '../providers/kata_provider.dart';
import '../providers/ohyo_provider.dart';
import '../providers/network_provider.dart';
import '../providers/role_provider.dart';
import '../services/role_service.dart';
import '../utils/responsive_utils.dart';
import '../core/navigation/app_router.dart';
import 'home/home_screen_dialog_manager.dart';
import 'home/home_screen_search_manager.dart';
import 'home/home_screen_app_bar.dart';
import 'home/home_screen_search_section.dart';
import 'home/home_screen_kata_list.dart';
import 'home/home_ohyo_list.dart';
import 'home/home_screen_error_display.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialSearchQuery,
  });

  final int initialTabIndex;
  final String? initialSearchQuery;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _searchScrollController = ScrollController();
  late TabController _tabController;
  bool _hasAppliedInitialSearch = false;
  bool _hasInitializedKatas = false;
  bool _hasInitializedOhyos = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);

    // Listen to tab changes to clear search when switching tabs
    _tabController.addListener(_onTabChanged);

    // Initialize kata and ohyo loading when home screen is shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only load the active tab immediately for faster startup
      if (widget.initialTabIndex == 0) {
        _initializeKatasIfNeeded();
      } else {
        _initializeOhyosIfNeeded();
      }
      _applyInitialSearchIfNeeded();
    });
    // TTS announcement disabled - only speak when user clicks TTS button
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _announcePageLoad();
    // });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchScrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _applyInitialSearchIfNeeded() {
    if (_hasAppliedInitialSearch) {
      return;
    }
    final initialQuery = widget.initialSearchQuery?.trim();
    if (initialQuery == null || initialQuery.isEmpty) {
      return;
    }
    _hasAppliedInitialSearch = true;
    _searchController.text = initialQuery;
    if (_tabController.index == 0) {
      _filterKatas(initialQuery);
    } else {
      _filterOhyos(initialQuery);
    }
  }

  void _onTabChanged() {
    if (_tabController.index == 0) {
      _initializeKatasIfNeeded();
    } else if (_tabController.index == 1) {
      _initializeOhyosIfNeeded();
    }
    // Clear search when switching tabs to avoid confusion
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
      _searchFocusNode.unfocus();

      // Reset the appropriate provider based on the new tab
      if (_tabController.index == 0) {
        // Switched to Kata tab - reset kata search
        ref.read(kataNotifierProvider.notifier).searchKatas('');
      } else if (_tabController.index == 1) {
        // Switched to Ohyo tab - reset ohyo search
        ref.read(ohyoNotifierProvider.notifier).resetOhyoTab();
      }
    }
  }

  void _initializeKatasIfNeeded() {
    if (_hasInitializedKatas) {
      return;
    }
    _hasInitializedKatas = true;
    ref.read(kataNotifierProvider.notifier).initializeKataLoading();
  }

  void _initializeOhyosIfNeeded() {
    if (_hasInitializedOhyos) {
      return;
    }
    _hasInitializedOhyos = true;
    ref.read(ohyoNotifierProvider.notifier).initializeOhyoLoading();
  }

  Future<void> _refreshKatas() async {
    await HomeScreenSearchManager.clearSearchAndRefresh(ref, _searchController);
  }

  Future<void> _deleteKata(int kataId, String kataName) async {
    // Show confirmation dialog
    final confirmed = await HomeScreenDialogManager.showDeleteKataConfirmationDialog(context, kataName);

    if (confirmed) {
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

  Future<void> _deleteOhyo(int ohyoId, String ohyoName) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ohyo verwijderen'),
        content: Text('Weet je zeker dat je "$ohyoName" wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      try {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Ohyo en afbeeldingen verwijderen...'),
                ],
              ),
              duration: Duration(seconds: 10),
            ),
          );
        }

        // Delete ohyo using provider
        await ref.read(ohyoNotifierProvider.notifier).deleteOhyo(ohyoId);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$ohyoName succesvol verwijderd'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fout bij verwijderen ohyo: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _refreshOhyos() async {
    await ref.read(ohyoNotifierProvider.notifier).loadOhyos();
  }

  void _filterKatas(String query) {
    ref.read(kataNotifierProvider.notifier).searchKatas(query);
  }

  void _filterOhyos(String query) {
    ref.read(ohyoNotifierProvider.notifier).searchOhyos(query);
  }

  void _resetOhyoTab() {
    // Clear search text
    _searchController.clear();
    // Reset focus
    _searchFocusNode.unfocus();
    // Reset ohyo provider state
    ref.read(ohyoNotifierProvider.notifier).resetOhyoTab();
  }

  PreferredSizeWidget _buildAppBar() {
    return HomeScreenAppBar(
      onRefresh: () {
        _refreshKatas();
        _refreshOhyos();
      },
      onLogout: _showLogoutConfirmationDialog,
      onResetOhyoTab: _resetOhyoTab,
      showResetButton: false, // Removed home icon - user is already on homepage
    );
  }

  Future<void> _showLogoutConfirmationDialog() async {
    final confirmed = await HomeScreenDialogManager.showLogoutConfirmationDialog(context);

    if (confirmed) {
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
    return HomeScreenKataList(
      katas: katas,
      onDeleteKata: _deleteKata,
      onRefresh: _refreshKatas,
    );
  }

  Widget _buildOhyoList(List<dynamic> ohyos) {
    return HomeOhyoList(
      ohyos: ohyos,
      onDelete: _deleteOhyo,
      onRefresh: _refreshOhyos,
    );
  }

  Widget _buildSearchSection(bool isConnected) {
    return HomeScreenSearchSection(
      searchController: _searchController,
      searchFocusNode: _searchFocusNode,
      scrollController: _searchScrollController,
      onSearchChanged: _tabController.index == 0 ? _filterKatas : _filterOhyos,
      isConnected: isConnected,
      currentTabIndex: _tabController.index,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final kataState = ref.watch(kataNotifierProvider);
    final ohyoState = ref.watch(ohyoNotifierProvider);
    final katas = kataState.filteredKatas;
    final ohyos = ohyoState.filteredOhyos;
    final isKataLoading = kataState.isLoading;
    final isOhyoLoading = ohyoState.isLoading;
    final kataError = kataState.error;
    final ohyoError = ohyoState.error;
    final isConnected = ref.watch(isConnectedProvider);

    return GestureDetector(
      onTap: () {
        // Remove focus from search field when tapping outside
        _searchFocusNode.unfocus();
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                mainAxisSize: MainAxisSize.max,
            children: [
              // Enhanced responsive search bar
              ResponsiveContainer(
                padding: context.responsivePadding,
                child: _buildSearchSection(isConnected),
              ),
            // Centralized connection error widget
            const ConnectionErrorWidget(),
            // Local error display (for non-network errors only)
            HomeScreenErrorDisplay(
              error: _tabController.index == 0 ? kataError : ohyoError,
              onClearError: () {
                if (_tabController.index == 0) {
                  ref.read(kataNotifierProvider.notifier).clearError();
                } else {
                  ref.read(ohyoNotifierProvider.notifier).clearError();
                }
              },
            ),
            // Tab bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  icon: Icon(Icons.self_improvement),
                  text: 'Kata',
                ),
                Tab(
                  icon: Icon(Icons.sports_martial_arts),
                  text: 'Ohyo',
                ),
              ],
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Theme.of(context).colorScheme.primary,
                    isScrollable: false,
            ),
                  // Tab content - Expanded to take remaining space
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Kata tab
                  isKataLoading
                      ? const ModernKataLoadingList(itemCount: 3, useGrid: true)
                      : RefreshIndicator(
                          onRefresh: _refreshKatas,
                          child: katas.isEmpty
                              ? Center(
                                  child: OverflowSafeText(
                                    'Geen kata\'s gevonden',
                                    style: Theme.of(context).textTheme.headlineSmall
                                        ?.copyWith(color: Colors.grey),
                                  ),
                                )
                              : _buildKataList(katas),
                        ),
                  // Ohyo tab
                  isOhyoLoading
                      ? const ModernKataLoadingList(itemCount: 3, useGrid: true)
                      : RefreshIndicator(
                          onRefresh: _refreshOhyos,
                          child: ohyos.isEmpty
                              ? Center(
                                  child: OverflowSafeText(
                                    'Geen ohyo\'s gevonden',
                                    style: Theme.of(context).textTheme.headlineSmall
                                        ?.copyWith(color: Colors.grey),
                                  ),
                                )
                              : _buildOhyoList(ohyos),
                        ),
                ],
              ),
            ),
          ],
              );
            },
          ),
        ),
        floatingActionButton: isKeyboardOpen
            ? null
            : Consumer(
                builder: (context, ref, child) {
                  final userRoleAsync = ref.watch(currentUserRoleProvider);

                  return userRoleAsync.when(
                    data: (role) => Semantics(
                      label: _tabController.index == 0
                          ? 'Nieuwe kata toevoegen'
                          : 'Nieuwe ohyo toevoegen',
                      button: true,
                      child: FloatingActionButton(
                        heroTag: null,
                        onPressed: () {
                          if (_tabController.index == 0) {
                            context.goToCreateKata();
                          } else {
                            // Check permissions for ohyo creation (same as kata)
                            if (role != UserRole.host) {
                              _showPermissionDeniedDialog(context);
                            } else {
                              context.goToCreateOhyo();
                            }
                          }
                        },
                        child: const Icon(Icons.add),
                      ),
                    ),
                    loading: () => const FloatingActionButton(
                      heroTag: null,
                      onPressed: null,
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stack) => FloatingActionButton(
                      heroTag: null,
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Fout bij laden gebruikersrol: $error')),
                      ),
                      child: const Icon(Icons.error),
                    ),
                  );
                },
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      ),
    );
  }


  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Geen Toegang'),
        content: const Text(
          "Alleen hosts kunnen nieuwe ohyo's toevoegen. Neem contact op met een host om toegang te krijgen.",
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
