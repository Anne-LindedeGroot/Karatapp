part of 'profile_screen.dart';

extension _ProfileScreenHelpers on _ProfileScreenState {
  /// Read the current page content using TTS
  Future<void> _readPageContent() async {
    try {
      // Add a small delay to ensure the screen is fully rendered
      await Future.delayed(const Duration(milliseconds: 500));

      final accessibilityState = ref.read(accessibilityNotifierProvider);

      // Only proceed if TTS is enabled
      if (!accessibilityState.isTextToSpeechEnabled) {
        debugPrint('ProfileScreen TTS: TTS is not enabled, skipping auto-read');
        return;
      }

      // Read only the relevant profile screen content, not the entire screen
      await _readProfileScreenContent();
    } catch (e) {
      debugPrint('ProfileScreen TTS Error: $e');
      // Don't rethrow the error to prevent screen from crashing
    }
  }

  /// Read only the profile screen content (similar to logout popup approach)
  Future<void> _readProfileScreenContent() async {
    try {
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      final currentUser = ref.read(authUserProvider);

      // Build the text to read
      final List<String> contentParts = [];

      // Add page title
      contentParts.add('Profiel pagina');
      contentParts.add('Gebruikersprofiel');

      // Add user info
      if (currentUser?.email != null) {
        contentParts.add('E-mail: ${currentUser!.email}');
      }

      // Add role info
      final userRoleAsync = ref.read(currentUserRoleProvider);
      userRoleAsync.when(
        data: (role) {
          contentParts.add('Rol: ${role.displayName}');
          contentParts.add('Beschrijving: ${role.description}');
        },
        loading: () => contentParts.add('Rol wordt geladen'),
        error: (error, stackTrace) => contentParts.add('Fout bij laden rol'),
      );

      // Add name info
      if (currentUser?.userMetadata?['full_name'] != null) {
        contentParts.add(
          'Volledige naam: ${currentUser!.userMetadata!['full_name']}',
        );
      } else {
        contentParts.add('Volledige naam: Niet ingesteld');
      }

      // Add accessibility settings
      final accessibilityState = ref.read(accessibilityNotifierProvider);
      contentParts.add(
        'Toegankelijkheid: Spraakknop ${accessibilityState.showTTSButton ? 'zichtbaar' : 'verborgen'}',
      );

      // Add data usage info
      final dataUsageState = ref.read(dataUsageProvider);
      final networkState = ref.read(networkProvider);
      contentParts.add(
        'Netwerkstatus: ${networkState.isConnected ? 'Verbonden' : 'Niet verbonden'}',
      );
      contentParts.add(
        'Dataverbruik modus: ${_getDataUsageModeText(dataUsageState.mode)}',
      );
      contentParts.add(
        'Maandelijks verbruik: ${dataUsageState.stats.formattedTotalUsage} van ${dataUsageState.monthlyDataLimit} MB',
      );

      final fullText = contentParts.join('. ');

      if (fullText.isNotEmpty) {
        debugPrint('ProfileScreen TTS: Reading content: $fullText');

        // Stop any current speech
        if (accessibilityNotifier.isSpeaking()) {
          await accessibilityNotifier.stopSpeaking();
          await Future.delayed(const Duration(milliseconds: 300));
        }

        // Speak the profile screen content
        await accessibilityNotifier.speak(fullText);
      } else {
        debugPrint('ProfileScreen TTS: No content to read');
      }
    } catch (e) {
      debugPrint('ProfileScreen TTS Error: $e');
    }
  }

  /// Get Dutch text for data usage mode
  String _getDataUsageModeText(DataUsageMode mode) {
    switch (mode) {
      case DataUsageMode.unlimited:
        return 'Onbeperkt';
      case DataUsageMode.moderate:
        return 'Gematigd';
      case DataUsageMode.strict:
        return 'Strikt';
      case DataUsageMode.wifiOnly:
        return 'Alleen Wi-Fi';
    }
  }
}
