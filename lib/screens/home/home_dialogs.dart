import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/role_provider.dart';
import '../../services/role_service.dart';

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
      builder: (context) => AlertDialog(
        title: const Text('Geen Toegang'),
        content: const Text(
          'Alleen hosts kunnen nieuwe kata\'s toevoegen. Neem contact op met een host om toegang te krijgen.',
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

  static Future<void> _showKataCreationDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nieuwe Kata Toevoegen'),
        content: const Text(
          'Kies hoe je een nieuwe kata wilt toevoegen:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // true = create new
            child: const Text('Nieuwe Kata Maken'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // false = cancel
            child: const Text('Annuleren'),
          ),
        ],
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
}
