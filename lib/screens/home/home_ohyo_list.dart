import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/ohyo_provider.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/collapsible_ohyo_card.dart';
import '../../widgets/modern_loading_widget.dart';

/// Home Ohyo List - Handles ohyo list building and display
class HomeOhyoList extends ConsumerStatefulWidget {
  final List<dynamic> ohyos;
  final Function(int, String) onDelete;
  final Future<void> Function() onRefresh;

  const HomeOhyoList({
    super.key,
    required this.ohyos,
    required this.onDelete,
    required this.onRefresh,
  });

  @override
  ConsumerState<HomeOhyoList> createState() => _HomeOhyoListState();
}

class _HomeOhyoListState extends ConsumerState<HomeOhyoList> {

  Widget _buildOhyoList(List<dynamic> ohyos) {
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
        children: ohyos.map((ohyo) => CollapsibleOhyoCard(
          key: ValueKey('ohyo_${ohyo.id}'),
          ohyo: ohyo,
          onDelete: () => widget.onDelete(ohyo.id, ohyo.name),
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
        children: ohyos.map((ohyo) => CollapsibleOhyoCard(
          key: ValueKey('ohyo_${ohyo.id}'),
          ohyo: ohyo,
          onDelete: () => widget.onDelete(ohyo.id, ohyo.name),
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
        children: ohyos.map((ohyo) => CollapsibleOhyoCard(
          key: ValueKey('ohyo_${ohyo.id}'),
          ohyo: ohyo,
          onDelete: () => widget.onDelete(ohyo.id, ohyo.name),
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
        children: ohyos.map((ohyo) => CollapsibleOhyoCard(
          key: ValueKey('ohyo_${ohyo.id}'),
          ohyo: ohyo,
          onDelete: () => widget.onDelete(ohyo.id, ohyo.name),
          useAdaptiveWidth: false,
        )).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ohyoState = ref.watch(ohyoNotifierProvider);
    final isLoading = ohyoState.isLoading;

    if (isLoading) {
      return const ModernKataLoadingList(itemCount: 3, useGrid: true);
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: widget.ohyos.isEmpty
          ? Center(
              child: Text(
                'Geen ohyo\'s gevonden',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            )
          : _buildOhyoList(widget.ohyos),
    );
  }
}
