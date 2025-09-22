import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/network_provider.dart';

class ConnectionErrorWidget extends ConsumerWidget {
  const ConnectionErrorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShow = ref.watch(shouldShowConnectionErrorProvider);
    final networkState = ref.watch(networkProvider);

    if (!shouldShow) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.wifi_off,
                color: Colors.orange.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verbindingsprobleem',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      networkState.lastError ?? 'Controleer je internetverbinding',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  ref.read(networkProvider.notifier).markErrorAsShown();
                },
                child: Text(
                  'Sluiten',
                  style: TextStyle(color: Colors.orange.shade700),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: networkState.isChecking
                    ? null
                    : () {
                        ref.read(networkProvider.notifier).retry();
                      },
                icon: networkState.isChecking
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.orange.shade700,
                          ),
                        ),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: Text(networkState.isChecking ? 'Controleren...' : 'Opnieuw'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ConnectionStatusIndicator extends ConsumerWidget {
  const ConnectionStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkStatus = ref.watch(networkStatusProvider);
    final isConnected = ref.watch(isConnectedProvider);

    // Only show indicator when there are connection issues
    if (isConnected) {
      return const SizedBox.shrink();
    }

    Color indicatorColor;
    IconData indicatorIcon;
    String statusText;

    switch (networkStatus) {
      case NetworkStatus.checking:
        indicatorColor = Colors.orange;
        indicatorIcon = Icons.wifi_find;
        statusText = 'Verbinding controleren...';
        break;
      case NetworkStatus.disconnected:
        indicatorColor = Colors.red;
        indicatorIcon = Icons.wifi_off;
        statusText = 'Geen verbinding';
        break;
      case NetworkStatus.unknown:
        indicatorColor = Colors.grey;
        indicatorIcon = Icons.help_outline;
        statusText = 'Verbinding onbekend';
        break;
      case NetworkStatus.connected:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: indicatorColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            indicatorIcon,
            size: 16,
            color: indicatorColor,
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              color: indicatorColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
