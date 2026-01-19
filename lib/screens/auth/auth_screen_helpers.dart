part of 'auth_screen.dart';

extension _AuthScreenHelpers on _AuthScreenState {
  String _friendlyAuthError(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('socket') ||
        lower.contains('connection') ||
        lower.contains('network') ||
        lower.contains('timeout') ||
        lower.contains('host lookup') ||
        lower.contains('operation not permitted')) {
      return 'Geen internetverbinding. Controleer je internet en probeer opnieuw.';
    }
    return 'Inloggen mislukt. Controleer je gegevens en probeer opnieuw.';
  }

  Future<void> _speakIfEnabled(String text) async {
    try {
      final accessibilityState = ref.read(accessibilityNotifierProvider);
      if (!accessibilityState.isTextToSpeechEnabled) return;
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      if (accessibilityNotifier.isSpeaking()) {
        await accessibilityNotifier.stopSpeaking();
        await Future.delayed(const Duration(milliseconds: 200));
      }
      await accessibilityNotifier.speak(text);
    } catch (e) {
      debugPrint('AuthScreen TTS Error (icon): $e');
    }
  }

  void _goToPasswordReset() {
    final email = _loginEmailController.text.trim();
    if (email.isNotEmpty) {
      final encodedEmail = Uri.encodeComponent(email);
      context.go('${AppRoutes.passwordReset}?email=$encodedEmail');
    } else {
      context.go(AppRoutes.passwordReset);
    }
  }
}
