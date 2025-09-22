import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

/// Font size options for accessibility
enum AccessibilityFontSize {
  small,
  normal,
  large,
  extraLarge,
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

  const AccessibilityState({
    this.fontSize = AccessibilityFontSize.normal,
    this.isDyslexiaFriendly = false,
    this.isTextToSpeechEnabled = false,
    this.speechRate = 0.5,
    this.speechPitch = 1.0,
    this.useHeadphones = true,
    this.isSpeaking = false,
  });

  AccessibilityState copyWith({
    AccessibilityFontSize? fontSize,
    bool? isDyslexiaFriendly,
    bool? isTextToSpeechEnabled,
    double? speechRate,
    double? speechPitch,
    bool? useHeadphones,
    bool? isSpeaking,
  }) {
    return AccessibilityState(
      fontSize: fontSize ?? this.fontSize,
      isDyslexiaFriendly: isDyslexiaFriendly ?? this.isDyslexiaFriendly,
      isTextToSpeechEnabled: isTextToSpeechEnabled ?? this.isTextToSpeechEnabled,
      speechRate: speechRate ?? this.speechRate,
      speechPitch: speechPitch ?? this.speechPitch,
      useHeadphones: useHeadphones ?? this.useHeadphones,
      isSpeaking: isSpeaking ?? this.isSpeaking,
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
        other.isSpeaking == isSpeaking;
  }

  @override
  int get hashCode => fontSize.hashCode ^ 
      isDyslexiaFriendly.hashCode ^ 
      isTextToSpeechEnabled.hashCode ^ 
      speechRate.hashCode ^ 
      speechPitch.hashCode ^
      useHeadphones.hashCode ^
      isSpeaking.hashCode;

  @override
  String toString() {
    return 'AccessibilityState(fontSize: $fontSize, isDyslexiaFriendly: $isDyslexiaFriendly, isTextToSpeechEnabled: $isTextToSpeechEnabled, speechRate: $speechRate, speechPitch: $speechPitch, useHeadphones: $useHeadphones, isSpeaking: $isSpeaking)';
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

  late FlutterTts _flutterTts;
  bool _isTtsInitialized = false;
  bool _isSpeaking = false;

  AccessibilityNotifier() : super(const AccessibilityState()) {
    _initializeTts();
    _loadAccessibilityFromPreferences();
  }

  /// Initialize text-to-speech
  Future<void> _initializeTts() async {
    try {
      _flutterTts = FlutterTts();
      
      // Set default language to Dutch
      await _flutterTts.setLanguage('nl-NL');
      
      // Set initial speech rate and pitch
      await _flutterTts.setSpeechRate(state.speechRate);
      await _flutterTts.setPitch(state.speechPitch);
      
      // Configure audio routing for headphones
      await _configureAudioRouting();
      
      // Set up TTS event handlers
      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
        state = state.copyWith(isSpeaking: true);
      });
      
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        state = state.copyWith(isSpeaking: false);
      });
      
      _flutterTts.setCancelHandler(() {
        _isSpeaking = false;
        state = state.copyWith(isSpeaking: false);
      });
      
      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        state = state.copyWith(isSpeaking: false);
        debugPrint('TTS Error: $msg');
      });
      
      _isTtsInitialized = true;
    } catch (e) {
      debugPrint('Error initializing TTS: $e');
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
          // Android specific configuration
          await _flutterTts.setEngine("com.google.android.tts");
          // Set audio stream to music to route through headphones
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
      final isTextToSpeechEnabled = prefs.getBool(_textToSpeechKey) ?? false;

      // Load speech rate
      final speechRate = prefs.getDouble(_speechRateKey) ?? 0.5;

      // Load speech pitch
      final speechPitch = prefs.getDouble(_speechPitchKey) ?? 1.0;

      // Load headphones setting
      final useHeadphones = prefs.getBool(_useHeadphonesKey) ?? true;

      state = AccessibilityState(
        fontSize: fontSize,
        isDyslexiaFriendly: isDyslexiaFriendly,
        isTextToSpeechEnabled: isTextToSpeechEnabled,
        speechRate: speechRate,
        speechPitch: speechPitch,
        useHeadphones: useHeadphones,
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

  /// Speak text using text-to-speech
  Future<void> speak(String text) async {
    if (!state.isTextToSpeechEnabled || !_isTtsInitialized) return;
    
    try {
      // Stop any current speech
      await _flutterTts.stop();
      
      // Update speaking state immediately
      _isSpeaking = true;
      state = state.copyWith(isSpeaking: true);
      
      // Speak the text
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('Error speaking text: $e');
      _isSpeaking = false;
      state = state.copyWith(isSpeaking: false);
    }
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

    return baseStyle.copyWith(
      // Increase letter spacing for better readability
      letterSpacing: (baseStyle.letterSpacing ?? 0) + 1.2,
      // Increase line height for better readability
      height: (baseStyle.height ?? 1.0) * 1.3,
      // Use a more dyslexia-friendly font weight
      fontWeight: FontWeight.w400,
    );
  }

  /// Get scaled text style based on accessibility settings
  TextStyle getAccessibleTextStyle(TextStyle baseStyle) {
    TextStyle scaledStyle = baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * state.fontScaleFactor,
    );

    return getDyslexiaFriendlyTextStyle(scaledStyle);
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
