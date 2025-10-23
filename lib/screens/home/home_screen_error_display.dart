import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/overflow_safe_widgets.dart';
import '../../core/theme/app_theme.dart';
import '../../utils/responsive_utils.dart';

class HomeScreenErrorDisplay extends ConsumerWidget {
  final String? error;
  final VoidCallback? onClearError;

  const HomeScreenErrorDisplay({
    super.key,
    this.error,
    this.onClearError,
  });

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
  Widget build(BuildContext context, WidgetRef ref) {
    if (error == null || _isNetworkError(error)) {
      return const SizedBox.shrink();
    }

    return ResponsiveContainer(
      margin: context.responsiveMargin,
      padding: context.responsivePadding,
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: context.responsiveBorderRadius,
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: double.infinity),
        child: OverflowSafeRow(
          children: [
            Icon(
              Icons.error,
              color: Colors.red,
              size: AppTheme.getResponsiveIconSize(context),
            ),
            SizedBox(width: context.responsiveSpacing(SpacingSize.sm)),
            OverflowSafeExpanded(
              child: OverflowSafeText(
                'Fout: $error',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red,
                ),
                maxLines: 2,
              ),
            ),
            OverflowSafeButton(
              onPressed: onClearError,
              isElevated: false,
              child: const Text('Sluiten'),
            ),
          ],
        ),
      ),
    );
  }
}
