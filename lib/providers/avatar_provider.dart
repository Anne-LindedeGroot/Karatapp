import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/avatar_model.dart';
import '../services/avatar_service.dart';
import '../supabase_client.dart';

/// Provider for avatar service
final avatarServiceProvider = Provider<AvatarService>((ref) {
  return AvatarService();
});

/// Provider for current user's avatar
final userAvatarProvider = StateNotifierProvider<UserAvatarNotifier, AsyncValue<UserAvatar?>>((ref) {
  final avatarService = ref.watch(avatarServiceProvider);
  return UserAvatarNotifier(avatarService);
});

/// Provider for avatar URL (with caching)
final avatarUrlProvider = FutureProvider.family<String?, String>((ref, userId) async {
  final avatarService = ref.watch(avatarServiceProvider);
  return await avatarService.getAvatarUrl(userId);
});

/// Provider for thumbnail avatar URL
final avatarThumbnailUrlProvider = FutureProvider.family<String?, String>((ref, userId) async {
  final avatarService = ref.watch(avatarServiceProvider);
  return await avatarService.getAvatarUrl(userId, thumbnail: true);
});

/// State notifier for managing user avatar
class UserAvatarNotifier extends StateNotifier<AsyncValue<UserAvatar?>> {
  final AvatarService _avatarService;
  
  UserAvatarNotifier(this._avatarService) : super(const AsyncValue.loading()) {
    _loadUserAvatar();
  }

  /// Load current user's avatar from auth metadata
  Future<void> _loadUserAvatar() async {
    try {
      final client = SupabaseClientManager().client;
      final user = client.auth.currentUser;
      
      if (user == null) {
        state = const AsyncValue.data(null);
        return;
      }

      // Check if user has custom avatar in storage
      final hasCustom = await _avatarService.hasCustomAvatar(user.id);
      
      if (hasCustom) {
        // Get signed URL for custom avatar
        final customUrl = await _avatarService.getAvatarUrl(user.id);
        state = AsyncValue.data(UserAvatar(
          customAvatarUrl: customUrl,
          type: AvatarType.custom,
          lastUpdated: DateTime.now(),
        ));
      } else {
        // Get avatar preferences from user metadata
        final metadata = user.userMetadata ?? {};
        final avatarType = metadata['avatar_type'] as String?;
        final presetAvatarId = metadata['preset_avatar_id'] as String?;
        final lastUpdatedStr = metadata['avatar_updated_at'] as String?;

        state = AsyncValue.data(UserAvatar(
          presetAvatarId: presetAvatarId ?? 'animal_panda', // Default avatar
          type: avatarType == 'custom' ? AvatarType.custom : AvatarType.preset,
          lastUpdated: lastUpdatedStr != null 
              ? DateTime.tryParse(lastUpdatedStr)
              : null,
        ));
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Upload custom avatar
  Future<void> uploadCustomAvatar(File imageFile) async {
    state = const AsyncValue.loading();
    
    try {
      final avatarPath = await _avatarService.uploadAvatar(imageFile);
      if (avatarPath == null) {
        throw Exception('Failed to upload avatar');
      }

      // Get signed URL for the uploaded avatar
      final client = SupabaseClientManager().client;
      final user = client.auth.currentUser!;
      final customUrl = await _avatarService.getAvatarUrl(user.id);

      // Update user metadata
      await client.auth.updateUser(
        UserAttributes(
          data: {
            'avatar_type': 'custom',
            'custom_avatar_url': avatarPath,
            'preset_avatar_id': null,
            'avatar_updated_at': DateTime.now().toIso8601String(),
          },
        ),
      );

      state = AsyncValue.data(UserAvatar(
        customAvatarUrl: customUrl,
        type: AvatarType.custom,
        lastUpdated: DateTime.now(),
      ));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Set preset avatar
  Future<void> setPresetAvatar(String avatarId) async {
    state = const AsyncValue.loading();
    
    try {
      final client = SupabaseClientManager().client;

      // Update user metadata
      await client.auth.updateUser(
        UserAttributes(
          data: {
            'avatar_type': 'preset',
            'preset_avatar_id': avatarId,
            'custom_avatar_url': null,
            'avatar_updated_at': DateTime.now().toIso8601String(),
          },
        ),
      );

      state = AsyncValue.data(UserAvatar(
        presetAvatarId: avatarId,
        type: AvatarType.preset,
        lastUpdated: DateTime.now(),
      ));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Delete custom avatar and revert to preset
  Future<void> deleteCustomAvatar({String? fallbackPresetId}) async {
    state = const AsyncValue.loading();
    
    try {
      // Delete from storage
      await _avatarService.deleteAvatar();

      final client = SupabaseClientManager().client;

      // Update user metadata to use preset avatar
      await client.auth.updateUser(
        UserAttributes(
          data: {
            'avatar_type': 'preset',
            'preset_avatar_id': fallbackPresetId ?? 'animal_panda',
            'custom_avatar_url': null,
            'avatar_updated_at': DateTime.now().toIso8601String(),
          },
        ),
      );

      state = AsyncValue.data(UserAvatar(
        presetAvatarId: fallbackPresetId ?? 'animal_panda',
        type: AvatarType.preset,
        lastUpdated: DateTime.now(),
      ));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Refresh avatar data
  Future<void> refresh() async {
    await _loadUserAvatar();
  }
}

/// Provider for checking if user has custom avatar
final hasCustomAvatarProvider = FutureProvider.family<bool, String?>((ref, userId) async {
  if (userId == null) return false;
  final avatarService = ref.watch(avatarServiceProvider);
  return await avatarService.hasCustomAvatar(userId);
});
