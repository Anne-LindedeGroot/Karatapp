import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/avatar_model.dart';
import '../providers/avatar_provider.dart';
import '../services/avatar_service.dart';
import '../desktop/desktop_camera_screen.dart';
import '../desktop/desktop_avatar_utils.dart';
import 'avatar_widget.dart';

class AvatarUploadWidget extends ConsumerStatefulWidget {
  final double size;
  final bool showUploadButton;
  final VoidCallback? onAvatarChanged;

  const AvatarUploadWidget({
    super.key,
    this.size = 120,
    this.showUploadButton = true,
    this.onAvatarChanged,
  });

  @override
  ConsumerState<AvatarUploadWidget> createState() => _AvatarUploadWidgetState();
}

class _AvatarUploadWidgetState extends ConsumerState<AvatarUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool get _isDesktopPlatform =>
      DesktopAvatarUtils.isDesktopPlatform();

  @override
  Widget build(BuildContext context) {
    final userAvatarAsync = ref.watch(userAvatarProvider);

    return Column(
      children: [
        // Avatar Display
        Stack(
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: userAvatarAsync.when(
                  data: (userAvatar) => _buildAvatarContent(userAvatar),
                  loading: () => _buildLoadingAvatar(),
                  error: (error, stack) => _buildErrorAvatar(),
                ),
              ),
            ),
            
            // Upload/Edit Button
            if (widget.showUploadButton)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _isUploading ? null : _showAvatarOptions,
                  child: Container(
                    width: widget.size * 0.25,
                    height: widget.size * 0.25,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: _isUploading
                        ? Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: widget.size * 0.12,
                          ),
                  ),
                ),
              ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Avatar Info
        userAvatarAsync.when(
          data: (userAvatar) => _buildAvatarInfo(userAvatar),
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => Text(
            'Error loading avatar',
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarContent(UserAvatar? userAvatar) {
    if (userAvatar == null) {
      return _buildDefaultAvatar();
    }

    if (userAvatar.type == AvatarType.custom && userAvatar.customAvatarUrl != null) {
      return Image.network(
        userAvatar.customAvatarUrl!,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }

    if (userAvatar.presetAvatarId != null) {
      final avatar = AvatarData.getAvatarById(userAvatar.presetAvatarId!);
      if (avatar != null) {
        return Image.asset(
          avatar.assetPath,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
        );
      }
    }

    return _buildDefaultAvatar();
  }

  Widget _buildLoadingAvatar() {
    return Container(
      width: widget.size,
      height: widget.size,
      color: Colors.grey.shade200,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorAvatar() {
    return Container(
      width: widget.size,
      height: widget.size,
      color: Colors.grey.shade200,
      child: Icon(
        Icons.error,
        color: Colors.grey.shade400,
        size: widget.size * 0.4,
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: widget.size,
      height: widget.size,
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
      child: Icon(
        Icons.person,
        color: Colors.white,
        size: widget.size * 0.5,
      ),
    );
  }

  Widget _buildAvatarInfo(UserAvatar? userAvatar) {
    if (userAvatar == null) return const SizedBox.shrink();

    return Column(
      children: [
        Text(
          userAvatar.type == AvatarType.custom ? 'Custom Avatar' : 'Preset Avatar',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        if (userAvatar.lastUpdated != null)
          Text(
            'Updated ${_formatDate(userAvatar.lastUpdated!)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => AvatarOptionsBottomSheet(
        onCameraSelected: _pickImageFromCamera,
        onGallerySelected: _pickImageFromGallery,
        onPresetSelected: _showPresetAvatars,
        onDeleteSelected: _deleteCustomAvatar,
        hasCustomAvatar: ref.read(userAvatarProvider).value?.type == AvatarType.custom,
        isDesktopPlatform: _isDesktopPlatform,
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    Navigator.pop(context);
    if (_isDesktopPlatform) {
      final imageFile = await DesktopCameraScreen.capture(context);
      if (imageFile != null) {
        await _uploadImage(imageFile);
      }
      return;
    }
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image != null) {
      await _uploadImage(File(image.path));
    }
  }

  Future<void> _pickImageFromGallery() async {
    Navigator.pop(context);
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image != null) {
      await _uploadImage(File(image.path));
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    if (!AvatarService.isValidImageFile(imageFile)) {
      _showErrorSnackBar('Please select a valid image file (JPG, PNG, WebP)');
      return;
    }

    final fileSize = await imageFile.length();
    if (fileSize > AvatarService.maxFileSize) {
      _showErrorSnackBar('File size must be less than 5MB');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      await ref.read(userAvatarProvider.notifier).uploadCustomAvatar(imageFile);
      widget.onAvatarChanged?.call();
      _showSuccessSnackBar('Avatar uploaded successfully!');
    } catch (e) {
      _showErrorSnackBar('Failed to upload avatar: ${e.toString()}');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showPresetAvatars() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PresetAvatarSelectionScreen(
          onAvatarSelected: (avatarId) async {
            try {
              await ref.read(userAvatarProvider.notifier).setPresetAvatar(avatarId);
              widget.onAvatarChanged?.call();
              _showSuccessSnackBar('Avatar updated successfully!');
            } catch (e) {
              _showErrorSnackBar('Failed to update avatar: ${e.toString()}');
            }
          },
        ),
      ),
    );
  }

  Future<void> _deleteCustomAvatar() async {
    Navigator.pop(context);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Custom Avatar'),
        content: const Text('Are you sure you want to delete your custom avatar? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(userAvatarProvider.notifier).deleteCustomAvatar();
        widget.onAvatarChanged?.call();
        _showSuccessSnackBar('Custom avatar deleted successfully!');
      } catch (e) {
        _showErrorSnackBar('Failed to delete avatar: ${e.toString()}');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class AvatarOptionsBottomSheet extends StatelessWidget {
  final VoidCallback onCameraSelected;
  final VoidCallback onGallerySelected;
  final VoidCallback onPresetSelected;
  final VoidCallback onDeleteSelected;
  final bool hasCustomAvatar;
  final bool isDesktopPlatform;

  const AvatarOptionsBottomSheet({
    super.key,
    required this.onCameraSelected,
    required this.onGallerySelected,
    required this.onPresetSelected,
    required this.onDeleteSelected,
    required this.hasCustomAvatar,
    required this.isDesktopPlatform,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Change Avatar',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildOption(
            context,
            icon: Icons.camera_alt,
            title: 'Take Photo',
            subtitle: isDesktopPlatform
                ? 'Desktop gebruikt galerij om een foto te kiezen'
                : 'Use camera to take a new photo',
            onTap: onCameraSelected,
          ),
          _buildOption(
            context,
            icon: Icons.photo_library,
            title: 'Choose from Gallery',
            subtitle: 'Select an existing photo',
            onTap: onGallerySelected,
          ),
          _buildOption(
            context,
            icon: Icons.face,
            title: 'Choose Preset Avatar',
            subtitle: 'Select from available avatars',
            onTap: onPresetSelected,
          ),
          if (hasCustomAvatar)
            _buildOption(
              context,
              icon: Icons.delete,
              title: 'Delete Custom Avatar',
              subtitle: 'Remove your custom avatar',
              onTap: onDeleteSelected,
              isDestructive: true,
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Theme.of(context).colorScheme.error : Theme.of(context).primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Theme.of(context).colorScheme.error : null,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(subtitle),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class PresetAvatarSelectionScreen extends StatefulWidget {
  final Function(String) onAvatarSelected;

  const PresetAvatarSelectionScreen({
    super.key,
    required this.onAvatarSelected,
  });

  @override
  State<PresetAvatarSelectionScreen> createState() => _PresetAvatarSelectionScreenState();
}

class _PresetAvatarSelectionScreenState extends State<PresetAvatarSelectionScreen> {
  AvatarCategory selectedCategory = AvatarCategory.animals;
  String? selectedAvatarId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Avatar'),
        actions: [
          if (selectedAvatarId != null)
            TextButton(
              onPressed: () {
                widget.onAvatarSelected(selectedAvatarId!);
                Navigator.pop(context);
              },
              child: const Text('Select'),
            ),
        ],
      ),
      body: Column(
        children: [
          // Category Tabs
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: AvatarCategory.values.length,
              itemBuilder: (context, index) {
                final category = AvatarCategory.values[index];
                final isSelected = category == selectedCategory;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(AvatarData.getCategoryDisplayName(category)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          selectedCategory = category;
                          selectedAvatarId = null;
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
          
          // Avatar Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: AvatarData.getAvatarsByCategory(selectedCategory).length,
              itemBuilder: (context, index) {
                final avatar = AvatarData.getAvatarsByCategory(selectedCategory)[index];
                final isSelected = avatar.id == selectedAvatarId;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedAvatarId = avatar.id;
                    });
                  },
                  child: AvatarPreview(
                    avatar: avatar,
                    isSelected: isSelected,
                    size: 80,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
