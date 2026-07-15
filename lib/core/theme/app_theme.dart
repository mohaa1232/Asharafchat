import 'package:flutter/material.dart';

/// AsharafChat brand palette — an original deep-blue / azure identity.
/// Deliberately distinct from any existing messaging app's color system
/// or iconography — do not reuse WhatsApp's green/teal palette or logo.
class AppColors {
  static const Color primaryDeepBlue = Color(0xFF0B3D91);
  static const Color primaryAzure = Color(0xFF1E6FEB);
  static const Color accentSky = Color(0xFF4FC3F7);
  static const Color backgroundLight = Color(0xFFF4F7FC);
  static const Color backgroundDark = Color(0xFF0A1220);
  static const Color bubbleSentLight = Color(0xFFDCEAFE);
  static const Color bubbleReceivedLight = Color(0xFFFFFFFF);
  static const Color bubbleSentDark = Color(0xFF1E4C8A);
  static const Color bubbleReceivedDark = Color(0xFF16202E);
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryAzure,
      brightness: Brightness.light,
      primary: AppColors.primaryDeepBlue,
      secondary: AppColors.accentSky,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryDeepBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primaryAzure,
      brightness: Brightness.dark,
      primary: AppColors.accentSky,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F1B2E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
