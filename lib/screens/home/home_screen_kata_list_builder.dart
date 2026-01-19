import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/collapsible_kata_card.dart';
import '../../widgets/responsive_layout.dart';
import '../../providers/kata_provider.dart';
import '../../utils/responsive_utils.dart';
import '../../desktop/desktop_kata_grid.dart';

/// Home Screen Kata List Builder - Handles building responsive kata lists
class HomeScreenKataListBuilder {
  /// Build kata list with responsive layout
  static Widget buildKataList(BuildContext context, WidgetRef ref, List<dynamic> katas, Function(int kataId, String kataName) onDelete) {
    final searchQuery = ref.watch(kataSearchQueryProvider);

    // If search is active, use responsive layout (no reordering during search)
    if (searchQuery.isNotEmpty) {
      return ResponsiveLayout(
        mobile: _buildMobileList(context, katas, onDelete),
        tablet: _buildTabletGrid(context, katas, onDelete),
        foldable: _buildFoldableGrid(context, katas, onDelete),
        largeFoldable: _buildLargeFoldableGrid(context, katas, onDelete),
        desktop: _buildDesktopGrid(context, katas, onDelete),
        largeDesktop: _buildLargeDesktopGrid(context, katas, onDelete),
      );
    }

    // Default responsive layout for normal browsing
    return ResponsiveLayout(
      mobile: _buildMobileList(context, katas, onDelete),
      tablet: _buildTabletGrid(context, katas, onDelete),
      foldable: _buildFoldableGrid(context, katas, onDelete),
      largeFoldable: _buildLargeFoldableGrid(context, katas, onDelete),
      desktop: _buildDesktopGrid(context, katas, onDelete),
      largeDesktop: _buildLargeDesktopGrid(context, katas, onDelete),
    );
  }

  /// Build mobile list view
  static Widget _buildMobileList(BuildContext context, List<dynamic> katas, Function(int kataId, String kataName) onDelete) {
    return ListView.builder(
      padding: EdgeInsets.only(
        bottom: ResponsiveUtils.responsiveButtonHeight(context) +
                context.responsiveSpacing(SpacingSize.lg),
      ),
      itemCount: katas.length,
      itemBuilder: (context, index) {
        final kata = katas[index];
        return CollapsibleKataCard(
          kata: kata,
          onDelete: () => onDelete(kata.id, kata.name),
        );
      },
    );
  }

  /// Build tablet grid
  static Widget _buildTabletGrid(BuildContext context, List<dynamic> katas, Function(int kataId, String kataName) onDelete) {
    return ResponsiveGrid(
      maxColumns: 2,
      padding: EdgeInsets.only(
        bottom: ResponsiveUtils.responsiveButtonHeight(context) +
                context.responsiveSpacing(SpacingSize.lg),
      ),
      mainAxisSpacing: context.responsiveSpacing(SpacingSize.md),
      crossAxisSpacing: context.responsiveSpacing(SpacingSize.md),
      childAspectRatio: 0.8,
      shrinkWrap: false,
      physics: const AlwaysScrollableScrollPhysics(),
      children: katas
          .map(
            (kata) => CollapsibleKataCard(
              kata: kata,
              onDelete: () => onDelete(kata.id, kata.name),
              useAdaptiveWidth: false,
            ),
          )
          .toList(),
    );
  }

  /// Build foldable grid
  static Widget _buildFoldableGrid(BuildContext context, List<dynamic> katas, Function(int kataId, String kataName) onDelete) {
    return ResponsiveGrid(
      maxColumns: 2,
      padding: EdgeInsets.only(
        bottom: ResponsiveUtils.responsiveButtonHeight(context) +
                context.responsiveSpacing(SpacingSize.lg),
      ),
      mainAxisSpacing: context.responsiveSpacing(SpacingSize.sm),
      crossAxisSpacing: context.responsiveSpacing(SpacingSize.sm),
      childAspectRatio: 0.85,
      shrinkWrap: false,
      physics: const AlwaysScrollableScrollPhysics(),
      children: katas
          .map(
            (kata) => CollapsibleKataCard(
              kata: kata,
              onDelete: () => onDelete(kata.id, kata.name),
              useAdaptiveWidth: false,
            ),
          )
          .toList(),
    );
  }

  /// Build large foldable grid
  static Widget _buildLargeFoldableGrid(BuildContext context, List<dynamic> katas, Function(int kataId, String kataName) onDelete) {
    return ResponsiveGrid(
      maxColumns: 3,
      padding: EdgeInsets.only(
        bottom: ResponsiveUtils.responsiveButtonHeight(context) +
                context.responsiveSpacing(SpacingSize.lg),
      ),
      mainAxisSpacing: context.responsiveSpacing(SpacingSize.md),
      crossAxisSpacing: context.responsiveSpacing(SpacingSize.md),
      childAspectRatio: 0.9,
      shrinkWrap: false,
      physics: const AlwaysScrollableScrollPhysics(),
      children: katas
          .map(
            (kata) => CollapsibleKataCard(
              kata: kata,
              onDelete: () => onDelete(kata.id, kata.name),
              useAdaptiveWidth: false,
            ),
          )
          .toList(),
    );
  }

  /// Build desktop grid
  static Widget _buildDesktopGrid(BuildContext context, List<dynamic> katas, Function(int kataId, String kataName) onDelete) {
    return DesktopKataGrid(
      katas: katas,
      onDelete: onDelete,
      isLargeDesktop: false,
      useAdaptiveWidth: false,
    );
  }

  /// Build large desktop grid
  static Widget _buildLargeDesktopGrid(BuildContext context, List<dynamic> katas, Function(int kataId, String kataName) onDelete) {
    return DesktopKataGrid(
      katas: katas,
      onDelete: onDelete,
      isLargeDesktop: true,
      useAdaptiveWidth: false,
    );
  }
}
