import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/storage/local_storage.dart';
import '../providers/data_usage_provider.dart';
import '../providers/network_provider.dart';
import '../services/enhanced_video_service.dart';

/// Smart preloading service for favorite content and frequently accessed data
class SmartPreloadService {
  Timer? _preloadTimer;
  static const Duration _preloadInterval = Duration(hours: 6); // Preload every 6 hours
  
  /// Start smart preloading
  void startSmartPreloading(Ref ref) {
    final dataUsageState = ref.read(dataUsageProvider);
    
    if (!dataUsageState.preloadFavorites) {
      debugPrint('Smart preloading disabled by user settings');
      return;
    }

    _preloadTimer?.cancel();
    
    // Initial preload
    _performSmartPreload(ref);
    
    // Schedule periodic preloads
    _preloadTimer = Timer.periodic(_preloadInterval, (_) {
      _performSmartPreload(ref);
    });
    
    debugPrint('🔄 Smart preloading started');
  }
  
  /// Stop smart preloading
  void stopSmartPreloading() {
    _preloadTimer?.cancel();
    _preloadTimer = null;
    debugPrint('⏹️ Smart preloading stopped');
  }
  
  /// Perform smart preload based on user behavior and preferences
  Future<void> _performSmartPreload(Ref ref) async {
    try {
      final dataUsageState = ref.read(dataUsageProvider);
      final networkState = ref.read(networkProvider);
      
      // Only preload if conditions are met
      if (!_shouldPreload(dataUsageState, networkState)) {
        debugPrint('Preload conditions not met, skipping...');
        return;
      }

      debugPrint('🚀 Starting smart preload...');
      
      // Get content to preload based on user behavior
      final preloadPlan = await _createPreloadPlan(ref);
      
      if (preloadPlan.isEmpty) {
        debugPrint('No content to preload');
        return;
      }

      // Execute preload plan
      await _executePreloadPlan(preloadPlan, ref);
      
      debugPrint('✅ Smart preload completed');
    } catch (e) {
      debugPrint('❌ Smart preload failed: $e');
    }
  }
  
  /// Check if preloading should occur
  bool _shouldPreload(dataUsageState, networkState) {
    // Must be connected
    if (!networkState.isConnected) return false;
    
    // Must be on Wi-Fi (unless user has unlimited mode)
    if (dataUsageState.mode != DataUsageMode.unlimited && 
        dataUsageState.connectionType != ConnectionType.wifi) {
      return false;
    }
    
    // Must have preloading enabled
    if (!dataUsageState.preloadFavorites) return false;
    
    // Don't preload if approaching data limit
    if (dataUsageState.shouldShowDataWarning) return false;
    
    return true;
  }
  
  /// Create a preload plan based on user behavior
  Future<Map<String, dynamic>> _createPreloadPlan(Ref ref) async {
    final plan = <String, dynamic>{};
    
    try {
      // Get favorite katas
      final favoriteKatas = LocalStorage.getFavoriteKatas();
      if (favoriteKatas.isNotEmpty) {
        plan['favoriteKatas'] = favoriteKatas;
        debugPrint('📋 Added ${favoriteKatas.length} favorite katas to preload plan');
      }
      
      // Get recently viewed katas (last 7 days)
      final recentKatas = _getRecentlyViewedKatas();
      if (recentKatas.isNotEmpty) {
        plan['recentKatas'] = recentKatas;
        debugPrint('📋 Added ${recentKatas.length} recent katas to preload plan');
      }
      
      // Get frequently accessed content
      final frequentContent = await _getFrequentlyAccessedContent();
      if (frequentContent.isNotEmpty) {
        plan['frequentContent'] = frequentContent;
        debugPrint('📋 Added ${frequentContent.length} frequent items to preload plan');
      }
      
      // Prioritize content based on usage patterns
      plan['priority'] = _prioritizeContent(plan);
      
    } catch (e) {
      debugPrint('Error creating preload plan: $e');
    }
    
    return plan;
  }
  
  /// Execute the preload plan
  Future<void> _executePreloadPlan(Map<String, dynamic> plan, Ref ref) async {
    final dataUsageState = ref.read(dataUsageProvider);
    int totalItems = 0;
    int processedItems = 0;
    
    try {
      // Count total items
      if (plan['favoriteKatas'] != null) totalItems += (plan['favoriteKatas'] as List).length;
      if (plan['recentKatas'] != null) totalItems += (plan['recentKatas'] as List).length;
      if (plan['frequentContent'] != null) totalItems += (plan['frequentContent'] as List).length;
      
      if (totalItems == 0) return;
      
      debugPrint('📦 Executing preload plan with $totalItems items');
      
      // Preload favorite katas
      if (plan['favoriteKatas'] != null) {
        final favoriteKatas = plan['favoriteKatas'] as List<CachedKata>;
        for (final kata in favoriteKatas) {
          await _preloadKataContent(kata, ref);
          processedItems++;
          
          // Check if we should continue based on data usage
          if (!_shouldContinuePreloading(dataUsageState, processedItems, totalItems)) {
            debugPrint('⏸️ Stopping preload due to data usage concerns');
            break;
          }
          
          // Small delay to avoid overwhelming the network
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      // Preload recent katas (lower priority)
      if (plan['recentKatas'] != null && _shouldContinuePreloading(dataUsageState, processedItems, totalItems)) {
        final recentKatas = plan['recentKatas'] as List<CachedKata>;
        for (final kata in recentKatas) {
          await _preloadKataContent(kata, ref);
          processedItems++;
          
          if (!_shouldContinuePreloading(dataUsageState, processedItems, totalItems)) {
            break;
          }
          
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      // Preload frequent content (lowest priority)
      if (plan['frequentContent'] != null && _shouldContinuePreloading(dataUsageState, processedItems, totalItems)) {
        final frequentContent = plan['frequentContent'] as List;
        for (final content in frequentContent) {
          await _preloadContent(content, ref);
          processedItems++;
          
          if (!_shouldContinuePreloading(dataUsageState, processedItems, totalItems)) {
            break;
          }
          
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      debugPrint('✅ Preload plan executed: $processedItems/$totalItems items processed');
      
    } catch (e) {
      debugPrint('❌ Error executing preload plan: $e');
    }
  }
  
  /// Preload content for a specific kata
  Future<void> _preloadKataContent(CachedKata kata, Ref ref) async {
    try {
      debugPrint('📥 Preloading content for kata: ${kata.name}');
      
      // Preload videos
      await EnhancedVideoService.preloadVideosForKata(kata.id, ref);
      
      // Preload images (if any)
      // This would integrate with your image system
      
      // Mark as preloaded
      _markAsPreloaded(kata.id, 'kata');
      
    } catch (e) {
      debugPrint('Error preloading kata ${kata.id}: $e');
    }
  }
  
  /// Preload generic content
  Future<void> _preloadContent(dynamic content, Ref ref) async {
    try {
      // This would handle different types of content
      debugPrint('📥 Preloading content: $content');
      
      // Mark as preloaded
      _markAsPreloaded(content['id'], content['type']);
      
    } catch (e) {
      debugPrint('Error preloading content: $e');
    }
  }
  
  /// Get recently viewed katas
  List<CachedKata> _getRecentlyViewedKatas() {
    try {
      final allKatas = LocalStorage.getAllKatas();
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      
      return allKatas.where((kata) {
        return kata.lastSynced.isAfter(weekAgo);
      }).toList();
    } catch (e) {
      debugPrint('Error getting recently viewed katas: $e');
      return [];
    }
  }
  
  /// Get frequently accessed content
  Future<List<Map<String, dynamic>>> _getFrequentlyAccessedContent() async {
    try {
      // This would analyze user behavior patterns
      // For now, return empty list as placeholder
      return [];
    } catch (e) {
      debugPrint('Error getting frequently accessed content: $e');
      return [];
    }
  }
  
  /// Prioritize content for preloading
  Map<String, int> _prioritizeContent(Map<String, dynamic> plan) {
    final priorities = <String, int>{};
    
    // Favorite katas get highest priority
    if (plan['favoriteKatas'] != null) {
      priorities['favoriteKatas'] = 1;
    }
    
    // Recent katas get medium priority
    if (plan['recentKatas'] != null) {
      priorities['recentKatas'] = 2;
    }
    
    // Frequent content gets lowest priority
    if (plan['frequentContent'] != null) {
      priorities['frequentContent'] = 3;
    }
    
    return priorities;
  }
  
  /// Check if preloading should continue
  bool _shouldContinuePreloading(dataUsageState, int processedItems, int totalItems) {
    // Don't continue if approaching data limit
    if (dataUsageState.shouldShowDataWarning) return false;
    
    // Don't continue if we've processed too many items
    if (processedItems >= 20) return false; // Limit to 20 items per session
    
    // Don't continue if we're not on Wi-Fi and not in unlimited mode
    if (dataUsageState.mode != DataUsageMode.unlimited && 
        dataUsageState.connectionType != ConnectionType.wifi) {
      return false;
    }
    
    return true;
  }
  
  /// Mark content as preloaded
  void _markAsPreloaded(int id, String type) {
    try {
      // This would update local storage to track preloaded content
      debugPrint('✅ Marked $type $id as preloaded');
    } catch (e) {
      debugPrint('Error marking content as preloaded: $e');
    }
  }
  
  /// Get preload statistics
  Map<String, dynamic> getPreloadStats() {
    try {
      // This would return statistics about preloaded content
      return {
        'totalPreloaded': 0,
        'lastPreloadTime': null,
        'nextPreloadTime': null,
        'successRate': 0.0,
      };
    } catch (e) {
      debugPrint('Error getting preload stats: $e');
      return {
        'totalPreloaded': 0,
        'lastPreloadTime': null,
        'nextPreloadTime': null,
        'successRate': 0.0,
      };
    }
  }
  
  /// Force immediate preload
  Future<void> forcePreload(Ref ref) async {
    debugPrint('🔄 Force preload requested');
    await _performSmartPreload(ref);
  }
  
  /// Clear preloaded content
  Future<void> clearPreloadedContent() async {
    try {
      // This would clear preloaded content from local storage
      debugPrint('🧹 Clearing preloaded content');
    } catch (e) {
      debugPrint('Error clearing preloaded content: $e');
    }
  }
}

/// Smart preload notifier
class SmartPreloadNotifier extends StateNotifier<Map<String, dynamic>> {
  final SmartPreloadService _preloadService = SmartPreloadService();

  SmartPreloadNotifier() : super({
    'isActive': false,
    'lastPreloadTime': null,
    'nextPreloadTime': null,
    'stats': {},
  });

  /// Start smart preloading
  void startPreloading(Ref ref) {
    _preloadService.startSmartPreloading(ref);
    state = {
      ...state,
      'isActive': true,
      'nextPreloadTime': DateTime.now().add(const Duration(hours: 6)),
    };
  }

  /// Stop smart preloading
  void stopPreloading() {
    _preloadService.stopSmartPreloading();
    state = {
      ...state,
      'isActive': false,
      'nextPreloadTime': null,
    };
  }

  /// Force immediate preload
  Future<void> forcePreload(Ref ref) async {
    await _preloadService.forcePreload(ref);
    state = {
      ...state,
      'lastPreloadTime': DateTime.now(),
      'nextPreloadTime': DateTime.now().add(const Duration(hours: 6)),
    };
  }

  /// Update stats
  void updateStats() {
    final stats = _preloadService.getPreloadStats();
    state = {
      ...state,
      'stats': stats,
    };
  }
}

// Providers
final smartPreloadProvider = StateNotifierProvider<SmartPreloadNotifier, Map<String, dynamic>>((ref) {
  return SmartPreloadNotifier();
});

final isPreloadingActiveProvider = Provider<bool>((ref) {
  return ref.watch(smartPreloadProvider)['isActive'] ?? false;
});
