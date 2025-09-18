import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/forum_service.dart';
import '../services/role_service.dart';
import 'auth_provider.dart';
import 'network_provider.dart';
import 'role_provider.dart';

// Provider for checking if current user is a host
final isHostProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authUserProvider);
  if (user == null) return false;
  
  // Check network status before making the call
  final networkState = ref.read(networkProvider);
  if (networkState.isDisconnected) {
    return false; // Default to false when offline
  }
  
  try {
    // Use the new role system first
    final userRole = await ref.watch(currentUserRoleProvider.future);
    if (userRole == UserRole.host) {
      return true;
    }
    
    // Fallback to old forum service check for backward compatibility
    final forumService = ForumService();
    final result = await forumService.isAppHost(user.id);
    return result;
  } catch (e) {
    // Return false on error instead of throwing
    return false;
  }
});

// Provider for checking if current user is a mediator
final isMediatorProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authUserProvider);
  if (user == null) return false;
  
  // Check network status before making the call
  final networkState = ref.read(networkProvider);
  if (networkState.isDisconnected) {
    return false; // Default to false when offline
  }
  
  try {
    final userRole = await ref.watch(currentUserRoleProvider.future);
    return userRole == UserRole.mediator;
  } catch (e) {
    return false;
  }
});

// Provider for checking if current user can moderate (mediator or host)
final canModerateProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authUserProvider);
  if (user == null) return false;
  
  // Check network status before making the call
  final networkState = ref.read(networkProvider);
  if (networkState.isDisconnected) {
    return false; // Default to false when offline
  }
  
  try {
    final userRole = await ref.watch(currentUserRoleProvider.future);
    return userRole == UserRole.mediator || userRole == UserRole.host;
  } catch (e) {
    return false;
  }
});

// Provider for checking if user can edit/delete a specific forum post
final canEditForumPostProvider = FutureProvider.family<bool, String>((ref, postAuthorId) async {
  final user = ref.watch(authUserProvider);
  if (user == null) return false;
  
  // User can edit if they are the author
  if (user.id == postAuthorId) return true;
  
  // Check network status before making the call
  final networkState = ref.read(networkProvider);
  if (networkState.isDisconnected) {
    return false; // Default to false when offline
  }
  
  try {
    // Or if they are a host
    final forumService = ForumService();
    return await forumService.isAppHost(user.id);
  } catch (e) {
    // Return false on error instead of throwing
    return false;
  }
});

// Provider for checking if user can edit/delete a specific forum comment
final canEditForumCommentProvider = FutureProvider.family<bool, Map<String, String>>((ref, params) async {
  final user = ref.watch(authUserProvider);
  if (user == null) return false;
  
  final commentAuthorId = params['commentAuthorId']!;
  final postAuthorId = params['postAuthorId']!;
  
  // User can edit if they are the comment author
  if (user.id == commentAuthorId) return true;
  
  // Or if they are the post author (forum creator)
  if (user.id == postAuthorId) return true;
  
  // Check network status before making the call
  final networkState = ref.read(networkProvider);
  if (networkState.isDisconnected) {
    return false; // Default to false when offline
  }
  
  try {
    // Or if they are a moderator (host or mediator)
    final userRole = await ref.watch(currentUserRoleProvider.future);
    return userRole == UserRole.host || userRole == UserRole.mediator;
  } catch (e) {
    // Return false on error instead of throwing
    return false;
  }
});

// Provider for checking if user can edit/delete a kata comment
final canEditKataCommentProvider = FutureProvider.family<bool, Map<String, String>>((ref, params) async {
  final user = ref.watch(authUserProvider);
  if (user == null) return false;
  
  final commentAuthorId = params['commentAuthorId']!;
  final kataAuthorId = params['kataAuthorId']!;
  
  // User can edit if they are the comment author
  if (user.id == commentAuthorId) return true;
  
  // Or if they are the kata author (kata creator)
  if (user.id == kataAuthorId) return true;
  
  // Check network status before making the call
  final networkState = ref.read(networkProvider);
  if (networkState.isDisconnected) {
    return false; // Default to false when offline
  }
  
  try {
    // Or if they are a moderator (host or mediator) - use the existing moderator provider
    final isModerator = await ref.watch(isCurrentUserModeratorProvider.future);
    return isModerator;
  } catch (e) {
    // Return false on error instead of throwing
    return false;
  }
});

// Utility class for permission checks
class PermissionUtils {
  static Future<bool> isHost(WidgetRef ref) async {
    final isHostAsync = ref.read(isHostProvider);
    return await isHostAsync.when(
      data: (isHost) => isHost,
      loading: () => false,
      error: (_, __) => false,
    );
  }
  
  static Future<bool> canEditForumPost(WidgetRef ref, String postAuthorId) async {
    final canEditAsync = ref.read(canEditForumPostProvider(postAuthorId));
    return await canEditAsync.when(
      data: (canEdit) => canEdit,
      loading: () => false,
      error: (_, __) => false,
    );
  }
  
  static Future<bool> canEditForumComment(WidgetRef ref, String commentAuthorId, String postAuthorId) async {
    final params = {
      'commentAuthorId': commentAuthorId,
      'postAuthorId': postAuthorId,
    };
    final canEditAsync = ref.read(canEditForumCommentProvider(params));
    return await canEditAsync.when(
      data: (canEdit) => canEdit,
      loading: () => false,
      error: (_, __) => false,
    );
  }
  
  static Future<bool> canEditKataComment(WidgetRef ref, String commentAuthorId, String kataAuthorId) async {
    final params = {
      'commentAuthorId': commentAuthorId,
      'kataAuthorId': kataAuthorId,
    };
    final canEditAsync = ref.read(canEditKataCommentProvider(params));
    return await canEditAsync.when(
      data: (canEdit) => canEdit,
      loading: () => false,
      error: (_, __) => false,
    );
  }
}
