import 'package:flutter/material.dart';
import '../services/role_service.dart';

class UserManagementService {
  final RoleService _roleService = RoleService();

  /// Split name into two lines for better display
  String _wrapEmailForDisplay(String email) {
    try {
      final parts = email.split('@');
      if (parts.length != 2) return email;
      final local = parts[0];
      final domain = parts[1].replaceAll('.', '.\u200B');
      return '$local@\u200B$domain';
    } catch (_) {
      return email;
    }
  }

  /// Format date for display
  String formatDate(dynamic dateValue) {
    if (dateValue == null) return 'Onbekend';

    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue);
      } else if (dateValue is DateTime) {
        date = dateValue;
      } else {
        return 'Onbekend';
      }

      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Onbekend';
    }
  }

  /// Build split name widget for display
  Widget buildSplitName(String fullName) {
    // Special handling for "anne-linde de Groot" to split into two sentences
    if (fullName.toLowerCase().contains('anne-linde') && fullName.toLowerCase().contains('de groot')) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Anne-Linde',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            overflow: TextOverflow.visible,
            maxLines: null,
            softWrap: true,
          ),
          Text(
            'de Groot',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            overflow: TextOverflow.visible,
            maxLines: null,
            softWrap: true,
          ),
        ],
      );
    }

    // For other names, try to split at common patterns
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      // Split roughly in the middle
      final midPoint = (parts.length / 2).ceil();
      final firstPart = parts.take(midPoint).join(' ');
      final secondPart = parts.skip(midPoint).join(' ');

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            firstPart,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            overflow: TextOverflow.visible,
            maxLines: null,
            softWrap: true,
          ),
          Text(
            secondPart,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            overflow: TextOverflow.visible,
            maxLines: null,
            softWrap: true,
          ),
        ],
      );
    }

    // Fallback to single line for short names
    return Text(
      fullName,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      overflow: TextOverflow.visible,
      maxLines: null,
      softWrap: true,
    );
  }

  /// Load all users with their roles
  Future<List<Map<String, dynamic>>> loadUsers() async {
    print('UserManagementService: Creating missing user profiles...');
    await _roleService.createMissingUserProfiles();

    // Debug: Run debug method to see what's available
    print('UserManagementService: Running debug user fetching...');
    await _roleService.debugUserFetching();

    print('UserManagementService: Calling getAllUsersWithRoles...');
    final users = await _roleService.getAllUsersWithRoles();
    print('UserManagementService: Received ${users.length} users');

    // Log detailed user information
    for (final user in users) {
      print('UserManagementService: User: ${user['email']} (${user['role']}) - ID: ${user['id']} - Created: ${user['created_at']}');
    }

    // Log success
    print('UserManagementService: SUCCESS - Found ${users.length} users');

    return users;
  }

  /// Get wrapped email for display
  String getWrappedEmail(String email) {
    return _wrapEmailForDisplay(email);
  }
}
