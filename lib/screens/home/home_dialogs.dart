import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/role_provider.dart';
import '../../services/role_service.dart';
import '../../widgets/global_tts_overlay.dart';
import '../../widgets/tts_clickable_text.dart';

/// Home Dialogs - Handles dialog management for the home screen
class HomeDialogs {
  static Future<void> showAddKataDialog(BuildContext context, WidgetRef ref) async {
    final userRoleAsync = ref.read(currentUserRoleProvider);
    
    return userRoleAsync.when(
      data: (role) async {
        if (role != UserRole.host) {
          _showPermissionDeniedDialog(context);
          return;
        }
        
        await _showKataCreationDialog(context, ref);
      },
      loading: () async {
        _showLoadingDialog(context);
      },
      error: (error, _) async {
        _showErrorDialog(context, 'Fout bij ophalen gebruikersrol: $error');
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
            'Alleen hosts kunnen nieuwe kata\'s toevoegen. Neem contact op met een host om toegang te krijgen.',
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

  static Future<void> _showKataCreationDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DialogTTSOverlay(
        child: AlertDialog(
          title: const TTSClickableText('Nieuwe Kata Toevoegen'),
          content: const TTSClickableText(
            'Kies hoe je een nieuwe kata wilt toevoegen:',
          ),
          actions: [
            TTSClickableWidget(
              ttsText: 'Nieuwe Kata Maken knop',
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(true), // true = create new
                child: const Text('Nieuwe Kata Maken'),
              ),
            ),
            TTSClickableWidget(
              ttsText: 'Annuleren knop',
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false), // false = cancel
                child: const Text('Annuleren'),
              ),
            ),
          ],
        ),
      ),
    );

    if (result == true && context.mounted) {
      context.push('/create-kata');
    }
  }

  static Future<bool> showDeleteConfirmationDialog(
    BuildContext context,
    String kataName,
  ) async {
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
}
