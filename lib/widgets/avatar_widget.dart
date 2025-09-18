import 'package:flutter/material.dart';
import '../models/avatar_model.dart';

class AvatarWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
              child: _buildAvatarContent(),
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

  Widget _buildAvatarContent() {
    // Priority: Custom avatar URL > Preset avatar > Initials fallback
    if (customAvatarUrl != null && customAvatarUrl!.isNotEmpty) {
      return Image.network(
        customAvatarUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildInitialsAvatar();
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

    if (avatarId != null && avatarId!.isNotEmpty) {
      final avatar = AvatarData.getAvatarById(avatarId!);
      if (avatar != null) {
        return Image.asset(
          avatar.assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildInitialsAvatar();
          },
        );
      }
    }

    return _buildInitialsAvatar();
  }

  Widget _buildInitialsAvatar() {
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
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
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
      child: SizedBox(
        width: size,
        height: size + 30, // Extra space for name
        child: Column(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected 
                      ? Theme.of(context).primaryColor 
                      : Colors.grey.shade300,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
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
            const SizedBox(height: 8),
            Text(
              avatar.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
