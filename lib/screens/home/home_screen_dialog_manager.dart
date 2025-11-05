import 'package:flutter/material.dart';

/// Home Screen Dialog Manager - Handles all dialogs in the home screen
class HomeScreenDialogManager {
  /// Show logout confirmation dialog
  static Future<bool> showLogoutConfirmationDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uitloggen'),
        content: const Text(
          'Weet je zeker dat je uit wilt loggen?',
          semanticsLabel:
              'Bevestiging bericht: Weet je zeker dat je uit wilt loggen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              backgroundColor: Colors.lightGreenAccent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text(
              'Nee dankje makker!',
              semanticsLabel:
                  'Nee dankje makker! Knop om uitloggen te annuleren en in de app te blijven',
              textAlign: TextAlign.center,
              overflow: TextOverflow.visible,
              maxLines: 1,
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text(
              'Ja tuurlijk!',
              semanticsLabel:
                  'Ja tuurlijk! Knop om te bevestigen en uit te loggen van de applicatie',
              textAlign: TextAlign.center,
              overflow: TextOverflow.visible,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  /// Show delete kata confirmation dialog
  static Future<bool> showDeleteKataConfirmationDialog(BuildContext context, String kataName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text('$kataName verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );

    return confirmed ?? false;
  }

  /// Show add kata dialog
  static Future<void> showAddKataDialog(BuildContext context) async {
    // Implementation for add kata dialog
    // This would contain the logic for showing the add kata dialog
  }
}
