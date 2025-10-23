import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/kata_provider.dart';
import '../../utils/responsive_utils.dart';

/// Home Screen Error Handler - Handles error states and network issues
class HomeScreenErrorHandler {
  /// Check if error is a network error
  static bool isNetworkError(String? error) {
    if (error == null) return false;
    
    final lowerError = error.toLowerCase();
    return lowerError.contains('network') ||
           lowerError.contains('connection') ||
           lowerError.contains('timeout') ||
           lowerError.contains('unreachable') ||
           lowerError.contains('failed to host lookup') ||
           lowerError.contains('socket exception') ||
           lowerError.contains('handshake exception');
  }

  /// Build error widget for network issues
  static Widget buildNetworkErrorWidget(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.responsiveSpacing(SpacingSize.lg)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
            Text(
              'Geen internetverbinding',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.sm)),
            Text(
              'Controleer je internetverbinding en probeer opnieuw.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.lg)),
            ElevatedButton.icon(
              onPressed: () async {
                await ref.read(kataNotifierProvider.notifier).refreshKatas();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Opnieuw proberen'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error widget for general errors
  static Widget buildGeneralErrorWidget(BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.responsiveSpacing(SpacingSize.lg)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
            Text(
              'Er is een fout opgetreden',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.sm)),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.lg)),
            ElevatedButton.icon(
              onPressed: () async {
                await ref.read(kataNotifierProvider.notifier).refreshKatas();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Opnieuw proberen'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build loading widget
  static Widget buildLoadingWidget(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Kata\'s laden...'),
        ],
      ),
    );
  }

  /// Build empty state widget
  static Widget buildEmptyStateWidget(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.responsiveSpacing(SpacingSize.lg)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_martial_arts,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.md)),
            Text(
              'Geen kata\'s gevonden',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: context.responsiveSpacing(SpacingSize.sm)),
            Text(
              'Er zijn momenteel geen kata\'s beschikbaar.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
