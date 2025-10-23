import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/kata_model.dart';
import '../../providers/role_provider.dart';
import '../../providers/accessibility_provider.dart';
import '../../services/role_service.dart';
import '../../screens/edit_kata_screen.dart';
import '../../utils/responsive_utils.dart';
import '../../core/theme/app_theme.dart';

/// Kata Card Interactions - Handles interaction logic for kata cards
class KataCardInteractions {
  static Future<void> speakKataContent(WidgetRef ref, Kata kata) async {
    try {
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      final skipGeneralInfo = ref.read(skipGeneralInfoInTTSProvider);
      
      // Build content for TTS based on settings
      final content = StringBuffer();
      
      // Always include kata name
      content.write('Kata: ${kata.name}. ');
      
      // Always include style (this is important kata information)
      if (kata.style.isNotEmpty && kata.style != 'Unknown') {
        content.write('Stijl: ${kata.style}. ');
      }
      
      // Include description only if not skipping general info
      if (!skipGeneralInfo && kata.description.isNotEmpty) {
        content.write('Beschrijving: ${kata.description}. ');
      }
      
      // Always include detailed media information (this is specific content, not general info)
      if (kata.imageUrls?.isNotEmpty == true) {
        final imageCount = kata.imageUrls!.length;
        content.write('Deze kata heeft $imageCount afbeeldingen van karate technieken en demonstraties. ');
        
        // Add specific image descriptions for first few images
        for (int i = 0; i < imageCount && i < 3; i++) {
          final imageUrl = kata.imageUrls![i];
          final imageType = _getImageTypeFromUrl(imageUrl);
          content.write('Afbeelding ${i + 1}: $imageType. ');
        }
        
        if (imageCount > 3) {
          content.write('En ${imageCount - 3} meer afbeeldingen beschikbaar. ');
        }
      }
      
      if (kata.videoUrls?.isNotEmpty == true) {
        final videoCount = kata.videoUrls!.length;
        content.write('Deze kata heeft $videoCount video\'s van karate demonstraties en instructies. ');
        
        // Add specific video descriptions for first few videos
        for (int i = 0; i < videoCount && i < 2; i++) {
          final videoUrl = kata.videoUrls![i];
          final videoDescription = _getVideoDescriptionFromUrl(videoUrl);
          content.write('Video ${i + 1}: $videoDescription. ');
        }
        
        if (videoCount > 2) {
          content.write('En ${videoCount - 2} meer video\'s beschikbaar. ');
        }
      }
      
      await accessibilityNotifier.speak(content.toString());
    } catch (e) {
      debugPrint('Error speaking kata content: $e');
    }
  }

  static Future<void> handleEditKata(BuildContext context, WidgetRef ref, Kata kata) async {
    final userRoleAsync = ref.read(currentUserRoleProvider);
    
    await userRoleAsync.when(
      data: (role) async {
        if (role == UserRole.host) {
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditKataScreen(kata: kata),
              ),
            );
          }
        } else {
          _showPermissionDeniedDialog(context);
        }
      },
      loading: () {
        _showLoadingDialog(context);
      },
      error: (error, _) {
        _showErrorDialog(context, 'Fout bij ophalen gebruikersrol: $error');
      },
    );
  }

  static Future<bool> handleDeleteKata(BuildContext context, WidgetRef ref, Kata kata) async {
    final userRoleAsync = ref.read(currentUserRoleProvider);
    
    return await userRoleAsync.when(
      data: (role) async {
        if (role == UserRole.host) {
          return await _showDeleteConfirmationDialog(context, kata.name);
        } else {
          _showPermissionDeniedDialog(context);
          return false;
        }
      },
      loading: () async {
        _showLoadingDialog(context);
        return false;
      },
      error: (error, _) async {
        _showErrorDialog(context, 'Fout bij ophalen gebruikersrol: $error');
        return false;
      },
    );
  }

  static void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Geen Toegang'),
        content: const Text(
          'Je hebt geen toestemming om deze kata te bewerken of verwijderen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Laden...'),
          ],
        ),
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fout'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static Future<bool> _showDeleteConfirmationDialog(BuildContext context, String kataName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kata Verwijderen'),
        content: Text(
          'Weet je zeker dat je "$kataName" wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuleren'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  static Widget buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Semantics(
      label: tooltip,
      button: true,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: AppTheme.getResponsiveIconSize(context, baseSize: 20.0),
          color: color,
        ),
        tooltip: tooltip,
        style: IconButton.styleFrom(
          padding: EdgeInsets.all(context.responsiveSpacing(SpacingSize.xs)),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  /// Get image type description from URL
  static String _getImageTypeFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();
      
      if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
        return 'JPEG foto van karate techniek';
      } else if (path.endsWith('.png')) {
        return 'PNG afbeelding van karate beweging';
      } else if (path.endsWith('.gif')) {
        return 'GIF animatie van karate techniek';
      } else if (path.endsWith('.webp')) {
        return 'WebP afbeelding van karate demonstratie';
      } else if (path.endsWith('.svg')) {
        return 'SVG diagram van karate techniek';
      } else {
        return 'Afbeelding van karate techniek';
      }
    } catch (e) {
      return 'Afbeelding van karate techniek';
    }
  }

  /// Get video description from URL
  static String _getVideoDescriptionFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      
      // Check for streaming platforms
      if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
        return 'YouTube video van karate demonstratie';
      } else if (uri.host.contains('vimeo.com')) {
        return 'Vimeo video van karate instructie';
      } else if (uri.host.contains('dailymotion.com')) {
        return 'Dailymotion video van karate training';
      } else if (uri.host.contains('twitch.tv')) {
        return 'Twitch video van live karate stream';
      }
      
      // Check for direct video files
      final path = uri.path.toLowerCase();
      if (path.endsWith('.mp4')) {
        return 'MP4 video van karate demonstratie';
      } else if (path.endsWith('.webm')) {
        return 'WebM video van karate techniek';
      } else if (path.endsWith('.avi')) {
        return 'AVI video van karate beweging';
      } else if (path.endsWith('.mov')) {
        return 'MOV video van karate instructie';
      }
      
      return 'Video van karate demonstratie';
    } catch (e) {
      return 'Video van karate demonstratie';
    }
  }
}
