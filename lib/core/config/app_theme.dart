import 'package:flutter/material.dart';

/// Material 3 theme for DoTogether.
/// Palette: #FFFBF1, #FFF2D0, #FFB2B2, #E36A6A
class AppTheme {
  static const _monoFont = 'monospace';

  /// Monospace applied to all display, headline, and title styles.
  static TextTheme _buildTextTheme(TextTheme base) {
    return base;
  }

  // Brand colors
  static const _cream = Color(0xFFFFFBF1);
  static const _warmYellow = Color(0xFFFFF2D0);
  static const _softPink = Color(0xFFFFB2B2);
  static const _coral = Color(0xFFE36A6A);

  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: _coral,
      onPrimary: Colors.white,
      primaryContainer: _softPink,
      onPrimaryContainer: const Color(0xFF4A1C1C),
      secondary: _warmYellow,
      onSecondary: const Color(0xFF3E3200),
      secondaryContainer: _warmYellow,
      onSecondaryContainer: const Color(0xFF3E3200),
      tertiary: const Color(0xFFD4956A),
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFFFDCC2),
      onTertiaryContainer: const Color(0xFF3B1E00),
      error: const Color(0xFFBA1A1A),
      onError: Colors.white,
      errorContainer: const Color(0xFFFFDAD6),
      onErrorContainer: const Color(0xFF410002),
      surface: _cream,
      onSurface: const Color(0xFF1C1B1F),
      onSurfaceVariant: const Color(0xFF534341),
      surfaceContainerHighest: const Color(0xFFF0E6D6),
      outline: const Color(0xFF857371),
      outlineVariant: const Color(0xFFD8C2BF),
      shadow: Colors.black,
      inverseSurface: const Color(0xFF362F2E),
      onInverseSurface: const Color(0xFFFBEEEC),
      inversePrimary: _softPink,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme:
          _buildTextTheme(ThemeData(brightness: Brightness.light).textTheme),
      scaffoldBackgroundColor: _cream,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: _cream,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: _softPink.withOpacity(0.4),
        indicatorShape: const CircleBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(size: 30, color: _coral);
          }
          return const IconThemeData(size: 28, color: Color(0xFF857371));
        }),
      ),
    );
  }

  static ThemeData dark() {
    // Dark variants of the palette
    const darkCoral = Color(0xFFFFB2B2);
    const darkSurface = Color(0xFF1C1B1F);
    const darkSurfaceContainer = Color(0xFF2B2527);

    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: darkCoral,
      onPrimary: const Color(0xFF5C1313),
      primaryContainer: _coral,
      onPrimaryContainer: Colors.white,
      secondary: _warmYellow,
      onSecondary: const Color(0xFF3E3200),
      secondaryContainer: const Color(0xFF5C4B00),
      onSecondaryContainer: _warmYellow,
      tertiary: const Color(0xFFFFDCC2),
      onTertiary: const Color(0xFF3B1E00),
      tertiaryContainer: const Color(0xFF6B3A10),
      onTertiaryContainer: const Color(0xFFFFDCC2),
      error: const Color(0xFFFFB4AB),
      onError: const Color(0xFF690005),
      errorContainer: const Color(0xFF93000A),
      onErrorContainer: const Color(0xFFFFDAD6),
      surface: darkSurface,
      onSurface: const Color(0xFFE6E1E5),
      onSurfaceVariant: const Color(0xFFD8C2BF),
      surfaceContainerHighest: darkSurfaceContainer,
      outline: const Color(0xFFA08C8A),
      outlineVariant: const Color(0xFF534341),
      shadow: Colors.black,
      inverseSurface: const Color(0xFFE6E1E5),
      onInverseSurface: const Color(0xFF1C1B1F),
      inversePrimary: _coral,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme:
          _buildTextTheme(ThemeData(brightness: Brightness.dark).textTheme),
      scaffoldBackgroundColor: darkSurface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: darkSurface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: darkSurfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        filled: true,
        fillColor: darkSurfaceContainer,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurfaceContainer,
        indicatorColor: _coral.withOpacity(0.3),
        indicatorShape: const CircleBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(size: 30, color: darkCoral);
          }
          return const IconThemeData(size: 28, color: Color(0xFFA08C8A));
        }),
      ),
    );
  }
}
