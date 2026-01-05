import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/connection_error_widget.dart';
import '../../widgets/enhanced_accessible_text.dart';
import '../../utils/responsive_utils.dart';
import '../../providers/accessibility_provider.dart';

class HomeScreenSearchSection extends ConsumerStatefulWidget {
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
  ConsumerState<HomeScreenSearchSection> createState() => _HomeScreenSearchSectionState();
}

class _HomeScreenSearchSectionState extends ConsumerState<HomeScreenSearchSection> {
  @override
  void initState() {
    super.initState();
    // Listen to text changes to rebuild when clear button should appear/disappear
    widget.searchController.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(HomeScreenSearchSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Rebuild when tab changes to update the hint text
    if (oldWidget.currentTabIndex != widget.currentTabIndex) {
      setState(() {});
    }
    // Update listener if controller changed
    if (oldWidget.searchController != widget.searchController) {
      oldWidget.searchController.removeListener(_onTextChanged);
      widget.searchController.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildSearchBar(BuildContext context) {
    final isKataTab = widget.currentTabIndex == 0;
    final hintText = isKataTab ? 'Kata\'s...' : 'Ohyo\'s...';
    final ttsLabel = isKataTab ? 'Zoek kata\'s invoerveld' : 'Zoek ohyo\'s invoerveld';

    final textScaler = MediaQuery.of(context).textScaler;
    final scaleFactor = textScaler.scale(1.0);
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final isDyslexiaFriendly = accessibilityState.isDyslexiaFriendly;
    final isExtraLarge = accessibilityState.fontSize == AccessibilityFontSize.extraLarge;
    final fontSizeMultiplier = (isDyslexiaFriendly || isExtraLarge) ? 1.1 : 1.0;
    
    // Increase horizontal padding to ensure full text visibility
    final horizontalPadding = 40.0 * scaleFactor.clamp(1.0, 1.8) * fontSizeMultiplier;

    return SizedBox(
      width: double.infinity,
        child: EnhancedAccessibleTextField(
        controller: widget.searchController,
        focusNode: widget.searchFocusNode,
        maxLines: 1, // Ensure single line for search
        scrollController: widget.scrollController,
        scrollPhysics: const BouncingScrollPhysics(),
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: widget.searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    widget.searchController.clear();
                    widget.onSearchChanged('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 28 * fontSizeMultiplier,
          ),
          hintStyle: TextStyle(
            fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize != null
                ? Theme.of(context).textTheme.bodyMedium!.fontSize! * fontSizeMultiplier
                : 14 * fontSizeMultiplier,
          ),
        ),
        onChanged: widget.onSearchChanged,
        onSubmitted: (value) {
          widget.searchFocusNode.unfocus();
        },
        customTTSLabel: ttsLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: Column(
        mainAxisSize: MainAxisSize.min,
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
          Expanded(
            flex: 2,
            child: _buildSearchBar(context),
          ),
          if (!widget.isConnected) ...[
            SizedBox(width: context.responsiveSpacing(SpacingSize.md)),
            const ConnectionStatusIndicator(),
          ],
        ],
      ),
    );
  }
}
