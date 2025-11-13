import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/responsive_utils.dart';
import '../../providers/kata_provider.dart';
import '../../widgets/enhanced_accessible_text.dart';

/// Home Screen Search Manager - Handles search and filtering functionality
class HomeScreenSearchManager {
  /// Filter katas based on search query
  static void filterKatas(WidgetRef ref, String query) {
    ref.read(kataNotifierProvider.notifier).searchKatas(query);
  }

  /// Clear search and refresh katas
  static Future<void> clearSearchAndRefresh(WidgetRef ref, TextEditingController searchController) async {
    // Clear search when refreshing
    searchController.clear();
    ref.read(kataNotifierProvider.notifier).searchKatas('');

    // Refresh kata data
    await ref.read(kataNotifierProvider.notifier).refreshKatas();
  }

  /// Build search bar widget
  static Widget buildSearchBar(BuildContext context, TextEditingController searchController, FocusNode searchFocusNode, Function(String) onSearchChanged) {
    return Padding(
      padding: EdgeInsets.all(context.responsiveSpacing(SpacingSize.md)),
      child: SizedBox(
        width: double.infinity,
        child: EnhancedAccessibleTextField(
          controller: searchController,
          focusNode: searchFocusNode,
          maxLines: 1, // Ensure single line for search
          customTTSLabel: 'Zoek kata\'s invoerveld',
          onChanged: onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Zoek kata\'s...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          ),
        ),
      ),
    );
  }

  /// Get search query from provider
  static String getSearchQuery(WidgetRef ref) {
    return ref.watch(kataSearchQueryProvider);
  }

  /// Check if search is active
  static bool isSearchActive(WidgetRef ref) {
    final searchQuery = getSearchQuery(ref);
    return searchQuery.isNotEmpty;
  }
}
