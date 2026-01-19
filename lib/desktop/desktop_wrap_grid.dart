import 'package:flutter/material.dart';
import 'desktop_layout.dart';

class DesktopWrapGrid extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  final double spacing;
  final double runSpacing;
  final bool isLargeDesktop;
  final ScrollPhysics physics;

  const DesktopWrapGrid({
    super.key,
    required this.children,
    required this.padding,
    required this.spacing,
    required this.runSpacing,
    this.isLargeDesktop = false,
    this.physics = const AlwaysScrollableScrollPhysics(),
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final config = DesktopLayoutConfig.forWidth(
          constraints.maxWidth,
          isLargeDesktop: isLargeDesktop,
        );
        final totalSpacing = spacing * (config.columns - 1);
        final availableWidth =
            constraints.maxWidth - padding.horizontal - totalSpacing;
        final itemWidth = availableWidth > 0
            ? availableWidth / config.columns
            : constraints.maxWidth;

        return SingleChildScrollView(
          physics: physics,
          child: Padding(
            padding: padding,
            child: Wrap(
              spacing: spacing,
              runSpacing: runSpacing,
              children: children
                  .map((child) => SizedBox(width: itemWidth, child: child))
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}
