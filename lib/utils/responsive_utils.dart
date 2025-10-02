import 'package:flutter/material.dart';

/// Responsive utility class for handling different screen sizes and orientations
class ResponsiveUtils {
  // Private constructor to prevent instantiation
  ResponsiveUtils._();

  // Breakpoints based on Material Design guidelines
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

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

  // Screen size enum for easier handling
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobileBreakpoint) return ScreenSize.mobile;
    if (width < tabletBreakpoint) return ScreenSize.tablet;
    if (width < desktopBreakpoint) return ScreenSize.desktop;
    return ScreenSize.largeDesktop;
  }

  // Responsive values based on screen size
  static T responsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    final screenSize = getScreenSize(context);
    switch (screenSize) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet ?? mobile;
      case ScreenSize.desktop:
        return desktop ?? tablet ?? mobile;
      case ScreenSize.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }

  // Responsive padding
  static EdgeInsets responsivePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: responsiveValue(
        context,
        mobile: 16.0,
        tablet: 24.0,
        desktop: 32.0,
        largeDesktop: 48.0,
      ),
      vertical: responsiveValue(
        context,
        mobile: 8.0,
        tablet: 12.0,
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

  // Grid column count based on screen size
  static int getGridColumns(BuildContext context, {int? maxColumns}) {
    final columns = responsiveValue(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
      largeDesktop: 4,
    );
    return maxColumns != null ? columns.clamp(1, maxColumns) : columns;
  }

  // Maximum content width for better readability
  static double getMaxContentWidth(BuildContext context) {
    return responsiveValue(
      context,
      mobile: double.infinity,
      tablet: 800.0,
      desktop: 1000.0,
      largeDesktop: 1200.0,
    );
  }

  // Responsive card width
  static double getCardWidth(BuildContext context) {
    return responsiveValue(
      context,
      mobile: double.infinity,
      tablet: 350.0,
      desktop: 400.0,
      largeDesktop: 450.0,
    );
  }

  // Responsive spacing
  static double getSpacing(BuildContext context, SpacingSize size) {
    final multiplier = switch (size) {
      SpacingSize.xs => 0.25,
      SpacingSize.sm => 0.5,
      SpacingSize.md => 1.0,
      SpacingSize.lg => 1.5,
      SpacingSize.xl => 2.0,
      SpacingSize.xxl => 3.0,
    };

    final baseSpacing = responsiveValue(
      context,
      mobile: 16.0,
      tablet: 20.0,
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
      desktop: 72.0,
      largeDesktop: 80.0,
    );
  }
}

// Enums for better type safety
enum ScreenSize {
  mobile,
  tablet,
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

// Extension methods for easier usage
extension ResponsiveContext on BuildContext {
  bool get isMobile => ResponsiveUtils.isMobile(this);
  bool get isTablet => ResponsiveUtils.isTablet(this);
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  bool get isLargeDesktop => ResponsiveUtils.isLargeDesktop(this);
  bool get isLandscape => ResponsiveUtils.isLandscape(this);
  bool get isPortrait => ResponsiveUtils.isPortrait(this);
  bool get isKeyboardVisible => ResponsiveUtils.isKeyboardVisible(this);
  
  ScreenSize get screenSize => ResponsiveUtils.getScreenSize(this);
  EdgeInsets get responsivePadding => ResponsiveUtils.responsivePadding(this);
  EdgeInsets get responsiveMargin => ResponsiveUtils.responsiveMargin(this);
  EdgeInsets get safeAreaPadding => ResponsiveUtils.getSafeAreaPadding(this);
  
  double responsiveSpacing(SpacingSize size) => ResponsiveUtils.getSpacing(this, size);
  double get maxContentWidth => ResponsiveUtils.getMaxContentWidth(this);
  double get cardWidth => ResponsiveUtils.getCardWidth(this);
  BorderRadius get responsiveBorderRadius => ResponsiveUtils.responsiveBorderRadius(this);
  BoxConstraints get dialogConstraints => ResponsiveUtils.getDialogConstraints(this);
  
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) => ResponsiveUtils.responsiveValue(
    this,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
    largeDesktop: largeDesktop,
  );
}
