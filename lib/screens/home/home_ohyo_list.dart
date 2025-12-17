import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/ohyo_provider.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/collapsible_ohyo_card.dart';
import '../../widgets/modern_loading_widget.dart';
import '../../providers/precaching_provider.dart';

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

  @override
  void initState() {
    super.initState();
    // Trigger pre-caching when ohyo list is loaded and has data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndTriggerPreCaching();
    });
  }

  void _checkAndTriggerPreCaching() {
    final ohyoState = ref.read(ohyoNotifierProvider);
    if (ohyoState.ohyos.isNotEmpty) {
      final preCachingNotifier = ref.read(preCachingProvider.notifier);
      if (preCachingNotifier.shouldTriggerPreCaching(ref)) {
        // Silent: Ohyo list loading not logged
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

  Widget _buildOhyoList(List<dynamic> ohyos) {
    // Use ListView for mobile (natural height) like kata cards
    if (context.isMobile) {
      return ListView.builder(
        padding: EdgeInsets.only(
          bottom: ResponsiveUtils.responsiveButtonHeight(context) +
                  context.responsiveSpacing(SpacingSize.lg),
        ),
        itemCount: ohyos.length,
        itemBuilder: (context, index) {
          final ohyo = ohyos[index];
          return CollapsibleOhyoCard(
            key: ValueKey('ohyo_${ohyo.id}'),
            ohyo: ohyo,
            onDelete: () => widget.onDelete(ohyo.id, ohyo.name),
            useAdaptiveWidth: true,
          );
        },
      );
    }

    // Use grid for larger screens with appropriate aspect ratios
    return ResponsiveLayout(
      mobile: Container(), // Mobile handled above
      tablet: ResponsiveGrid(
        maxColumns: 2,
        padding: EdgeInsets.only(
          bottom: ResponsiveUtils.responsiveButtonHeight(context) +
                  context.responsiveSpacing(SpacingSize.lg),
        ),
        mainAxisSpacing: context.responsiveSpacing(SpacingSize.md),
        crossAxisSpacing: context.responsiveSpacing(SpacingSize.md),
        childAspectRatio: 0.8, // Match kata aspect ratio
        shrinkWrap: false,
        physics: const AlwaysScrollableScrollPhysics(),
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
        childAspectRatio: 0.85, // Match kata aspect ratio
        shrinkWrap: false,
        physics: const AlwaysScrollableScrollPhysics(),
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
        childAspectRatio: 0.9, // Match kata aspect ratio
        shrinkWrap: false,
        physics: const AlwaysScrollableScrollPhysics(),
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
