import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/home_app_bar_actions.dart';
import '../../providers/accessibility_provider.dart';

class HomeScreenAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback? onRefresh;
  final VoidCallback? onLogout;
  final VoidCallback? onResetOhyoTab;
  final bool showResetButton;

  const HomeScreenAppBar({
    super.key,
    this.onRefresh,
    this.onLogout,
    this.onResetOhyoTab,
    this.showResetButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final isExtraLarge = accessibilityState.fontSize == AccessibilityFontSize.extraLarge;
    final isLarge = accessibilityState.fontSize == AccessibilityFontSize.large;
    final isDyslexiaFriendly = accessibilityState.isDyslexiaFriendly;
    final isSmall = accessibilityState.fontSize == AccessibilityFontSize.small;
    
    // For regular fonts: maximize space utilization with larger fonts
    // For dyslexia fonts: keep smaller to prevent overlap
    double logoSize;
    double? titleFontSize;
    double logoSpacing;
    
    if (isDyslexiaFriendly) {
      // Dyslexia font: smaller elements to prevent overlap
      if (isExtraLarge) {
        logoSize = 24.0;
        titleFontSize = 20.0;
        logoSpacing = 4.0;
      } else if (isLarge) {
        logoSize = 26.0;
        titleFontSize = 18.0;
        logoSpacing = 5.0;
      } else {
        logoSize = 28.0;
        titleFontSize = 16.0;
        logoSpacing = 6.0;
      }
    } else {
      // Regular font: maximize space utilization
      if (isExtraLarge) {
        logoSize = 32.0; // Smaller logo for more title space
        titleFontSize = 24.0; // Large font to fill space
        logoSpacing = 8.0;
      } else if (isLarge) {
        logoSize = 36.0; // Medium logo
        titleFontSize = 22.0; // Large font to fill space
        logoSpacing = 8.0;
      } else if (isSmall) {
        logoSize = 40.0; // Full size logo
        titleFontSize = 18.0; // Good size for small
        logoSpacing = 8.0;
      } else {
        // Normal size: maximize space
        logoSize = 38.0; // Slightly smaller logo
        titleFontSize = 20.0; // Larger font to fill space
        logoSpacing = 8.0;
      }
    }
    
    return AppBar(
      titleSpacing: 0,
      centerTitle: false, // Align to left for maximum space usage
      title: Row(
        children: [
          Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900] // Dark background for dark mode
                  : const Color(0xFF4CAF50), // Green background for light mode
            ),
            child: ClipOval(
              child: Transform.translate(
                offset: Offset(1.5 * (logoSize / 40), 0), // Scale offset proportionally
                child: Image.asset(
                  'assets/icons/rounded_logo.png',
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.cover, // Ensures image fills the circle evenly
                  alignment: Alignment.center, // Forces exact center alignment
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
          SizedBox(width: logoSpacing),
          // Expanded to fill remaining space
          Expanded(
            child: Text(
              "Karatapp",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
      actions: [
        HomeAppBarActions(
          onRefresh: onRefresh,
          onLogout: onLogout,
          onResetOhyoTab: onResetOhyoTab,
          showResetButton: showResetButton,
        ),
      ],
    );
  }
}
