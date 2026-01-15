import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/tts_clickable_text.dart';
import '../../widgets/global_tts_overlay.dart';
import '../../providers/accessibility_provider.dart';

/// Home Screen Dialog Manager - Handles all dialogs in the home screen
class HomeScreenDialogManager {
  /// Show logout confirmation dialog
  static Future<bool> showLogoutConfirmationDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _LogoutDialog(),
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

class _LogoutDialog extends ConsumerStatefulWidget {
  const _LogoutDialog();

  @override
  ConsumerState<_LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends ConsumerState<_LogoutDialog> {
  bool _hasAutoRead = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_hasAutoRead) return;
    _hasAutoRead = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final accessibilityState = ref.read(accessibilityNotifierProvider);
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);

      if (!accessibilityState.isTextToSpeechEnabled) {
        return;
      }

      const textToRead =
          'Uitloggen. Weet je zeker dat je uit wilt loggen? '
          'Nee dankje makker! Knop om uitloggen te annuleren en in de app te blijven. '
          'Ja tuurlijk! Knop om te bevestigen en uit te loggen van de applicatie.';

      if (accessibilityNotifier.isSpeaking()) {
        await accessibilityNotifier.stopSpeaking();
        await Future.delayed(const Duration(milliseconds: 250));
      }

      await accessibilityNotifier.speak(textToRead);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DialogTTSOverlay(
      child: AlertDialog(
        title: TTSClickableWidget(
          ttsText: 'Uitloggen',
          child: const Text('Uitloggen'),
        ),
        content: TTSClickableWidget(
          ttsText: 'Weet je zeker dat je uit wilt loggen?',
          child: const Text(
            'Weet je zeker dat je uit wilt loggen?',
            semanticsLabel:
                'Bevestiging bericht: Weet je zeker dat je uit wilt loggen?',
          ),
        ),
        actions: [
          TTSClickableWidget(
            ttsText:
                'Nee dankje makker! Knop om uitloggen te annuleren en in de app te blijven',
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                backgroundColor: Colors.lightGreenAccent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text(
                'Nee dankje makker!',
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
                maxLines: 1,
              ),
            ),
          ),
          TTSClickableWidget(
            ttsText:
                'Ja tuurlijk! Knop om te bevestigen en uit te loggen van de applicatie',
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text(
                'Ja tuurlijk!',
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
                maxLines: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
