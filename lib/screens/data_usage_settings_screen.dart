import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_usage_provider.dart';
import '../providers/network_provider.dart';

class DataUsageSettingsScreen extends ConsumerStatefulWidget {
  const DataUsageSettingsScreen({super.key});

  @override
  ConsumerState<DataUsageSettingsScreen> createState() => _DataUsageSettingsScreenState();
}

class _DataUsageSettingsScreenState extends ConsumerState<DataUsageSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final dataUsageState = ref.watch(dataUsageProvider);
    final networkState = ref.watch(networkProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dataverbruik & Offline'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status Card
            _buildConnectionStatusCard(theme, networkState, dataUsageState),
            
            const SizedBox(height: 24),
            
            // Data Usage Mode
            _buildDataUsageModeCard(theme, dataUsageState),
            
            const SizedBox(height: 16),
            
            // Quality Settings
            _buildQualitySettingsCard(theme, dataUsageState),
            
            const SizedBox(height: 16),
            
            // Data Limits & Warnings
            _buildDataLimitsCard(theme, dataUsageState),
            
            const SizedBox(height: 16),
            
            // Offline Features
            _buildOfflineFeaturesCard(theme, dataUsageState),
            
            const SizedBox(height: 16),
            
            // Usage Statistics
            _buildUsageStatisticsCard(theme, dataUsageState),
            
            const SizedBox(height: 24),
            
            // Reset Button
            _buildResetButton(theme),
            
            // Add more space below the reset button
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard(ThemeData theme, networkState, dataUsageState) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  networkState.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: networkState.isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Netwerkstatus',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status:',
                  style: theme.textTheme.bodyMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: networkState.isConnected ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    networkState.isConnected ? 'Verbonden' : 'Niet verbonden',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: networkState.isConnected ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Type:',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  _getConnectionTypeText(dataUsageState.connectionType),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (dataUsageState.isOfflineMode) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.offline_bolt, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Offline modus actief',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDataUsageModeCard(ThemeData theme, dataUsageState) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dataverbruik Modus',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...DataUsageMode.values.map((mode) => RadioListTile<DataUsageMode>(
              title: Text(_getDataUsageModeTitle(mode)),
              subtitle: Text(_getDataUsageModeDescription(mode)),
              value: mode,
              // ignore: deprecated_member_use
              groupValue: dataUsageState.mode,
              // ignore: deprecated_member_use
              onChanged: (DataUsageMode? value) {
                if (value != null) {
                  ref.read(dataUsageProvider.notifier).setMode(value);
                }
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildQualitySettingsCard(ThemeData theme, dataUsageState) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kwaliteitsinstellingen',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Video Quality
            Text(
              'Video Kwaliteit',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<DataUsageQuality>(
              initialValue: dataUsageState.videoQuality,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: DataUsageQuality.values.map((quality) => DropdownMenuItem(
                value: quality,
                child: Text(_getQualityTitle(quality)),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(dataUsageProvider.notifier).setVideoQuality(value);
                }
              },
            ),
            
            const SizedBox(height: 16),
            
            // Image Quality
            Text(
              'Afbeelding Kwaliteit',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<DataUsageQuality>(
              initialValue: dataUsageState.imageQuality,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: DataUsageQuality.values.map((quality) => DropdownMenuItem(
                value: quality,
                child: Text(_getQualityTitle(quality)),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  ref.read(dataUsageProvider.notifier).setImageQuality(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataLimitsCard(ThemeData theme, dataUsageState) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Limieten & Waarschuwingen',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Monthly Data Limit
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Maandelijkse Limiet:',
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '${dataUsageState.monthlyDataLimit} MB',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Slider(
              value: dataUsageState.monthlyDataLimit.toDouble(),
              min: 100,
              max: 10000,
              divisions: 99,
              label: '${dataUsageState.monthlyDataLimit} MB',
              onChanged: (value) {
                ref.read(dataUsageProvider.notifier).setMonthlyDataLimit(value.round());
              },
            ),
            
            const SizedBox(height: 16),
            
            // Data Warnings
            SwitchListTile(
              title: const Text('Data Waarschuwingen Tonen'),
              subtitle: const Text('Krijg een melding wanneer je de data limiet nadert'),
              value: dataUsageState.showDataWarnings,
              onChanged: (value) {
                ref.read(dataUsageProvider.notifier).setShowDataWarnings(value);
              },
            ),
            
            // Usage Progress
            if (dataUsageState.monthlyDataLimit > 0) ...[
              const SizedBox(height: 16),
              Text(
                'Huidig Verbruik',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (dataUsageState.stats.totalBytesUsed / (1024 * 1024)) / dataUsageState.monthlyDataLimit,
                backgroundColor: Colors.grey.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  dataUsageState.shouldShowDataWarning ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${dataUsageState.stats.formattedTotalUsage} / ${dataUsageState.monthlyDataLimit} MB',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineFeaturesCard(ThemeData theme, dataUsageState) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Offline Functies',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Favorieten Voorladen'),
              subtitle: const Text('Download automatisch favoriete inhoud op Wi-Fi'),
              value: dataUsageState.preloadFavorites,
              onChanged: (value) {
                ref.read(dataUsageProvider.notifier).setPreloadFavorites(value);
              },
            ),
            
            SwitchListTile(
              title: const Text('Achtergrond Synchronisatie'),
              subtitle: const Text('Synchroniseer data automatisch wanneer verbonden'),
              value: dataUsageState.backgroundSync,
              onChanged: (value) {
                ref.read(dataUsageProvider.notifier).setBackgroundSync(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStatisticsCard(ThemeData theme, dataUsageState) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verbruik Statistieken',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildStatRow('Totaal Verbruik', dataUsageState.stats.formattedTotalUsage, theme),
            _buildStatRow('Video\'s', dataUsageState.stats.formattedVideosUsage, theme),
            _buildStatRow('Afbeeldingen', dataUsageState.stats.formattedImagesUsage, theme),
            _buildStatRow('Forum', dataUsageState.stats.formattedForumUsage, theme),
            
            const SizedBox(height: 16),
            
            Text(
              'Laatste Reset: ${_formatDate(dataUsageState.stats.lastReset)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showResetDialog(theme),
        icon: const Icon(Icons.refresh),
        label: const Text('Verbruik Statistieken Resetten'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _showResetDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verbruik Statistieken Resetten'),
        content: const Text(
          'Dit zal alle verbruik statistieken resetten. Deze actie kan niet ongedaan worden gemaakt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () {
              ref.read(dataUsageProvider.notifier).resetMonthlyStats();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Verbruik statistieken succesvol gereset')),
              );
            },
            child: const Text('Resetten'),
          ),
        ],
      ),
    );
  }

  String _getConnectionTypeText(ConnectionType type) {
    switch (type) {
      case ConnectionType.wifi:
        return 'Wi-Fi';
      case ConnectionType.cellular:
        return '4G/5G';
      case ConnectionType.unknown:
        return 'Onbekend';
    }
  }

  String _getDataUsageModeTitle(DataUsageMode mode) {
    switch (mode) {
      case DataUsageMode.unlimited:
        return 'Onbeperkt';
      case DataUsageMode.moderate:
        return 'Gematigd';
      case DataUsageMode.strict:
        return 'Strikt';
      case DataUsageMode.wifiOnly:
        return 'Alleen Wi-Fi';
    }
  }

  String _getDataUsageModeDescription(DataUsageMode mode) {
    switch (mode) {
      case DataUsageMode.unlimited:
        return 'Geen beperkingen op dataverbruik';
      case DataUsageMode.moderate:
        return 'Enkele beperkingen op hoogbandbreedte inhoud';
      case DataUsageMode.strict:
        return 'Maximaal data besparen, lagere kwaliteit';
      case DataUsageMode.wifiOnly:
        return 'Alleen inhoud downloaden op Wi-Fi';
    }
  }

  String _getQualityTitle(DataUsageQuality quality) {
    switch (quality) {
      case DataUsageQuality.low:
        return 'Laag (Data Besparen)';
      case DataUsageQuality.medium:
        return 'Gemiddeld (Gebalanceerd)';
      case DataUsageQuality.high:
        return 'Hoog (Beste Kwaliteit)';
      case DataUsageQuality.auto:
        return 'Automatisch (Slim)';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
