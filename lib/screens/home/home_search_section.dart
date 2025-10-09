import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/kata_provider.dart';
import '../../providers/network_provider.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/responsive_layout.dart';
import '../../widgets/connection_error_widget.dart';

/// Home Search Section - Handles search functionality for the home screen
class HomeSearchSection extends ConsumerStatefulWidget {
  const HomeSearchSection({super.key});

  @override
  ConsumerState<HomeSearchSection> createState() => _HomeSearchSectionState();
}

class _HomeSearchSectionState extends ConsumerState<HomeSearchSection> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Widget _buildSearchSection(bool isConnected) {
    return ResponsiveLayout(
      mobile: Column(
        children: [
          _buildSearchBar(),
          if (!isConnected) ...[
            SizedBox(height: context.responsiveSpacing(SpacingSize.sm)),
            const ConnectionStatusIndicator(),
          ],
        ],
      ),
      desktop: Row(
        children: [
          Expanded(flex: 2, child: _buildSearchBar()),
          SizedBox(width: context.responsiveSpacing(SpacingSize.md)),
          if (!isConnected) const ConnectionStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      decoration: InputDecoration(
        hintText: 'Zoek kata\'s...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  ref.read(kataNotifierProvider.notifier).searchKatas('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
      onChanged: (value) {
        ref.read(kataNotifierProvider.notifier).searchKatas(value);
      },
      onSubmitted: (value) {
        _searchFocusNode.unfocus();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(isConnectedProvider);
    return _buildSearchSection(isConnected);
  }
}
