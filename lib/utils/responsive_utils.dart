import 'package:flutter/material.dart';

/// Responsive utility class for handling different screen sizes and orientations
class ResponsiveUtils {
  // Private constructor to prevent instantiation
  ResponsiveUtils._();

  // Breakpoints based on Material Design guidelines
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;
  
  // Foldable device breakpoints
  static const double foldableBreakpoint = 840;
  static const double largeFoldableBreakpoint = 1000;

  // Screen size categories
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  // Foldable device detection
  static bool isFoldable(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= foldableBreakpoint && width < largeFoldableBreakpoint;
  }

  static bool isLargeFoldable(BuildContext context) {
    return MediaQuery.of(context).size.width >= largeFoldableBreakpoint;
  }

  // Check if device is in dual-screen mode (foldable unfolded)
  static bool isDualScreen(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.width >= foldableBreakpoint && 
           mediaQuery.size.width > 600; // Simplified check for dual screen
  }

  // Screen size enum for easier handling
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return ScreenSize.mobile;
    if (width < foldableBreakpoint) return ScreenSize.tablet;
    if (width < largeFoldableBreakpoint) return ScreenSize.foldable;
    if (width < tabletBreakpoint) return ScreenSize.largeFoldable;
    if (width < desktopBreakpoint) return ScreenSize.desktop;
    return ScreenSize.largeDesktop;
  }

  // Responsive values based on screen size
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? foldable,
    T? largeFoldable,
    T? desktop,
    T? largeDesktop,
  }) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.foldable:
        return foldable ?? tablet ?? mobile;
      case ScreenSize.largeFoldable:
        return largeFoldable ?? foldable ?? tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? largeFoldable ?? foldable ?? tablet ?? mobile;
      case ScreenSize.largeDesktop:
        return largeDesktop ?? desktop ?? largeFoldable ?? foldable ?? tablet ?? mobile;
    }
  }

  // Responsive padding with landscape optimization
  static EdgeInsets responsivePadding(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isMobileLandscape = isMobile(context) && isLandscape;
    
    return EdgeInsets.symmetric(
      horizontal: responsiveValue(
        context,
        mobile: isMobileLandscape ? 12.0 : 16.0,
        tablet: 24.0,
        foldable: 20.0,
        largeFoldable: 28.0,
        desktop: 32.0,
        largeDesktop: 48.0,
      ),
      vertical: responsiveValue(
        context,
        mobile: isMobileLandscape ? 4.0 : 8.0,
        tablet: 12.0,
        foldable: 8.0,
        largeFoldable: 12.0,
        desktop: 16.0,
        largeDesktop: 20.0,
      ),
    );
  }

  // Responsive margin
  static EdgeInsets responsiveMargin(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: responsiveValue(
        context,
        mobile: 8.0,
        tablet: 16.0,
        desktop: 24.0,
        largeDesktop: 32.0,
      ),
      vertical: responsiveValue(
        context,
        mobile: 4.0,
        tablet: 8.0,
        desktop: 12.0,
        largeDesktop: 16.0,
      ),
    );
  }

  // Responsive font sizes
  static double responsiveFontSize(
    BuildContext context, {
    required double baseFontSize,
    double? mobileScale,
    double? tabletScale,
    double? desktopScale,
  }) {
    final scale = responsiveValue(
      context,
      mobile: mobileScale ?? 1.0,
      tablet: tabletScale ?? 1.1,
      desktop: desktopScale ?? 1.2,
      largeDesktop: 1.3,
    );
    return baseFontSize * scale;
  }

  // Grid column count based on screen size with landscape optimization
  static int getGridColumns(BuildContext context, {int? maxColumns}) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isMobileLandscape = isMobile(context) && isLandscape;
    
    final columns = responsiveValue(
      context,
      mobile: isMobileLandscape ? 2 : 1,
      tablet: isLandscape ? 3 : 2,
      foldable: 2,
      largeFoldable: 3,
      desktop: 3,
      largeDesktop: 4,
    );
    return maxColumns != null ? columns.clamp(1, maxColumns) : columns;
  }

  // Maximum content width for better readability with foldable support
  static double getMaxContentWidth(BuildContext context) {
    final isDualScreenDevice = isDualScreen(context);
    
    return responsiveValue(
      context,
      mobile: double.infinity,
      tablet: 800.0,
      foldable: isDualScreenDevice ? 600.0 : 700.0,
      largeFoldable: isDualScreenDevice ? 800.0 : 900.0,
      desktop: 1000.0,
      largeDesktop: 1200.0,
    );
  }

  // Responsive card width with landscape optimization
  static double getCardWidth(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isMobileLandscape = isMobile(context) && isLandscape;
    
    return responsiveValue(
      context,
      mobile: isMobileLandscape ? 200.0 : double.infinity,
      tablet: isLandscape ? 300.0 : 350.0,
      foldable: 320.0,
      largeFoldable: 380.0,
      desktop: 400.0,
      largeDesktop: 450.0,
    );
  }

  // Responsive spacing with landscape optimization
  static double getSpacing(BuildContext context, SpacingSize size) {
    final multiplier = switch (size) {
      SpacingSize.xs => 0.25,
      SpacingSize.sm => 0.5,
      SpacingSize.md => 1.0,
      SpacingSize.lg => 1.5,
      SpacingSize.xl => 2.0,
      SpacingSize.xxl => 3.0,
    };

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isMobileLandscape = isMobile(context) && isLandscape;

    final baseSpacing = responsiveValue(
      context,
      mobile: isMobileLandscape ? 12.0 : 16.0,
      tablet: isLandscape ? 16.0 : 20.0,
      foldable: 18.0,
      largeFoldable: 22.0,
      desktop: 24.0,
      largeDesktop: 28.0,
    );

    return baseSpacing * multiplier;
  }

  // Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // Check if device is in portrait mode
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  // Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  // Get keyboard height
  static double getKeyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  // Check if keyboard is visible
  static bool isKeyboardVisible(BuildContext context) {
    return getKeyboardHeight(context) > 0;
  }

  // Responsive border radius
  static BorderRadius responsiveBorderRadius(BuildContext context) {
    final radius = responsiveValue(
      context,
      mobile: 8.0,
      tablet: 10.0,
      desktop: 12.0,
      largeDesktop: 14.0,
    );
    return BorderRadius.circular(radius);
  }

  // Responsive elevation
  static double responsiveElevation(BuildContext context, {double baseElevation = 2.0}) {
    final multiplier = responsiveValue(
      context,
      mobile: 1.0,
      tablet: 1.2,
      desktop: 1.4,
      largeDesktop: 1.6,
    );
    return baseElevation * multiplier;
  }

  // Responsive icon size
  static double responsiveIconSize(BuildContext context, {double baseSize = 24.0}) {
    final multiplier = responsiveValue(
      context,
      mobile: 1.0,
      tablet: 1.1,
      desktop: 1.2,
      largeDesktop: 1.3,
    );
    return baseSize * multiplier;
  }

  // Responsive button height
  static double responsiveButtonHeight(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 48.0,
      tablet: 52.0,
      desktop: 56.0,
      largeDesktop: 60.0,
    );
  }

  // Responsive app bar height
  static double responsiveAppBarHeight(BuildContext context) {
    return responsiveValue(
      context,
      mobile: kToolbarHeight,
      tablet: kToolbarHeight + 8.0,
      desktop: kToolbarHeight + 16.0,
      largeDesktop: kToolbarHeight + 24.0,
    );
  }

  // Get responsive constraints for dialogs and modals
  static BoxConstraints getDialogConstraints(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return BoxConstraints(
      maxWidth: responsiveValue(
        context,
        mobile: screenSize.width * 0.9,
        tablet: 500.0,
        desktop: 600.0,
        largeDesktop: 700.0,
      ),
      maxHeight: screenSize.height * 0.8,
    );
  }

  // Responsive list tile height
  static double responsiveListTileHeight(BuildContext context) {
    return responsiveValue(
      context,
      mobile: 56.0,
      tablet: 64.0,
      foldable: 60.0,
      largeFoldable: 68.0,
      desktop: 72.0,
      largeDesktop: 80.0,
    );
  }

  // Dynamic type scaling integration with system settings
  static double getSystemTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor;
  }

  // Get device pixel ratio for responsive images
  static double getDevicePixelRatio(BuildContext context) {
    return MediaQuery.of(context).devicePixelRatio;
  }

  // Get screen density category
  static ScreenDensity getScreenDensity(BuildContext context) {
    final pixelRatio = getDevicePixelRatio(context);
    if (pixelRatio <= 1.0) return ScreenDensity.low;
    if (pixelRatio <= 2.0) return ScreenDensity.medium;
    if (pixelRatio <= 3.0) return ScreenDensity.high;
    return ScreenDensity.extraHigh;
  }

  // Get appropriate image size based on screen density
  static String getImageSizeSuffix(BuildContext context) {
    final density = getScreenDensity(context);
    switch (density) {
      case ScreenDensity.low:
        return '1x';
      case ScreenDensity.medium:
        return '2x';
      case ScreenDensity.high:
        return '3x';
      case ScreenDensity.extraHigh:
        return '4x';
    }
  }

  // Get responsive image dimensions based on screen size and density
  static Size getResponsiveImageSize(BuildContext context, {Size? baseSize}) {
    final base = baseSize ?? const Size(200, 200);
    final density = getScreenDensity(context);
    final isLandscapeMode = isLandscape(context);
    
    double widthMultiplier = 1.0;
    double heightMultiplier = 1.0;
    
    // Adjust for screen density
    switch (density) {
      case ScreenDensity.low:
        widthMultiplier = 0.8;
        heightMultiplier = 0.8;
        break;
      case ScreenDensity.medium:
        widthMultiplier = 1.0;
        heightMultiplier = 1.0;
        break;
      case ScreenDensity.high:
        widthMultiplier = 1.2;
        heightMultiplier = 1.2;
        break;
      case ScreenDensity.extraHigh:
        widthMultiplier = 1.5;
        heightMultiplier = 1.5;
        break;
    }
    
    // Adjust for landscape orientation
    if (isLandscapeMode && isMobile(context)) {
      widthMultiplier *= 0.8;
      heightMultiplier *= 0.6;
    }
    
    return Size(
      base.width * widthMultiplier,
      base.height * heightMultiplier,
    );
  }

  // Get foldable hinge information (simplified)
  static HingeInfo? getHingeInfo(BuildContext context) {
    // Simplified implementation - just check if device is foldable
    if (isFoldable(context) || isLargeFoldable(context)) {
      return HingeInfo(
        bounds: Rect.zero,
        state: HingeState.unknown,
      );
    }
    return null;
  }

  // Check if content should be split across foldable screens
  static bool shouldSplitContent(BuildContext context) {
    // Simplified implementation - split content on large foldable devices in landscape
    return isLandscape(context) && 
           MediaQuery.of(context).size.width > foldableBreakpoint &&
           (isFoldable(context) || isLargeFoldable(context));
  }
}

// Enums for better type safety
enum ScreenSize {
  mobile,
  tablet,
  foldable,
  largeFoldable,
  desktop,
  largeDesktop,
}

enum SpacingSize {
  xs,
  sm,
  md,
  lg,
  xl,
  xxl,
}

enum ScreenDensity {
  low,
  medium,
  high,
  extraHigh,
}

// Hinge information for foldable devices
class HingeInfo {
  final Rect bounds;
  final HingeState state;

  const HingeInfo({
    required this.bounds,
    required this.state,
  });
}

// Simplified hinge state enum
enum HingeState {
  unknown,
  closed,
  halfOpened,
  opened,
}

// Extension methods for easier usage
extension ResponsiveContext on BuildContext {
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  bool get isLargeDesktop => ResponsiveUtils.isLargeDesktop(this);
  bool get isFoldable => ResponsiveUtils.isFoldable(this);
  bool get isLargeFoldable => ResponsiveUtils.isLargeFoldable(this);
  bool get isDualScreen => ResponsiveUtils.isDualScreen(this);
  bool get isLandscape => ResponsiveUtils.isLandscape(this);
  bool get isPortrait => ResponsiveUtils.isPortrait(this);
  bool get isKeyboardVisible => ResponsiveUtils.isKeyboardVisible(this);
  bool get shouldSplitContent => ResponsiveUtils.shouldSplitContent(this);
  
  ScreenSize get screenSize => ResponsiveUtils.getScreenSize(this);
  ScreenDensity get screenDensity => ResponsiveUtils.getScreenDensity(this);
  double get systemTextScaleFactor => ResponsiveUtils.getSystemTextScaleFactor(this);
  double get devicePixelRatio => ResponsiveUtils.getDevicePixelRatio(this);
  String get imageSizeSuffix => ResponsiveUtils.getImageSizeSuffix(this);
  HingeInfo? get hingeInfo => ResponsiveUtils.getHingeInfo(this);
  
  EdgeInsets get responsivePadding => ResponsiveUtils.responsivePadding(this);
  EdgeInsets get responsiveMargin => ResponsiveUtils.responsiveMargin(this);
  EdgeInsets get safeAreaPadding => ResponsiveUtils.getSafeAreaPadding(this);
  
  double responsiveSpacing(SpacingSize size) => ResponsiveUtils.getSpacing(this, size);
  double get maxContentWidth => ResponsiveUtils.getMaxContentWidth(this);
  double get cardWidth => ResponsiveUtils.getCardWidth(this);
  BorderRadius get responsiveBorderRadius => ResponsiveUtils.responsiveBorderRadius(this);
  BoxConstraints get dialogConstraints => ResponsiveUtils.getDialogConstraints(this);
  Size getResponsiveImageSize({Size? baseSize}) => ResponsiveUtils.getResponsiveImageSize(this, baseSize: baseSize);
  
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? foldable,
    T? largeFoldable,
    T? desktop,
    T? largeDesktop,
  }) => ResponsiveUtils.responsiveValue(
    this,
    mobile: mobile,
    tablet: tablet,
    foldable: foldable,
    largeFoldable: largeFoldable,
    desktop: desktop,
    largeDesktop: largeDesktop,
  );
}
