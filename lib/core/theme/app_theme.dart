// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  
  // Success, warning, error colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  
  // ====================
  // LIGHT THEME
  // ====================
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // Color scheme
    colorScheme: const ColorScheme.light(
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
      background: Color(0xFFFAFAFA),
      onBackground: darkGrey,
      error: errorRed,
      onError: Colors.white,
    ),
    
    // App bar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryTeal,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
    ),
    
    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: primaryTeal.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    ),
    
    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryTeal,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
      ),
    ),
    
    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: lightGrey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: lightGrey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryTeal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(
        color: mediumGrey,
        fontFamily: 'Inter',
      ),
    ),
    
    // Card theme
    cardTheme: CardTheme(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Colors.white,
    ),
    
    // Text theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: darkGrey,
        fontFamily: 'Inter',
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: darkGrey,
        fontFamily: 'Inter',
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: darkGrey,
        fontFamily: 'Inter',
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: darkGrey,
        fontFamily: 'Inter',
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: darkGrey,
        fontFamily: 'Inter',
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: mediumGrey,
        fontFamily: 'Inter',
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: darkGrey,
        fontFamily: 'Inter',
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: darkGrey,
        fontFamily: 'Inter',
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: mediumGrey,
        fontFamily: 'Inter',
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: darkGrey,
        fontFamily: 'Inter',
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: mediumGrey,
        fontFamily: 'Inter',
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: mediumGrey,
        fontFamily: 'Inter',
      ),
    ),
    
    // Checkbox theme
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryTeal;
        }
        return Colors.transparent;
      }),
      checkColor: MaterialStateProperty.all(Colors.white),
    ),
    
    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryTeal;
        }
        return mediumGrey;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryTealLight;
        }
        return lightGrey;
      }),
    ),
    
    // Progress indicator theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryTeal,
    ),
    
    // Floating action button theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryTeal,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    
    // Bottom navigation bar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primaryTeal,
      unselectedItemColor: mediumGrey,
      type: BottomNavigationBarType.fixed,
    ),
    
    // Scaffold background
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    
    // Divider theme
    dividerTheme: DividerThemeData(
      color: lightGrey,
      thickness: 1,
    ),
  );
  
  // ====================
  // DARK THEME
  // ====================
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // Color scheme
    colorScheme: const ColorScheme.dark(
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
      background: Color(0xFF121212),
      onBackground: Colors.white,
      error: Color(0xFFEF5350),
      onError: Colors.white,
    ),
    
    // App bar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
    ),
    
    // Elevated button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryTealLight,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: primaryTealLight.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    ),
    
    // Text button theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryTealLight,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          fontFamily: 'Inter',
        ),
      ),
    ),
    
    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF404040)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF404040)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryTealLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF5350)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(
        color: Color(0xFFB0B0B0),
        fontFamily: 'Inter',
      ),
    ),
    
    // Card theme
    cardTheme: CardTheme(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: const Color(0xFF1E1E1E),
    ),
    
    // Text theme
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'Inter',
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: 'Inter',
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        fontFamily: 'Inter',
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        fontFamily: 'Inter',
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        fontFamily: 'Inter',
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFFB0B0B0),
        fontFamily: 'Inter',
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: Colors.white,
        fontFamily: 'Inter',
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: Colors.white,
        fontFamily: 'Inter',
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: Color(0xFFB0B0B0),
        fontFamily: 'Inter',
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
        fontFamily: 'Inter',
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFFB0B0B0),
        fontFamily: 'Inter',
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Color(0xFFB0B0B0),
        fontFamily: 'Inter',
      ),
    ),
    
    // Scaffold background
    scaffoldBackgroundColor: const Color(0xFF121212),
    
    // Other theme components...
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryTealLight;
        }
        return Colors.transparent;
      }),
      checkColor: MaterialStateProperty.all(Colors.white),
    ),
    
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryTealLight;
        }
        return const Color(0xFF666666);
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryTealDark;
        }
        return const Color(0xFF404040);
      }),
    ),
    
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryTealLight,
    ),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryTealLight,
      foregroundColor: Colors.white,
      elevation: 4,
    ),
    
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      selectedItemColor: primaryTealLight,
      unselectedItemColor: Color(0xFF666666),
      type: BottomNavigationBarType.fixed,
    ),
    
    dividerTheme: const DividerThemeData(
      color: Color(0xFF404040),
      thickness: 1,
    ),
  );
  
  // ====================
  // HELPER METHODS
  // ====================
  
  /// Get theme based on brightness
  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme : lightTheme;
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
  
  /// Get surface color with elevation
  static Color getSurfaceColor(BuildContext context, {double elevation = 0}) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surface;
    
    if (elevation == 0) return baseColor;
    
    final overlayColor = theme.brightness == Brightness.dark 
        ? Colors.white 
        : Colors.black;
    
    final opacity = (elevation / 24).clamp(0.0, 1.0) * 0.05;
    return Color.alphaBlend(
      overlayColor.withOpacity(opacity),
      baseColor,
    );
  }
}

