import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/role_service.dart';
import 'auth_provider.dart';

// Provider for the RoleService instance
final roleServiceProvider = Provider<RoleService>((ref) {
  return RoleService();
});

// Provider for current user's role
final currentUserRoleProvider = FutureProvider.autoDispose<UserRole>((ref) async {
  final user = ref.watch(authUserProvider);
  if (user == null) return UserRole.user;
  
  try {
    final roleService = ref.read(roleServiceProvider);
    final role = await roleService.getCurrentUserRole();
    return role;
  } catch (e) {
    // Only default to user if there's a real error, not network issues
    print('RoleProvider: Error in currentUserRoleProvider: $e');
    return UserRole.user;
  }
});

// Provider to force refresh current user role (useful after database changes)
final refreshCurrentUserRoleProvider = FutureProvider.family<UserRole, int>((ref, refreshKey) async {
  final user = ref.watch(authUserProvider);
  if (user == null) return UserRole.user;
  
  try {
    final roleService = ref.read(roleServiceProvider);
    final role = await roleService.getCurrentUserRole();
    print('RoleProvider: Refreshed role: ${role.value}');
    return role;
  } catch (e) {
    print('RoleProvider: Error refreshing role: $e');
    return UserRole.user;
  }
});

// Provider for checking if current user can assign roles
final canAssignRolesProvider = FutureProvider<bool>((ref) async {
  final userRole = await ref.watch(currentUserRoleProvider.future);
  return userRole == UserRole.host;
});

// Provider for checking if current user is a host
final isCurrentUserHostProvider = FutureProvider<bool>((ref) async {
  final userRole = await ref.watch(currentUserRoleProvider.future);
  return userRole == UserRole.host;
});

// Provider for checking if current user is a mediator or host
final isCurrentUserModeratorProvider = FutureProvider<bool>((ref) async {
  final userRole = await ref.watch(currentUserRoleProvider.future);
  return userRole == UserRole.mediator || userRole == UserRole.host;
});

// StateNotifier for role management actions
class RoleNotifier extends StateNotifier<AsyncValue<void>> {
  final RoleService _roleService;

  RoleNotifier(this._roleService) : super(const AsyncValue.data(null));

  Future<bool> assignRole(String userId, UserRole role) async {
    state = const AsyncValue.loading();
    
    try {
      final success = await _roleService.assignRole(userId, role);
      if (success) {
        state = const AsyncValue.data(null);
        return true;
      } else {
        state = AsyncValue.error('Failed to assign role', StackTrace.current);
        return false;
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsersWithRoles() async {
    try {
      return await _roleService.getAllUsersWithRoles();
    } catch (e) {
      return [];
    }
  }

  bool hasPermission(UserRole userRole, String permission) {
    return _roleService.hasPermission(userRole, permission);
  }

  // Method to force refresh current user role
  Future<UserRole> refreshCurrentUserRole() async {
    try {
      return await _roleService.getCurrentUserRole();
    } catch (e) {
      return UserRole.user;
    }
  }
}

// Provider for the RoleNotifier
final roleNotifierProvider = StateNotifierProvider<RoleNotifier, AsyncValue<void>>((ref) {
  final roleService = ref.watch(roleServiceProvider);
  return RoleNotifier(roleService);
});

// Convenience providers for specific permissions
final canModerateContentProvider = FutureProvider<bool>((ref) async {
  final userRole = await ref.watch(currentUserRoleProvider.future);
  final roleNotifier = ref.read(roleNotifierProvider.notifier);
  return roleNotifier.hasPermission(userRole, 'moderate_content');
});

final canDeleteAnyPostProvider = FutureProvider<bool>((ref) async {
  final userRole = await ref.watch(currentUserRoleProvider.future);
  final roleNotifier = ref.read(roleNotifierProvider.notifier);
  return roleNotifier.hasPermission(userRole, 'delete_any_post');
});

final canPinPostsProvider = FutureProvider<bool>((ref) async {
  final userRole = await ref.watch(currentUserRoleProvider.future);
  final roleNotifier = ref.read(roleNotifierProvider.notifier);
  return roleNotifier.hasPermission(userRole, 'pin_posts');
});

final canLockPostsProvider = FutureProvider<bool>((ref) async {
  final userRole = await ref.watch(currentUserRoleProvider.future);
  final roleNotifier = ref.read(roleNotifierProvider.notifier);
  return roleNotifier.hasPermission(userRole, 'lock_posts');
});

final canMuteUsersProvider = FutureProvider<bool>((ref) async {
  final userRole = await ref.watch(currentUserRoleProvider.future);
  final roleNotifier = ref.read(roleNotifierProvider.notifier);
  return roleNotifier.hasPermission(userRole, 'mute_users');
});
