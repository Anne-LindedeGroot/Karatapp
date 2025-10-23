import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/connection_error_widget.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/modern_loading_widget.dart';
import '../widgets/overflow_safe_widgets.dart';
import '../providers/auth_provider.dart';
import '../providers/kata_provider.dart';
import '../providers/network_provider.dart';
import '../utils/responsive_utils.dart';
import 'home/home_screen_dialog_manager.dart';
import 'home/home_screen_search_manager.dart';
import 'home/home_screen_app_bar.dart';
import 'home/home_screen_search_section.dart';
import 'home/home_screen_kata_list.dart';
import 'home/home_screen_add_kata_dialog.dart';
import 'home/home_screen_error_display.dart';

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

  void _filterKatas(String query) {
    ref.read(kataNotifierProvider.notifier).searchKatas(query);
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
    );
  }

  Widget _buildSearchSection(bool isConnected) {
    return HomeScreenSearchSection(
      searchController: _searchController,
      searchFocusNode: _searchFocusNode,
      onSearchChanged: _filterKatas,
      isConnected: isConnected,
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

  @override
  Widget build(BuildContext context) {
    final kataState = ref.watch(kataNotifierProvider);
    final katas = kataState.filteredKatas;
    final isLoading = kataState.isLoading;
    final error = kataState.error;
    final isConnected = ref.watch(isConnectedProvider);

    return GestureDetector(
      onTap: () {
        // Remove focus from search field when tapping outside
        _searchFocusNode.unfocus();
      },
      child: Scaffold(
        appBar: HomeScreenAppBar(
          onRefresh: _refreshKatas,
          onLogout: _showLogoutConfirmationDialog,
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
            HomeScreenErrorDisplay(
              error: error,
              onClearError: () {
                ref.read(kataNotifierProvider.notifier).clearError();
              },
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
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(color: Colors.grey),
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
    await showDialog(
      context: context,
      builder: (context) => const HomeScreenAddKataDialog(),
    );
  }
}
