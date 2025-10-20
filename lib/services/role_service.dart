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

  // Check if current user can assign roles (hosts and mediators can assign roles)
  Future<bool> canAssignRoles() async {
    final currentRole = await getCurrentUserRole();
    return currentRole == UserRole.host || currentRole == UserRole.mediator;
  }

  // Assign role to a user (hosts and mediators can do this)
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
      print('RoleService: Starting getAllUsersWithRoles (profiles + roles only)...');
      
      final currentUser = _client.auth.currentUser;
      final currentUserRole = await getCurrentUserRole();
      
      // Fetch all visible profiles (RLS should allow host/mediator to see all)
      final profilesResponse = await _client
          .from('user_profiles')
          .select('user_id, full_name, email, created_at');
      
      final allUsers = List<Map<String, dynamic>>.from(profilesResponse).map((profile) => {
        'id': profile['user_id'] as String,
        'email': profile['email'] ?? 'Unknown',
        'full_name': profile['full_name'] ?? 'Unknown User',
        'created_at': profile['created_at'],
        'email_confirmed': true,
        'last_sign_in': null,
        'is_deleted': false,
        'deleted_at': null,
      }).toList();
      
      print('RoleService: Loaded ${allUsers.length} users from user_profiles');
      
      // Ensure current user appears at least once
      if (currentUser != null && !allUsers.any((u) => u['id'] == currentUser.id)) {
        allUsers.insert(0, {
          'id': currentUser.id,
          'email': currentUser.email ?? 'Unknown',
          'full_name': currentUser.userMetadata?['full_name'] ?? 
                      currentUser.userMetadata?['name'] ?? 
                      currentUser.email?.split('@')[0] ?? 'Unknown User',
          'created_at': currentUser.createdAt,
          'email_confirmed': currentUser.emailConfirmedAt != null,
          'last_sign_in': currentUser.lastSignInAt,
          'is_deleted': false,
          'deleted_at': null,
        });
      }
      
      // Fetch roles once and map latest per user
      List<Map<String, dynamic>> roles = [];
      try {
        final rolesResponse = await _client
            .from('user_roles')
            .select('user_id, role, granted_at');
        roles = List<Map<String, dynamic>>.from(rolesResponse);
        print('RoleService: Loaded ${roles.length} role rows');
      } catch (e) {
        print('RoleService: Could not read user_roles: $e');
      }
      
      final usersWithRoles = <Map<String, dynamic>>[];
      for (final user in allUsers) {
        final userId = user['id'] as String;
        final userRoles = roles.where((r) => r['user_id'] == userId).toList();
        final latestRole = userRoles.isNotEmpty
            ? userRoles.reduce((a, b) =>
                DateTime.parse(a['granted_at']).isAfter(DateTime.parse(b['granted_at'])) ? a : b)
            : null;
        
        String roleValue = latestRole?['role'] ?? 'user';
        if (currentUser != null && userId == currentUser.id) {
          roleValue = currentUserRole.value;
        }
        
        usersWithRoles.add({
          'id': userId,
          'email': user['email'],
          'full_name': user['full_name'],
          'role': roleValue,
          'role_granted_at': latestRole?['granted_at'],
          'created_at': user['created_at'],
          'email_confirmed': user['email_confirmed'],
          'last_sign_in': user['last_sign_in'],
          'is_deleted': user['is_deleted'],
          'deleted_at': user['deleted_at'],
        });
      }
      
      usersWithRoles.sort((a, b) {
        final aCreated = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime(1970);
        final bCreated = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime(1970);
        return bCreated.compareTo(aCreated);
      });
      
      print('RoleService: Returning ${usersWithRoles.length} users');
      return usersWithRoles;
    } catch (e) {
      print('RoleService: getAllUsersWithRoles failed: $e');
      final currentUser = _client.auth.currentUser;
      if (currentUser != null) {
        final currentUserRole = await getCurrentUserRole();
        return [{
          'id': currentUser.id,
          'email': currentUser.email ?? 'Unknown',
          'full_name': currentUser.userMetadata?['full_name'] ?? 
                      currentUser.userMetadata?['name'] ?? 
                      currentUser.email?.split('@')[0] ?? 'Unknown User',
          'role': currentUserRole.value,
          'role_granted_at': DateTime.now().toIso8601String(),
          'created_at': currentUser.createdAt,
          'email_confirmed': currentUser.emailConfirmedAt != null,
          'last_sign_in': currentUser.lastSignInAt,
          'is_deleted': false,
          'deleted_at': null,
        }];
      }
      return [];
    }
  }

  // Create user profile entry (call this after user registration)
  Future<bool> createUserProfile(String userId, String email, String fullName) async {
    try {
      // Check if profile already exists
      final existingProfile = await _client
          .from('user_profiles')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();
      
      if (existingProfile != null) {
        print('RoleService: User profile already exists for $userId');
        return true;
      }
      
      await _client
          .from('user_profiles')
          .insert({
            'user_id': userId,
            'email': email,
            'full_name': fullName,
            'created_at': DateTime.now().toIso8601String(),
          });
      print('RoleService: User profile created successfully for $userId');
      return true;
    } catch (e) {
      print('RoleService: Error creating user profile: $e');
      // Don't fail if user_profiles table doesn't exist
      return true;
    }
  }

  // Create profiles for existing users who don't have them
  Future<void> createMissingUserProfiles() async {
    try {
      print('RoleService: Creating missing user profiles...');
      
      // Get current user first
      final currentUser = _client.auth.currentUser;
      if (currentUser != null) {
        try {
          // Check if current user profile exists
          final existingProfile = await _client
              .from('user_profiles')
              .select('user_id')
              .eq('user_id', currentUser.id)
              .maybeSingle();
          
          if (existingProfile == null) {
            print('RoleService: Creating profile for current user: ${currentUser.email}');
            // Create missing profile
            final fullName = currentUser.userMetadata?['full_name'] ?? 
                           currentUser.userMetadata?['name'] ?? 
                           currentUser.email?.split('@')[0] ?? 'Unknown User';
            
            await createUserProfile(
              currentUser.id, 
              currentUser.email ?? 'unknown@example.com', 
              fullName
            );
          }
          
          // Also ensure user has a default role if none exists
          final existingRole = await _client
              .from('user_roles')
              .select('user_id')
              .eq('user_id', currentUser.id)
              .maybeSingle();
              
          if (existingRole == null) {
            print('RoleService: Creating default role for current user');
            await _client
                .from('user_roles')
                .insert({
                  'user_id': currentUser.id,
                  'role': 'user',
                  'granted_by': currentUser.id, // Self-granted default role
                  'granted_at': DateTime.now().toIso8601String(),
                });
          }
        } catch (e) {
          print('RoleService: Error creating profile for current user: $e');
        }
      }
      
      // Try to get all authenticated users and create profiles for them
      try {
        print('RoleService: Attempting to create profiles for all users...');
        
        // First, try to get users from auth.users table
        List<Map<String, dynamic>> authUsers = [];
        try {
          final authUsersResponse = await _client
              .from('auth.users')
              .select('id, email, created_at, user_metadata')
              .limit(100);
          
          authUsers = List<Map<String, dynamic>>.from(authUsersResponse);
          print('RoleService: Found ${authUsers.length} auth users to process');
        } catch (authError) {
          print('RoleService: Could not fetch auth users: $authError');
        }
        
        // If we couldn't get auth users, try to get them from admin API
        if (authUsers.isEmpty) {
          try {
            final adminUsers = await _client.auth.admin.listUsers();
            print('RoleService: Found ${adminUsers.length} users via admin API');
            
            for (final adminUser in adminUsers) {
              authUsers.add({
                'id': adminUser.id,
                'email': adminUser.email ?? 'unknown@example.com',
                'created_at': adminUser.createdAt,
                'user_metadata': adminUser.userMetadata,
              });
            }
          } catch (adminError) {
            print('RoleService: Could not fetch users via admin API: $adminError');
          }
        }
        
        // Process each user to ensure they have profiles and roles
        for (final authUser in authUsers) {
          try {
            final userId = authUser['id'] as String;
            final email = authUser['email'] as String;
            
            // Check if profile exists
            final existingProfile = await _client
                .from('user_profiles')
                .select('user_id')
                .eq('user_id', userId)
                .maybeSingle();
            
            if (existingProfile == null) {
              print('RoleService: Creating profile for user: $email');
              final fullName = authUser['user_metadata']?['full_name'] ?? 
                             authUser['user_metadata']?['name'] ?? 
                             email.split('@')[0];
              
              await createUserProfile(userId, email, fullName);
            }
            
            // Check if role exists
            final existingRole = await _client
                .from('user_roles')
                .select('user_id')
                .eq('user_id', userId)
                .maybeSingle();
                
            if (existingRole == null) {
              print('RoleService: Creating default role for user: $email');
              await _client
                  .from('user_roles')
                  .insert({
                    'user_id': userId,
                    'role': 'user',
                    'granted_by': userId, // Self-granted default role
                    'granted_at': DateTime.now().toIso8601String(),
                  });
            }
          } catch (e) {
            print('RoleService: Error processing user ${authUser['email']}: $e');
            // Continue processing other users if one fails
          }
        }
      } catch (e) {
        print('RoleService: Error in bulk profile creation: $e');
      }
    } catch (e) {
      print('RoleService: Error in createMissingUserProfiles: $e');
      // Silently fail - this is not critical for app functionality
    }
  }

  // Debug method to test user fetching
  Future<void> debugUserFetching() async {
    print('=== DEBUG USER FETCHING ===');
    
    try {
      // Test 1: Try admin API first (most comprehensive)
      print('Test 1: Admin API');
      final adminUsers = await _client.auth.admin.listUsers();
      print('Found ${adminUsers.length} users via admin API');
      for (final user in adminUsers) {
        print('  - ${user.email} (${user.id}) - Created: ${user.createdAt}');
      }
    } catch (e) {
      print('Admin API failed: $e');
    }
    
    try {
      // Test 2: Try auth.users table
      print('Test 2: auth.users table');
      final authUsers = await _client
          .from('auth.users')
          .select('id, email, created_at, email_confirmed_at, last_sign_in_at')
          .limit(20);
      print('Found ${authUsers.length} users in auth.users');
      for (final user in authUsers) {
        print('  - ${user['email']} (${user['id']}) - Created: ${user['created_at']}');
      }
    } catch (e) {
      print('auth.users table failed: $e');
    }
    
    try {
      // Test 3: Try profiles table
      print('Test 3: user_profiles table');
      final profiles = await _client
          .from('user_profiles')
          .select('user_id, email, full_name, created_at')
          .limit(20);
      print('Found ${profiles.length} profiles');
      for (final profile in profiles) {
        print('  - ${profile['email']} (${profile['user_id']}) - Created: ${profile['created_at']}');
      }
    } catch (e) {
      print('user_profiles table failed: $e');
    }
    
    try {
      // Test 4: Try forum_posts table (only for reference)
      print('Test 4: forum_posts table');
      final posts = await _client
          .from('forum_posts')
          .select('author_id, author_name, created_at')
          .limit(10);
      print('Found ${posts.length} forum posts');
      final uniqueUserIds = <String>{};
      for (final post in posts) {
        if (post['author_id'] != null) {
          uniqueUserIds.add(post['author_id'] as String);
        }
      }
      print('Found ${uniqueUserIds.length} unique user IDs from forum posts');
      for (final post in posts) {
        print('  - ${post['author_name']} (${post['author_id']}) - Created: ${post['created_at']}');
      }
    } catch (e) {
      print('forum_posts table failed: $e');
    }
    
    print('=== END DEBUG ===');
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
        return userRole == UserRole.mediator || userRole == UserRole.host;
      case 'pin_posts':
        return userRole == UserRole.mediator || userRole == UserRole.host;
      case 'lock_posts':
        return userRole == UserRole.mediator || userRole == UserRole.host;
      default:
        return false;
    }
  }
}
