import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/network_provider.dart';
import '../providers/data_usage_provider.dart';
import '../services/offline_sync_service.dart';

/// Offline indicator widget that shows connection status and sync progress
class OfflineIndicatorWidget extends ConsumerWidget {
  final bool showDetails;
  final bool compact;

  const OfflineIndicatorWidget({
    super.key,
    this.showDetails = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkState = ref.watch(networkProvider);
    final dataUsageState = ref.watch(dataUsageProvider);
    final syncState = ref.watch(offlineSyncProvider);

    if (compact) {
      return _buildCompactIndicator(context, networkState, dataUsageState, syncState);
    }

    return _buildFullIndicator(context, ref, networkState, dataUsageState, syncState);
  }

  Widget _buildCompactIndicator(
    BuildContext context,
    networkState,
    dataUsageState,
    syncState,
  ) {
    final theme = Theme.of(context);
    
    if (networkState.isConnected && !dataUsageState.isOfflineMode) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(networkState, dataUsageState, syncState).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(networkState, dataUsageState, syncState).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(networkState, dataUsageState, syncState),
            size: 16,
            color: _getStatusColor(networkState, dataUsageState, syncState),
          ),
          const SizedBox(width: 4),
          Text(
            _getStatusText(networkState, dataUsageState, syncState),
            style: theme.textTheme.bodySmall?.copyWith(
              color: _getStatusColor(networkState, dataUsageState, syncState),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullIndicator(
    BuildContext context,
    WidgetRef ref,
    networkState,
    dataUsageState,
    syncState,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Row(
              children: [
                Icon(
                  _getStatusIcon(networkState, dataUsageState, syncState),
                  color: _getStatusColor(networkState, dataUsageState, syncState),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getStatusTitle(networkState, dataUsageState, syncState),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (syncState.isSyncing) ...[
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatusColor(networkState, dataUsageState, syncState),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Status Description
            Text(
              _getStatusDescription(networkState, dataUsageState, syncState),
              style: theme.textTheme.bodyMedium,
            ),
            
            // Sync Progress
            if (syncState.isSyncing) ...[
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Syncing ${_getOperationText(syncState.currentOperation)}...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(syncState.progress * 100).toInt()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: syncState.progress,
                    backgroundColor: Colors.grey.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getStatusColor(networkState, dataUsageState, syncState),
                    ),
                  ),
                ],
              ),
            ],
            
            // Data Usage Warning
            if (dataUsageState.shouldShowDataWarning) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Approaching monthly data limit (${dataUsageState.stats.formattedTotalUsage} used)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Action Buttons
            if (showDetails) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (!networkState.isConnected) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => ref.read(networkProvider.notifier).retry(),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry Connection'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                  if (networkState.isConnected && syncState.pendingItems > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => ref.read(offlineSyncProvider.notifier).startFullSync(ref as Ref),
                        icon: const Icon(Icons.sync, size: 16),
                        label: const Text('Sync Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: theme.colorScheme.onSecondary,
                        ),
                      ),
                    ),
                  ],
                  if (networkState.isConnected && syncState.status != SyncOperation.comprehensiveCache) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: FutureBuilder<bool>(
                        future: ref.read(offlineSyncProvider.notifier).isComprehensiveCacheCompleted(),
                        builder: (context, snapshot) {
                          final isCompleted = snapshot.data ?? false;
                          return ElevatedButton.icon(
                            onPressed: isCompleted
                                ? null
                                : () => ref.read(offlineSyncProvider.notifier).comprehensiveCache(ref),
                            icon: Icon(
                              isCompleted ? Icons.check_circle : Icons.cloud_download,
                              size: 16,
                            ),
                            label: Text(isCompleted ? 'Fully Cached' : 'Cache Everything'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCompleted
                                  ? Colors.green
                                  : theme.colorScheme.tertiary,
                              foregroundColor: isCompleted
                                  ? Colors.white
                                  : theme.colorScheme.onTertiary,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(NetworkState networkState, DataUsageState dataUsageState, OfflineSyncState syncState) {
    if (dataUsageState.isOfflineMode) return Colors.orange;
    if (!networkState.isConnected) return Colors.red;
    if (syncState.isSyncing) return Colors.blue;
    if (syncState.hasRecentErrors) return Colors.orange;
    return Colors.green;
  }

  IconData _getStatusIcon(NetworkState networkState, DataUsageState dataUsageState, OfflineSyncState syncState) {
    if (dataUsageState.isOfflineMode) return Icons.offline_bolt;
    if (!networkState.isConnected) return Icons.wifi_off;
    if (syncState.isSyncing) return Icons.sync;
    if (syncState.hasRecentErrors) return Icons.sync_problem;
    return Icons.wifi;
  }

  String _getStatusText(NetworkState networkState, DataUsageState dataUsageState, OfflineSyncState syncState) {
    if (dataUsageState.isOfflineMode) return 'Offline';
    if (!networkState.isConnected) {
      // Show "Offline" if truly offline (no WiFi/cellular), "Geen verbinding" if connected but no internet
      if (dataUsageState.connectionType == ConnectionType.unknown) {
        return 'Offline';
      } else {
        return 'Offline';
      }
    }
    if (syncState.isSyncing) return 'Syncing';
    if (syncState.hasRecentErrors) return 'Sync Issues';
    return 'Online';
  }

  String _getStatusTitle(NetworkState networkState, DataUsageState dataUsageState, OfflineSyncState syncState) {
    if (dataUsageState.isOfflineMode) return 'Offline Mode Active';
    if (!networkState.isConnected) {
      if (dataUsageState.connectionType == ConnectionType.unknown) {
        return 'Offline';
      } else {
        return 'Offline';
      }
    }
    if (syncState.isSyncing) return 'Synchronizing Data';
    if (syncState.hasRecentErrors) return 'Sync Issues Detected';
    return 'Connected';
  }

  String _getStatusDescription(NetworkState networkState, DataUsageState dataUsageState, OfflineSyncState syncState) {
    if (dataUsageState.isOfflineMode) {
      return 'App is running in offline mode. Some features may be limited.';
    }
    if (!networkState.isConnected) {
      if (dataUsageState.connectionType == ConnectionType.unknown) {
        return 'Device is offline. Turn on WiFi or mobile data to connect.';
      } else {
        return 'Connected to network but no internet access. Check your connection.';
      }
    }
    if (syncState.isSyncing) {
      if (syncState.currentOperation == SyncOperation.comprehensiveCache) {
        return 'Downloading all content for complete offline functionality. This may take several minutes and use significant data.';
      }
      return 'Updating your data with the latest information from the server.';
    }
    if (syncState.hasRecentErrors) {
      return 'Some data failed to sync. Tap "Sync Now" to retry.';
    }
    return 'All systems operational. Your data is up to date.';
  }

  String _getOperationText(SyncOperation? operation) {
    switch (operation) {
      case SyncOperation.katas:
        return 'katas';
      case SyncOperation.forumPosts:
        return 'forum posts';
      case SyncOperation.userData:
        return 'user data';
      case SyncOperation.videos:
        return 'videos';
      case SyncOperation.images:
        return 'images';
      case SyncOperation.comprehensiveCache:
        return 'everything for offline use';
      case null:
        return 'data';
    }
  }
}

/// Floating offline indicator for persistent status display
class FloatingOfflineIndicator extends ConsumerWidget {
  const FloatingOfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkState = ref.watch(networkProvider);
    final dataUsageState = ref.watch(dataUsageProvider);
    final syncState = ref.watch(offlineSyncProvider);

    // Only show if there's an issue or sync is happening
    if (networkState.isConnected && 
        !dataUsageState.isOfflineMode && 
        !syncState.isSyncing && 
        !syncState.hasRecentErrors) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 8,
      right: 8,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getStatusColor(networkState, dataUsageState, syncState),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getStatusIcon(networkState, dataUsageState, syncState),
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getStatusText(networkState, dataUsageState, syncState),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (syncState.isSyncing) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    value: syncState.progress,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(NetworkState networkState, DataUsageState dataUsageState, OfflineSyncState syncState) {
    if (dataUsageState.isOfflineMode) return Colors.orange;
    if (!networkState.isConnected) return Colors.red;
    if (syncState.isSyncing) return Colors.blue;
    if (syncState.hasRecentErrors) return Colors.orange;
    return Colors.green;
  }

  IconData _getStatusIcon(NetworkState networkState, DataUsageState dataUsageState, OfflineSyncState syncState) {
    if (dataUsageState.isOfflineMode) return Icons.offline_bolt;
    if (!networkState.isConnected) return Icons.wifi_off;
    if (syncState.isSyncing) return Icons.sync;
    if (syncState.hasRecentErrors) return Icons.sync_problem;
    return Icons.wifi;
  }

  String _getStatusText(NetworkState networkState, DataUsageState dataUsageState, OfflineSyncState syncState) {
    if (dataUsageState.isOfflineMode) return 'Offline Mode';
    if (!networkState.isConnected) return 'No Connection';
    if (syncState.isSyncing) return 'Syncing...';
    if (syncState.hasRecentErrors) return 'Sync Issues';
    return 'Connected';
  }
}

/// Data usage warning banner
class DataUsageWarningBanner extends ConsumerWidget {
  const DataUsageWarningBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataUsageState = ref.watch(dataUsageProvider);

    if (!dataUsageState.shouldShowDataWarning) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final usagePercentage = (dataUsageState.stats.totalBytesUsed / (1024 * 1024)) / dataUsageState.monthlyDataLimit;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: usagePercentage > 0.9 ? Colors.red.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: usagePercentage > 0.9 ? Colors.red : Colors.orange,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            usagePercentage > 0.9 ? Icons.error : Icons.warning,
            color: usagePercentage > 0.9 ? Colors.red : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  usagePercentage > 0.9 ? 'Data Limit Exceeded' : 'Approaching Data Limit',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: usagePercentage > 0.9 ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${dataUsageState.stats.formattedTotalUsage} of ${dataUsageState.monthlyDataLimit} MB used',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: usagePercentage > 0.9 ? Colors.red : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // Navigate to data usage settings
              Navigator.of(context).pushNamed('/data-usage-settings');
            },
            child: Text(
              'Settings',
              style: TextStyle(
                color: usagePercentage > 0.9 ? Colors.red : Colors.orange,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
