import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/role_service.dart';
import '../services/mute_service.dart';
import '../providers/role_provider.dart';
import '../providers/mute_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/connection_error_widget.dart';
import '../widgets/tts_headphones_button.dart';
import '../services/context_aware_page_tts_service.dart';
import '../core/navigation/app_router.dart';

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

  Future<void> _changeUserRole(
    String userId,
    String userName,
    UserRole newRole,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Rol Wijzigen voor $userName'),
        content: Text(
          'Weet je zeker dat je $userName\'s rol wilt wijzigen naar ${newRole.displayName}?\n\n'
          '${newRole.description}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getRoleColor(newRole),
              foregroundColor: Colors.white,
            ),
            child: const Text('Rol Wijzigen'),
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
                      child: Row(
                        children: [
                          const Icon(Icons.volume_up, color: Colors.green),
                          const SizedBox(width: 12),
                          Column(
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
                              ),
                              Text(
                                'Tijd over: ${muteInfo.timeRemainingText}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
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
                          Text('Dempgeschiedenis Bekijken'),
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
                          Text('Dempen voor 1 Dag'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'mute_3days',
                      child: const Row(
                        children: [
                          Icon(Icons.volume_off, color: Colors.orange),
                          SizedBox(width: 12),
                          Text('Dempen voor 3 Dagen'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'mute_1week',
                      child: const Row(
                        children: [
                          Icon(Icons.volume_off, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Dempen voor 1 Week'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'mute_1month',
                      child: const Row(
                        children: [
                          Icon(Icons.volume_off, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Dempen voor 1 Maand'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'mute_3months',
                      child: const Row(
                        children: [
                          Icon(Icons.volume_off, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Dempen voor 3 Maanden'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'mute_6months',
                      child: const Row(
                        children: [
                          Icon(Icons.volume_off, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Dempen voor 6 Maanden'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'mute_1year',
                      child: const Row(
                        children: [
                          Icon(Icons.volume_off, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Dempen voor 1 Jaar'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'mute_custom',
                      child: const Row(
                        children: [
                          Icon(Icons.schedule, color: Colors.purple),
                          SizedBox(width: 12),
                          Text('Aangepaste Duur'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'view_history',
                      child: const Row(
                        children: [
                          Icon(Icons.history, color: Colors.blue),
                          SizedBox(width: 12),
                          Text('Dempgeschiedenis Bekijken'),
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
          loading: () =>
              const Icon(Icons.hourglass_empty, size: 20, color: Colors.grey),
          error: (error, stackTrace) =>
              const Icon(Icons.error, size: 20, color: Colors.red),
        );
      },
    );
  }

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
      builder: (context) => AlertDialog(
        title: Text('$userName Ontdempen'),
        content: Text('Weet je zeker dat je $userName wilt ontdempen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ontdempen'),
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
        title: Text('Aangepaste Dempingsduur voor $userName'),
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

    if (mounted) {
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
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
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
                            color: isCurrentRole
                                ? Colors.grey
                                : Colors.grey[600],
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
    final currentUser = ref.watch(authUserProvider);

    return userRoleAsync.when(
      data: (userRole) {
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
              AppBarTTSButton(
                customTestText: 'Spraak is nu ingeschakeld voor gebruikersbeheer',
                onToggle: () {
                  // Use the context-aware TTS service for user management
                  Future.delayed(const Duration(milliseconds: 500), () {
                    ContextAwarePageTTSService.readUserManagementScreen(context, ref);
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadUsers,
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
                    const Text(
                      'Beheer gebruikersrollen en demp gebruikers. Hosts kunnen rollen wijzigen, zowel hosts als moderators kunnen gebruikers dempen.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
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
                                  child: const Text('Opnieuw Proberen'),
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
                                      'Geen Gebruikers Gevonden',
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
                                    final email =
                                        user['email'] as String? ?? 'Geen email';
                                    final fullName =
                                        user['full_name'] as String? ?? 'Geen naam';
                                    final roleString =
                                        user['role'] as String? ?? 'user';
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
                                                            'Jij',
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
          title: const Text('Gebruikersbeheer'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Gebruikersbeheer'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Fout bij Laden Rol',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
