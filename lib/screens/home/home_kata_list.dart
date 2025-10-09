import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/kata_model.dart';
import '../../providers/kata_provider.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/collapsible_kata_card.dart';
import '../../widgets/modern_loading_widget.dart';

/// Home Kata List - Handles kata list building and display
class HomeKataList extends ConsumerStatefulWidget {
  final List<Kata> katas;
  final Function(String, String) onDelete;
  final Future<void> Function() onRefresh;

  const HomeKataList({
    super.key,
    required this.katas,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  ConsumerState<HomeKataList> createState() => _HomeKataListState();
}

class _HomeKataListState extends ConsumerState<HomeKataList> {

  Widget _buildKataList(List<Kata> katas) {
    return ResponsiveLayout(
      mobile: ResponsiveGrid(
        maxColumns: 1,
        padding: EdgeInsets.only(
          bottom: ResponsiveUtils.responsiveButtonHeight(context) + 
                  context.responsiveSpacing(SpacingSize.lg),
        ),
        mainAxisSpacing: context.responsiveSpacing(SpacingSize.md),
        crossAxisSpacing: context.responsiveSpacing(SpacingSize.md),
        childAspectRatio: 1.2,
        children: katas.map((kata) => CollapsibleKataCard(
          kata: kata,
          onDelete: () => widget.onDelete(kata.id.toString(), kata.name),
          useAdaptiveWidth: true,
        )).toList(),
      ),
      tablet: ResponsiveGrid(
        maxColumns: 2,
        padding: EdgeInsets.only(
          bottom: ResponsiveUtils.responsiveButtonHeight(context) + 
                  context.responsiveSpacing(SpacingSize.lg),
        ),
        mainAxisSpacing: context.responsiveSpacing(SpacingSize.md),
        crossAxisSpacing: context.responsiveSpacing(SpacingSize.md),
        childAspectRatio: 0.9,
        children: katas.map((kata) => CollapsibleKataCard(
          kata: kata,
          onDelete: () => widget.onDelete(kata.id.toString(), kata.name),
          useAdaptiveWidth: false,
        )).toList(),
      ),
      largeFoldable: ResponsiveGrid(
        maxColumns: 3,
        padding: EdgeInsets.only(
          bottom: ResponsiveUtils.responsiveButtonHeight(context) + 
                  context.responsiveSpacing(SpacingSize.lg),
        ),
        mainAxisSpacing: context.responsiveSpacing(SpacingSize.md),
        crossAxisSpacing: context.responsiveSpacing(SpacingSize.md),
        childAspectRatio: 0.9,
        children: katas.map((kata) => CollapsibleKataCard(
          kata: kata,
          onDelete: () => widget.onDelete(kata.id.toString(), kata.name),
          useAdaptiveWidth: false,
        )).toList(),
      ),
      desktop: ResponsiveGrid(
        maxColumns: 3,
        padding: EdgeInsets.only(
          bottom: ResponsiveUtils.responsiveButtonHeight(context) + 
                  context.responsiveSpacing(SpacingSize.lg),
        ),
        mainAxisSpacing: context.responsiveSpacing(SpacingSize.md),
        crossAxisSpacing: context.responsiveSpacing(SpacingSize.md),
        childAspectRatio: 0.9,
        children: katas.map((kata) => CollapsibleKataCard(
          kata: kata,
          onDelete: () => widget.onDelete(kata.id.toString(), kata.name),
          useAdaptiveWidth: false,
        )).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kataState = ref.watch(kataNotifierProvider);
    final isLoading = kataState.isLoading;

    if (isLoading) {
      return const ModernKataLoadingList(itemCount: 3, useGrid: true);
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: widget.katas.isEmpty
          ? Center(
              child: Text(
                'Geen kata\'s gevonden',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            )
          : _buildKataList(widget.katas),
    );
  }
}
