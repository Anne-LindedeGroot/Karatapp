import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/connection_error_widget.dart';
import '../../widgets/enhanced_accessible_text.dart';
import '../../utils/responsive_utils.dart';
import '../../core/theme/app_theme.dart';

class HomeScreenSearchSection extends ConsumerWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSearchChanged;
  final bool isConnected;
  final int currentTabIndex; // 0 = Kata, 1 = Ohyo

  const HomeScreenSearchSection({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.isConnected,
    required this.currentTabIndex,
  });

  Widget _buildSearchBar(BuildContext context) {
    final isKataTab = currentTabIndex == 0;
    final hintText = isKataTab ? 'Zoek kata\'s...' : 'Zoek ohyo\'s...';
    final ttsLabel = isKataTab ? 'Zoek kata\'s invoerveld' : 'Zoek ohyo\'s invoerveld';

    return SizedBox(
      width: double.infinity,
      child: EnhancedAccessibleTextField(
        controller: searchController,
        focusNode: searchFocusNode,
        customTTSLabel: ttsLabel,
        maxLines: 1, // Ensure single line for search
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(
            Icons.search,
            size: AppTheme.getResponsiveIconSize(context),
          ),
          border: OutlineInputBorder(
            borderRadius: context.responsiveBorderRadius,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        ),
        onChanged: onSearchChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveLayout(
      mobile: Column(
        children: [
          _buildSearchBar(context),
          if (!isConnected) ...[
            SizedBox(height: context.responsiveSpacing(SpacingSize.sm)),
            const ConnectionStatusIndicator(),
          ],
        ],
      ),
      desktop: Row(
        children: [
          Expanded(flex: 2, child: _buildSearchBar(context)),
          SizedBox(width: context.responsiveSpacing(SpacingSize.md)),
          if (!isConnected) const ConnectionStatusIndicator(),
        ],
      ),
    );
  }
}
