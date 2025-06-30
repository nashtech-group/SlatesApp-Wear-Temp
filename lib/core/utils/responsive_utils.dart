import 'package:flutter/material.dart';

/// Responsive utility class for consistent responsive design across the app
/// Provides device detection, sizing, spacing, and styling utilities
class ResponsiveUtils {
  final BuildContext context;
  late final Size _screenSize;
  
  ResponsiveUtils(this.context) {
    _screenSize = MediaQuery.of(context).size;
  }

  // ====================
  // DEVICE DETECTION
  // ====================
  
  /// Check if current device is a wearable (smartwatch)
  bool get isWearable => _screenSize.width < 250 || _screenSize.height < 250;
  
  /// Check if current device is a small mobile phone
  bool get isSmallMobile => _screenSize.width < 360 || _screenSize.height < 640;
  
  /// Check if current device is a tablet
  bool get isTablet => _screenSize.width > 768;
  
  /// Check if current device has a round screen (common on smartwatches)
  bool get isRoundScreen => _screenSize.width == _screenSize.height;
  
  /// Get device type as enum for easier switching
  DeviceType get deviceType {
    if (isWearable) return DeviceType.wearable;
    if (isSmallMobile) return DeviceType.smallMobile;
    if (isTablet) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  // ====================
  // RESPONSIVE SPACING
  // ====================
  
  /// Get standard padding based on device type
  double get padding {
    switch (deviceType) {
      case DeviceType.wearable:
        return 8.0;
      case DeviceType.smallMobile:
        return 16.0;
      case DeviceType.mobile:
        return 20.0;
      case DeviceType.tablet:
        return 24.0;
    }
  }
  
  /// Get small spacing between elements
  double get smallSpacing {
    switch (deviceType) {
      case DeviceType.wearable:
        return 4.0;
      case DeviceType.smallMobile:
        return 6.0;
      case DeviceType.mobile:
        return 8.0;
      case DeviceType.tablet:
        return 10.0;
    }
  }
  
  /// Get medium spacing between elements
  double get mediumSpacing {
    switch (deviceType) {
      case DeviceType.wearable:
        return 8.0;
      case DeviceType.smallMobile:
        return 12.0;
      case DeviceType.mobile:
        return 16.0;
      case DeviceType.tablet:
        return 20.0;
    }
  }
  
  /// Get large spacing between sections
  double get largeSpacing {
    switch (deviceType) {
      case DeviceType.wearable:
        return 16.0;
      case DeviceType.smallMobile:
        return 20.0;
      case DeviceType.mobile:
        return 24.0;
      case DeviceType.tablet:
        return 32.0;
    }
  }
  
  /// Get extra large spacing for major sections
  double get extraLargeSpacing {
    switch (deviceType) {
      case DeviceType.wearable:
        return 24.0;
      case DeviceType.smallMobile:
        return 32.0;
      case DeviceType.mobile:
        return 40.0;
      case DeviceType.tablet:
        return 48.0;
    }
  }

  // ====================
  // RESPONSIVE SIZING
  // ====================
  
  /// Get logo size based on device type
  double get logoSize {
    switch (deviceType) {
      case DeviceType.wearable:
        return 60.0;
      case DeviceType.smallMobile:
        return 80.0;
      case DeviceType.mobile:
        return 120.0;
      case DeviceType.tablet:
        return 150.0;
    }
  }
  
  /// Get splash screen logo size (typically larger)
  double get splashLogoSize {
    switch (deviceType) {
      case DeviceType.wearable:
        return 80.0;
      case DeviceType.smallMobile:
        return 120.0;
      case DeviceType.mobile:
        return 150.0;
      case DeviceType.tablet:
        return 200.0;
    }
  }
  
  /// Get button height based on device type
  double get buttonHeight {
    switch (deviceType) {
      case DeviceType.wearable:
        return 36.0;
      case DeviceType.smallMobile:
        return 44.0;
      case DeviceType.mobile:
        return 48.0;
      case DeviceType.tablet:
        return 52.0;
    }
  }
  
  /// Get icon size based on device type
  double get iconSize {
    switch (deviceType) {
      case DeviceType.wearable:
        return 14.0;
      case DeviceType.smallMobile:
        return 16.0;
      case DeviceType.mobile:
        return 18.0;
      case DeviceType.tablet:
        return 20.0;
    }
  }
  
  /// Get large icon size
  double get largeIconSize {
    switch (deviceType) {
      case DeviceType.wearable:
        return 18.0;
      case DeviceType.smallMobile:
        return 20.0;
      case DeviceType.mobile:
        return 24.0;
      case DeviceType.tablet:
        return 28.0;
    }
  }
  
  /// Get border radius based on device type
  double get borderRadius {
    switch (deviceType) {
      case DeviceType.wearable:
        return 8.0;
      case DeviceType.smallMobile:
        return 12.0;
      case DeviceType.mobile:
        return 16.0;
      case DeviceType.tablet:
        return 20.0;
    }
  }
  
  /// Get large border radius
  double get largeBorderRadius {
    switch (deviceType) {
      case DeviceType.wearable:
        return 20.0;
      case DeviceType.smallMobile:
        return 25.0;
      case DeviceType.mobile:
        return 30.0;
      case DeviceType.tablet:
        return 35.0;
    }
  }

  // ====================
  // RESPONSIVE TEXT SCALING
  // ====================
  
  /// Get scaled font size
  double getScaledFontSize(double baseFontSize) {
    switch (deviceType) {
      case DeviceType.wearable:
        return baseFontSize * 0.7;
      case DeviceType.smallMobile:
        return baseFontSize * 0.85;
      case DeviceType.mobile:
        return baseFontSize;
      case DeviceType.tablet:
        return baseFontSize * 1.1;
    }
  }
  
  /// Get responsive headline text style
  TextStyle? getHeadlineStyle({
    Color? color,
    FontWeight? fontWeight,
    double? baseFontSize,
  }) {
    final theme = Theme.of(context);
    TextStyle? baseStyle;
    
    switch (deviceType) {
      case DeviceType.wearable:
        baseStyle = theme.textTheme.titleLarge;
        break;
      case DeviceType.smallMobile:
        baseStyle = theme.textTheme.headlineSmall;
        break;
      case DeviceType.mobile:
        baseStyle = theme.textTheme.headlineMedium;
        break;
      case DeviceType.tablet:
        baseStyle = theme.textTheme.headlineLarge;
        break;
    }
    
    return baseStyle?.copyWith(
      color: color,
      fontWeight: fontWeight ?? FontWeight.bold,
      fontSize: baseFontSize != null ? getScaledFontSize(baseFontSize) : null,
    );
  }
  
  /// Get responsive title text style
  TextStyle? getTitleStyle({
    Color? color,
    FontWeight? fontWeight,
    double? baseFontSize,
  }) {
    final theme = Theme.of(context);
    TextStyle? baseStyle;
    
    switch (deviceType) {
      case DeviceType.wearable:
        baseStyle = theme.textTheme.titleSmall;
        break;
      case DeviceType.smallMobile:
        baseStyle = theme.textTheme.titleMedium;
        break;
      case DeviceType.mobile:
        baseStyle = theme.textTheme.titleLarge;
        break;
      case DeviceType.tablet:
        baseStyle = theme.textTheme.headlineSmall;
        break;
    }
    
    return baseStyle?.copyWith(
      color: color,
      fontWeight: fontWeight,
      fontSize: baseFontSize != null ? getScaledFontSize(baseFontSize) : null,
    );
  }
  
  /// Get responsive body text style
  TextStyle? getBodyStyle({
    Color? color,
    FontWeight? fontWeight,
    double? baseFontSize,
  }) {
    final theme = Theme.of(context);
    TextStyle? baseStyle;
    
    switch (deviceType) {
      case DeviceType.wearable:
        baseStyle = theme.textTheme.bodySmall;
        break;
      case DeviceType.smallMobile:
        baseStyle = theme.textTheme.bodyMedium;
        break;
      case DeviceType.mobile:
        baseStyle = theme.textTheme.bodyLarge;
        break;
      case DeviceType.tablet:
        baseStyle = theme.textTheme.titleSmall;
        break;
    }
    
    return baseStyle?.copyWith(
      color: color,
      fontWeight: fontWeight,
      fontSize: baseFontSize != null ? getScaledFontSize(baseFontSize) : null,
    );
  }
  
  /// Get responsive caption text style
  TextStyle? getCaptionStyle({
    Color? color,
    FontWeight? fontWeight,
    double? baseFontSize,
  }) {
    final theme = Theme.of(context);
    TextStyle? baseStyle;
    
    switch (deviceType) {
      case DeviceType.wearable:
        baseStyle = theme.textTheme.bodySmall?.copyWith(fontSize: 10);
        break;
      case DeviceType.smallMobile:
        baseStyle = theme.textTheme.bodySmall?.copyWith(fontSize: 12);
        break;
      case DeviceType.mobile:
        baseStyle = theme.textTheme.bodySmall;
        break;
      case DeviceType.tablet:
        baseStyle = theme.textTheme.bodyMedium;
        break;
    }
    
    return baseStyle?.copyWith(
      color: color,
      fontWeight: fontWeight,
      fontSize: baseFontSize != null ? getScaledFontSize(baseFontSize) : null,
    );
  }

  // ====================
  // RESPONSIVE EDGE INSETS
  // ====================
  
  /// Get responsive padding for containers
  EdgeInsets get containerPadding => EdgeInsets.all(padding);
  
  /// Get responsive padding for forms
  EdgeInsets get formPadding {
    return EdgeInsets.symmetric(
      horizontal: padding,
      vertical: mediumSpacing,
    );
  }
  
  /// Get responsive padding for input fields
  EdgeInsets get inputPadding {
    return EdgeInsets.symmetric(
      horizontal: isWearable ? 12 : 16,
      vertical: isWearable ? 8 : 16,
    );
  }
  
  /// Get responsive padding for buttons
  EdgeInsets get buttonPadding {
    return EdgeInsets.symmetric(
      horizontal: isWearable ? 12 : 16,
      vertical: isWearable ? 8 : 12,
    );
  }

  // ====================
  // RESPONSIVE WIDGETS
  // ====================
  
  /// Get responsive sized box for spacing
  Widget get smallSpacer => SizedBox(height: smallSpacing);
  Widget get mediumSpacer => SizedBox(height: mediumSpacing);
  Widget get largeSpacer => SizedBox(height: largeSpacing);
  Widget get extraLargeSpacer => SizedBox(height: extraLargeSpacing);
  
  /// Get responsive horizontal spacing
  Widget get smallHorizontalSpacer => SizedBox(width: smallSpacing);
  Widget get mediumHorizontalSpacer => SizedBox(width: mediumSpacing);
  Widget get largeHorizontalSpacer => SizedBox(width: largeSpacing);

  // ====================
  // CUSTOM RESPONSIVE VALUES
  // ====================
  
  /// Get custom responsive value based on device type
  T getResponsiveValue<T>({
    required T wearable,
    required T smallMobile,
    required T mobile,
    T? tablet,
  }) {
    switch (deviceType) {
      case DeviceType.wearable:
        return wearable;
      case DeviceType.smallMobile:
        return smallMobile;
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
    }
  }
  
  /// Scale a value based on screen size ratio
  double scaleValue(double baseValue, {double? maxScale}) {
    final scale = _screenSize.width / 360; // Base width 360dp
    final scaledValue = baseValue * scale;
    return maxScale != null ? scaledValue.clamp(baseValue, baseValue * maxScale) : scaledValue;
  }
}

/// Enum for different device types
enum DeviceType {
  wearable,
  smallMobile,
  mobile,
  tablet,
}

/// Extension to easily access ResponsiveUtils from BuildContext
extension ResponsiveExtension on BuildContext {
  ResponsiveUtils get responsive => ResponsiveUtils(this);
}