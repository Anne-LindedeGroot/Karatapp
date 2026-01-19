import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/collapsible_kata_card.dart';
import '../../widgets/responsive_layout.dart';
import '../../providers/kata_provider.dart';
import '../../utils/responsive_utils.dart';
import '../../desktop/desktop_kata_grid.dart';

class HomeScreenKataList extends ConsumerWidget {
  final List<dynamic> katas;
  final Function(int kataId, String kataName) onDeleteKata;
  final Future<void> Function() onRefresh;

  const HomeScreenKataList({
    super.key,
    required this.katas,
    required this.onDeleteKata,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = ref.watch(kataSearchQueryProvider);
    // If search is active, use responsive layout (no reordering during search)
    if (searchQuery.isNotEmpty) {
      final desktopGrid = DesktopKataGrid.maybe(
        context: context,
        katas: katas,
        onDelete: onDeleteKata,
        keyPrefix: 'desktop_kata_',
        useAdaptiveWidth: false,
      );
      if (desktopGrid != null) {
        return desktopGrid;
      }

      return ResponsiveLayout(
        mobile: ListView.builder(
          padding: EdgeInsets.only(
            bottom:
                ResponsiveUtils.responsiveButtonHeight(context) +
                context.responsiveSpacing(SpacingSize.lg),
          ),
          itemCount: katas.length,
          itemBuilder: (context, index) {
            final kata = katas[index];
            return CollapsibleKataCard(
              key: ValueKey('search_kata_${kata.id}'),
              kata: kata,
              onDelete: () => onDeleteKata(kata.id, kata.name),
            );
          },
        ),
        tablet: ResponsiveGrid(
          maxColumns: 2,
          padding: EdgeInsets.only(
            bottom:
                ResponsiveUtils.responsiveButtonHeight(context) +
                context.responsiveSpacing(SpacingSize.md),
          ),
          mainAxisSpacing: context.responsiveSpacing(SpacingSize.md),
          crossAxisSpacing: context.responsiveSpacing(SpacingSize.md),
          childAspectRatio: 0.6,
          shrinkWrap: false,
          physics: const AlwaysScrollableScrollPhysics(),
          children: katas
              .map(
                (kata) => CollapsibleKataCard(
                  key: ValueKey('search_kata_${kata.id}'),
                  kata: kata,
                  onDelete: () => onDeleteKata(kata.id, kata.name),
                  useAdaptiveWidth: false,
                ),
              )
              .toList(),
        ),
        foldable: ResponsiveGrid(
          maxColumns: 2,
          padding: EdgeInsets.only(
            bottom:
                ResponsiveUtils.responsiveButtonHeight(context) +
                context.responsiveSpacing(SpacingSize.lg),
          ),
          mainAxisSpacing: context.responsiveSpacing(SpacingSize.sm),
          crossAxisSpacing: context.responsiveSpacing(SpacingSize.sm),
          childAspectRatio: 0.65,
          shrinkWrap: false,
          physics: const AlwaysScrollableScrollPhysics(),
          children: katas
              .map(
                (kata) => CollapsibleKataCard(
                  key: ValueKey('search_kata_${kata.id}'),
                  kata: kata,
                  onDelete: () => onDeleteKata(kata.id, kata.name),
                  useAdaptiveWidth: false,
                ),
              )
              .toList(),
        ),
        largeFoldable: ResponsiveGrid(
          maxColumns: 3,
          padding: EdgeInsets.only(
            bottom:
                ResponsiveUtils.responsiveButtonHeight(context) +
                context.responsiveSpacing(SpacingSize.lg),
          ),
          mainAxisSpacing: context.responsiveSpacing(SpacingSize.md),
          crossAxisSpacing: context.responsiveSpacing(SpacingSize.md),
          childAspectRatio: 0.7,
          shrinkWrap: false,
          physics: const AlwaysScrollableScrollPhysics(),
          children: katas
              .map(
                (kata) => CollapsibleKataCard(
                  key: ValueKey('search_kata_${kata.id}'),
                  kata: kata,
                  onDelete: () => onDeleteKata(kata.id, kata.name),
                  useAdaptiveWidth: false,
                ),
              )
              .toList(),
        ),
        desktop: DesktopKataGrid(
          katas: katas,
          onDelete: onDeleteKata,
          isLargeDesktop: ResponsiveUtils.isLargeDesktop(context),
          keyPrefix: 'desktop_kata_',
          useAdaptiveWidth: false,
        ),
        largeDesktop: DesktopKataGrid(
          katas: katas,
          onDelete: onDeleteKata,
          isLargeDesktop: ResponsiveUtils.isLargeDesktop(context),
          keyPrefix: 'desktop_kata_',
          useAdaptiveWidth: false,
        ),
      );
    }

    // Use ReorderableListView when not searching (mobile only for drag-and-drop)
    if (context.isMobile) {
      return ReorderableListView.builder(
        padding: EdgeInsets.only(
          bottom:
              ResponsiveUtils.responsiveButtonHeight(context) +
              context.responsiveSpacing(SpacingSize.lg),
        ),
        itemCount: katas.length,
        onReorder: (int oldIndex, int newIndex) {
          ref
              .read(kataNotifierProvider.notifier)
              .reorderKatas(oldIndex, newIndex);
        },
        itemBuilder: (context, index) {
          final kata = katas[index];
          return Container(
            key: ValueKey('reorder_kata_${kata.id}'),
            child: CollapsibleKataCard(
              key: ValueKey('reorder_card_kata_${kata.id}'),
              kata: kata,
              onDelete: () => onDeleteKata(kata.id, kata.name),
            ),
          );
        },
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (BuildContext context, Widget? child) {
              final double animValue = Curves.easeInOut.transform(
                animation.value,
              );
              final double elevation = lerpDouble(0, 6, animValue)!;
              final double scale = lerpDouble(1, 1.02, animValue)!;
              return Transform.scale(
                scale: scale,
                child: Card(elevation: elevation, child: child),
              );
            },
            child: child,
          );
        },
      );
    }

    final desktopGrid = DesktopKataGrid.maybe(
      context: context,
      katas: katas,
      onDelete: onDeleteKata,
      keyPrefix: 'desktop_kata_',
      useAdaptiveWidth: false,
    );
    if (desktopGrid != null) {
      return desktopGrid;
    }

    // For larger screens, use grid layout without reordering
    return ResponsiveLayout(
      mobile: ResponsiveGrid(
        maxColumns: 1,
        padding: EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
        shrinkWrap: false,
        physics: const AlwaysScrollableScrollPhysics(),
        children: katas
            .map(
              (kata) => CollapsibleKataCard(
                key: ValueKey('grid_kata_${kata.id}'),
                kata: kata,
                onDelete: () => onDeleteKata(kata.id, kata.name),
              ),
            )
            .toList(),
      ),
      tablet: ResponsiveGrid(
        maxColumns: 2,
        padding: EdgeInsets.only(
          bottom:
              ResponsiveUtils.responsiveButtonHeight(context) +
              context.responsiveSpacing(SpacingSize.lg),
        ),
        mainAxisSpacing: context.responsiveSpacing(SpacingSize.md),
        crossAxisSpacing: context.responsiveSpacing(SpacingSize.md),
        childAspectRatio: 0.6,
        shrinkWrap: false,
        physics: const AlwaysScrollableScrollPhysics(),
        children: katas
            .map(
              (kata) => CollapsibleKataCard(
                key: ValueKey('grid_kata_${kata.id}'),
                kata: kata,
                onDelete: () => onDeleteKata(kata.id, kata.name),
                useAdaptiveWidth: false,
              ),
            )
            .toList(),
      ),
      foldable: ResponsiveGrid(
        maxColumns: 2,
        padding: EdgeInsets.only(
          bottom:
              ResponsiveUtils.responsiveButtonHeight(context) +
              context.responsiveSpacing(SpacingSize.lg),
        ),
        mainAxisSpacing: context.responsiveSpacing(SpacingSize.sm),
        crossAxisSpacing: context.responsiveSpacing(SpacingSize.sm),
        childAspectRatio: 0.65,
        shrinkWrap: false,
        physics: const AlwaysScrollableScrollPhysics(),
        children: katas
            .map(
              (kata) => CollapsibleKataCard(
                key: ValueKey('grid_kata_${kata.id}'),
                kata: kata,
                onDelete: () => onDeleteKata(kata.id, kata.name),
                useAdaptiveWidth: false,
              ),
            )
            .toList(),
      ),
      largeFoldable: ResponsiveGrid(
        maxColumns: 3,
        padding: EdgeInsets.only(
          bottom:
              ResponsiveUtils.responsiveButtonHeight(context) +
              context.responsiveSpacing(SpacingSize.lg),
        ),
        mainAxisSpacing: context.responsiveSpacing(SpacingSize.md),
        crossAxisSpacing: context.responsiveSpacing(SpacingSize.md),
        childAspectRatio: 0.7,
        shrinkWrap: false,
        physics: const AlwaysScrollableScrollPhysics(),
        children: katas
            .map(
              (kata) => CollapsibleKataCard(
                key: ValueKey('grid_kata_${kata.id}'),
                kata: kata,
                onDelete: () => onDeleteKata(kata.id, kata.name),
                useAdaptiveWidth: false,
              ),
            )
            .toList(),
      ),
      desktop: DesktopKataGrid(
        katas: katas,
        onDelete: onDeleteKata,
        isLargeDesktop: ResponsiveUtils.isLargeDesktop(context),
        keyPrefix: 'desktop_kata_',
        useAdaptiveWidth: false,
      ),
      largeDesktop: DesktopKataGrid(
        katas: katas,
        onDelete: onDeleteKata,
        isLargeDesktop: ResponsiveUtils.isLargeDesktop(context),
        keyPrefix: 'desktop_kata_',
        useAdaptiveWidth: false,
      ),
    );
  }
}
