import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/home_app_bar_actions.dart';

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
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[900] // Dark background for dark mode
                  : const Color(0xFF4CAF50), // Green background for light mode
            ),
            child: ClipOval(
              child: Transform.translate(
                offset: const Offset(1.5, 0), // Move slightly right to center optically
                child: Image.asset(
                  'assets/icons/rounded_logo.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover, // Ensures image fills the circle evenly
                  alignment: Alignment.center, // Forces exact center alignment
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text("Karatapp"),
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
