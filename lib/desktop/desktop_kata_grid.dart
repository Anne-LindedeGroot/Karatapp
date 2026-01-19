import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../widgets/collapsible_kata_card.dart';
import 'desktop_platform_utils.dart';
import 'desktop_wrap_grid.dart';

class DesktopKataGrid extends StatelessWidget {
  final List<dynamic> katas;
  final void Function(int kataId, String kataName) onDelete;
  final bool isLargeDesktop;
  final String? keyPrefix;
  final bool useAdaptiveWidth;
  final EdgeInsets? padding;

  const DesktopKataGrid({
    super.key,
    required this.katas,
    required this.onDelete,
    this.isLargeDesktop = false,
    this.keyPrefix,
    this.useAdaptiveWidth = false,
    this.padding,
  });

  static Widget? maybe({
    required BuildContext context,
    required List<dynamic> katas,
    required void Function(int kataId, String kataName) onDelete,
    String? keyPrefix,
    bool useAdaptiveWidth = false,
    EdgeInsets? padding,
  }) {
    if (!DesktopPlatformUtils.isDesktopPlatform()) {
      return null;
    }

    return DesktopKataGrid(
      katas: katas,
      onDelete: onDelete,
      isLargeDesktop: ResponsiveUtils.isLargeDesktop(context),
      keyPrefix: keyPrefix,
      useAdaptiveWidth: useAdaptiveWidth,
      padding: padding,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DesktopWrapGrid(
      isLargeDesktop: isLargeDesktop,
      padding: padding ??
          EdgeInsets.only(
            bottom:
                ResponsiveUtils.responsiveButtonHeight(context) +
                context.responsiveSpacing(SpacingSize.lg),
          ),
      spacing: context.responsiveSpacing(SpacingSize.md),
      runSpacing: context.responsiveSpacing(SpacingSize.md),
      children: katas
          .map(
            (kata) => CollapsibleKataCard(
              key: keyPrefix != null ? ValueKey('$keyPrefix${kata.id}') : null,
              kata: kata,
              onDelete: () => onDelete(kata.id, kata.name),
              useAdaptiveWidth: useAdaptiveWidth,
            ),
          )
          .toList(),
    );
  }
}
