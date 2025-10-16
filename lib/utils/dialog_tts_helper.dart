import 'package:flutter/material.dart';
import '../widgets/global_tts_overlay.dart';
import '../widgets/tts_clickable_text.dart';

/// Helper class to easily create TTS-enabled dialogs
class DialogTTSHelper {
  /// Show a simple alert dialog with TTS support
  static Future<bool?> showAlertDialog({
    required BuildContext context,
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DialogTTSOverlay(
        child: AlertDialog(
          title: TTSClickableText(title),
          content: TTSClickableText(content),
          actions: [
            if (cancelText != null)
              TTSClickableWidget(
                ttsText: '$cancelText knop',
                child: TextButton(
                  onPressed: () {
                    onCancel?.call();
                    Navigator.of(context).pop(false);
                  },
                  child: Text(cancelText),
                ),
              ),
            if (confirmText != null)
              TTSClickableWidget(
                ttsText: '$confirmText knop',
                child: ElevatedButton(
                  onPressed: () {
                    onConfirm?.call();
                    Navigator.of(context).pop(true);
                  },
                  child: Text(confirmText),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Show a confirmation dialog with TTS support
  static Future<bool> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'Bevestigen',
    String cancelText = 'Annuleren',
    Color? confirmButtonColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => DialogTTSOverlay(
        child: AlertDialog(
          title: TTSClickableText(title),
          content: TTSClickableText(content),
          actions: [
            TTSClickableWidget(
              ttsText: '$cancelText knop',
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelText),
              ),
            ),
            TTSClickableWidget(
              ttsText: '$confirmText knop',
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: confirmButtonColor != null
                    ? ElevatedButton.styleFrom(
                        backgroundColor: confirmButtonColor,
                        foregroundColor: Colors.white,
                      )
                    : null,
                child: Text(confirmText),
              ),
            ),
          ],
        ),
      ),
    );
    return result ?? false;
  }

  /// Show an error dialog with TTS support
  static void showErrorDialog({
    required BuildContext context,
    required String message,
    String title = 'Fout',
    String buttonText = 'OK',
  }) {
    showDialog(
      context: context,
      builder: (context) => DialogTTSOverlay(
        child: AlertDialog(
          title: TTSClickableText(title),
          content: TTSClickableText(message),
          actions: [
            TTSClickableWidget(
              ttsText: '$buttonText knop',
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show a loading dialog with TTS support
  static void showLoadingDialog({
    required BuildContext context,
    String message = 'Laden...',
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => DialogTTSOverlay(
        child: AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              TTSClickableText(message),
            ],
          ),
        ),
      ),
    );
  }

  /// Show a success dialog with TTS support
  static void showSuccessDialog({
    required BuildContext context,
    required String message,
    String title = 'Succes',
    String buttonText = 'OK',
  }) {
    showDialog(
      context: context,
      builder: (context) => DialogTTSOverlay(
        child: AlertDialog(
          title: TTSClickableText(title),
          content: TTSClickableText(message),
          actions: [
            TTSClickableWidget(
              ttsText: '$buttonText knop',
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(buttonText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
