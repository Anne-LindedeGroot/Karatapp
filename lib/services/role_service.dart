import 'package:supabase_flutter/supabase_flutter.dart';

enum UserRole {
  user('user', 'User', 'Gewone gebruiker met basis rechten'),
  mediator('mediator', 'Mediator', 'Kan inhoud modereren en helpen bij het oplossen van conflicten'),
  host('host', 'Host', 'Volledige administratieve toegang tot de applicatie');

  const UserRole(this.value, this.displayName, this.description);
  
  final String value;
  final String displayName;
  final String description;
}

class RoleService {
  final SupabaseClient _client = Supabase.instance.client;

  // Get current user's role
  Future<UserRole> getCurrentUserRole() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        print('RoleService: No authenticated user found');
        return UserRole.user;
      }

      print('RoleService: Fetching role for user ${user.id}');

      final response = await _client
          .from('user_roles')
          .select('role, granted_at, user_id')
          .eq('user_id', user.id)
          .order('granted_at', ascending: false)
          .limit(1)
          .maybeSingle();

      print('RoleService: Database response: $response');

      if (response == null) {
        print('RoleService: No role found in database, defaulting to user');
        return UserRole.user;
      }

      final roleValue = response['role'] as String;
      print('RoleService: Found role: $roleValue');
      
      final userRole = UserRole.values.firstWhere(
        (role) => role.value == roleValue,
        orElse: () => UserRole.user,
      );
      
      print('RoleService: Returning role: ${userRole.value}');
      return userRole;
    } catch (e) {
      print('RoleService: Error fetching role: $e');
      return UserRole.user;
    }
  }

  // Get user's role by user ID
  Future<UserRole> getUserRole(String userId) async {
    try {
      final response = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', userId)
          .order('granted_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return UserRole.user;

      final roleValue = response['role'] as String;
      return UserRole.values.firstWhere(
        (role) => role.value == roleValue,
        orElse: () => UserRole.user,
      );
    } catch (e) {
      return UserRole.user;
    }
  }

  // Check if current user can assign roles (only hosts can assign roles)
  Future<bool> canAssignRoles() async {
    final currentRole = await getCurrentUserRole();
    return currentRole == UserRole.host;
  }

  // Assign role to a user (only hosts can do this)
  Future<bool> assignRole(String userId, UserRole role) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return false;

      // Check if current user can assign roles
      if (!(await canAssignRoles())) {
        throw Exception('You do not have permission to assign roles');
      }

      // Remove existing roles for this user
      await _client
          .from('user_roles')
          .delete()
          .eq('user_id', userId);

      // Insert new role
      await _client
          .from('user_roles')
          .insert({
            'user_id': userId,
            'role': role.value,
            'granted_by': currentUser.id,
            'granted_at': DateTime.now().toIso8601String(),
          });

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get all users with their roles (for admin interface)
  Future<List<Map<String, dynamic>>> getAllUsersWithRoles() async {
    try {
      print('RoleService: Fetching all users with roles...');
      
      // First, try to get all users from a user_profiles table if it exists
      // This is a common pattern where user profile data is stored separately
      List<Map<String, dynamic>> allUsers = [];
      
      try {
        print('RoleService: Attempting to fetch from user_profiles table...');
        final profilesResponse = await _client
            .from('user_profiles')
            .select('user_id, full_name, email, created_at');
        
        allUsers = List<Map<String, dynamic>>.from(profilesResponse);
        print('RoleService: Found ${allUsers.length} users in user_profiles table');
      } catch (e) {
        print('RoleService: user_profiles table not found or error: $e');
        
        // Fallback: Try to get users from any table that references user_id
        // This could be posts, comments, or any other user-generated content
        try {
          print('RoleService: Trying to find users from user activity...');
          
          // Get unique user IDs from various tables where users might have activity
          final Set<String> userIds = <String>{};
          
          // Try to get user IDs from common tables
          try {
            final kataUsers = await _client
                .from('katas')
                .select('created_by')
                .not('created_by', 'is', null);
            for (final kata in kataUsers) {
              if (kata['created_by'] != null) {
                userIds.add(kata['created_by'] as String);
              }
            }
            print('RoleService: Found ${userIds.length} users from katas table');
          } catch (e) {
            print('RoleService: Could not fetch from katas table: $e');
          }
          
          try {
            final forumUsers = await _client
                .from('forum_posts')
                .select('author_id')
                .not('author_id', 'is', null);
            for (final post in forumUsers) {
              if (post['author_id'] != null) {
                userIds.add(post['author_id'] as String);
              }
            }
            print('RoleService: Found ${userIds.length} total users including forum posts');
          } catch (e) {
            print('RoleService: Could not fetch from forum_posts table: $e');
          }
          
          // Add current user to ensure they appear in the list
          final currentUser = _client.auth.currentUser;
          if (currentUser != null) {
            userIds.add(currentUser.id);
          }
          
          // Convert user IDs to user objects with basic info
          allUsers = userIds.map((userId) {
            if (currentUser != null && currentUser.id == userId) {
              return {
                'user_id': userId,
                'full_name': currentUser.userMetadata?['full_name'] ?? 
                            currentUser.userMetadata?['name'] ?? 
                            currentUser.email?.split('@')[0] ?? 'Unknown User',
                'email': currentUser.email ?? 'Unknown',
                'created_at': DateTime.now().toIso8601String(),
              };
            } else {
              return {
                'user_id': userId,
                'full_name': 'User ${userId.substring(0, 8)}...',
                'email': 'user-${userId.substring(0, 8)}@unknown.com',
                'created_at': DateTime.now().toIso8601String(),
              };
            }
          }).toList();
          
        } catch (e) {
          print('RoleService: Could not find users from activity tables: $e');
          
          // Final fallback: just show current user
          final currentUser = _client.auth.currentUser;
          if (currentUser != null) {
            allUsers = [{
              'user_id': currentUser.id,
              'full_name': currentUser.userMetadata?['full_name'] ?? 
                          currentUser.userMetadata?['name'] ?? 
                          currentUser.email?.split('@')[0] ?? 'Unknown User',
              'email': currentUser.email ?? 'Unknown',
              'created_at': DateTime.now().toIso8601String(),
            }];
          }
        }
      }
      
      if (allUsers.isEmpty) {
        print('RoleService: No users found');
        return [];
      }
      
      // Now get all user roles
      final rolesResponse = await _client
          .from('user_roles')
          .select('user_id, role, granted_at');

      final roles = List<Map<String, dynamic>>.from(rolesResponse);
      print('RoleService: Found ${roles.length} role assignments');

      // Combine user data with role data
      final usersWithRoles = <Map<String, dynamic>>[];
      
      for (final user in allUsers) {
        final userId = user['user_id'] as String;
        
        // Get user roles for this user
        final userRoles = roles.where((role) => role['user_id'] == userId).toList();
        final latestRole = userRoles.isNotEmpty 
            ? userRoles.reduce((a, b) => 
                DateTime.parse(a['granted_at']).isAfter(DateTime.parse(b['granted_at'])) ? a : b)
            : null;

        usersWithRoles.add({
          'id': userId,
          'email': user['email'] ?? 'Unknown',
          'full_name': user['full_name'] ?? 'Unknown User',
          'role': latestRole?['role'] ?? 'user',
          'role_granted_at': latestRole?['granted_at'],
          'created_at': user['created_at'],
        });
      }

      print('RoleService: Returning ${usersWithRoles.length} users with roles');
      return usersWithRoles;
      
    } catch (e) {
      print('RoleService: Error fetching users with roles: $e');
      
      // Fallback: at least show current user
      final currentUser = _client.auth.currentUser;
      if (currentUser != null) {
        final currentRole = await getCurrentUserRole();
        return [{
          'id': currentUser.id,
          'email': currentUser.email ?? 'Unknown',
          'full_name': currentUser.userMetadata?['full_name'] ?? 
                      currentUser.userMetadata?['name'] ?? 
                      currentUser.email?.split('@')[0] ?? 'Unknown User',
          'role': currentRole.value,
          'role_granted_at': DateTime.now().toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        }];
      }
      
      return [];
    }
  }

  // Create user profile entry (call this after user registration)
  Future<bool> createUserProfile(String userId, String email, String fullName) async {
    try {
      await _client
          .from('user_profiles')
          .insert({
            'user_id': userId,
            'email': email,
            'full_name': fullName,
            'created_at': DateTime.now().toIso8601String(),
          });
      return true;
    } catch (e) {
      print('RoleService: Error creating user profile: $e');
      // Don't fail if user_profiles table doesn't exist
      return true;
    }
  }

  // Check specific permissions based on role
  bool hasPermission(UserRole userRole, String permission) {
    switch (permission) {
      case 'moderate_content':
        return userRole == UserRole.mediator || userRole == UserRole.host;
      case 'delete_any_post':
        return userRole == UserRole.host;
      case 'mute_users':
        return userRole == UserRole.mediator || userRole == UserRole.host;
      case 'assign_roles':
        return userRole == UserRole.host;
      case 'pin_posts':
        return userRole == UserRole.mediator || userRole == UserRole.host;
      case 'lock_posts':
        return userRole == UserRole.mediator || userRole == UserRole.host;
      default:
        return false;
    }
  }
}
