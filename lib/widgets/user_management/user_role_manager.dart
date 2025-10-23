import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/role_service.dart';
import '../../widgets/tts_clickable_text.dart';
import '../../widgets/global_tts_overlay.dart';

class UserRoleManager extends ConsumerWidget {
  final String userId;
  final String userName;
  final UserRole currentRole;

  const UserRoleManager({
    super.key,
    required this.userId,
    required this.userName,
    required this.currentRole,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    getRoleIcon(role),
                    size: 18,
                    color: isCurrentRole ? Colors.grey : getRoleColor(role),
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
        _changeUserRole(context, ref, newRole);
      },
    );
  }

  Future<void> _changeUserRole(BuildContext context, WidgetRef ref, UserRole newRole) async {
    final roleService = RoleService();

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
                  backgroundColor: getRoleColor(newRole),
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
        if (context.mounted) {
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

        final success = await roleService.assignRole(userId, newRole);

        if (context.mounted) {
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
        if (context.mounted) {
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

  static Color getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.host:
        return Colors.purple;
      case UserRole.mediator:
        return Colors.orange;
      case UserRole.user:
        return Colors.blue;
    }
  }

  static IconData getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.host:
        return Icons.admin_panel_settings;
      case UserRole.mediator:
        return Icons.gavel;
      case UserRole.user:
        return Icons.person;
    }
  }

  static Widget buildRoleChip(UserRole role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: getRoleColor(role).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: getRoleColor(role).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(getRoleIcon(role), size: 16, color: getRoleColor(role)),
          const SizedBox(width: 6),
          Text(
            role.displayName,
            style: TextStyle(
              color: getRoleColor(role),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
