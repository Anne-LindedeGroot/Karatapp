import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;
import 'theme_provider.dart';

/// Font size options for accessibility
enum AccessibilityFontSize {
  small('Klein'),
  normal('Normaal'),
  large('Groot'),
  extraLarge('Extra Groot');

  const AccessibilityFontSize(this.displayName);
  final String displayName;
}


/// Accessibility state class
class AccessibilityState {
  final AccessibilityFontSize fontSize;
  final bool isDyslexiaFriendly;
  final bool isTextToSpeechEnabled;
  final double speechRate;
  final double speechPitch;
  final bool useHeadphones;
  final bool isSpeaking;
  final bool showTTSButton;
  final bool skipGeneralInfoInTTSKata;
  final bool skipGeneralInfoInTTSOhyo;

  const AccessibilityState({
    this.fontSize = AccessibilityFontSize.normal,
    this.isDyslexiaFriendly = false,
    this.isTextToSpeechEnabled = true,
    this.speechRate = 0.5,
    this.speechPitch = 1.0,
    this.useHeadphones = true,
    this.isSpeaking = false,
    this.showTTSButton = true,
    this.skipGeneralInfoInTTSKata = false,
    this.skipGeneralInfoInTTSOhyo = false,
  });

  AccessibilityState copyWith({
    AccessibilityFontSize? fontSize,
    bool? isDyslexiaFriendly,
    bool? isTextToSpeechEnabled,
    double? speechRate,
    double? speechPitch,
    bool? useHeadphones,
    bool? isSpeaking,
    bool? showTTSButton,
    bool? skipGeneralInfoInTTSKata,
    bool? skipGeneralInfoInTTSOhyo,
  }) {
    return AccessibilityState(
      fontSize: fontSize ?? this.fontSize,
      isDyslexiaFriendly: isDyslexiaFriendly ?? this.isDyslexiaFriendly,
      isTextToSpeechEnabled: isTextToSpeechEnabled ?? this.isTextToSpeechEnabled,
      speechRate: speechRate ?? this.speechRate,
      speechPitch: speechPitch ?? this.speechPitch,
      useHeadphones: useHeadphones ?? this.useHeadphones,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      showTTSButton: showTTSButton ?? this.showTTSButton,
      skipGeneralInfoInTTSKata: skipGeneralInfoInTTSKata ?? this.skipGeneralInfoInTTSKata,
      skipGeneralInfoInTTSOhyo: skipGeneralInfoInTTSOhyo ?? this.skipGeneralInfoInTTSOhyo,
    );
  }

  /// Get font scale factor based on selected font size
  double get fontScaleFactor {
    switch (fontSize) {
      case AccessibilityFontSize.small:
        return 0.85;
      case AccessibilityFontSize.normal:
        return 1.0;
      case AccessibilityFontSize.large:
        return 1.2;
      case AccessibilityFontSize.extraLarge:
        return 1.5;
    }
  }

  /// Get font size description
  String get fontSizeDescription {
    switch (fontSize) {
      case AccessibilityFontSize.small:
        return 'Klein';
      case AccessibilityFontSize.normal:
        return 'Normaal';
      case AccessibilityFontSize.large:
        return 'Groot';
      case AccessibilityFontSize.extraLarge:
        return 'Extra Groot';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccessibilityState &&
        other.fontSize == fontSize &&
        other.isDyslexiaFriendly == isDyslexiaFriendly &&
        other.isTextToSpeechEnabled == isTextToSpeechEnabled &&
        other.speechRate == speechRate &&
        other.speechPitch == speechPitch &&
        other.useHeadphones == useHeadphones &&
        other.isSpeaking == isSpeaking &&
        other.showTTSButton == showTTSButton &&
        other.skipGeneralInfoInTTSKata == skipGeneralInfoInTTSKata &&
        other.skipGeneralInfoInTTSOhyo == skipGeneralInfoInTTSOhyo;
  }

  @override
  int get hashCode => fontSize.hashCode ^
      isDyslexiaFriendly.hashCode ^
      isTextToSpeechEnabled.hashCode ^
      speechRate.hashCode ^
      speechPitch.hashCode ^
      useHeadphones.hashCode ^
      isSpeaking.hashCode ^
      showTTSButton.hashCode ^
      skipGeneralInfoInTTSKata.hashCode ^
      skipGeneralInfoInTTSOhyo.hashCode;

  @override
  String toString() {
    return 'AccessibilityState(fontSize: $fontSize, isDyslexiaFriendly: $isDyslexiaFriendly, isTextToSpeechEnabled: $isTextToSpeechEnabled, speechRate: $speechRate, speechPitch: $speechPitch, useHeadphones: $useHeadphones, isSpeaking: $isSpeaking, showTTSButton: $showTTSButton, skipGeneralInfoInTTSKata: $skipGeneralInfoInTTSKata, skipGeneralInfoInTTSOhyo: $skipGeneralInfoInTTSOhyo)';
  }
}

/// Accessibility notifier class
class AccessibilityNotifier extends StateNotifier<AccessibilityState> {
  static const String _fontSizeKey = 'accessibility_font_size';
  static const String _dyslexiaFriendlyKey = 'accessibility_dyslexia_friendly';
  static const String _textToSpeechKey = 'accessibility_text_to_speech';
  static const String _speechRateKey = 'accessibility_speech_rate';
  static const String _speechPitchKey = 'accessibility_speech_pitch';
  static const String _useHeadphonesKey = 'accessibility_use_headphones';
  static const String _showTTSButtonKey = 'accessibility_show_tts_button';
  static const String _skipGeneralInfoInTTSKataKey = 'accessibility_skip_general_info_in_tts_kata';
  static const String _skipGeneralInfoInTTSOhyoKey = 'accessibility_skip_general_info_in_tts_ohyo';

  late FlutterTts _flutterTts;
  bool _isTtsInitialized = false;
  bool _isSpeaking = false;

  AccessibilityNotifier() : super(const AccessibilityState()) {
    _initializeAsync();
  }

  /// Initialize TTS and load preferences asynchronously
  Future<void> _initializeAsync() async {
    await _initializeTts();
    await _loadAccessibilityFromPreferences();
  }


  /// Initialize text-to-speech
  Future<void> _initializeTts() async {
    try {
      debugPrint('Initializing TTS...');
      _flutterTts = FlutterTts();
      
      // Wait a moment for TTS to be ready
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Set up TTS event handlers first
      _flutterTts.setStartHandler(() {
        debugPrint('TTS: Speech started');
        print('▶️ TTS: Speech started');
        _isSpeaking = true;
        state = state.copyWith(isSpeaking: true);
      });
      
      _flutterTts.setCompletionHandler(() {
        debugPrint('TTS: Speech completed');
        print('✅ TTS: Speech completed');
        _isSpeaking = false;
        state = state.copyWith(isSpeaking: false);
      });
      
      _flutterTts.setCancelHandler(() {
        debugPrint('TTS: Speech cancelled');
        print('⏹️ TTS: Speech cancelled');
        _isSpeaking = false;
        state = state.copyWith(isSpeaking: false);
      });
      
      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS Error: $msg');
        print('❌ TTS Error: $msg');
        _isSpeaking = false;
        state = state.copyWith(isSpeaking: false);
      });
      
      // Configure TTS engine for Android
      if (Platform.isAndroid) {
        await _configureAndroidTTS();
      }
      
      // Check available languages
      try {
        final languages = await _flutterTts.getLanguages;
        debugPrint('Available TTS languages: $languages');
      } catch (e) {
        debugPrint('Could not get available languages: $e');
      }
      
      // Try to set Dutch language with better fallback logic
      await _setOptimalLanguage();
      
      // Set initial speech parameters
      try {
        await _flutterTts.setSpeechRate(state.speechRate);
        await _flutterTts.setPitch(state.speechPitch);
        debugPrint('TTS speech parameters set: rate=${state.speechRate}, pitch=${state.speechPitch}');
      } catch (e) {
        debugPrint('Error setting speech parameters: $e');
      }
      
      // Configure audio routing for headphones
      await _configureAudioRouting();
      
      _isTtsInitialized = true;
      debugPrint('TTS initialized successfully');
      
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
      _isTtsInitialized = false;
    }
  }

  /// Configure Android TTS engine
  Future<void> _configureAndroidTTS() async {
    try {
      // Get available engines
      final engines = await _flutterTts.getEngines;
      debugPrint('Available TTS engines: $engines');
      
      if (engines == null || engines.isEmpty) {
        debugPrint('No TTS engines available, using default');
        return;
      }
      
      // Try to use Samsung TTS if available (common on Samsung devices)
      Map<String, dynamic>? samsungEngine;
      try {
        samsungEngine = engines.firstWhere(
          (engine) {
            if (engine is Map<String, dynamic>) {
              final name = engine['name']?.toString() ?? '';
              return name.toLowerCase().contains('samsung');
            }
            return false;
          },
          orElse: () => <String, dynamic>{},
        );
      } catch (e) {
        debugPrint('Error finding Samsung engine: $e');
        samsungEngine = <String, dynamic>{};
      }
      
      if (samsungEngine != null && samsungEngine.isNotEmpty) {
        final engineName = samsungEngine['name']?.toString() ?? '';
        if (engineName.isNotEmpty) {
          debugPrint('Using Samsung TTS engine: $engineName');
          await _flutterTts.setEngine(engineName);
          return;
        }
      }
      
      // Try Google TTS as fallback
      Map<String, dynamic>? googleEngine;
      try {
        googleEngine = engines.firstWhere(
          (engine) {
            if (engine is Map<String, dynamic>) {
              final name = engine['name']?.toString() ?? '';
              return name.toLowerCase().contains('google');
            }
            return false;
          },
          orElse: () => <String, dynamic>{},
        );
      } catch (e) {
        debugPrint('Error finding Google engine: $e');
        googleEngine = <String, dynamic>{};
      }
      
      if (googleEngine != null && googleEngine.isNotEmpty) {
        final engineName = googleEngine['name']?.toString() ?? '';
        if (engineName.isNotEmpty) {
          debugPrint('Using Google TTS engine: $engineName');
          await _flutterTts.setEngine(engineName);
          return;
        }
      }
      
      // Use default engine
      debugPrint('Using default TTS engine');
    } catch (e) {
      debugPrint('Error configuring Android TTS: $e');
    }
  }

  /// Set optimal language for TTS
  Future<void> _setOptimalLanguage() async {
    try {
      // Try Dutch variants in order of preference - be more aggressive
      final dutchVariants = ['nl-NL', 'nl-BE', 'nl', 'nl_NL', 'nl_BE'];
      
      for (final variant in dutchVariants) {
        final result = await _flutterTts.setLanguage(variant);
        debugPrint('Set language $variant result: $result');
        
        if (result == 1) {
          debugPrint('Successfully set language to $variant');
          return;
        }
      }
      
      // If no Dutch available, try English as fallback
      debugPrint('No Dutch language variant available, trying English as fallback');
      final englishResult = await _flutterTts.setLanguage('en-US');
      if (englishResult == 1) {
        debugPrint('Successfully set language to English as fallback');
        return;
      }
      
      // Try system default
      final defaultResult = await _flutterTts.setLanguage('');
      debugPrint('Set system default language result: $defaultResult');
      debugPrint('Warning: Using system default language for TTS');
    } catch (e) {
      debugPrint('Error setting optimal language: $e');
    }
  }

  /// Configure audio routing for headphones
  Future<void> _configureAudioRouting() async {
    if (!_isTtsInitialized) return;
    
    try {
      if (state.useHeadphones) {
        // Configure TTS to use headphones/external audio devices
        if (Platform.isIOS) {
          // iOS specific configuration
          await _flutterTts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            [
              IosTextToSpeechAudioCategoryOptions.allowBluetooth,
              IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
              IosTextToSpeechAudioCategoryOptions.allowAirPlay,
            ],
            IosTextToSpeechAudioMode.spokenAudio,
          );
        } else if (Platform.isAndroid) {
          // Android specific configuration - don't set specific engine here
          // as it's already configured in _configureAndroidTTS
          await _flutterTts.setSilence(0);
        }
      } else {
        // Use device speakers
        if (Platform.isIOS) {
          await _flutterTts.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker],
            IosTextToSpeechAudioMode.spokenAudio,
          );
        }
      }
    } catch (e) {
      debugPrint('Error configuring audio routing: $e');
    }
  }

  /// Load accessibility settings from SharedPreferences
  Future<void> _loadAccessibilityFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load font size
      final fontSizeString = prefs.getString(_fontSizeKey);
      AccessibilityFontSize fontSize = AccessibilityFontSize.normal;
      if (fontSizeString != null) {
        fontSize = AccessibilityFontSize.values.firstWhere(
          (size) => size.toString() == fontSizeString,
          orElse: () => AccessibilityFontSize.normal,
        );
      }

      // Load dyslexia-friendly setting
      final isDyslexiaFriendly = prefs.getBool(_dyslexiaFriendlyKey) ?? false;

      // Load text-to-speech setting
      final isTextToSpeechEnabled = prefs.getBool(_textToSpeechKey) ?? true;

      // Load speech rate
      final speechRate = prefs.getDouble(_speechRateKey) ?? 0.5;

      // Load speech pitch
      final speechPitch = prefs.getDouble(_speechPitchKey) ?? 1.0;

      // Load headphones setting
      final useHeadphones = prefs.getBool(_useHeadphonesKey) ?? true;

      // Load TTS button visibility setting
      final showTTSButton = prefs.getBool(_showTTSButtonKey) ?? true;

      // Load skip general info in TTS settings
      final skipGeneralInfoInTTSKata = prefs.getBool(_skipGeneralInfoInTTSKataKey) ?? false;
      final skipGeneralInfoInTTSOhyo = prefs.getBool(_skipGeneralInfoInTTSOhyoKey) ?? false;

      state = AccessibilityState(
        fontSize: fontSize,
        isDyslexiaFriendly: isDyslexiaFriendly,
        isTextToSpeechEnabled: isTextToSpeechEnabled,
        speechRate: speechRate,
        speechPitch: speechPitch,
        useHeadphones: useHeadphones,
        showTTSButton: showTTSButton,
        skipGeneralInfoInTTSKata: skipGeneralInfoInTTSKata,
        skipGeneralInfoInTTSOhyo: skipGeneralInfoInTTSOhyo,
      );

      // Update TTS settings if initialized
      if (_isTtsInitialized) {
        await _flutterTts.setSpeechRate(speechRate);
        await _flutterTts.setPitch(speechPitch);
        await _configureAudioRouting();
      }
    } catch (e) {
      debugPrint('Error loading accessibility preferences: $e');
    }
  }

  /// Save accessibility settings to SharedPreferences
  Future<void> _saveAccessibilityToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fontSizeKey, state.fontSize.toString());
      await prefs.setBool(_dyslexiaFriendlyKey, state.isDyslexiaFriendly);
      await prefs.setBool(_textToSpeechKey, state.isTextToSpeechEnabled);
      await prefs.setDouble(_speechRateKey, state.speechRate);
      await prefs.setDouble(_speechPitchKey, state.speechPitch);
      await prefs.setBool(_useHeadphonesKey, state.useHeadphones);
      await prefs.setBool(_showTTSButtonKey, state.showTTSButton);
      await prefs.setBool(_skipGeneralInfoInTTSKataKey, state.skipGeneralInfoInTTSKata);
      await prefs.setBool(_skipGeneralInfoInTTSOhyoKey, state.skipGeneralInfoInTTSOhyo);
    } catch (e) {
      debugPrint('Error saving accessibility preferences: $e');
    }
  }

  /// Set font size
  Future<void> setFontSize(AccessibilityFontSize fontSize) async {
    state = state.copyWith(fontSize: fontSize);
    await _saveAccessibilityToPreferences();
  }

  /// Toggle font size cycling through all available sizes
  Future<void> toggleFontSize() async {
    AccessibilityFontSize newFontSize;
    switch (state.fontSize) {
      case AccessibilityFontSize.small:
        newFontSize = AccessibilityFontSize.normal;
        break;
      case AccessibilityFontSize.normal:
        newFontSize = AccessibilityFontSize.large;
        break;
      case AccessibilityFontSize.large:
        newFontSize = AccessibilityFontSize.extraLarge;
        break;
      case AccessibilityFontSize.extraLarge:
        newFontSize = AccessibilityFontSize.small;
        break;
    }
    await setFontSize(newFontSize);
  }

  /// Set dyslexia-friendly mode
  Future<void> setDyslexiaFriendly(bool isDyslexiaFriendly) async {
    state = state.copyWith(isDyslexiaFriendly: isDyslexiaFriendly);
    await _saveAccessibilityToPreferences();
  }

  /// Toggle dyslexia-friendly mode
  Future<void> toggleDyslexiaFriendly() async {
    await setDyslexiaFriendly(!state.isDyslexiaFriendly);
  }

  /// Set text-to-speech enabled
  Future<void> setTextToSpeechEnabled(bool isEnabled) async {
    state = state.copyWith(isTextToSpeechEnabled: isEnabled);
    // If enabling TTS, also show the TTS button
    if (isEnabled && !state.showTTSButton) {
      state = state.copyWith(showTTSButton: true);
    }
    await _saveAccessibilityToPreferences();
  }

  /// Toggle text-to-speech
  Future<void> toggleTextToSpeech() async {
    await setTextToSpeechEnabled(!state.isTextToSpeechEnabled);
  }

  /// Set speech rate
  Future<void> setSpeechRate(double rate) async {
    state = state.copyWith(speechRate: rate);
    if (_isTtsInitialized) {
      await _flutterTts.setSpeechRate(rate);
    }
    await _saveAccessibilityToPreferences();
  }

  /// Set speech pitch
  Future<void> setSpeechPitch(double pitch) async {
    state = state.copyWith(speechPitch: pitch);
    if (_isTtsInitialized) {
      await _flutterTts.setPitch(pitch);
    }
    await _saveAccessibilityToPreferences();
  }

  /// Set headphones usage
  Future<void> setUseHeadphones(bool useHeadphones) async {
    state = state.copyWith(useHeadphones: useHeadphones);
    if (_isTtsInitialized) {
      await _configureAudioRouting();
    }
    await _saveAccessibilityToPreferences();
  }

  /// Toggle headphones usage
  Future<void> toggleUseHeadphones() async {
    await setUseHeadphones(!state.useHeadphones);
  }

  /// Set TTS button visibility
  Future<void> setShowTTSButton(bool show) async {
    state = state.copyWith(showTTSButton: show);
    // If hiding the TTS button, also disable TTS functionality
    if (!show && state.isTextToSpeechEnabled) {
      state = state.copyWith(isTextToSpeechEnabled: false);
    }
    await _saveAccessibilityToPreferences();
  }

  /// Toggle TTS button visibility
  Future<void> toggleShowTTSButton() async {
    final newValue = !state.showTTSButton;
    await setShowTTSButton(newValue);
  }

  /// Set skip general info in TTS for kata
  Future<void> setSkipGeneralInfoInTTSKata(bool skip) async {
    state = state.copyWith(skipGeneralInfoInTTSKata: skip);
    await _saveAccessibilityToPreferences();
  }

  /// Toggle skip general info in TTS for kata
  Future<void> toggleSkipGeneralInfoInTTSKata() async {
    await setSkipGeneralInfoInTTSKata(!state.skipGeneralInfoInTTSKata);
  }

  /// Set skip general info in TTS for ohyo
  Future<void> setSkipGeneralInfoInTTSOhyo(bool skip) async {
    state = state.copyWith(skipGeneralInfoInTTSOhyo: skip);
    await _saveAccessibilityToPreferences();
  }

  /// Toggle skip general info in TTS for ohyo
  Future<void> toggleSkipGeneralInfoInTTSOhyo() async {
    await setSkipGeneralInfoInTTSOhyo(!state.skipGeneralInfoInTTSOhyo);
  }

  /// Speak text using text-to-speech with improved error handling
  Future<void> speak(String text) async {
    debugPrint('TTS: speak() called with text: "$text"');
    print('🗣️ TTS: speak() called with text: "$text"');

    if (!state.isTextToSpeechEnabled) {
      debugPrint('TTS: Text-to-speech is disabled');
      print('❌ TTS: Text-to-speech is disabled');
      return;
    }
    
    // Clean and validate text
    final cleanText = text.trim();
    if (cleanText.isEmpty) {
      debugPrint('TTS: Empty text provided, skipping');
      print('❌ TTS: Empty text provided, skipping');
      return;
    }
    
    // Ensure TTS is initialized
    if (!_isTtsInitialized) {
      debugPrint('TTS: Not initialized, attempting initialization...');
      await _initializeTts();
      if (!_isTtsInitialized) {
        debugPrint('TTS: Initialization failed, cannot speak');
        return;
      }
    }
    
    try {
      // Stop any current speech first
      await _flutterTts.stop();
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Set speech parameters
      await _flutterTts.setSpeechRate(state.speechRate);
      await _flutterTts.setPitch(state.speechPitch);
      
      // Update speaking state immediately
      _isSpeaking = true;
      state = state.copyWith(isSpeaking: true);
      
      debugPrint('TTS: Starting to speak: "${cleanText.length > 100 ? '${cleanText.substring(0, 100)}...' : cleanText}"');
      // Show full TTS output in terminal for debugging
      print('🗣️ FULL TTS OUTPUT: "$cleanText"');
      
      // Speak with timeout and retry logic
      final result = await _speakWithTimeout(cleanText);
      
      if (result) {
        debugPrint('TTS: Speech started successfully');
      } else {
        debugPrint('TTS: Speech failed to start');
        _isSpeaking = false;
        state = state.copyWith(isSpeaking: false);
      }
      
    } catch (e) {
      debugPrint('TTS Error: $e');
      _isSpeaking = false;
      state = state.copyWith(isSpeaking: false);
      
      // Try to reinitialize TTS on error
      _isTtsInitialized = false;
      Future.delayed(const Duration(milliseconds: 1000), () async {
        await _initializeTts();
      });
    }
  }

  /// Speak text with timeout and retry logic
  Future<bool> _speakWithTimeout(String text) async {
    int attempts = 0;
    const maxAttempts = 2; // Reduced attempts for faster response
    
    while (attempts < maxAttempts) {
      try {
        final result = await _flutterTts.speak(text).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('TTS: Speech timeout on attempt ${attempts + 1}');
            return 0;
          },
        );
        
        debugPrint('TTS speak result (attempt ${attempts + 1}): $result');
        
        if (result == 1) {
          return true;
        }
        
        attempts++;
        if (attempts < maxAttempts) {
          debugPrint('TTS: Speak attempt $attempts failed, retrying...');
          await Future.delayed(Duration(milliseconds: 200 * attempts));
        }
      } catch (e) {
        debugPrint('TTS: Speak attempt ${attempts + 1} threw error: $e');
        attempts++;
        if (attempts < maxAttempts) {
          await Future.delayed(Duration(milliseconds: 200 * attempts));
        }
      }
    }
    
    return false;
  }


  /// Stop text-to-speech
  Future<void> stopSpeaking() async {
    if (!_isTtsInitialized) return;
    
    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      state = state.copyWith(isSpeaking: false);
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }
  }

  /// Check if TTS is currently speaking
  bool isSpeaking() {
    return _isSpeaking;
  }

  /// Get dyslexia-friendly text style modifications
  TextStyle getDyslexiaFriendlyTextStyle(TextStyle baseStyle) {
    if (!state.isDyslexiaFriendly) return baseStyle;

    // Apply dyslexic-friendly formatting with optimized spacing for smooth readability
    return baseStyle.copyWith(
      fontFamily: 'OpenDyslexic',
      // Reduced letter spacing for better word flow
      letterSpacing: (baseStyle.letterSpacing ?? 0.0) + 0.2,
      // Minimal word spacing to prevent awkward line breaks
      wordSpacing: 1.0,
      // Balanced line height for comfortable reading
      height: (baseStyle.height ?? 1.2) + 0.15,
    );
  }

  /// Get scaled text style based on accessibility settings
  TextStyle getAccessibleTextStyle(TextStyle baseStyle) {
    double effectiveScaleFactor = state.fontScaleFactor;

    // Don't reduce font size for dyslexia font - maintain identical sizing
    TextStyle scaledStyle = baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * effectiveScaleFactor,
    );

    return getDyslexiaFriendlyTextStyle(scaledStyle);
  }

  /// Get scaled text style that integrates with system dynamic type scaling
  TextStyle getSystemAwareTextStyle(TextStyle baseStyle, BuildContext context) {
    // Get system text scale factor
    final systemScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);

    // Combine user preference with system scaling
    double combinedScaleFactor = state.fontScaleFactor * systemScaleFactor;

    // Don't reduce font size for dyslexia font - maintain identical sizing
    // Clamp the scale factor to reasonable bounds
    final clampedScaleFactor = combinedScaleFactor.clamp(0.5, 3.0);

    TextStyle scaledStyle = baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * clampedScaleFactor,
    );

    return getDyslexiaFriendlyTextStyle(scaledStyle);
  }

  /// Check if system dynamic type is enabled and larger than normal
  bool isSystemDynamicTypeEnabled(BuildContext context) {
    final systemScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    return systemScaleFactor > 1.0;
  }

  /// Get the effective font scale factor combining user and system settings
  double getEffectiveFontScaleFactor(BuildContext context) {
    final systemScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
    return (state.fontScaleFactor * systemScaleFactor).clamp(0.5, 3.0);
  }


  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}

/// Accessibility provider
final accessibilityNotifierProvider = StateNotifierProvider<AccessibilityNotifier, AccessibilityState>(
  (ref) => AccessibilityNotifier(),
);

/// Convenience providers for specific accessibility properties
final fontSizeProvider = Provider<AccessibilityFontSize>((ref) {
  return ref.watch(accessibilityNotifierProvider).fontSize;
});

final fontScaleFactorProvider = Provider<double>((ref) {
  return ref.watch(accessibilityNotifierProvider).fontScaleFactor;
});

final isDyslexiaFriendlyProvider = Provider<bool>((ref) {
  return ref.watch(accessibilityNotifierProvider).isDyslexiaFriendly;
});

final isTextToSpeechEnabledProvider = Provider<bool>((ref) {
  return ref.watch(accessibilityNotifierProvider).isTextToSpeechEnabled;
});

final speechRateProvider = Provider<double>((ref) {
  return ref.watch(accessibilityNotifierProvider).speechRate;
});

final speechPitchProvider = Provider<double>((ref) {
  return ref.watch(accessibilityNotifierProvider).speechPitch;
});

final useHeadphonesProvider = Provider<bool>((ref) {
  return ref.watch(accessibilityNotifierProvider).useHeadphones;
});

final isSpeakingProvider = Provider<bool>((ref) {
  return ref.watch(accessibilityNotifierProvider).isSpeaking;
});

final showTTSButtonProvider = Provider<bool>((ref) {
  return ref.watch(accessibilityNotifierProvider).showTTSButton;
});

final skipGeneralInfoInTTSKataProvider = Provider<bool>((ref) {
  return ref.watch(accessibilityNotifierProvider).skipGeneralInfoInTTSKata;
});

final skipGeneralInfoInTTSOhyoProvider = Provider<bool>((ref) {
  return ref.watch(accessibilityNotifierProvider).skipGeneralInfoInTTSOhyo;
});

final fontSizeDescriptionProvider = Provider<String>((ref) {
  return ref.watch(accessibilityNotifierProvider).fontSizeDescription;
});


/// Extension to get font size description
extension AccessibilityFontSizeExtension on AccessibilityFontSize {
  String get fontSizeDescription {
    switch (this) {
      case AccessibilityFontSize.small:
        return 'Klein';
      case AccessibilityFontSize.normal:
        return 'Normaal';
      case AccessibilityFontSize.large:
        return 'Groot';
      case AccessibilityFontSize.extraLarge:
        return 'Extra Groot';
    }
  }
}

/// Provider that syncs dyslexia-friendly setting between accessibility and theme providers
final dyslexiaFriendlySyncProvider = Provider<void>((ref) {
  // Listen to accessibility state changes and sync to theme
  ref.listen<AccessibilityState>(accessibilityNotifierProvider, (previous, next) {
    final themeNotifier = ref.read(themeNotifierProvider.notifier);
    final currentThemeState = ref.read(themeNotifierProvider);

    // Sync the dyslexia-friendly setting from accessibility to theme
    if (next.isDyslexiaFriendly != currentThemeState.isDyslexiaFriendly) {
      themeNotifier.setDyslexiaFriendly(next.isDyslexiaFriendly);
    }
  });

  return; // Provider returns void
});
