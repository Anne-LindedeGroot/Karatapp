import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/role_provider.dart';
import '../../providers/accessibility_provider.dart';
import '../../services/user_management_service.dart';
import '../../services/role_service.dart';
import 'user_role_manager.dart';
import 'user_mute_manager.dart';

class UserListItem extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  final int index;

  const UserListItem({
    super.key,
    required this.user,
    required this.index,
  });

  @override
  ConsumerState<UserListItem> createState() => _UserListItemState();
}

class _UserListItemState extends ConsumerState<UserListItem> {
  final UserManagementService _userManagementService = UserManagementService();

  @override
  Widget build(BuildContext context) {
    final userId = widget.user['id'] as String;
    final userName = widget.user['full_name'] as String? ?? widget.user['email']?.split('@')[0] ?? 'Onbekende Gebruiker';
    final userEmail = widget.user['email'] as String? ?? '';
    final userRole = UserRole.values.firstWhere(
      (role) => role.value == widget.user['role'],
      orElse: () => UserRole.user,
    );
    final isDeleted = widget.user['is_deleted'] as bool? ?? false;
    final deletedAt = widget.user['deleted_at'];
    final lastSignIn = widget.user['last_sign_in'];
    final emailConfirmed = widget.user['email_confirmed'] as bool? ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDeleted
          ? Colors.grey.withValues(alpha: 0.1)
          : null,
      child: InkWell(
        onTap: () => _speakUserContent(),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: isDeleted
                    ? Colors.grey
                    : UserRoleManager.getRoleColor(userRole),
                child: Icon(
                  isDeleted
                      ? Icons.person_off
                      : UserRoleManager.getRoleIcon(userRole),
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
                  _userManagementService.getWrappedEmail(userEmail),
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
                  UserRoleManager.buildRoleChip(userRole),
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
                                  UserRoleManager(
                                    userId: userId,
                                    userName: userName,
                                    currentRole: userRole,
                                  ),
                                if (currentUserRole == UserRole.host)
                                  const SizedBox(width: 8),
                                // Hosts and mediators can mute users
                                if (currentUserRole == UserRole.host || currentUserRole == UserRole.mediator)
                                  UserMuteManager(
                                    userId: userId,
                                    userName: userName,
                                  ),
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
                  'Verwijderd op: ${_userManagementService.formatDate(deletedAt)}',
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
                  'Laatste login: ${_userManagementService.formatDate(lastSignIn)}',
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
  }

  Future<void> _speakUserContent() async {
    try {
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);

      final userName = widget.user['full_name'] as String? ?? widget.user['email']?.split('@')[0] ?? 'Onbekende Gebruiker';
      final userEmail = widget.user['email'] as String? ?? '';
      final userRole = UserRole.values.firstWhere(
        (role) => role.value == widget.user['role'],
        orElse: () => UserRole.user,
      );
      final isDeleted = widget.user['is_deleted'] as bool? ?? false;

      // Build comprehensive content for TTS
      final content = StringBuffer();
      content.write('User ${widget.index}: $userName. ');

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
}
