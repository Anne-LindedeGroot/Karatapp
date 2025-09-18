import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../models/avatar_model.dart';
import '../widgets/avatar_widget.dart';
import '../providers/auth_provider.dart';
import '../utils/image_utils.dart';
import 'dart:io';

class AvatarSelectionScreen extends ConsumerStatefulWidget {
  const AvatarSelectionScreen({super.key});

  @override
  ConsumerState<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends ConsumerState<AvatarSelectionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedAvatarId;
  File? _selectedCustomImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    
    // Get current user's avatar
    final currentUser = ref.read(authUserProvider);
    _selectedAvatarId = currentUser?.userMetadata?['avatar_id']?.toString();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading || _isUploading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Avatar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: isLoading ? null : _saveAvatar,
            child: Text(
              'Save',
              style: TextStyle(
                color: isLoading ? Colors.grey : Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Custom'),
            Tab(text: 'Animals'),
            Tab(text: 'Karate Men'),
            Tab(text: 'Karate Women'),
            Tab(text: 'Martial Arts'),
            Tab(text: 'Dojo & Items'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCustomTab(),
          _buildCategoryTab(AvatarCategory.animals),
          _buildCategoryTab(AvatarCategory.karateMan),
          _buildCategoryTab(AvatarCategory.karateWoman),
          _buildCategoryTab(AvatarCategory.martialArtsCharacters),
          _buildCategoryTab(AvatarCategory.karateItems),
        ],
      ),
    );
  }

  Widget _buildCustomTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Upload Your Own Photo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (_selectedCustomImage != null)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                  width: 3,
                ),
              ),
              child: ClipOval(
                child: Image.file(
                  _selectedCustomImage!,
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 2,
                ),
                color: Colors.grey.shade100,
              ),
              child: Icon(
                Icons.add_a_photo,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _isUploading ? null : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ],
          ),
          if (_selectedCustomImage != null) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedCustomImage = null;
                  _selectedAvatarId = null;
                });
              },
              icon: const Icon(Icons.delete),
              label: const Text('Remove Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryTab(AvatarCategory category) {
    final avatars = AvatarData.getAvatarsByCategory(category);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AvatarData.getCategoryDisplayName(category),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: avatars.length,
              itemBuilder: (context, index) {
                final avatar = avatars[index];
                final isSelected = _selectedAvatarId == avatar.id && _selectedCustomImage == null;
                
                return AvatarPreview(
                  avatar: avatar,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedAvatarId = avatar.id;
                      _selectedCustomImage = null; // Clear custom image when selecting preset
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      File? imageFile;
      
      if (source == ImageSource.camera) {
        imageFile = await ImageUtils.captureImageWithCamera();
      } else {
        imageFile = await ImageUtils.pickImageFromGallery();
      }
      
      if (imageFile != null) {
        setState(() {
          _selectedCustomImage = imageFile;
          _selectedAvatarId = null; // Clear preset selection when picking custom image
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveAvatar() async {
    if (_selectedAvatarId == null && _selectedCustomImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an avatar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      if (_selectedCustomImage != null) {
        // Upload custom image
        final currentUser = ref.read(authUserProvider);
        if (currentUser != null) {
          final fileName = 'avatar_${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final avatarUrl = await ImageUtils.uploadImageToSupabase(
            _selectedCustomImage!,
            fileName,
            0, // Use 0 as a special folder for avatars
          );
          
          if (avatarUrl != null) {
            await ref.read(authNotifierProvider.notifier).updateUserAvatar(
              avatarUrl,
              AvatarType.custom,
            );
          } else {
            throw Exception('Failed to upload avatar image');
          }
        }
      } else if (_selectedAvatarId != null) {
        // Save preset avatar
        await ref.read(authNotifierProvider.notifier).updateUserAvatar(
          _selectedAvatarId!,
          AvatarType.preset,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating avatar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

}
