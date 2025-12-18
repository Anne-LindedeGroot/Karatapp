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
    final shouldReduceSize = isLarge || isExtraLarge;
    
    // Make logo as small as possible when big/extra big font size is on
    final logoSize = shouldReduceSize ? 24.0 : 40.0;
    final textSize = shouldReduceSize ? 14.0 : null;
    
    return AppBar(
      titleSpacing: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
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
          SizedBox(width: shouldReduceSize ? 4 : 8), // Smaller spacing when reduced
          Text(
            "Karatapp",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: textSize,
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
