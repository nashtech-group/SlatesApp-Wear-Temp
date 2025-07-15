// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';

class AppTheme {
  // ====================
  // BRAND COLORS FROM LOGO
  // ====================

  // Primary teal/blue from logo curve
  static const Color primaryTeal = Color(0xFF1B7A8C);
  static const Color primaryTealLight = Color(0xFF4DA6B8);
  static const Color primaryTealDark = Color(0xFF0F5A68);

  // Secondary colors derived from logo
  static const Color secondaryBlue = Color(0xFF2196F3);
  static const Color accentCyan = Color(0xFF00BCD4);

  // Neutral colors for text (matching logo)
  static const Color darkGrey = Color(0xFF2C2C2C); // Logo text color
  static const Color mediumGrey = Color(0xFF666666);
  static const Color lightGrey = Color(0xFFE0E0E0);

  // ====================
  // SEMANTIC COLORS
  // ====================

  // Success, warning, error colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color successGreenLight = Color(0xFF81C784);
  static const Color successGreenDark = Color(0xFF388E3C);

  static const Color warningOrange = Color(0xFFFF9800);
  static const Color warningOrangeLight = Color(0xFFFFB74D);
  static const Color warningOrangeDark = Color(0xFFF57C00);

  static const Color errorRed = Color(0xFFF44336);
  static const Color errorRedLight = Color(0xFFEF5350);
  static const Color errorRedDark = Color(0xFFD32F2F);

  static const Color infoBlue = Color(0xFF2196F3);
  static const Color infoBlueDark = Color(0xFF1976D2);

  // ====================
  // STATUS COLORS
  // ====================

  // Guard/Duty Status Colors
  static const Color statusPresent = successGreen;
  static const Color statusAbsent = errorRed;
  static const Color statusPending = warningOrange;
  static const Color statusLate = infoBlue;
  static const Color statusLeftEarly = Color(0xFFFFEB3B); // Yellow
  static const Color statusExpired = mediumGrey;
  static const Color statusLateAndLeftEarly = Color(0xFF9C27B0); // Purple

  // Connection Status Colors
  static const Color statusOnline = successGreen;
  static const Color statusOffline = errorRed;
  static const Color statusConnecting = warningOrange;

  // Battery Status Colors
  static const Color batteryHigh = successGreen;
  static const Color batteryMedium = warningOrange;
  static const Color batteryLow = errorRed;
  static const Color batteryCritical = Color(0xFF8B0000); // Dark red

  // Location/Signal Status Colors  
  static const Color signalExcellent = successGreen;
  static const Color signalGood = Color(0xFF8BC34A); // Light green
  static const Color signalFair = warningOrange;
  static const Color signalPoor = errorRed;
  static const Color signalNone = mediumGrey;

  // ====================
  // RESPONSIVE THEME BUILDERS
  // ====================

  /// Create responsive light theme
  static ThemeData lightTheme(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return _buildTheme(context, responsive, Brightness.light);
  }

  /// Create responsive dark theme
  static ThemeData darkTheme(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return _buildTheme(context, responsive, Brightness.dark);
  }

  /// Build theme with responsive components
  static ThemeData _buildTheme(BuildContext context, ResponsiveUtils responsive, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,

      // Color scheme
      colorScheme: isDark ? _darkColorScheme : _lightColorScheme,

      // App bar theme with responsive sizing
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: responsive.getTitleStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        )?.copyWith(fontFamily: 'Inter'),
      ),

      // Responsive elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? primaryTealLight : primaryTeal,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: (isDark ? primaryTealLight : primaryTeal).withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsive.borderRadius),
          ),
          textStyle: responsive.getBodyStyle(
            fontWeight: FontWeight.w600,
          )?.copyWith(fontFamily: 'Inter'),
          padding: responsive.buttonPadding,
        ),
      ),

      // Responsive text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? primaryTealLight : primaryTeal,
          textStyle: responsive.getCaptionStyle(
            fontWeight: FontWeight.w500,
          )?.copyWith(fontFamily: 'Inter'),
          padding: responsive.buttonPadding * 0.75,
        ),
      ),

      // Responsive outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? primaryTealLight : primaryTeal,
          side: BorderSide(color: isDark ? primaryTealLight : primaryTeal),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsive.borderRadius),
          ),
          textStyle: responsive.getBodyStyle(
            fontWeight: FontWeight.w600,
          )?.copyWith(fontFamily: 'Inter'),
          padding: responsive.buttonPadding,
        ),
      ),

      // Responsive input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius),
          borderSide: BorderSide(color: isDark ? const Color(0xFF404040) : lightGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius),
          borderSide: BorderSide(color: isDark ? const Color(0xFF404040) : lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius),
          borderSide: BorderSide(
            color: isDark ? primaryTealLight : primaryTeal, 
            width: 2
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius),
          borderSide: BorderSide(color: isDark ? const Color(0xFFEF5350) : errorRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFFEF5350) : errorRed, 
            width: 2
          ),
        ),
        contentPadding: responsive.inputPadding,
        labelStyle: GoogleFonts.inter(
          textStyle: responsive.getBodyStyle(
            color: isDark ? const Color(0xFFB0B0B0) : mediumGrey,
          ),
        ),
        hintStyle: GoogleFonts.inter(
          textStyle: responsive.getBodyStyle(
            color: isDark ? const Color(0xFFB0B0B0) : mediumGrey,
          ),
        ),
      ),

      // Responsive card theme
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius),
        ),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      ),

      // Responsive text theme
      textTheme: _buildResponsiveTextTheme(responsive, isDark),

      // Responsive checkbox theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? primaryTealLight : primaryTeal;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: isDark ? const Color(0xFFB0B0B0) : mediumGrey),
      ),

      // Responsive switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? primaryTealLight : primaryTeal;
          }
          return isDark ? const Color(0xFFB0B0B0) : mediumGrey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark 
                ? primaryTealLight.withValues(alpha: 0.5) 
                : primaryTealLight;
          }
          return isDark ? const Color(0xFF404040) : lightGrey;
        }),
      ),

      // Progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? primaryTealLight : primaryTeal,
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: isDark ? primaryTealLight : primaryTeal,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        selectedItemColor: isDark ? primaryTealLight : primaryTeal,
        unselectedItemColor: isDark ? const Color(0xFFB0B0B0) : mediumGrey,
        type: BottomNavigationBarType.fixed,
      ),

      // Scaffold background
      scaffoldBackgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA),

      // Responsive divider theme
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF404040) : lightGrey,
        thickness: 1,
      ),
    );
  }

  /// Build responsive text theme with Google Fonts
  static TextTheme _buildResponsiveTextTheme(ResponsiveUtils responsive, bool isDark) {
    final textColor = isDark ? Colors.white : darkGrey;
    final secondaryTextColor = isDark ? const Color(0xFFB0B0B0) : mediumGrey;

    return TextTheme(
      headlineLarge: responsive.getHeadlineStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
        baseFontSize: 32,
      ),
      
      headlineMedium: responsive.getHeadlineStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
        baseFontSize: 28,
      ),
      
      headlineSmall: responsive.getHeadlineStyle(
        color: textColor,
        fontWeight: FontWeight.w600,
        baseFontSize: 24,
      ),
      
      titleLarge: responsive.getTitleStyle(
        color: textColor,
        fontWeight: FontWeight.w600,
        baseFontSize: 22,
      ),
      
      titleMedium: responsive.getTitleStyle(
        color: textColor,
        fontWeight: FontWeight.w500,
        baseFontSize: 16,
      ),
      
      titleSmall: responsive.getTitleStyle(
        color: secondaryTextColor,
        fontWeight: FontWeight.w500,
        baseFontSize: 14,
      ),
      
      bodyLarge: responsive.getBodyStyle(
        color: textColor,
        fontWeight: FontWeight.normal,
        baseFontSize: 16,
      ),
      
      bodyMedium: responsive.getBodyStyle(
        color: textColor,
        fontWeight: FontWeight.normal,
        baseFontSize: 14,
      ),
      
      bodySmall: responsive.getBodyStyle(
        color: secondaryTextColor,
        fontWeight: FontWeight.normal,
        baseFontSize: 12,
      ),
      
      labelLarge: responsive.getCaptionStyle(
        color: textColor,
        fontWeight: FontWeight.w500,
        baseFontSize: 14,
      ),
      
      labelMedium: responsive.getCaptionStyle(
        color: secondaryTextColor,
        fontWeight: FontWeight.w500,
        baseFontSize: 12,
      ),
      
      labelSmall: responsive.getCaptionStyle(
        color: secondaryTextColor,
        fontWeight: FontWeight.w500,
        baseFontSize: 11,
      ),
    );
  }

  // ====================
  // COLOR SCHEMES
  // ====================

  static const ColorScheme _lightColorScheme = ColorScheme.light(
    primary: primaryTeal,
    primaryContainer: primaryTealLight,
    onPrimary: Colors.white,
    onPrimaryContainer: darkGrey,
    secondary: secondaryBlue,
    secondaryContainer: Color(0xFFE3F2FD),
    onSecondary: Colors.white,
    onSecondaryContainer: darkGrey,
    tertiary: accentCyan,
    surface: Colors.white,
    onSurface: darkGrey,
    error: errorRed,
    onError: Colors.white,
  );

  static const ColorScheme _darkColorScheme = ColorScheme.dark(
    primary: primaryTealLight,
    primaryContainer: primaryTealDark,
    onPrimary: Colors.white,
    onPrimaryContainer: Colors.white,
    secondary: secondaryBlue,
    secondaryContainer: Color(0xFF1565C0),
    onSecondary: Colors.white,
    onSecondaryContainer: Colors.white,
    tertiary: accentCyan,
    surface: Color(0xFF1E1E1E),
    onSurface: Colors.white,
    error: Color(0xFFEF5350),
    onError: Colors.white,
  );

  // ====================
  // STATUS COLOR UTILITIES
  // ====================

  /// Get guard duty status color based on status code
  static Color getGuardStatusColor(int status, {bool isDark = false}) {
    switch (status) {
      case AppConstants.presentStatus:
        return statusPresent;
      case AppConstants.absentStatus:
        return statusAbsent;
      case AppConstants.pendingStatus:
        return statusPending;
      case AppConstants.presentButLeftEarlyStatus:
        return statusLeftEarly;
      case AppConstants.absentWithoutPermissionStatus:
        return statusExpired;
      case AppConstants.presentButLateStatus:
        return statusLate;
      case AppConstants.presentButLateAndLeftEarlyStatus:
        return statusLateAndLeftEarly;
      default:
        return isDark ? mediumGrey : lightGrey;
    }
  }

  /// Get connection status color
  static Color getConnectionStatusColor(bool isOnline, {bool isConnecting = false}) {
    if (isConnecting) return statusConnecting;
    return isOnline ? statusOnline : statusOffline;
  }

  /// Get battery status color based on percentage
  static Color getBatteryStatusColor(int batteryLevel) {
    if (batteryLevel <= AppConstants.criticalBatteryThreshold) {
      return batteryCritical;
    } else if (batteryLevel <= AppConstants.lowBatteryThreshold) {
      return batteryLow;
    } else if (batteryLevel <= 50) {
      return batteryMedium;
    } else {
      return batteryHigh;
    }
  }

  /// Get signal strength color (0-4 scale)
  static Color getSignalStrengthColor(int signalStrength) {
    switch (signalStrength) {
      case 0:
        return signalNone;
      case 1:
        return signalPoor;
      case 2:
        return signalFair;
      case 3:
        return signalGood;
      case 4:
        return signalExcellent;
      default:
        return signalNone;
    }
  }

  /// Get priority color (high, medium, low)
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
      case 'critical':
        return errorRed;
      case 'medium':
      case 'normal':
        return warningOrange;
      case 'low':
      default:
        return successGreen;
    }
  }

  // ====================
  // HELPER METHODS
  // ====================

  /// Get theme based on brightness
  static ThemeData getTheme(BuildContext context, Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme(context) : lightTheme(context);
  }

  /// Get primary color based on brightness
  static Color getPrimaryColor(Brightness brightness) {
    return brightness == Brightness.dark ? primaryTealLight : primaryTeal;
  }

  /// Get logo text color based on theme
  static Color getLogoTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : darkGrey;
  }

  /// Get text color based on background color
  static Color getTextColorForBackground(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? darkGrey : Colors.white;
  }

  /// Get responsive brand gradient decoration
  static BoxDecoration getBrandGradientDecoration(
    BuildContext context, {
    BorderRadius? borderRadius,
    List<Color>? colors,
  }) {
    final responsive = context.responsive;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors ??
            [
              primaryTeal,
              primaryTealLight,
              secondaryBlue.withValues(alpha: 0.8),
            ],
      ),
      borderRadius: borderRadius ?? BorderRadius.circular(responsive.borderRadius),
    );
  }

  /// Get surface color with elevation
  static Color getSurfaceColor(BuildContext context, {double elevation = 0}) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surface;

    if (elevation == 0) return baseColor;

    final overlayColor =
        theme.brightness == Brightness.dark ? Colors.white : Colors.black;

    final opacity = (elevation / 24).clamp(0.0, 1.0) * 0.05;
    return Color.alphaBlend(
      overlayColor.withValues(alpha: opacity),
      baseColor,
    );
  }

  // ====================
  // RESPONSIVE BUTTON HELPERS
  // ====================

  /// Get responsive button colors for different states
  static ButtonColors getResponsiveButtonColors(
    BuildContext context, {
    Color? customBackgroundColor,
    Color? customTextColor,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ButtonColors(
      backgroundColor: customBackgroundColor ?? colorScheme.primary,
      textColor: customTextColor ?? colorScheme.onPrimary,
      loadingSpinnerColor:
          theme.progressIndicatorTheme.color ?? colorScheme.primary,
      disabledBackgroundColor: colorScheme.outline,
      disabledTextColor: colorScheme.onSurface.withValues(alpha: 0.38),
    );
  }

  /// Get responsive loading spinner color
  static Color getResponsiveLoadingSpinnerColor(BuildContext context,
      {bool isDisabled = false}) {
    final theme = Theme.of(context);

    if (isDisabled) {
      return theme.brightness == Brightness.dark
          ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
          : theme.colorScheme.onSurface.withValues(alpha: 0.4);
    }

    return theme.progressIndicatorTheme.color ?? theme.colorScheme.primary;
  }

  /// Get responsive button style with Google Fonts
  static ButtonStyle getResponsiveButtonStyle(
    BuildContext context, {
    Color? backgroundColor,
    Color? textColor,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
  }) {
    final theme = Theme.of(context);
    final responsive = context.responsive;
    final buttonColors = getResponsiveButtonColors(
      context,
      customBackgroundColor: backgroundColor,
      customTextColor: textColor,
    );

    return ElevatedButton.styleFrom(
      backgroundColor: buttonColors.backgroundColor,
      foregroundColor: buttonColors.textColor,
      disabledBackgroundColor: buttonColors.disabledBackgroundColor,
      disabledForegroundColor: buttonColors.disabledTextColor,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(responsive.borderRadius),
      ),
      elevation: 2,
      shadowColor: theme.shadowColor.withValues(alpha: 0.2),
      padding: padding ?? responsive.buttonPadding,
      textStyle: GoogleFonts.inter(
        textStyle: responsive.getBodyStyle(fontWeight: FontWeight.w600),
      ),
    );
  }

  // ====================
  // RESPONSIVE BUTTON VARIANTS
  // ====================

  /// Responsive primary button style
  static ButtonStyle responsivePrimaryButtonStyle(BuildContext context) {
    return getResponsiveButtonStyle(context);
  }

  /// Responsive secondary button style
  static ButtonStyle responsiveSecondaryButtonStyle(BuildContext context) {
    final theme = Theme.of(context);
    return getResponsiveButtonStyle(
      context,
      backgroundColor: theme.colorScheme.secondary,
      textColor: theme.colorScheme.onSecondary,
    );
  }

  /// Responsive destructive button style
  static ButtonStyle responsiveDestructiveButtonStyle(BuildContext context) {
    final theme = Theme.of(context);
    return getResponsiveButtonStyle(
      context,
      backgroundColor: theme.colorScheme.error,
      textColor: theme.colorScheme.onError,
    );
  }

  /// Responsive success button style
  static ButtonStyle responsiveSuccessButtonStyle(BuildContext context) {
    return getResponsiveButtonStyle(
      context,
      backgroundColor: successGreen,
      textColor: Colors.white,
    );
  }

  /// Responsive warning button style
  static ButtonStyle responsiveWarningButtonStyle(BuildContext context) {
    return getResponsiveButtonStyle(
      context,
      backgroundColor: warningOrange,
      textColor: Colors.white,
    );
  }

  // ====================
  // RESPONSIVE COMPONENT HELPERS
  // ====================

  /// Get responsive input decoration with Google Fonts
  static InputDecoration getResponsiveInputDecoration(
    BuildContext context, {
    String? labelText,
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final theme = Theme.of(context);
    final responsive = context.responsive;

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: theme.inputDecorationTheme.fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        borderSide: theme.inputDecorationTheme.border?.borderSide ?? BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        borderSide: theme.inputDecorationTheme.enabledBorder?.borderSide ?? BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        borderSide: theme.inputDecorationTheme.focusedBorder?.borderSide ?? 
            BorderSide(color: theme.colorScheme.primary, width: 2),
      ),
      contentPadding: responsive.inputPadding,
      labelStyle: GoogleFonts.inter(textStyle: responsive.getBodyStyle()),
      hintStyle: GoogleFonts.inter(textStyle: responsive.getBodyStyle()),
    );
  }

  /// Get responsive card decoration
  static BoxDecoration getResponsiveCardDecoration(
    BuildContext context, {
    Color? backgroundColor,
    double? elevation,
  }) {
    final theme = Theme.of(context);
    final responsive = context.responsive;

    return BoxDecoration(
      color: backgroundColor ?? theme.cardTheme.color,
      borderRadius: BorderRadius.circular(responsive.borderRadius),
      boxShadow: elevation != null ? [
        BoxShadow(
          color: theme.shadowColor.withValues(alpha: 0.1),
          blurRadius: elevation * 2,
          offset: Offset(0, elevation),
        ),
      ] : null,
    );
  }

  /// Get responsive container padding
  static EdgeInsets getResponsiveContainerPadding(BuildContext context) {
    return context.responsive.containerPadding;
  }

  /// Get responsive form padding
  static EdgeInsets getResponsiveFormPadding(BuildContext context) {
    return context.responsive.formPadding;
  }

  /// Helper method to get Google Fonts Inter text style
  static TextStyle? getInterTextStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}

// ====================
// HELPER DATA CLASS
// ====================

/// Data class to hold button color information
class ButtonColors {
  final Color backgroundColor;
  final Color textColor;
  final Color loadingSpinnerColor;
  final Color disabledBackgroundColor;
  final Color disabledTextColor;

  const ButtonColors({
    required this.backgroundColor,
    required this.textColor,
    required this.loadingSpinnerColor,
    required this.disabledBackgroundColor,
    required this.disabledTextColor,
  });
}