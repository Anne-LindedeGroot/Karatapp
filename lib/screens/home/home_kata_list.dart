import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/kata_model.dart';
import '../../providers/kata_provider.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/collapsible_kata_card.dart';
import '../../widgets/modern_loading_widget.dart';
import '../../providers/precaching_provider.dart';
import '../../desktop/desktop_kata_grid.dart';

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

  @override
  void initState() {
    super.initState();
    // Trigger pre-caching when kata list is loaded and has data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndTriggerPreCaching();
    });
  }

  void _checkAndTriggerPreCaching() {
    final kataState = ref.read(kataNotifierProvider);
    if (kataState.katas.isNotEmpty) {
      final preCachingNotifier = ref.read(preCachingProvider.notifier);
      if (preCachingNotifier.shouldTriggerPreCaching(ref)) {
        debugPrint('🏠 Kata list loaded with ${kataState.katas.length} katas, triggering pre-caching');
        preCachingNotifier.triggerPreCaching(ref);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Also check when dependencies change (in case data loads after init)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndTriggerPreCaching();
    });
  }

  Widget _buildKataList(List<Kata> katas) {
    final desktopGrid = DesktopKataGrid.maybe(
      context: context,
      katas: katas,
      onDelete: (kataId, kataName) =>
          widget.onDelete(kataId.toString(), kataName),
      useAdaptiveWidth: false,
    );
    if (desktopGrid != null) {
      return desktopGrid;
    }

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
        childAspectRatio: 0.6,
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
        childAspectRatio: 0.65,
        children: katas.map((kata) => CollapsibleKataCard(
          kata: kata,
          onDelete: () => widget.onDelete(kata.id.toString(), kata.name),
          useAdaptiveWidth: false,
        )).toList(),
      ),
      desktop: DesktopKataGrid(
        katas: katas,
        onDelete: (kataId, kataName) =>
            widget.onDelete(kataId.toString(), kataName),
        isLargeDesktop: ResponsiveUtils.isLargeDesktop(context),
        useAdaptiveWidth: false,
      ),
      largeDesktop: DesktopKataGrid(
        katas: katas,
        onDelete: (kataId, kataName) =>
            widget.onDelete(kataId.toString(), kataName),
        isLargeDesktop: ResponsiveUtils.isLargeDesktop(context),
        useAdaptiveWidth: false,
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
