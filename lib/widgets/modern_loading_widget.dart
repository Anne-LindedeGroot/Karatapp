import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/responsive_utils.dart';
import '../core/theme/app_theme.dart';

/// Modern, responsive loading widgets with shimmer effects
class ModernLoadingWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  const ModernLoadingWidget({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Shimmer.fromColors(
      baseColor: baseColor ?? (isDark ? Colors.grey[800]! : Colors.grey[300]!),
      highlightColor: highlightColor ?? (isDark ? Colors.grey[700]! : Colors.grey[100]!),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius ?? AppTheme.getResponsiveBorderRadius(context),
        ),
      ),
    );
  }
}

/// Modern loading card for kata items
class ModernKataLoadingCard extends StatelessWidget {
  const ModernKataLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: AppTheme.getResponsiveMargin(context),
      elevation: AppTheme.getResponsiveElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.getResponsiveBorderRadius(context),
      ),
      child: Padding(
        padding: AppTheme.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Drag handle placeholder
                ModernLoadingWidget(
                  width: context.responsiveValue(mobile: 32.0, tablet: 36.0, desktop: 40.0),
                  height: context.responsiveValue(mobile: 32.0, tablet: 36.0, desktop: 40.0),
                ),
                SizedBox(width: context.responsiveSpacing(SpacingSize.sm)),
                // Title and style placeholders
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ModernLoadingWidget(
                        width: double.infinity,
                        height: context.responsiveValue(mobile: 20.0, tablet: 24.0, desktop: 28.0),
                      ),
                      SizedBox(height: context.responsiveSpacing(SpacingSize.xs)),
                      ModernLoadingWidget(
                        width: context.responsiveValue(mobile: 120.0, tablet: 140.0, desktop: 160.0),
                        height: context.responsiveValue(mobile: 16.0, tablet: 18.0, desktop: 20.0),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: context.responsiveSpacing(SpacingSize.sm)),
                // Action buttons placeholder
                ModernLoadingWidget(
                  width: context.responsiveValue(mobile: 80.0, tablet: 90.0, desktop: 100.0),
                  height: context.responsiveValue(mobile: 32.0, tablet: 36.0, desktop: 40.0),
                ),
              ],
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
            // Description placeholder
            ModernLoadingWidget(
              width: double.infinity,
              height: context.responsiveValue(mobile: 60.0, tablet: 70.0, desktop: 80.0),
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.sm)),
            // Image placeholder
            ModernLoadingWidget(
              width: double.infinity,
              height: context.responsiveValue(mobile: 150.0, tablet: 180.0, desktop: 200.0),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modern loading list for multiple kata cards
class ModernKataLoadingList extends StatelessWidget {
  final int itemCount;
  final bool useGrid;

  const ModernKataLoadingList({
    super.key,
    this.itemCount = 3,
    this.useGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    final items = List.generate(itemCount, (index) => const ModernKataLoadingCard());

    if (useGrid && context.isDesktop) {
      return GridView.builder(
        padding: AppTheme.getResponsivePadding(context),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveUtils.getGridColumns(context, maxColumns: 3),
          mainAxisSpacing: context.responsiveSpacing(SpacingSize.md),
          crossAxisSpacing: context.responsiveSpacing(SpacingSize.md),
          childAspectRatio: 0.8,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => items[index],
      );
    }

    return ListView.builder(
      padding: AppTheme.getResponsivePadding(context),
      itemCount: itemCount,
      itemBuilder: (context, index) => items[index],
    );
  }
}

/// Modern loading widget for forum posts
class ModernForumPostLoadingCard extends StatelessWidget {
  const ModernForumPostLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: AppTheme.getResponsiveMargin(context),
      elevation: AppTheme.getResponsiveElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: AppTheme.getResponsiveBorderRadius(context),
      ),
      child: Padding(
        padding: AppTheme.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and user info
            Row(
              children: [
                ModernLoadingWidget(
                  width: context.responsiveValue(mobile: 40.0, tablet: 48.0, desktop: 56.0),
                  height: context.responsiveValue(mobile: 40.0, tablet: 48.0, desktop: 56.0),
                  borderRadius: BorderRadius.circular(100),
                ),
                SizedBox(width: context.responsiveSpacing(SpacingSize.sm)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ModernLoadingWidget(
                        width: context.responsiveValue(mobile: 120.0, tablet: 140.0, desktop: 160.0),
                        height: context.responsiveValue(mobile: 16.0, tablet: 18.0, desktop: 20.0),
                      ),
                      SizedBox(height: context.responsiveSpacing(SpacingSize.xs)),
                      ModernLoadingWidget(
                        width: context.responsiveValue(mobile: 80.0, tablet: 90.0, desktop: 100.0),
                        height: context.responsiveValue(mobile: 12.0, tablet: 14.0, desktop: 16.0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
            // Title
            ModernLoadingWidget(
              width: double.infinity,
              height: context.responsiveValue(mobile: 24.0, tablet: 28.0, desktop: 32.0),
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.sm)),
            // Content
            ModernLoadingWidget(
              width: double.infinity,
              height: context.responsiveValue(mobile: 80.0, tablet: 90.0, desktop: 100.0),
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
            // Footer with stats
            Row(
              children: [
                ModernLoadingWidget(
                  width: context.responsiveValue(mobile: 60.0, tablet: 70.0, desktop: 80.0),
                  height: context.responsiveValue(mobile: 16.0, tablet: 18.0, desktop: 20.0),
                ),
                const Spacer(),
                ModernLoadingWidget(
                  width: context.responsiveValue(mobile: 80.0, tablet: 90.0, desktop: 100.0),
                  height: context.responsiveValue(mobile: 16.0, tablet: 18.0, desktop: 20.0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Modern loading list for forum posts
class ModernForumPostLoadingList extends StatelessWidget {
  final int itemCount;

  const ModernForumPostLoadingList({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: AppTheme.getResponsivePadding(context),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ModernForumPostLoadingCard(),
    );
  }
}

/// Modern loading widget for text content
class ModernTextLoadingWidget extends StatelessWidget {
  final int lines;
  final double? lineHeight;
  final double? spacing;

  const ModernTextLoadingWidget({
    super.key,
    this.lines = 3,
    this.lineHeight,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final height = lineHeight ?? context.responsiveValue(mobile: 16.0, tablet: 18.0, desktop: 20.0);
    final gap = spacing ?? context.responsiveSpacing(SpacingSize.xs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines, (index) {
        // Make the last line shorter for more realistic appearance
        final isLastLine = index == lines - 1;
        final width = isLastLine ? 0.7 : 1.0;

        return Padding(
          padding: EdgeInsets.only(bottom: index < lines - 1 ? gap : 0),
          child: ModernLoadingWidget(
            width: MediaQuery.of(context).size.width * width,
            height: height,
          ),
        );
      }),
    );
  }
}

/// Modern loading widget for buttons
class ModernButtonLoadingWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final bool isRounded;

  const ModernButtonLoadingWidget({
    super.key,
    this.width,
    this.height,
    this.isRounded = true,
  });

  @override
  Widget build(BuildContext context) {
    return ModernLoadingWidget(
      width: width ?? context.responsiveValue(mobile: 100.0, tablet: 120.0, desktop: 140.0),
      height: height ?? ResponsiveUtils.responsiveButtonHeight(context),
      borderRadius: isRounded 
          ? AppTheme.getResponsiveBorderRadius(context)
          : BorderRadius.zero,
    );
  }
}

/// Modern loading widget for images
class ModernImageLoadingWidget extends StatelessWidget {
  final double? width;
  final double? height;
  final double aspectRatio;
  final bool isCircular;

  const ModernImageLoadingWidget({
    super.key,
    this.width,
    this.height,
    this.aspectRatio = 1.0,
    this.isCircular = false,
  });

  @override
  Widget build(BuildContext context) {
    final finalWidth = width ?? context.responsiveValue(mobile: 100.0, tablet: 120.0, desktop: 140.0);
    final finalHeight = height ?? ((finalWidth ?? 100.0) / aspectRatio);

    return ModernLoadingWidget(
      width: finalWidth,
      height: finalHeight,
      borderRadius: isCircular 
          ? BorderRadius.circular((finalWidth ?? 100.0) / 2)
          : AppTheme.getResponsiveBorderRadius(context),
    );
  }
}

/// Modern loading widget for list tiles
class ModernListTileLoadingWidget extends StatelessWidget {
  final bool hasLeading;
  final bool hasTrailing;
  final bool hasSubtitle;

  const ModernListTileLoadingWidget({
    super.key,
    this.hasLeading = true,
    this.hasTrailing = false,
    this.hasSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppTheme.getResponsivePadding(context),
      child: Row(
        children: [
          if (hasLeading) ...[
            ModernImageLoadingWidget(
              width: context.responsiveValue(mobile: 40.0, tablet: 48.0, desktop: 56.0),
              height: context.responsiveValue(mobile: 40.0, tablet: 48.0, desktop: 56.0),
              isCircular: true,
            ),
            SizedBox(width: context.responsiveSpacing(SpacingSize.md)),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModernLoadingWidget(
                  width: double.infinity,
                  height: context.responsiveValue(mobile: 16.0, tablet: 18.0, desktop: 20.0),
                ),
                if (hasSubtitle) ...[
                  SizedBox(height: context.responsiveSpacing(SpacingSize.xs)),
                  ModernLoadingWidget(
                    width: MediaQuery.of(context).size.width * 0.6,
                    height: context.responsiveValue(mobile: 14.0, tablet: 16.0, desktop: 18.0),
                  ),
                ],
              ],
            ),
          ),
          if (hasTrailing) ...[
            SizedBox(width: context.responsiveSpacing(SpacingSize.md)),
            ModernLoadingWidget(
              width: context.responsiveValue(mobile: 24.0, tablet: 28.0, desktop: 32.0),
              height: context.responsiveValue(mobile: 24.0, tablet: 28.0, desktop: 32.0),
            ),
          ],
        ],
      ),
    );
  }
}
