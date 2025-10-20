import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/role_service.dart';
import '../services/mute_service.dart';
import '../providers/role_provider.dart';
import '../providers/mute_provider.dart';
import '../providers/accessibility_provider.dart';
import '../widgets/connection_error_widget.dart';
import '../core/navigation/app_router.dart';
import '../widgets/global_tts_overlay.dart';
import '../widgets/tts_clickable_text.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String? _error;
  final RoleService _roleService = RoleService();

  // Insert zero-width break opportunities to allow wrapping after '@' and '.'
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

  @override
  void initState() {
    super.initState();
    print('UserManagementScreen: initState called');
    _loadUsers();
    // TTS announcement disabled - only speak when user clicks TTS button
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _announcePageLoad();
    // });
  }


  Future<void> _speakUserContent(Map<String, dynamic> user, int index) async {
    try {
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      
      final userName = user['full_name'] as String? ?? user['email']?.split('@')[0] ?? 'Onbekende Gebruiker';
      final userEmail = user['email'] as String? ?? '';
      final userRole = UserRole.values.firstWhere(
        (role) => role.name == user['role'],
        orElse: () => UserRole.user,
      );
      final isDeleted = user['is_deleted'] as bool? ?? false;
      
      // Build comprehensive content for TTS
      final content = StringBuffer();
      content.write('User $index: $userName. ');
      
      if (userEmail.isNotEmpty) {
        content.write('Email: $userEmail. ');
      }
      
      content.write('Role: ${userRole.displayName}. ');
      content.write('${userRole.description}. ');
      
      if (isDeleted) {
        content.write('This account has been deleted. ');
      }
      
      await accessibilityNotifier.speak(content.toString());
    } catch (e) {
      debugPrint('Error speaking user content: $e');
    }
  }

  String _formatDate(dynamic dateValue) {
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

  /// Split name into two lines for better display
  Widget _buildSplitName(String fullName) {
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

  Future<void> _loadUsers() async {
    print('UserManagementScreen: Loading users...');
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // First, ensure user profiles exist
      print('UserManagementScreen: Creating missing user profiles...');
      await _roleService.createMissingUserProfiles();
      
      // Debug: Run debug method to see what's available
      print('UserManagementScreen: Running debug user fetching...');
      await _roleService.debugUserFetching();
      
      print('UserManagementScreen: Calling getAllUsersWithRoles...');
      final users = await _roleService.getAllUsersWithRoles();
      print('UserManagementScreen: Received ${users.length} users');
      
      // Log detailed user information
      for (final user in users) {
        print('UserManagementScreen: User: ${user['email']} (${user['role']}) - ID: ${user['id']} - Created: ${user['created_at']}');
      }
      
      // Log success
      print('UserManagementScreen: SUCCESS - Found ${users.length} users');
      
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      print('UserManagementScreen: Error loading users: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }


  Future<void> _changeUserRole(
    String userId,
    String userName,
    UserRole newRole,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DialogTTSOverlay(
        child: AlertDialog(
          title: TTSClickableText('Rol Wijzigen voor $userName'),
          content: TTSClickableText(
            'Weet je zeker dat je $userName\'s rol wilt wijzigen naar ${newRole.displayName}?\n\n'
            '${newRole.description}',
          ),
          actions: [
            TTSClickableWidget(
              ttsText: 'Annuleren knop',
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuleren'),
              ),
            ),
            TTSClickableWidget(
              ttsText: 'Rol Wijzigen knop',
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getRoleColor(newRole),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Rol Wijzigen'),
              ),
            ),
          ],
        ),
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
                  Text('Gebruikersrol bijwerken...'),
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
                content: Text(
                  'Rol van $userName succesvol gewijzigd naar ${newRole.displayName}',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            // Reload users to reflect changes
            _loadUsers();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Kon rol van $userName niet wijzigen'),
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
              content: Text('Fout bij wijzigen rol: $e'),
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
          Icon(_getRoleIcon(role), size: 16, color: _getRoleColor(role)),
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
              tooltip: isMuted ? 'Gebruiker is gedempt' : 'Gebruiker dempen',
              itemBuilder: (context) {
                if (isMuted) {
                  return [
                    PopupMenuItem<String>(
                      value: 'unmute',
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Row(
                          children: [
                            const Icon(Icons.volume_up, color: Colors.green),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Gebruiker Ontdempen'),
                                  Text(
                                    'Gedempt tot: ${muteInfo.mutedUntil.day}/${muteInfo.mutedUntil.month}/${muteInfo.mutedUntil.year}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                    overflow: TextOverflow.visible,
                                  ),
                                  Text(
                                    'Tijd over: ${muteInfo.timeRemainingText}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                    overflow: TextOverflow.visible,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'view_history',
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: const Row(
                          children: [
                            Icon(Icons.history, color: Colors.blue),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Dempgeschiedenis Bekijken',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ];
                } else {
                  return [
                    PopupMenuItem<String>(
                      value: 'mute_1day',
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: const Row(
                          children: [
                            Icon(Icons.volume_off, color: Colors.orange),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Dempen voor 1 Dag',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'mute_3days',
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: const Row(
                          children: [
                            Icon(Icons.volume_off, color: Colors.orange),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Dempen voor 3 Dagen',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'mute_1week',
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: const Row(
                          children: [
                            Icon(Icons.volume_off, color: Colors.red),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Dempen voor 1 Week',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'mute_1month',
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: const Row(
                          children: [
                            Icon(Icons.volume_off, color: Colors.red),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Dempen voor 1 Maand',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'mute_3months',
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: const Row(
                          children: [
                            Icon(Icons.volume_off, color: Colors.red),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Dempen voor 3 Maanden',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'mute_6months',
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: const Row(
                          children: [
                            Icon(Icons.volume_off, color: Colors.red),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Dempen voor 6 Maanden',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'mute_1year',
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: const Row(
                          children: [
                            Icon(Icons.volume_off, color: Colors.red),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Dempen voor 1 Jaar',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'mute_custom',
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: const Row(
                          children: [
                            Icon(Icons.schedule, color: Colors.purple),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Aangepaste Duur',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'view_history',
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: const Row(
                          children: [
                            Icon(Icons.history, color: Colors.blue),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Dempgeschiedenis Bekijken',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
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
          loading: () =>
              const Icon(Icons.hourglass_empty, size: 20, color: Colors.grey),
          error: (error, stackTrace) =>
              const Icon(Icons.error, size: 20, color: Colors.red),
        );
      },
    );
  }

  // Delete functionality removed per requirements

  Future<void> _handleMuteAction(
    String action,
    String userId,
    String userName,
  ) async {
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

  Future<void> _muteUser(
    String userId,
    String userName,
    MuteDuration duration,
  ) async {
    final reason = await _showReasonDialog(
      '$userName Dempen',
      'Geef een reden op voor het dempen van deze gebruiker:',
    );
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
              content: Text(
                '$userName succesvol gedempt voor ${duration.displayName}',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
          // Refresh the user list to show updated mute status
          setState(() {});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kon $userName niet dempen'),
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
            content: Text('Fout bij dempen gebruiker: $e'),
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
      builder: (context) => DialogTTSOverlay(
        child: AlertDialog(
          title: TTSClickableText('$userName Ontdempen'),
          content: TTSClickableText('Weet je zeker dat je $userName wilt ontdempen?'),
          actions: [
            TTSClickableWidget(
              ttsText: 'Annuleren knop',
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuleren'),
              ),
            ),
            TTSClickableWidget(
              ttsText: 'Ontdempen knop',
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ontdempen'),
              ),
            ),
          ],
        ),
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
                content: Text('$userName succesvol ontdempt'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            // Refresh the user list to show updated mute status
            setState(() {});
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Kon $userName niet ontdempen'),
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
              content: Text('Fout bij ontdempen gebruiker: $e'),
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
                hintText: 'Voer reden in...',
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
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Bevestigen'),
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
        title: Text('Aangepaste Duur voor $userName'),
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
            child: const Text('Annuleren'),
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

    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Dempgeschiedenis voor $userName'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: history.isEmpty
              ? const Center(child: Text('Geen dempgeschiedenis'))
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
                            Text(
                              'Gedempt: ${mute.mutedAt.day}/${mute.mutedAt.month}/${mute.mutedAt.year}',
                            ),
                            Text(
                              'Tot: ${mute.mutedUntil.day}/${mute.mutedUntil.month}/${mute.mutedUntil.year}',
                            ),
                            if (!mute.isActive && mute.unmutedAt != null)
                              Text(
                                'Ontdempt: ${mute.unmutedAt!.day}/${mute.unmutedAt!.month}/${mute.unmutedAt!.year}',
                              ),
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
            child: const Text('Sluiten'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector(
    String userId,
    String userName,
    UserRole currentRole,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDarkMode
        ? Colors.blue.shade300 // Lighter blue for dark mode
        : Theme.of(context).primaryColor; // Original color for light mode

    return PopupMenuButton<UserRole>(
      icon: Icon(Icons.edit, color: iconColor, size: 20),
      tooltip: 'Rol Wijzigen',
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
      itemBuilder: (context) {
        return UserRole.values.map((role) {
          final isCurrentRole = role == currentRole;
          return PopupMenuItem<UserRole>(
            value: role,
            enabled: !isCurrentRole,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 300),
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
                            color: isCurrentRole
                                ? Colors.grey
                                : Colors.grey[600],
                          ),
                          maxLines: null,
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                      ],
                    ),
                  ),
                  if (isCurrentRole) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check, color: Colors.green, size: 16),
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
    print('UserManagementScreen: Current user role state: ${userRoleAsync.runtimeType}');

    return userRoleAsync.when(
      data: (userRole) {
        print('UserManagementScreen: Current user role: ${userRole.value}');
        if (userRole != UserRole.host && userRole != UserRole.mediator) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Toegang Geweigerd'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.goToHome(),
              ),
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Toegang Geweigerd',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Alleen hosts en moderators kunnen gebruikersbeheer openen.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Gebruikersbeheer'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.goToHome(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  print('UserManagementScreen: Manual refresh triggered');
                  _loadUsers();
                },
                tooltip: 'Gebruikers Verversen',
              ),
            ],
          ),
          body: Column(
            children: [
              // Connection error widget
              const ConnectionErrorWidget(),

              // Combined header with privacy warning
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
                    // Main header
                    Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Gebruikersrollenbeheer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Beheer gebruikersrollen en demp gebruikers. Hosts en moderators kunnen rollen wijzigen en gebruikers dempen. Alle gebruikers worden getoond, inclusief verwijderde accounts.',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.left,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      maxLines: null,
                    ),
                    
                    // Privacy warning section
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.privacy_tip,
                                color: Colors.orange.shade700,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Privacy Waarschuwing',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Deze pagina bevat gevoelige persoonlijke gegevens. Bij gebruik van spraakfunctie: '
                            'zet volume laag of gebruik koptelefoon/oordopjes, vooral in openbare ruimtes.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                            maxLines: null,
                          ),
                        ],
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
                                  'Fout bij Laden Gebruikers',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _error!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadUsers,
                                  child: const Text('Opnieuw Proberen'),
                                ),
                              ],
                            ),
                          )
                        : _users.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.people_outline,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Geen gebruikers gevonden',
                                      style: TextStyle(fontSize: 18, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Dit kan betekenen dat er nog geen gebruikers zijn geregistreerd,\nof dat er een probleem is met het ophalen van gebruikers.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        print('UserManagementScreen: Manual refresh triggered from empty state');
                                        _loadUsers();
                                      },
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Opnieuw proberen'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: _users.length,
                                shrinkWrap: false,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final user = _users[index];
                                  final userId = user['id'] as String;
                                  final userName = user['full_name'] as String? ?? user['email']?.split('@')[0] ?? 'Onbekende Gebruiker';
                                  final userEmail = user['email'] as String? ?? '';
                                  final userRole = UserRole.values.firstWhere(
                                    (role) => role.name == user['role'],
                                    orElse: () => UserRole.user,
                                  );
                                  final isDeleted = user['is_deleted'] as bool? ?? false;
                                  final deletedAt = user['deleted_at'];
                                  final lastSignIn = user['last_sign_in'];
                                  final emailConfirmed = user['email_confirmed'] as bool? ?? false;

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    color: isDeleted 
                                        ? Colors.grey.withValues(alpha: 0.1)
                                        : null,
                                    child: InkWell(
                                      onTap: () => _speakUserContent(user, index + 1),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(16),
                                        leading: Stack(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: isDeleted 
                                                  ? Colors.grey
                                                  : _getRoleColor(userRole),
                                              child: Icon(
                                                isDeleted 
                                                    ? Icons.person_off
                                                    : _getRoleIcon(userRole),
                                                color: Colors.white,
                                              ),
                                            ),
                                            if (isDeleted)
                                              Positioned(
                                                right: 0,
                                                bottom: 0,
                                                child: Container(
                                                  padding: const EdgeInsets.all(2),
                                                  decoration: const BoxDecoration(
                                                    color: Colors.red,
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.delete,
                                                    size: 12,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        title: Row(
                                          children: [
                                            Expanded(
                                              child: isDeleted 
                                                  ? Text(
                                                      userName,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 15,
                                                        color: Colors.grey[600],
                                                        decoration: TextDecoration.lineThrough,
                                                      ),
                                                      overflow: TextOverflow.visible,
                                                      maxLines: null,
                                                      softWrap: true,
                                                    )
                                                  : Text(
                                                      userName,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 15,
                                                      ),
                                                      overflow: TextOverflow.visible,
                                                      maxLines: null,
                                                      softWrap: true,
                                                    ),
                                            ),
                                            if (isDeleted)
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Colors.red.withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'VERWIJDERD',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (userEmail.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                _wrapEmailForDisplay(userEmail),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDeleted 
                                                      ? Colors.grey[500]
                                                      : Colors.grey,
                                                ),
                                                overflow: TextOverflow.visible,
                                                maxLines: null,
                                                softWrap: true,
                                              ),
                                            ],
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                _buildRoleChip(userRole),
                                                const SizedBox(width: 8),
                                                if (!emailConfirmed)
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(
                                                        color: Colors.orange.withValues(alpha: 0.3),
                                                      ),
                                                    ),
                                                    child: const Text(
                                                      'Niet Bevestigd',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.orange,
                                                      ),
                                                    ),
                                                  ),
                                                const Spacer(),
                                                if (!isDeleted)
                                                  Consumer(
                                                    builder: (context, ref, child) {
                                                      final currentUserRoleAsync = ref.watch(currentUserRoleProvider);
                                                      return currentUserRoleAsync.when(
                                                        data: (currentUserRole) => FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              // Only hosts can change roles
                                                              if (currentUserRole == UserRole.host)
                                                                _buildRoleSelector(
                                                                  userId,
                                                                  userName,
                                                                  userRole,
                                                                ),
                                                              if (currentUserRole == UserRole.host)
                                                                const SizedBox(width: 8),
                                                              // Hosts and mediators can mute users
                                                              if (currentUserRole == UserRole.host || currentUserRole == UserRole.mediator)
                                                                _buildMuteButton(userId, userName),
                                                            ],
                                                          ),
                                                        ),
                                                        loading: () => const SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child: CircularProgressIndicator(strokeWidth: 2),
                                                        ),
                                                        error: (_, __) => const Icon(
                                                          Icons.error,
                                                          color: Colors.red,
                                                          size: 20,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                              ],
                                            ),
                                            // actions are inline with the role chip; removed extra top-right block
                                            if (isDeleted && deletedAt != null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'Verwijderd op: ${_formatDate(deletedAt)}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.red,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                            if (lastSignIn != null && !isDeleted) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'Laatste login: ${_formatDate(lastSignIn)}',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        trailing: isDeleted 
                                            ? const Icon(
                                                Icons.block,
                                                color: Colors.grey,
                                                size: 20,
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Gebruikersbeheer'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.goToHome(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(
          title: const Text('Gebruikersbeheer'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.goToHome(),
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
                'Fout bij Laden Gebruikersrol',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.goToHome(),
                child: const Text('Terug naar Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
