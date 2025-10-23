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

  const HomeScreenSearchSection({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchChanged,
    required this.isConnected,
  });

  Widget _buildSearchBar(BuildContext context) {
    return EnhancedAccessibleTextField(
      controller: searchController,
      focusNode: searchFocusNode,
      customTTSLabel: 'Zoek kata\'s invoerveld',
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
      onChanged: onSearchChanged,
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
