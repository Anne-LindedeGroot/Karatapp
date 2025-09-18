import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/mute_service.dart';
import 'auth_provider.dart';

// Provider for the MuteService instance
final muteServiceProvider = Provider<MuteService>((ref) {
  return MuteService();
});

// Provider to check if current user can mute others
final canMuteUsersProvider = FutureProvider<bool>((ref) async {
  final muteService = ref.read(muteServiceProvider);
  return await muteService.canMuteUsers();
});

// Provider to check if a specific user is muted
final isUserMutedProvider = FutureProvider.family<bool, String>((ref, userId) async {
  final muteService = ref.read(muteServiceProvider);
  return await muteService.isUserMuted(userId);
});

// Provider to get current mute info for a user
final currentMuteProvider = FutureProvider.family<MuteInfo?, String>((ref, userId) async {
  final muteService = ref.read(muteServiceProvider);
  return await muteService.getCurrentMute(userId);
});

// Provider to get all active mutes (for admin view)
final activeMutesProvider = FutureProvider<List<MuteInfo>>((ref) async {
  final muteService = ref.read(muteServiceProvider);
  return await muteService.getAllActiveMutes();
});

// Provider to get mute history for a user
final userMuteHistoryProvider = FutureProvider.family<List<MuteInfo>, String>((ref, userId) async {
  final muteService = ref.read(muteServiceProvider);
  return await muteService.getUserMuteHistory(userId);
});

// Provider to get mute statistics
final muteStatisticsProvider = FutureProvider<Map<String, int>>((ref) async {
  final muteService = ref.read(muteServiceProvider);
  return await muteService.getMuteStatistics();
});

// StateNotifier for mute management actions
class MuteNotifier extends StateNotifier<AsyncValue<void>> {
  final MuteService _muteService;

  MuteNotifier(this._muteService) : super(const AsyncValue.data(null));

  Future<bool> muteUser({
    required String userId,
    required MuteDuration duration,
    required String reason,
  }) async {
    state = const AsyncValue.loading();
    
    try {
      final success = await _muteService.muteUser(
        userId: userId,
        duration: duration,
        reason: reason,
      );
      
      if (success) {
        state = const AsyncValue.data(null);
        return true;
      } else {
        state = AsyncValue.error('Failed to mute user', StackTrace.current);
        return false;
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  Future<bool> unmuteUser(String userId) async {
    state = const AsyncValue.loading();
    
    try {
      final success = await _muteService.unmuteUser(userId);
      
      if (success) {
        state = const AsyncValue.data(null);
        return true;
      } else {
        state = AsyncValue.error('Failed to unmute user', StackTrace.current);
        return false;
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  Future<bool> isUserMuted(String userId) async {
    try {
      return await _muteService.isUserMuted(userId);
    } catch (e) {
      return false;
    }
  }

  Future<MuteInfo?> getCurrentMute(String userId) async {
    try {
      return await _muteService.getCurrentMute(userId);
    } catch (e) {
      return null;
    }
  }

  Future<List<MuteInfo>> getAllActiveMutes() async {
    try {
      return await _muteService.getAllActiveMutes();
    } catch (e) {
      return [];
    }
  }

  Future<List<MuteInfo>> getUserMuteHistory(String userId) async {
    try {
      return await _muteService.getUserMuteHistory(userId);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, int>> getMuteStatistics() async {
    try {
      return await _muteService.getMuteStatistics();
    } catch (e) {
      return {
        'active': 0,
        'total': 0,
        'expired_today': 0,
      };
    }
  }
}

// Provider for the MuteNotifier
final muteNotifierProvider = StateNotifierProvider<MuteNotifier, AsyncValue<void>>((ref) {
  final muteService = ref.watch(muteServiceProvider);
  return MuteNotifier(muteService);
});

// Provider to check if current user is muted
final isCurrentUserMutedProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authUserProvider);
  if (user == null) return false;
  
  final muteService = ref.read(muteServiceProvider);
  return await muteService.isUserMuted(user.id);
});

// Provider to get current user's mute info
final currentUserMuteProvider = FutureProvider<MuteInfo?>((ref) async {
  final user = ref.watch(authUserProvider);
  if (user == null) return null;
  
  final muteService = ref.read(muteServiceProvider);
  return await muteService.getCurrentMute(user.id);
});

// Provider to refresh mute data (useful after mute/unmute operations)
final refreshMuteDataProvider = FutureProvider.family<void, int>((ref, refreshKey) async {
  // This provider is used to force refresh other mute-related providers
  // by invalidating them when the refreshKey changes
  ref.invalidate(activeMutesProvider);
  ref.invalidate(muteStatisticsProvider);
  ref.invalidate(isCurrentUserMutedProvider);
  ref.invalidate(currentUserMuteProvider);
});
