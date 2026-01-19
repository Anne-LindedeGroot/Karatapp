import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../widgets/collapsible_ohyo_card.dart';
import 'desktop_platform_utils.dart';
import 'desktop_wrap_grid.dart';

class DesktopOhyoGrid extends StatelessWidget {
  final List<dynamic> ohyos;
  final void Function(int ohyoId, String ohyoName) onDelete;
  final bool isLargeDesktop;
  final String? keyPrefix;
  final bool useAdaptiveWidth;
  final EdgeInsets? padding;

  const DesktopOhyoGrid({
    super.key,
    required this.ohyos,
    required this.onDelete,
    this.isLargeDesktop = false,
    this.keyPrefix,
    this.useAdaptiveWidth = false,
    this.padding,
  });

  static Widget? maybe({
    required BuildContext context,
    required List<dynamic> ohyos,
    required void Function(int ohyoId, String ohyoName) onDelete,
    String? keyPrefix,
    bool useAdaptiveWidth = false,
    EdgeInsets? padding,
  }) {
    if (!DesktopPlatformUtils.isDesktopPlatform()) {
      return null;
    }

    return DesktopOhyoGrid(
      ohyos: ohyos,
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
      children: ohyos
          .map(
            (ohyo) => CollapsibleOhyoCard(
              key: keyPrefix != null ? ValueKey('$keyPrefix${ohyo.id}') : null,
              ohyo: ohyo,
              onDelete: () => onDelete(ohyo.id, ohyo.name),
              useAdaptiveWidth: useAdaptiveWidth,
            ),
          )
          .toList(),
    );
  }
}
