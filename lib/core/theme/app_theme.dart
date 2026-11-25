import 'package:flutter/material.dart';

class HissouColors {
  // Brand identity extracted directly from Hissou's official logo
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color primaryNavyLight = Color(0xFF1E293B);
  static const Color primaryNavyDark = Color(0xFF0A0F1D);

  // Vibrant Brand Accents
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentAmberLight = Color(0xFFFEF3C7);
  static const Color accentAmberDark = Color(0xFFD97706);

  static const Color softRose = Color(0xFFF43F5E);
  static const Color softRoseLight = Color(0xFFFFE4E6);
  static const Color warmPlum = Color(0xFF8B5CF6);
  static const Color warmPlumLight = Color(0xFFEDE9FE);

  // High-End Surface Tints
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color cardSurfaceLight = Colors.white;
  static const Color backgroundDark = Color(0xFF090D16);
  static const Color cardSurfaceDark = Color(0xFF131B2E);
  static const Color cardSurfaceDarkElevated = Color(0xFF1B2640);

  // Status & Utility Colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warningOrange = Color(0xFFF97316);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color neutralGrey = Color(0xFF64748B);
  static const Color borderSubtle = Color(0x18000000);
}

class HissouAnimations {
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 600);

  static const Curve spring = Curves.easeOutBack;
  static const Curve smooth = Curves.easeInOutCubic;
  static const Curve bouncy = Curves.elasticOut;
}

class HissouDecorations {
  static BoxDecoration glassCard({required bool isDark, double radius = 24}) {
    return BoxDecoration(
      color: isDark
          ? HissouColors.cardSurfaceDark.withAlpha(220)
          : Colors.white.withAlpha(240),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: isDark
            ? Colors.white.withAlpha(25)
            : Colors.black.withAlpha(12),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark ? Colors.black45 : Colors.black.withAlpha(15),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration glowingGradientButton({
    required List<Color> colors,
    double radius = 18,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: colors.first.withAlpha(80),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

class HissouTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: HissouColors.primaryNavy,
      primary: HissouColors.primaryNavy,
      secondary: HissouColors.accentAmber,
      tertiary: HissouColors.softRose,
      surface: HissouColors.backgroundLight,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: HissouColors.backgroundLight,
      fontFamily: null,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: HissouColors.primaryNavy,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: HissouColors.primaryNavy),
      ),
      cardTheme: CardThemeData(
        color: HissouColors.cardSurfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: HissouColors.borderSubtle, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HissouColors.primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: const BorderSide(color: Colors.transparent),
        selectedColor: HissouColors.primaryNavy,
        secondarySelectedColor: HissouColors.primaryNavy,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: HissouColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: HissouColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: HissouColors.primaryNavy, width: 2),
        ),
        hintStyle: const TextStyle(
          color: HissouColors.neutralGrey,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: HissouColors.accentAmber,
      primary: HissouColors.accentAmber,
      secondary: HissouColors.softRose,
      surface: HissouColors.cardSurfaceDark,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: HissouColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: HissouColors.cardSurfaceDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: HissouColors.cardSurfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withAlpha(20), width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HissouColors.cardSurfaceDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withAlpha(25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.white.withAlpha(20)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: HissouColors.accentAmber, width: 2),
        ),
      ),
    );
  }
}
