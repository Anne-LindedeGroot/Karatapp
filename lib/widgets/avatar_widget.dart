import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/avatar_model.dart';
import '../services/offline_media_cache_service.dart';
import '../providers/network_provider.dart';

class AvatarWidget extends ConsumerWidget {
  final String? avatarId;
  final String? customAvatarUrl;
  final String? userName;
  final double size;
  final VoidCallback? onTap;
  final bool showEditIcon;

  const AvatarWidget({
    super.key,
    this.avatarId,
    this.customAvatarUrl,
    this.userName,
    this.size = 60,
    this.onTap,
    this.showEditIcon = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: _buildAvatarContent(context, ref),
            ),
          ),
          if (showEditIcon)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: size * 0.3,
                height: size * 0.3,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: size * 0.15,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent(BuildContext context, WidgetRef ref) {
    // Priority: Custom avatar URL > Preset avatar > Initials fallback
    if (customAvatarUrl != null && customAvatarUrl!.isNotEmpty) {
      return FutureBuilder<String>(
        future: OfflineMediaCacheService.getMediaUrl(customAvatarUrl!, false, ref),
        builder: (context, snapshot) {
          final resolvedUrl = snapshot.data ?? customAvatarUrl!;
          final isLocalFile = resolvedUrl.startsWith('/') || resolvedUrl.startsWith('file://');

          if (isLocalFile) {
            return Image.file(
              File(resolvedUrl.replaceFirst('file://', '')),
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildInitialsAvatar(context);
              },
            );
          } else {
            // Check if we're offline - if so, don't try to load network image
            final networkState = ref.watch(networkProvider);
            if (networkState.isDisconnected) {
              return _buildInitialsAvatar(context);
            }

            return Image.network(
              resolvedUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildInitialsAvatar(context);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
            );
          }
        },
      );
    }

    if (avatarId != null && avatarId!.isNotEmpty) {
      final avatar = AvatarData.getAvatarById(avatarId!);
      if (avatar != null) {
        return Image.asset(
          avatar.assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildInitialsAvatar(context);
          },
        );
      }
    }

    return _buildInitialsAvatar(context);
  }

  Widget _buildInitialsAvatar(BuildContext context) {
    final initials = _getInitials(userName);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade300,
            Colors.purple.shade300,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(
            initials,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
              height: 1.0, // Ensure consistent line height
            ) ?? TextStyle(
              color: Colors.white,
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
              height: 1.0, // Ensure consistent line height
            ),
          ),
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) {
      return '?';
    }

    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'.toUpperCase();
    }
  }
}

class AvatarPreview extends StatelessWidget {
  final Avatar avatar;
  final bool isSelected;
  final VoidCallback? onTap;
  final double size;

  const AvatarPreview({
    super.key,
    required this.avatar,
    this.isSelected = false,
    this.onTap,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Colors.green
                          : Colors.grey.shade300,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.green.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      avatar.assetPath,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.image,
                          color: Colors.grey.shade400,
                          size: size * 0.4,
                        ),
                      ),
                    ),
                  ),
                ),
                // Green circle overlay for selected avatar
                if (isSelected)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: size * 0.3,
                      height: size * 0.3,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check,
                        color: Colors.white,
                        size: size * 0.15,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: size,
                maxWidth: size,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  avatar.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Colors.green
                        : Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
