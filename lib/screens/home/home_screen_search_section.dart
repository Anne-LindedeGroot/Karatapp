import 'package:flutter/material.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/connection_error_widget.dart';
import '../../widgets/enhanced_accessible_text.dart';
import '../../utils/responsive_utils.dart';
import '../../core/theme/app_theme.dart';

class HomeScreenSearchSection extends StatefulWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ScrollController scrollController;
  final ValueChanged<String> onSearchChanged;
  final bool isConnected;
  final int currentTabIndex; // 0 = Kata, 1 = Ohyo

  const HomeScreenSearchSection({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.scrollController,
    required this.onSearchChanged,
    required this.isConnected,
    required this.currentTabIndex,
  });

  @override
  State<HomeScreenSearchSection> createState() => _HomeScreenSearchSectionState();
}

class _HomeScreenSearchSectionState extends State<HomeScreenSearchSection> {
  @override
  void didUpdateWidget(HomeScreenSearchSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Rebuild when tab changes to update the hint text
    if (oldWidget.currentTabIndex != widget.currentTabIndex) {
      setState(() {});
    }
  }

  Widget _buildSearchBar(BuildContext context) {
    final isKataTab = widget.currentTabIndex == 0;
    final hintText = isKataTab ? 'Zoek kata\'s...' : 'Zoek ohyo\'s...';
    final ttsLabel = isKataTab ? 'Zoek kata\'s invoerveld' : 'Zoek ohyo\'s invoerveld';

    return SizedBox(
      width: double.infinity,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 56, // Minimum height for single line
          maxHeight: 120, // Maximum height for 3 lines
        ),
        child: EnhancedAccessibleTextField(
        controller: widget.searchController,
        focusNode: widget.searchFocusNode,
        scrollController: widget.scrollController,
        scrollPhysics: const BouncingScrollPhysics(),
        customTTSLabel: ttsLabel,
        maxLines: 3, // Allow multiple lines to show full text
        minLines: 1, // Start with single line
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(
            Icons.search,
            size: AppTheme.getResponsiveIconSize(context),
          ),
          border: OutlineInputBorder(
            borderRadius: context.responsiveBorderRadius,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
        onChanged: widget.onSearchChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: Column(
        children: [
          _buildSearchBar(context),
          if (!widget.isConnected) ...[
            SizedBox(height: context.responsiveSpacing(SpacingSize.sm)),
            const ConnectionStatusIndicator(),
          ],
        ],
      ),
      desktop: Row(
        children: [
          Expanded(flex: 2, child: _buildSearchBar(context)),
          SizedBox(width: context.responsiveSpacing(SpacingSize.md)),
          if (!widget.isConnected) const ConnectionStatusIndicator(),
        ],
      ),
    );
  }
}
