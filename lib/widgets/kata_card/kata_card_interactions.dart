import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/kata_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/role_provider.dart';
import '../../providers/accessibility_provider.dart';
import '../../services/role_service.dart';
import '../../screens/edit_kata_screen.dart';
import '../../utils/responsive_utils.dart';
import '../../core/theme/app_theme.dart';
import '../global_tts_overlay.dart';
import '../tts_clickable_text.dart';

/// Kata Card Interactions - Handles interaction logic for kata cards
class KataCardInteractions {
  static Future<void> speakKataContent(WidgetRef ref, Kata kata) async {
    try {
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      
      // Build comprehensive content for TTS
      final content = StringBuffer();
      content.write('Kata: ${kata.name}. ');
      
      if (kata.style.isNotEmpty && kata.style != 'Unknown') {
        content.write('Stijl: ${kata.style}. ');
      }
      
      if (kata.description.isNotEmpty) {
        content.write('Beschrijving: ${kata.description}. ');
      }
      
      if (kata.imageUrls?.isNotEmpty == true) {
        content.write('Deze kata heeft ${kata.imageUrls?.length} afbeeldingen. ');
      }
      
      if (kata.videoUrls?.isNotEmpty == true) {
        content.write('Deze kata heeft ${kata.videoUrls?.length} video\'s. ');
      }
      
      await accessibilityNotifier.speak(content.toString());
    } catch (e) {
      debugPrint('Error speaking kata content: $e');
    }
  }

  static Future<void> handleEditKata(BuildContext context, WidgetRef ref, Kata kata) async {
    final currentUser = ref.read(authUserProvider);
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
    final currentUser = ref.read(authUserProvider);
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
      builder: (context) => DialogTTSOverlay(
        child: AlertDialog(
          title: const TTSClickableText('Geen Toegang'),
          content: const TTSClickableText(
            'Je hebt geen toestemming om deze kata te bewerken of verwijderen.',
          ),
          actions: [
            TTSClickableWidget(
              ttsText: 'OK knop',
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DialogTTSOverlay(
        child: const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              TTSClickableText('Laden...'),
            ],
          ),
        ),
      ),
    );
  }

  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => DialogTTSOverlay(
        child: AlertDialog(
          title: const TTSClickableText('Fout'),
          content: TTSClickableText(message),
          actions: [
            TTSClickableWidget(
              ttsText: 'OK knop',
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Future<bool> _showDeleteConfirmationDialog(BuildContext context, String kataName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DialogTTSOverlay(
        child: AlertDialog(
          title: const TTSClickableText('Kata Verwijderen'),
          content: TTSClickableText(
            'Weet je zeker dat je "$kataName" wilt verwijderen? Deze actie kan niet ongedaan worden gemaakt.',
          ),
          actions: [
            TTSClickableWidget(
              ttsText: 'Annuleren knop',
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuleren'),
              ),
            ),
            TTSClickableWidget(
              ttsText: 'Verwijderen knop',
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Verwijderen'),
              ),
            ),
          ],
        ),
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
}
