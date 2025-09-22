import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode options
enum AppThemeMode {
  light,
  dark,
  system,
}

/// Color scheme options
enum AppColorScheme {
  defaultGreen,
  emeraldGreen,
  neonGreen,
  forestGreen,
  mintGreen,
  blue,
  purple,
  orange,
}

/// Theme state class
class ThemeState {
  final AppThemeMode themeMode;
  final AppColorScheme colorScheme;
  final bool isHighContrast;
  final bool glowEffects;

  const ThemeState({
    this.themeMode = AppThemeMode.system,
    this.colorScheme = AppColorScheme.defaultGreen,
    this.isHighContrast = false,
    this.glowEffects = false,
  });

  ThemeState copyWith({
    AppThemeMode? themeMode,
    AppColorScheme? colorScheme,
    bool? isHighContrast,
    bool? glowEffects,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      colorScheme: colorScheme ?? this.colorScheme,
      isHighContrast: isHighContrast ?? this.isHighContrast,
      glowEffects: glowEffects ?? this.glowEffects,
    );
  }

  /// Convert to Flutter ThemeMode
  ThemeMode get flutterThemeMode {
    switch (themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThemeState &&
        other.themeMode == themeMode &&
        other.colorScheme == colorScheme &&
        other.isHighContrast == isHighContrast &&
        other.glowEffects == glowEffects;
  }

  @override
  int get hashCode => themeMode.hashCode ^ colorScheme.hashCode ^ isHighContrast.hashCode ^ glowEffects.hashCode;

  @override
  String toString() {
    return 'ThemeState(themeMode: $themeMode, colorScheme: $colorScheme, isHighContrast: $isHighContrast, glowEffects: $glowEffects)';
  }
}

/// Theme notifier class
class ThemeNotifier extends StateNotifier<ThemeState> {
  static const String _themeModeKey = 'theme_mode';
  static const String _colorSchemeKey = 'color_scheme';
  static const String _highContrastKey = 'high_contrast';
  static const String _glowEffectsKey = 'glow_effects';

  ThemeNotifier() : super(const ThemeState()) {
    _loadThemeFromPreferences();
  }

  /// Load theme settings from SharedPreferences
  Future<void> _loadThemeFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load theme mode
      final themeModeString = prefs.getString(_themeModeKey);
      AppThemeMode themeMode = AppThemeMode.system;
      if (themeModeString != null) {
        themeMode = AppThemeMode.values.firstWhere(
          (mode) => mode.toString() == themeModeString,
          orElse: () => AppThemeMode.system,
        );
      }

      // Load color scheme
      final colorSchemeString = prefs.getString(_colorSchemeKey);
      AppColorScheme colorScheme = AppColorScheme.defaultGreen;
      if (colorSchemeString != null) {
        colorScheme = AppColorScheme.values.firstWhere(
          (scheme) => scheme.toString() == colorSchemeString,
          orElse: () => AppColorScheme.defaultGreen,
        );
      }

      // Load high contrast setting
      final isHighContrast = prefs.getBool(_highContrastKey) ?? false;

      // Load glow effects setting
      final glowEffects = prefs.getBool(_glowEffectsKey) ?? false;

      state = ThemeState(
        themeMode: themeMode,
        colorScheme: colorScheme,
        isHighContrast: isHighContrast,
        glowEffects: glowEffects,
      );
    } catch (e) {
      // If there's an error loading preferences, use defaults
      debugPrint('Error loading theme preferences: $e');
    }
  }

  /// Save theme settings to SharedPreferences
  Future<void> _saveThemeToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, state.themeMode.toString());
      await prefs.setString(_colorSchemeKey, state.colorScheme.toString());
      await prefs.setBool(_highContrastKey, state.isHighContrast);
      await prefs.setBool(_glowEffectsKey, state.glowEffects);
    } catch (e) {
      debugPrint('Error saving theme preferences: $e');
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(AppThemeMode themeMode) async {
    state = state.copyWith(themeMode: themeMode);
    await _saveThemeToPreferences();
  }

  /// Toggle between light and dark mode (ignores system)
  Future<void> toggleTheme() async {
    final newThemeMode = state.themeMode == AppThemeMode.light
        ? AppThemeMode.dark
        : AppThemeMode.light;
    await setThemeMode(newThemeMode);
  }

  /// Set high contrast mode
  Future<void> setHighContrast(bool isHighContrast) async {
    state = state.copyWith(isHighContrast: isHighContrast);
    await _saveThemeToPreferences();
  }

  /// Toggle high contrast mode
  Future<void> toggleHighContrast() async {
    await setHighContrast(!state.isHighContrast);
  }

  /// Set color scheme
  Future<void> setColorScheme(AppColorScheme colorScheme) async {
    state = state.copyWith(colorScheme: colorScheme);
    await _saveThemeToPreferences();
  }

  /// Set glow effects
  Future<void> setGlowEffects(bool glowEffects) async {
    state = state.copyWith(glowEffects: glowEffects);
    await _saveThemeToPreferences();
  }

  /// Toggle glow effects
  Future<void> toggleGlowEffects() async {
    await setGlowEffects(!state.glowEffects);
  }

  /// Reset to system theme
  Future<void> resetToSystem() async {
    await setThemeMode(AppThemeMode.system);
  }

  /// Get theme description for UI
  String get themeDescription {
    final baseDescription = switch (state.themeMode) {
      AppThemeMode.light => state.isHighContrast ? 'Licht (Hoog Contrast)' : 'Licht',
      AppThemeMode.dark => state.isHighContrast ? 'Donker (Hoog Contrast)' : 'Donker',
      AppThemeMode.system => state.isHighContrast ? 'Systeem (Hoog Contrast)' : 'Systeem',
    };
    
    final colorDescription = switch (state.colorScheme) {
      AppColorScheme.defaultGreen => 'Standaard Groen',
      AppColorScheme.emeraldGreen => 'Smaragd Groen',
      AppColorScheme.neonGreen => 'Neon Groen',
      AppColorScheme.forestGreen => 'Bos Groen',
      AppColorScheme.mintGreen => 'Mint Groen',
      AppColorScheme.blue => 'Blauw',
      AppColorScheme.purple => 'Paars',
      AppColorScheme.orange => 'Oranje',
    };
    
    return '$baseDescription - $colorDescription${state.glowEffects ? ' (Gloed)' : ''}';
  }

  /// Get color scheme name
  String get colorSchemeName {
    return switch (state.colorScheme) {
      AppColorScheme.defaultGreen => 'Standaard Groen',
      AppColorScheme.emeraldGreen => 'Smaragd Groen',
      AppColorScheme.neonGreen => 'Neon Groen',
      AppColorScheme.forestGreen => 'Bos Groen',
      AppColorScheme.mintGreen => 'Mint Groen',
      AppColorScheme.blue => 'Blauw',
      AppColorScheme.purple => 'Paars',
      AppColorScheme.orange => 'Oranje',
    };
  }

  /// Get appropriate icon for current theme
  IconData get themeIcon {
    switch (state.themeMode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  /// Get appropriate icon for color scheme
  IconData get colorSchemeIcon {
    return switch (state.colorScheme) {
      AppColorScheme.defaultGreen => Icons.palette,
      AppColorScheme.emeraldGreen => Icons.diamond,
      AppColorScheme.neonGreen => Icons.flash_on,
      AppColorScheme.forestGreen => Icons.forest,
      AppColorScheme.mintGreen => Icons.eco,
      AppColorScheme.blue => Icons.water_drop,
      AppColorScheme.purple => Icons.auto_awesome,
      AppColorScheme.orange => Icons.local_fire_department,
    };
  }
}

/// Theme provider
final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeState>(
  (ref) => ThemeNotifier(),
);

/// Convenience providers for specific theme properties
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeNotifierProvider).flutterThemeMode;
});

final colorSchemeProvider = Provider<AppColorScheme>((ref) {
  return ref.watch(themeNotifierProvider).colorScheme;
});

final isHighContrastProvider = Provider<bool>((ref) {
  return ref.watch(themeNotifierProvider).isHighContrast;
});

final glowEffectsProvider = Provider<bool>((ref) {
  return ref.watch(themeNotifierProvider).glowEffects;
});

final themeDescriptionProvider = Provider<String>((ref) {
  return ref.read(themeNotifierProvider.notifier).themeDescription;
});

final colorSchemeNameProvider = Provider<String>((ref) {
  return ref.read(themeNotifierProvider.notifier).colorSchemeName;
});

final themeIconProvider = Provider<IconData>((ref) {
  return ref.read(themeNotifierProvider.notifier).themeIcon;
});

final colorSchemeIconProvider = Provider<IconData>((ref) {
  return ref.read(themeNotifierProvider.notifier).colorSchemeIcon;
});
