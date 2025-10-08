import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../providers/theme_provider.dart';
import '../../utils/responsive_utils.dart';

/// Comprehensive design system for the Karate Flutter App
class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Enhanced color palette with modern, accessible colors
  static const Color _primaryGreen = Color(0xFF2E7D32);
  static const Color _primaryGreenDark = Color(0xFF1B5E20);
  static const Color _primaryGreenLight = Color(0xFF4CAF50);
  static const Color _primaryGreenAccent = Color(0xFF66BB6A);
  
  static const Color _secondaryOrange = Color(0xFFFF8F00);
  static const Color _secondaryOrangeDark = Color(0xFFE65100);
  static const Color _secondaryOrangeLight = Color(0xFFFFB74D);
  static const Color _secondaryOrangeAccent = Color(0xFFFFA726);
  
  static const Color _errorRed = Color(0xFFD32F2F);
  static const Color _warningAmber = Color(0xFFF57C00);
  static const Color _successGreen = Color(0xFF388E3C);
  static const Color _infoBlue = Color(0xFF1976D2);
  
  // Enhanced neutral colors with better contrast ratios
  static const Color _neutral900 = Color(0xFF0D1117);
  static const Color _neutral800 = Color(0xFF161B22);
  static const Color _neutral700 = Color(0xFF21262D);
  static const Color _neutral600 = Color(0xFF30363D);
  static const Color _neutral500 = Color(0xFF484F58);
  static const Color _neutral400 = Color(0xFF656D76);
  static const Color _neutral300 = Color(0xFF8B949E);
  static const Color _neutral200 = Color(0xFFB1BAC4);
  static const Color _neutral100 = Color(0xFFD0D7DE);
  static const Color _neutral50 = Color(0xFFF6F8FA);
  
  // Surface colors for better depth and hierarchy
  static const Color _surfaceLight = Color(0xFFFFFFFF);
  static const Color _surfaceLightVariant = Color(0xFFF8F9FA);
  static const Color _surfaceDark = Color(0xFF0D1117);
  static const Color _surfaceDarkVariant = Color(0xFF161B22);

  // Typography
  static const String _fontFamily = 'Roboto';
  static const String _dyslexiaFriendlyFontFamily = 'OpenDyslexic';
  
  static const TextStyle _displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );
  
  static const TextStyle _displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
  );
  
  static const TextStyle _displaySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );
  
  static const TextStyle _headlineLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.25,
  );
  
  static const TextStyle _headlineMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.29,
  );
  
  static const TextStyle _headlineSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.33,
  );
  
  static const TextStyle _titleLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.27,
  );
  
  static const TextStyle _titleMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.50,
  );
  
  static const TextStyle _titleSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  static const TextStyle _bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.50,
  );
  
  static const TextStyle _bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );
  
  static const TextStyle _bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );
  
  static const TextStyle _labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );
  
  static const TextStyle _labelMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );
  
  static const TextStyle _labelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // Spacing system
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing56 = 56.0;
  static const double spacing64 = 64.0;

  // Border radius
  static const double radiusSmall = 4.0;
  static const double radiusMedium = 8.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  static const double radiusRound = 50.0;

  // Elevation
  static const double elevation0 = 0.0;
  static const double elevation1 = 1.0;
  static const double elevation2 = 2.0;
  static const double elevation3 = 3.0;
  static const double elevation4 = 4.0;
  static const double elevation6 = 6.0;
  static const double elevation8 = 8.0;
  static const double elevation12 = 12.0;
  static const double elevation16 = 16.0;
  static const double elevation24 = 24.0;

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationExtraSlow = Duration(milliseconds: 800);

  // Responsive helper methods
  static EdgeInsets getResponsivePadding(BuildContext context, {double multiplier = 1.0}) {
    return ResponsiveUtils.responsivePadding(context) * multiplier;
  }

  static EdgeInsets getResponsiveMargin(BuildContext context, {double multiplier = 1.0}) {
    return ResponsiveUtils.responsiveMargin(context) * multiplier;
  }

  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    return ResponsiveUtils.responsiveFontSize(context, baseFontSize: baseFontSize);
  }

  static BorderRadius getResponsiveBorderRadius(BuildContext context, {double multiplier = 1.0}) {
    final radius = ResponsiveUtils.responsiveBorderRadius(context);
    return BorderRadius.circular(radius.topLeft.x * multiplier);
  }

  static double getResponsiveElevation(BuildContext context, {double baseElevation = 2.0}) {
    return ResponsiveUtils.responsiveElevation(context, baseElevation: baseElevation);
  }

  static double getResponsiveIconSize(BuildContext context, {double baseSize = 24.0}) {
    return ResponsiveUtils.responsiveIconSize(context, baseSize: baseSize);
  }

  // Color scheme palettes
  static const Map<AppColorScheme, Map<String, Color>> _colorPalettes = {
    AppColorScheme.defaultGreen: {
      'primary': _primaryGreen,
      'primaryDark': _primaryGreenDark,
      'primaryLight': _primaryGreenLight,
    },
    AppColorScheme.emeraldGreen: {
      'primary': Color(0xFF50C878),
      'primaryDark': Color(0xFF2E8B57),
      'primaryLight': Color(0xFF90EE90),
    },
    AppColorScheme.neonGreen: {
      'primary': Color(0xFF39FF14),
      'primaryDark': Color(0xFF32CD32),
      'primaryLight': Color(0xFF7FFF00),
    },
    AppColorScheme.forestGreen: {
      'primary': Color(0xFF228B22),
      'primaryDark': Color(0xFF006400),
      'primaryLight': Color(0xFF9ACD32),
    },
    AppColorScheme.mintGreen: {
      'primary': Color(0xFF98FB98),
      'primaryDark': Color(0xFF00FA9A),
      'primaryLight': Color(0xFFAFEEEE),
    },
    AppColorScheme.blue: {
      'primary': Color(0xFF2196F3),
      'primaryDark': Color(0xFF1976D2),
      'primaryLight': Color(0xFF64B5F6),
    },
    AppColorScheme.purple: {
      'primary': Color(0xFF9C27B0),
      'primaryDark': Color(0xFF7B1FA2),
      'primaryLight': Color(0xFFBA68C8),
    },
    AppColorScheme.orange: {
      'primary': _secondaryOrange,
      'primaryDark': _secondaryOrangeDark,
      'primaryLight': _secondaryOrangeLight,
    },
  };

  /// Get color palette for a specific color scheme
  static Map<String, Color> getColorPalette(AppColorScheme colorScheme) {
    return _colorPalettes[colorScheme] ?? _colorPalettes[AppColorScheme.defaultGreen]!;
  }

  /// Create glow effect decoration
  static BoxDecoration createGlowDecoration({
    required Color color,
    double blurRadius = 10.0,
    double spreadRadius = 2.0,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      borderRadius: borderRadius,
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.6),
          blurRadius: blurRadius,
          spreadRadius: spreadRadius,
          offset: const Offset(0, 0),
        ),
        BoxShadow(
          color: color.withValues(alpha: 0.3),
          blurRadius: blurRadius * 2,
          spreadRadius: spreadRadius * 2,
          offset: const Offset(0, 0),
        ),
      ],
    );
  }

  /// Create glow text style
  static TextStyle createGlowTextStyle({
    required TextStyle baseStyle,
    required Color glowColor,
    double blurRadius = 10.0,
  }) {
    return baseStyle.copyWith(
      shadows: [
        Shadow(
          color: glowColor.withValues(alpha: 0.8),
          blurRadius: blurRadius,
          offset: const Offset(0, 0),
        ),
        Shadow(
          color: glowColor.withValues(alpha: 0.4),
          blurRadius: blurRadius * 2,
          offset: const Offset(0, 0),
        ),
      ],
    );
  }

  /// Get the appropriate font family based on dyslexia-friendly setting
  static String _getFontFamily(bool isDyslexiaFriendly) {
    return isDyslexiaFriendly ? _dyslexiaFriendlyFontFamily : _fontFamily;
  }

  /// Generate theme data based on theme state with accessibility scaling
  static ThemeData getThemeData({
    required AppThemeMode themeMode,
    required AppColorScheme colorScheme,
    required bool isHighContrast,
    required bool glowEffects,
    required Brightness systemBrightness,
    double? fontScaleFactor,
    bool isDyslexiaFriendly = false,
  }) {
    // Determine effective brightness
    final Brightness effectiveBrightness = switch (themeMode) {
      AppThemeMode.light => Brightness.light,
      AppThemeMode.dark => Brightness.dark,
      AppThemeMode.system => systemBrightness,
    };

    // Handle high contrast themes first
    if (isHighContrast) {
      return effectiveBrightness == Brightness.light 
          ? highContrastLightTheme 
          : highContrastDarkTheme;
    }

    // Get color palette for the selected scheme
    final colorPalette = getColorPalette(colorScheme);
    final primary = colorPalette['primary']!;
    final primaryDark = colorPalette['primaryDark']!;
    final primaryLight = colorPalette['primaryLight']!;

    // Create custom color scheme
    final ColorScheme customColorScheme = effectiveBrightness == Brightness.light
        ? ColorScheme.light(
            brightness: Brightness.light,
            primary: primary,
            onPrimary: Colors.white,
            primaryContainer: primaryLight,
            onPrimaryContainer: _neutral900,
            secondary: _secondaryOrange,
            onSecondary: Colors.white,
            secondaryContainer: _secondaryOrangeLight,
            onSecondaryContainer: _neutral900,
            tertiary: _infoBlue,
            onTertiary: Colors.white,
            error: _errorRed,
            onError: Colors.white,
            errorContainer: const Color(0xFFFFDAD6),
            onErrorContainer: const Color(0xFF410002),
            surface: Colors.white,
            onSurface: _neutral900,
            surfaceContainerHighest: _neutral100,
            onSurfaceVariant: _neutral700,
            outline: _neutral400,
            outlineVariant: _neutral300,
            shadow: Colors.black,
            scrim: Colors.black,
            inverseSurface: _neutral800,
            onInverseSurface: _neutral100,
            inversePrimary: primaryLight,
            surfaceTint: primary,
          )
        : ColorScheme.dark(
            brightness: Brightness.dark,
            primary: primaryLight,
            onPrimary: _neutral900,
            primaryContainer: primaryDark,
            onPrimaryContainer: primaryLight,
            secondary: _secondaryOrangeLight,
            onSecondary: _neutral900,
            secondaryContainer: _secondaryOrangeDark,
            onSecondaryContainer: _secondaryOrangeLight,
            tertiary: const Color(0xFF90CAF9),
            onTertiary: _neutral900,
            error: const Color(0xFFFFB4AB),
            onError: const Color(0xFF690005),
            errorContainer: const Color(0xFF93000A),
            onErrorContainer: const Color(0xFFFFDAD6),
            surface: const Color(0xFF000000),
            onSurface: _neutral100,
            surfaceContainerHighest: _neutral800,
            onSurfaceVariant: _neutral400,
            outline: _neutral600,
            outlineVariant: _neutral700,
            shadow: Colors.black,
            scrim: Colors.black,
            inverseSurface: _neutral100,
            onInverseSurface: _neutral800,
            inversePrimary: primary,
            surfaceTint: primaryLight,
          );

    // Build base theme with accessibility scaling
    ThemeData baseTheme = _buildThemeFromColorScheme(
      customColorScheme, 
      fontScaleFactor: fontScaleFactor,
      isDyslexiaFriendly: isDyslexiaFriendly,
      context: null, // Context will be passed when theme is applied
    );

    // Apply glow effects if enabled
    if (glowEffects) {
      baseTheme = _applyGlowEffects(baseTheme, primary);
    }

    return baseTheme;
  }

  /// Create scaled text style based on font scale factor with system integration
  static TextStyle _createScaledTextStyle(TextStyle baseStyle, double? fontScaleFactor, BuildContext? context) {
    if (fontScaleFactor == null || fontScaleFactor == 1.0) {
      // Still check for system dynamic type even if user scaling is disabled
      if (context != null) {
        final systemScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
        if (systemScaleFactor > 1.0) {
          return baseStyle.copyWith(
            fontSize: (baseStyle.fontSize ?? 14) * systemScaleFactor.clamp(1.0, 2.0),
          );
        }
      }
      return baseStyle;
    }
    
    // Combine user preference with system scaling if context is available
    double effectiveScaleFactor = fontScaleFactor;
    if (context != null) {
      final systemScaleFactor = MediaQuery.textScalerOf(context).scale(1.0);
      effectiveScaleFactor = (fontScaleFactor * systemScaleFactor).clamp(0.5, 3.0);
    }
    
    return baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * effectiveScaleFactor,
    );
  }

  /// Create text style with appropriate font family
  static TextStyle _createTextStyleWithFont(TextStyle baseStyle, bool isDyslexiaFriendly) {
    return baseStyle.copyWith(
      fontFamily: _getFontFamily(isDyslexiaFriendly),
    );
  }

  /// Build theme from color scheme with accessibility scaling
  static ThemeData _buildThemeFromColorScheme(
    ColorScheme colorScheme, {
    double? fontScaleFactor,
    bool isDyslexiaFriendly = false,
    BuildContext? context,
  }) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: _getFontFamily(isDyslexiaFriendly),
      scaffoldBackgroundColor: colorScheme.surface,
      
      // Typography with accessibility scaling and dyslexia-friendly font
      textTheme: TextTheme(
        displayLarge: _createScaledTextStyle(_createTextStyleWithFont(_displayLarge.copyWith(color: colorScheme.onSurface), isDyslexiaFriendly), fontScaleFactor, context),
        displayMedium: _createScaledTextStyle(_createTextStyleWithFont(_displayMedium.copyWith(color: colorScheme.onSurface), isDyslexiaFriendly), fontScaleFactor, context),
        displaySmall: _createScaledTextStyle(_createTextStyleWithFont(_displaySmall.copyWith(color: colorScheme.onSurface), isDyslexiaFriendly), fontScaleFactor, context),
        headlineLarge: _createScaledTextStyle(_createTextStyleWithFont(_headlineLarge.copyWith(color: colorScheme.onSurface), isDyslexiaFriendly), fontScaleFactor, context),
        headlineMedium: _createScaledTextStyle(_createTextStyleWithFont(_headlineMedium.copyWith(color: colorScheme.onSurface), isDyslexiaFriendly), fontScaleFactor, context),
        headlineSmall: _createScaledTextStyle(_createTextStyleWithFont(_headlineSmall.copyWith(color: colorScheme.onSurface), isDyslexiaFriendly), fontScaleFactor, context),
        titleLarge: _createScaledTextStyle(_createTextStyleWithFont(_titleLarge.copyWith(color: colorScheme.onSurface), isDyslexiaFriendly), fontScaleFactor, context),
        titleMedium: _createScaledTextStyle(_createTextStyleWithFont(_titleMedium.copyWith(color: colorScheme.onSurface), isDyslexiaFriendly), fontScaleFactor, context),
        titleSmall: _createScaledTextStyle(_createTextStyleWithFont(_titleSmall.copyWith(color: colorScheme.onSurface), isDyslexiaFriendly), fontScaleFactor, context),
        bodyLarge: _createScaledTextStyle(_createTextStyleWithFont(_bodyLarge.copyWith(color: colorScheme.onSurface), isDyslexiaFriendly), fontScaleFactor, context),
        bodyMedium: _createScaledTextStyle(_createTextStyleWithFont(_bodyMedium.copyWith(color: colorScheme.onSurface), isDyslexiaFriendly), fontScaleFactor, context),
        bodySmall: _createScaledTextStyle(_createTextStyleWithFont(_bodySmall.copyWith(color: colorScheme.onSurface), isDyslexiaFriendly), fontScaleFactor, context),
        labelLarge: _createScaledTextStyle(_createTextStyleWithFont(_labelLarge.copyWith(color: colorScheme.onSurface), isDyslexiaFriendly), fontScaleFactor, context),
        labelMedium: _createScaledTextStyle(_createTextStyleWithFont(_labelMedium.copyWith(color: colorScheme.onSurface), isDyslexiaFriendly), fontScaleFactor, context),
        labelSmall: _createScaledTextStyle(_createTextStyleWithFont(_labelSmall.copyWith(color: colorScheme.onSurface), isDyslexiaFriendly), fontScaleFactor, context),
      ),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        elevation: elevation0,
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.surfaceTint,
        titleTextStyle: _titleLarge.copyWith(color: colorScheme.onSurface),
        systemOverlayStyle: colorScheme.brightness == Brightness.light 
            ? SystemUiOverlayStyle.dark 
            : SystemUiOverlayStyle.light,
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: elevation2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        color: colorScheme.brightness == Brightness.dark 
            ? const Color(0xFF1B4332) // Dark green color for cards in dark theme
            : colorScheme.surface, // Default surface color for light theme
        surfaceTintColor: colorScheme.surfaceTint,
        margin: const EdgeInsets.all(spacing8),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: elevation2,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          textStyle: _labelLarge,
          minimumSize: const Size(64, 44),
        ),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: elevation6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: elevation8,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        selectedLabelStyle: _labelSmall,
        unselectedLabelStyle: _labelSmall,
      ),
    );
  }

  /// Apply glow effects to theme
  static ThemeData _applyGlowEffects(ThemeData baseTheme, Color glowColor) {
    return baseTheme.copyWith(
      // Enhanced elevated button with glow
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: baseTheme.elevatedButtonTheme.style?.copyWith(
          elevation: WidgetStateProperty.all(elevation6),
          shadowColor: WidgetStateProperty.all(glowColor.withValues(alpha: 0.5)),
        ),
      ),
      
      // Enhanced floating action button with glow
      floatingActionButtonTheme: baseTheme.floatingActionButtonTheme.copyWith(
        elevation: elevation8,
      ),
      
      // Enhanced card theme with subtle glow
      cardTheme: baseTheme.cardTheme.copyWith(
        elevation: elevation4,
        shadowColor: glowColor.withValues(alpha: 0.2),
      ),
    );
  }

  // Light theme
  static ThemeData get lightTheme {
    const ColorScheme colorScheme = ColorScheme.light(
      brightness: Brightness.light,
      primary: _primaryGreen,
      onPrimary: Colors.white,
      primaryContainer: _primaryGreenLight,
      onPrimaryContainer: _neutral900,
      secondary: _secondaryOrange,
      onSecondary: Colors.white,
      secondaryContainer: _secondaryOrangeLight,
      onSecondaryContainer: _neutral900,
      tertiary: _infoBlue,
      onTertiary: Colors.white,
      error: _errorRed,
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: Colors.white,
      onSurface: _neutral900,
      surfaceContainerHighest: _neutral100,
      onSurfaceVariant: _neutral700,
      outline: _neutral400,
      outlineVariant: _neutral300,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: _neutral800,
      onInverseSurface: _neutral100,
      inversePrimary: _primaryGreenLight,
      surfaceTint: _primaryGreen,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: _fontFamily,
      
      // Typography
      textTheme: TextTheme(
        displayLarge: _displayLarge.copyWith(color: colorScheme.onSurface),
        displayMedium: _displayMedium.copyWith(color: colorScheme.onSurface),
        displaySmall: _displaySmall.copyWith(color: colorScheme.onSurface),
        headlineLarge: _headlineLarge.copyWith(color: colorScheme.onSurface),
        headlineMedium: _headlineMedium.copyWith(color: colorScheme.onSurface),
        headlineSmall: _headlineSmall.copyWith(color: colorScheme.onSurface),
        titleLarge: _titleLarge.copyWith(color: colorScheme.onSurface),
        titleMedium: _titleMedium.copyWith(color: colorScheme.onSurface),
        titleSmall: _titleSmall.copyWith(color: colorScheme.onSurface),
        bodyLarge: _bodyLarge.copyWith(color: colorScheme.onSurface),
        bodyMedium: _bodyMedium.copyWith(color: colorScheme.onSurface),
        bodySmall: _bodySmall.copyWith(color: colorScheme.onSurface),
        labelLarge: _labelLarge.copyWith(color: colorScheme.onSurface),
        labelMedium: _labelMedium.copyWith(color: colorScheme.onSurface),
        labelSmall: _labelSmall.copyWith(color: colorScheme.onSurface),
      ),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        elevation: elevation0,
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.surfaceTint,
        titleTextStyle: _titleLarge.copyWith(color: colorScheme.onSurface),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: elevation2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        color: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        margin: const EdgeInsets.all(spacing8),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: elevation2,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          textStyle: _labelLarge,
          minimumSize: const Size(64, 44), // Accessibility minimum touch target
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          textStyle: _labelLarge,
          minimumSize: const Size(64, 44), // Accessibility minimum touch target
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spacing16,
            vertical: spacing8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: _labelLarge,
          minimumSize: const Size(64, 44), // Accessibility minimum touch target
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing12,
        ),
        labelStyle: _bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
        hintStyle: _bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: elevation6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: elevation8,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        selectedLabelStyle: _labelSmall,
        unselectedLabelStyle: _labelSmall,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        deleteIconColor: colorScheme.onSurfaceVariant,
        disabledColor: colorScheme.onSurface.withValues(alpha: 0.12),
        selectedColor: colorScheme.secondaryContainer,
        secondarySelectedColor: colorScheme.secondaryContainer,
        shadowColor: colorScheme.shadow,
        surfaceTintColor: colorScheme.surfaceTint,
        labelStyle: _labelMedium,
        secondaryLabelStyle: _labelMedium,
        brightness: Brightness.light,
        elevation: elevation1,
        pressElevation: elevation2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        elevation: elevation24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        titleTextStyle: _headlineSmall.copyWith(color: colorScheme.onSurface),
        contentTextStyle: _bodyMedium.copyWith(color: colorScheme.onSurface),
      ),
      
      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: _bodyMedium.copyWith(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: elevation6,
      ),
      
      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing8,
        ),
        minVerticalPadding: spacing8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        titleTextStyle: _bodyLarge.copyWith(color: colorScheme.onSurface),
        subtitleTextStyle: _bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
        leadingAndTrailingTextStyle: _labelMedium.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: spacing16,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurfaceVariant;
        }),
      ),
    );
  }

  // Dark theme
  static ThemeData get darkTheme {
    const ColorScheme colorScheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: _primaryGreenLight,
      onPrimary: _neutral900,
      primaryContainer: _primaryGreenDark,
      onPrimaryContainer: _primaryGreenLight,
      secondary: _secondaryOrangeLight,
      onSecondary: _neutral900,
      secondaryContainer: _secondaryOrangeDark,
      onSecondaryContainer: _secondaryOrangeLight,
      tertiary: Color(0xFF90CAF9),
      onTertiary: _neutral900,
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF000000),
      onSurface: _neutral100,
      surfaceContainerHighest: _neutral800,
      onSurfaceVariant: _neutral400,
      outline: _neutral600,
      outlineVariant: _neutral700,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: _neutral100,
      onInverseSurface: _neutral800,
      inversePrimary: _primaryGreen,
      surfaceTint: _primaryGreenLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: Colors.black,
      
      // Typography
      textTheme: TextTheme(
        displayLarge: _displayLarge.copyWith(color: colorScheme.onSurface),
        displayMedium: _displayMedium.copyWith(color: colorScheme.onSurface),
        displaySmall: _displaySmall.copyWith(color: colorScheme.onSurface),
        headlineLarge: _headlineLarge.copyWith(color: colorScheme.onSurface),
        headlineMedium: _headlineMedium.copyWith(color: colorScheme.onSurface),
        headlineSmall: _headlineSmall.copyWith(color: colorScheme.onSurface),
        titleLarge: _titleLarge.copyWith(color: colorScheme.onSurface),
        titleMedium: _titleMedium.copyWith(color: colorScheme.onSurface),
        titleSmall: _titleSmall.copyWith(color: colorScheme.onSurface),
        bodyLarge: _bodyLarge.copyWith(color: colorScheme.onSurface),
        bodyMedium: _bodyMedium.copyWith(color: colorScheme.onSurface),
        bodySmall: _bodySmall.copyWith(color: colorScheme.onSurface),
        labelLarge: _labelLarge.copyWith(color: colorScheme.onSurface),
        labelMedium: _labelMedium.copyWith(color: colorScheme.onSurface),
        labelSmall: _labelSmall.copyWith(color: colorScheme.onSurface),
      ),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        elevation: elevation0,
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.surfaceTint,
        titleTextStyle: _titleLarge.copyWith(color: colorScheme.onSurface),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: elevation2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
        color: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        margin: const EdgeInsets.all(spacing8),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: elevation2,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          textStyle: _labelLarge,
          minimumSize: const Size(64, 44), // Accessibility minimum touch target
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusLarge),
          ),
          textStyle: _labelLarge,
          minimumSize: const Size(64, 44), // Accessibility minimum touch target
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spacing16,
            vertical: spacing8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          textStyle: _labelLarge,
          minimumSize: const Size(64, 44), // Accessibility minimum touch target
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing12,
        ),
        labelStyle: _bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
        hintStyle: _bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: elevation6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: elevation8,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        selectedLabelStyle: _labelSmall,
        unselectedLabelStyle: _labelSmall,
      ),
      
      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        deleteIconColor: colorScheme.onSurfaceVariant,
        disabledColor: colorScheme.onSurface.withValues(alpha: 0.12),
        selectedColor: colorScheme.secondaryContainer,
        secondarySelectedColor: colorScheme.secondaryContainer,
        shadowColor: colorScheme.shadow,
        surfaceTintColor: colorScheme.surfaceTint,
        labelStyle: _labelMedium,
        secondaryLabelStyle: _labelMedium,
        brightness: Brightness.dark,
        elevation: elevation1,
        pressElevation: elevation2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        elevation: elevation24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        titleTextStyle: _headlineSmall.copyWith(color: colorScheme.onSurface),
        contentTextStyle: _bodyMedium.copyWith(color: colorScheme.onSurface),
      ),
      
      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: _bodyMedium.copyWith(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: elevation6,
      ),
      
      // List Tile Theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing16,
          vertical: spacing8,
        ),
        minVerticalPadding: spacing8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        titleTextStyle: _bodyLarge.copyWith(color: colorScheme.onSurface),
        subtitleTextStyle: _bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
        leadingAndTrailingTextStyle: _labelMedium.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: spacing16,
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.onPrimary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(colorScheme.onPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSmall),
        ),
      ),
      
      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.onSurfaceVariant;
        }),
      ),
    );
  }

  // High contrast theme for accessibility
  static ThemeData get highContrastLightTheme {
    const ColorScheme colorScheme = ColorScheme.light(
      brightness: Brightness.light,
      primary: Colors.black,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFF000000),
      onPrimaryContainer: Colors.white,
      secondary: Color(0xFF000000),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF000000),
      onSecondaryContainer: Colors.white,
      tertiary: Color(0xFF000000),
      onTertiary: Colors.white,
      error: Color(0xFFD32F2F),
      onError: Colors.white,
      errorContainer: Color(0xFFFFEBEE),
      onErrorContainer: Color(0xFFD32F2F),
      surface: Colors.white,
      onSurface: Colors.black,
      surfaceContainerHighest: Color(0xFFF5F5F5),
      onSurfaceVariant: Colors.black,
      outline: Colors.black,
      outlineVariant: Colors.black,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Colors.black,
      onInverseSurface: Colors.white,
      inversePrimary: Colors.white,
      surfaceTint: Colors.black,
    );

    return lightTheme.copyWith(
      colorScheme: colorScheme,
      // Override specific themes for high contrast
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: elevation4,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16, // Larger touch targets
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
            side: const BorderSide(color: Colors.black, width: 2),
          ),
          textStyle: _labelLarge.copyWith(fontWeight: FontWeight.bold),
          minimumSize: const Size(88, 48), // Larger minimum size for accessibility
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          side: const BorderSide(color: Colors.black, width: 3),
          textStyle: _labelLarge.copyWith(fontWeight: FontWeight.bold),
          minimumSize: const Size(88, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: Colors.black, width: 3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: Colors.black, width: 3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: Colors.black, width: 4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 3),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing20,
          vertical: spacing16,
        ),
        labelStyle: _bodyMedium.copyWith(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        hintStyle: _bodyMedium.copyWith(
          color: Colors.black54,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // High contrast dark theme for accessibility
  static ThemeData get highContrastDarkTheme {
    const ColorScheme colorScheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: Colors.white,
      onPrimary: Colors.black,
      primaryContainer: Colors.white,
      onPrimaryContainer: Colors.black,
      secondary: Colors.white,
      onSecondary: Colors.black,
      secondaryContainer: Colors.white,
      onSecondaryContainer: Colors.black,
      tertiary: Colors.white,
      onTertiary: Colors.black,
      error: Color(0xFFFF5252),
      onError: Colors.black,
      errorContainer: Color(0xFFFF5252),
      onErrorContainer: Colors.black,
      surface: Colors.black,
      onSurface: Colors.white,
      surfaceContainerHighest: Color(0xFF1A1A1A),
      onSurfaceVariant: Colors.white,
      outline: Colors.white,
      outlineVariant: Colors.white,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Colors.white,
      onInverseSurface: Colors.black,
      inversePrimary: Colors.black,
      surfaceTint: Colors.white,
    );

    return darkTheme.copyWith(
      colorScheme: colorScheme,
      // Override specific themes for high contrast
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: elevation4,
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
          textStyle: _labelLarge.copyWith(fontWeight: FontWeight.bold),
          minimumSize: const Size(88, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spacing24,
            vertical: spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
          side: const BorderSide(color: Colors.white, width: 3),
          textStyle: _labelLarge.copyWith(fontWeight: FontWeight.bold),
          minimumSize: const Size(88, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: Colors.white, width: 3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: Colors.white, width: 3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: Colors.white, width: 4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: Color(0xFFFF5252), width: 3),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: Color(0xFFFF5252), width: 4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spacing20,
          vertical: spacing16,
        ),
        labelStyle: _bodyMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        hintStyle: _bodyMedium.copyWith(
          color: Colors.white70,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
