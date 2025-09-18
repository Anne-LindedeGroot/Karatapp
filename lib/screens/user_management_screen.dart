import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/role_service.dart';
import '../services/mute_service.dart';
import '../providers/role_provider.dart';
import '../providers/mute_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/connection_error_widget.dart';
import '../core/navigation/app_router.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;
  final RoleService _roleService = RoleService();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final users = await _roleService.getAllUsersWithRoles();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _changeUserRole(String userId, String userName, UserRole newRole) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Role for $userName'),
        content: Text(
          'Are you sure you want to change $userName\'s role to ${newRole.displayName}?\n\n'
          '${newRole.description}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getRoleColor(newRole),
              foregroundColor: Colors.white,
            ),
            child: const Text('Change Role'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Updating user role...'),
                ],
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }

        final success = await _roleService.assignRole(userId, newRole);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully changed $userName\'s role to ${newRole.displayName}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            // Reload users to reflect changes
            _loadUsers();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to change $userName\'s role'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error changing role: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.host:
        return Colors.purple;
      case UserRole.mediator:
        return Colors.orange;
      case UserRole.user:
        return Colors.blue;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.host:
        return Icons.admin_panel_settings;
      case UserRole.mediator:
        return Icons.gavel;
      case UserRole.user:
        return Icons.person;
    }
  }

  Widget _buildRoleChip(UserRole role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getRoleColor(role).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getRoleColor(role).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getRoleIcon(role),
            size: 16,
            color: _getRoleColor(role),
          ),
          const SizedBox(width: 6),
          Text(
            role.displayName,
            style: TextStyle(
              color: _getRoleColor(role),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuteButton(String userId, String userName) {
    return Consumer(
      builder: (context, ref, child) {
        final muteAsync = ref.watch(currentMuteProvider(userId));
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        
        return muteAsync.when(
          data: (muteInfo) {
            final isMuted = muteInfo != null && !muteInfo.isExpired;
            final muteIconColor = isMuted 
                ? Colors.red 
                : (isDarkMode ? Colors.grey[400] : Colors.grey[600]);
            
            return PopupMenuButton<String>(
              icon: Icon(
                isMuted ? Icons.volume_off : Icons.volume_up,
                color: muteIconColor,
                size: 20,
              ),
              tooltip: isMuted ? 'User is muted' : 'Mute user',
              itemBuilder: (context) {
                if (isMuted) {
                  return [
                    PopupMenuItem<String>(
                      value: 'unmute',
                      child: Row(
                        children: [
                          const Icon(Icons.volume_up, color: Colors.green),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Unmute User'),
                              Text(
                                'Muted until: ${muteInfo.mutedUntil.day}/${muteInfo.mutedUntil.month}/${muteInfo.mutedUntil.year}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              Text(
                                'Time left: ${muteInfo.timeRemainingText}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'view_history',
                      child: const Row(
                        children: [
                          Icon(Icons.history, color: Colors.blue),
                          SizedBox(width: 12),
                          Text('View Mute History'),
                        ],
                      ),
                    ),
                  ];
                } else {
                  return [
                    PopupMenuItem<String>(
                      value: 'mute_1day',
                      child: const Row(
                        children: [
                          Icon(Icons.volume_off, color: Colors.orange),
                          SizedBox(width: 12),
                          Text('Mute for 1 Day'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'mute_3days',
                      child: const Row(
                        children: [
                          Icon(Icons.volume_off, color: Colors.orange),
                          SizedBox(width: 12),
                          Text('Mute for 3 Days'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'mute_1week',
                      child: const Row(
                        children: [
                          Icon(Icons.volume_off, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Mute for 1 Week'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'mute_1month',
                      child: const Row(
                        children: [
                          Icon(Icons.volume_off, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Mute for 1 Month'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'mute_3months',
                      child: const Row(
                        children: [
                          Icon(Icons.volume_off, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Mute for 3 Months'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'mute_6months',
                      child: const Row(
                        children: [
                          Icon(Icons.volume_off, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Mute for 6 Months'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'mute_1year',
                      child: const Row(
                        children: [
                          Icon(Icons.volume_off, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Mute for 1 Year'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'mute_custom',
                      child: const Row(
                        children: [
                          Icon(Icons.schedule, color: Colors.purple),
                          SizedBox(width: 12),
                          Text('Custom Duration'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'view_history',
                      child: const Row(
                        children: [
                          Icon(Icons.history, color: Colors.blue),
                          SizedBox(width: 12),
                          Text('View Mute History'),
                        ],
                      ),
                    ),
                  ];
                }
              },
              onSelected: (String action) {
                _handleMuteAction(action, userId, userName);
              },
            );
          },
          loading: () => const Icon(Icons.hourglass_empty, size: 20, color: Colors.grey),
          error: (_, __) => const Icon(Icons.error, size: 20, color: Colors.red),
        );
      },
    );
  }

  Future<void> _handleMuteAction(String action, String userId, String userName) async {
    switch (action) {
      case 'unmute':
        await _unmuteUser(userId, userName);
        break;
      case 'mute_1day':
        await _muteUser(userId, userName, MuteDuration.oneDay);
        break;
      case 'mute_3days':
        await _muteUser(userId, userName, MuteDuration.threeDays);
        break;
      case 'mute_1week':
        await _muteUser(userId, userName, MuteDuration.oneWeek);
        break;
      case 'mute_1month':
        await _muteUser(userId, userName, MuteDuration.oneMonth);
        break;
      case 'mute_3months':
        await _muteUser(userId, userName, MuteDuration.threeMonths);
        break;
      case 'mute_6months':
        await _muteUser(userId, userName, MuteDuration.sixMonths);
        break;
      case 'mute_1year':
        await _muteUser(userId, userName, MuteDuration.oneYear);
        break;
      case 'mute_custom':
        await _showCustomMuteDialog(userId, userName);
        break;
      case 'view_history':
        await _showMuteHistory(userId, userName);
        break;
    }
  }

  Future<void> _muteUser(String userId, String userName, MuteDuration duration) async {
    final reason = await _showReasonDialog('Mute $userName', 'Please provide a reason for muting this user:');
    if (reason == null || reason.trim().isEmpty) return;

    try {
      final muteNotifier = ref.read(muteNotifierProvider.notifier);
      final success = await muteNotifier.muteUser(
        userId: userId,
        duration: duration,
        reason: reason.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully muted $userName for ${duration.displayName}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
          // Refresh the user list to show updated mute status
          setState(() {});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to mute $userName'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error muting user: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _unmuteUser(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unmute $userName'),
        content: Text('Are you sure you want to unmute $userName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Unmute'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final muteNotifier = ref.read(muteNotifierProvider.notifier);
        final success = await muteNotifier.unmuteUser(userId);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully unmuted $userName'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            // Refresh the user list to show updated mute status
            setState(() {});
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to unmute $userName'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error unmuting user: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<String?> _showReasonDialog(String title, String prompt) async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(prompt),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomMuteDialog(String userId, String userName) async {
    MuteDuration? selectedDuration;
    
    final duration = await showDialog<MuteDuration>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Custom Mute Duration for $userName'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400, // Fixed height to prevent overflow
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: MuteDuration.values.map((duration) {
                return ListTile(
                  title: Text(duration.displayName),
                  subtitle: Text(
                    duration.description,
                    style: const TextStyle(fontSize: 12),
                  ),
                  leading: Icon(
                    selectedDuration == duration 
                        ? Icons.radio_button_checked 
                        : Icons.radio_button_unchecked,
                    color: selectedDuration == duration 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey,
                  ),
                  onTap: () {
                    selectedDuration = duration;
                    Navigator.pop(context, duration);
                  },
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (duration != null) {
      await _muteUser(userId, userName, duration);
    }
  }

  Future<void> _showMuteHistory(String userId, String userName) async {
    final muteNotifier = ref.read(muteNotifierProvider.notifier);
    final history = await muteNotifier.getUserMuteHistory(userId);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Mute History for $userName'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: history.isEmpty
                ? const Center(child: Text('No mute history'))
                : ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final mute = history[index];
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            mute.isActive ? Icons.volume_off : Icons.volume_up,
                            color: mute.isActive ? Colors.red : Colors.green,
                          ),
                          title: Text(mute.reason),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Muted: ${mute.mutedAt.day}/${mute.mutedAt.month}/${mute.mutedAt.year}'),
                              Text('Until: ${mute.mutedUntil.day}/${mute.mutedUntil.month}/${mute.mutedUntil.year}'),
                              if (!mute.isActive && mute.unmutedAt != null)
                                Text('Unmuted: ${mute.unmutedAt!.day}/${mute.unmutedAt!.month}/${mute.unmutedAt!.year}'),
                            ],
                          ),
                          trailing: mute.isActive
                              ? Text(
                                  mute.timeRemainingText,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : const Icon(Icons.check, color: Colors.green),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildRoleSelector(String userId, String userName, UserRole currentRole) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDarkMode 
        ? Colors.blue.shade300  // Lighter blue for dark mode
        : Theme.of(context).primaryColor;  // Original color for light mode
    
    return PopupMenuButton<UserRole>(
      icon: Icon(
        Icons.edit,
        color: iconColor,
        size: 20,
      ),
      tooltip: 'Change Role',
      constraints: const BoxConstraints(
        minWidth: 200,
        maxWidth: 280,
      ),
      itemBuilder: (context) {
        return UserRole.values.map((role) {
          final isCurrentRole = role == currentRole;
          return PopupMenuItem<UserRole>(
            value: role,
            enabled: !isCurrentRole,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 260),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _getRoleIcon(role),
                    size: 18,
                    color: isCurrentRole ? Colors.grey : _getRoleColor(role),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          role.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isCurrentRole ? Colors.grey : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          role.description,
                          style: TextStyle(
                            fontSize: 11,
                            color: isCurrentRole ? Colors.grey : Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
                      ],
                    ),
                  ),
                  if (isCurrentRole) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.check,
                      color: Colors.green,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList();
      },
      onSelected: (UserRole newRole) {
        _changeUserRole(userId, userName, newRole);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if current user is host
    final userRoleAsync = ref.watch(currentUserRoleProvider);
    final currentUser = ref.watch(authUserProvider);

    return userRoleAsync.when(
      data: (userRole) {
        if (userRole != UserRole.host && userRole != UserRole.mediator) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Access Denied'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.goToHome(),
              ),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock,
                    size: 64,
                    color: Colors.red,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Access Denied',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Only hosts and mediators can access user management.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('User Management'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.goToHome(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadUsers,
                tooltip: 'Refresh Users',
              ),
            ],
          ),
          body: Column(
            children: [
              // Connection error widget
              const ConnectionErrorWidget(),
              
              // Header info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'User Role Management',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Manage user roles and mute users. Hosts can change roles, both hosts and mediators can mute users.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // Users list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Error Loading Users',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadUsers,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _users.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.people_outline,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No Users Found',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadUsers,
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _users.length,
                                  itemBuilder: (context, index) {
                                    final user = _users[index];
                                    final userId = user['id'] as String;
                                    final email = user['email'] as String? ?? 'No email';
                                    final fullName = user['full_name'] as String? ?? 'No name';
                                    final roleString = user['role'] as String? ?? 'user';
                                    final role = UserRole.values.firstWhere(
                                      (r) => r.value == roleString,
                                      orElse: () => UserRole.user,
                                    );
                                    final isCurrentUser = userId == currentUser?.id;

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      elevation: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            // User avatar
                                            CircleAvatar(
                                              radius: 24,
                                              backgroundColor: _getRoleColor(role).withValues(alpha: 0.2),
                                              child: Icon(
                                                Icons.person,
                                                color: _getRoleColor(role),
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            
                                            // User info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          fullName,
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w600,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                      ),
                                                      if (isCurrentUser)
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 2,
                                                          ),
                                                          decoration: BoxDecoration(
                                                            color: Colors.green.withValues(alpha: 0.1),
                                                            borderRadius: BorderRadius.circular(12),
                                                            border: Border.all(
                                                              color: Colors.green.withValues(alpha: 0.3),
                                                            ),
                                                          ),
                                                          child: const Text(
                                                            'You',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: Colors.green,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    email,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  _buildRoleChip(role),
                                                ],
                                              ),
                                            ),
                                            
                                            // Controls (only show for other users)
                                            if (!isCurrentUser) ...[
                                              _buildMuteButton(userId, fullName),
                                              // Only hosts can change roles
                                              if (userRole == UserRole.host) ...[
                                                const SizedBox(width: 8),
                                                _buildRoleSelector(userId, fullName, role),
                                              ],
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error Loading Role',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
