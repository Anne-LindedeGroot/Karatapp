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
      // Regular font: optimize sizes to fit "Karatapp" fully without overlap
      if (isExtraLarge) {
        logoSize = 28.0; // Smaller logo to make room for full text
        titleFontSize = 21.0; // Reduced to fit fully
        logoSpacing = 5.0; // Minimal spacing
      } else if (isLarge) {
        logoSize = 32.0; // Smaller logo
        titleFontSize = 19.0; // Good size to fit fully
        logoSpacing = 5.0;
      } else if (isSmall) {
        logoSize = 36.0; // Medium logo
        titleFontSize = 17.0; // Good size for small
        logoSpacing = 5.0;
      } else {
        // Normal size: optimize to fit "Karatapp" fully
        logoSize = 34.0; // Smaller logo to make room
        titleFontSize = 18.0; // Optimized size to fit fully
        logoSpacing = 5.0; // Minimal spacing
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
          // Flexible instead of Expanded to prevent overlap with actions
          Flexible(
            child: Text(
              "Karatapp",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.visible, // Show full word, no ellipsis
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
