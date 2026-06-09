import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  // ── Text Styles ──
  static const _fontUi      = 'Inter';
  static const _fontDisplay = 'Georgia';
  static const _fontTibetan = 'NotoSerifTibetan';

  static TextTheme _buildTextTheme(bool dark) {
    final base = dark ? NZColors.cream : NZColors.charcoal;
    final subtle = dark ? NZColors.stoneLight : NZColors.stone;
    return TextTheme(
      // Display — Georgia
      displayLarge:  TextStyle(fontFamily: _fontDisplay, fontSize: 32, fontWeight: FontWeight.w700, color: base, height: 1.2),
      displayMedium: TextStyle(fontFamily: _fontDisplay, fontSize: 26, fontWeight: FontWeight.w700, color: base, height: 1.25),
      displaySmall:  TextStyle(fontFamily: _fontDisplay, fontSize: 22, fontWeight: FontWeight.w700, color: base, height: 1.3),
      // Headline — Inter
      headlineLarge: TextStyle(fontFamily: _fontUi, fontSize: 20, fontWeight: FontWeight.w700, color: base),
      headlineMedium:TextStyle(fontFamily: _fontUi, fontSize: 18, fontWeight: FontWeight.w600, color: base),
      headlineSmall: TextStyle(fontFamily: _fontUi, fontSize: 16, fontWeight: FontWeight.w600, color: base),
      // Title — Inter
      titleLarge:    TextStyle(fontFamily: _fontUi, fontSize: 16, fontWeight: FontWeight.w600, color: base),
      titleMedium:   TextStyle(fontFamily: _fontUi, fontSize: 14, fontWeight: FontWeight.w600, color: base),
      titleSmall:    TextStyle(fontFamily: _fontUi, fontSize: 12, fontWeight: FontWeight.w600, color: base),
      // Body — Inter
      bodyLarge:     TextStyle(fontFamily: _fontUi, fontSize: 16, color: base, height: 1.6),
      bodyMedium:    TextStyle(fontFamily: _fontUi, fontSize: 14, color: base, height: 1.5),
      bodySmall:     TextStyle(fontFamily: _fontUi, fontSize: 12, color: subtle, height: 1.4),
      labelLarge:    TextStyle(fontFamily: _fontUi, fontSize: 14, fontWeight: FontWeight.w600, color: base),
      labelMedium:   TextStyle(fontFamily: _fontUi, fontSize: 12, fontWeight: FontWeight.w500, color: subtle),
      labelSmall:    TextStyle(fontFamily: _fontUi, fontSize: 11, fontWeight: FontWeight.w500, color: subtle),
    );
  }

  static ThemeData get lightTheme => _buildTheme(false);
  static ThemeData get darkTheme  => _buildTheme(true);

  static ThemeData _buildTheme(bool dark) {
    final bg = dark ? NZColors.darkBg : NZColors.cream;
    final surface = dark ? NZColors.darkSurface : NZColors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme(
        brightness: dark ? Brightness.dark : Brightness.light,
        primary: NZColors.maroon,
        onPrimary: NZColors.white,
        primaryContainer: NZColors.maroonDark,
        onPrimaryContainer: NZColors.cream,
        secondary: NZColors.gold,
        onSecondary: NZColors.white,
        secondaryContainer: NZColors.goldDim,
        onSecondaryContainer: NZColors.charcoal,
        tertiary: NZColors.saffron,
        onTertiary: NZColors.white,
        surface: surface,
        onSurface: dark ? NZColors.cream : NZColors.charcoal,
        surfaceContainerHighest: dark ? NZColors.darkCard : NZColors.creamDark,
        onSurfaceVariant: dark ? NZColors.stoneLight : NZColors.stone,
        outline: NZColors.border,
        error: const Color(0xFFB00020),
        onError: NZColors.white,
        errorContainer: const Color(0xFFFFDAD6),
        onErrorContainer: const Color(0xFF410002),
        scrim: NZColors.overlay,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: _buildTextTheme(dark),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: dark ? NZColors.darkSurface : NZColors.maroon,
        foregroundColor: NZColors.white,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily: _fontDisplay,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: NZColors.white,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: NZColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      // BottomNav
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: NZColors.maroon,
        unselectedItemColor: NZColors.stone,
        selectedLabelStyle: const TextStyle(fontFamily: _fontUi, fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontFamily: _fontUi, fontSize: 11),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? NZColors.darkCard : NZColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NZColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NZColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NZColors.maroon, width: 1.5),
        ),
        hintStyle: const TextStyle(color: NZColors.stoneLight, fontFamily: _fontUi, fontSize: 14),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: dark ? NZColors.darkCard : NZColors.creamDark,
        selectedColor: NZColors.maroon,
        labelStyle: const TextStyle(fontFamily: _fontUi, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: NZColors.border,
        thickness: 1,
        space: 0,
      ),

      // Icon
      iconTheme: IconThemeData(color: dark ? NZColors.stoneLight : NZColors.stone, size: 22),
      primaryIconTheme: const IconThemeData(color: NZColors.white),

      // Tab bar
      tabBarTheme: TabBarThemeData(
        labelColor: NZColors.maroon,
        unselectedLabelColor: NZColors.stone,
        indicatorColor: NZColors.maroon,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontFamily: _fontUi, fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontFamily: _fontUi, fontSize: 13),
        dividerColor: NZColors.border,
      ),
    );
  }

  // ── Tibetan text style helper ──
  static TextStyle tibetan({double size = 15, Color? color, FontWeight weight = FontWeight.w400}) =>
      TextStyle(fontFamily: _fontTibetan, fontSize: size, color: color ?? NZColors.gold, fontWeight: weight, height: 1.4);
}
