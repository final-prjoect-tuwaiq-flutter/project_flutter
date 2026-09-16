import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppCustomColors extends ThemeExtension<AppCustomColors> {
  final Color accentColor;
  final Color accentColorSoft;
  final Color solidDarkOrange; // البرتقالي الداكن المخصص للباج
  final Color glassBackgroundDark;
  final Color glassBackgroundLight;
  final Color darkGlassStrong; // الدرجة الداكنة الموحدة للحاويات

  const AppCustomColors({
    required this.accentColor,
    required this.accentColorSoft,
    required this.solidDarkOrange,
    required this.glassBackgroundDark,
    required this.glassBackgroundLight,
    required this.darkGlassStrong,
  });

  @override
  AppCustomColors copyWith({
    Color? accentColor, Color? accentColorSoft, Color? solidDarkOrange,
    Color? glassBackgroundDark, Color? glassBackgroundLight, Color? darkGlassStrong,
  }) {
    return AppCustomColors(
      accentColor: accentColor ?? this.accentColor,
      accentColorSoft: accentColorSoft ?? this.accentColorSoft,
      solidDarkOrange: solidDarkOrange ?? this.solidDarkOrange,
      glassBackgroundDark: glassBackgroundDark ?? this.glassBackgroundDark,
      glassBackgroundLight: glassBackgroundLight ?? this.glassBackgroundLight,
      darkGlassStrong: darkGlassStrong ?? this.darkGlassStrong,
    );
  }

  @override
  AppCustomColors lerp(ThemeExtension<AppCustomColors>? other, double t) {
    if (other is! AppCustomColors) return this;
    return AppCustomColors(
      accentColor: Color.lerp(accentColor, other.accentColor, t)!,
      accentColorSoft: Color.lerp(accentColorSoft, other.accentColorSoft, t)!,
      solidDarkOrange: Color.lerp(solidDarkOrange, other.solidDarkOrange, t)!,
      glassBackgroundDark: Color.lerp(glassBackgroundDark, other.glassBackgroundDark, t)!,
      glassBackgroundLight: Color.lerp(glassBackgroundLight, other.glassBackgroundLight, t)!,
      darkGlassStrong: Color.lerp(darkGlassStrong, other.darkGlassStrong, t)!,
    );
  }
}

class AppTheme {
  static const Color accentOrange = Color(0xFFFF7A3D); 
  static const Color accentOrangeSoft = Color(0x26FF7A3D); 
  
  static const Color baseBlack = Color(0xFF191D21); 
  static const Color backgroundColor = Color(0xFFF8F9FA); 
  static const Color surfaceColor = Color(0xFFFFFFFF); 
  
  static const Color textMainColor = Color(0xFF1D1D1D); 
  static const Color textSecondaryColor = Color(0xFF757575); 

  static ButtonStyle get blackCtaButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: baseBlack, 
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      );

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.cairoTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      
      colorScheme: const ColorScheme.light(
        primary: baseBlack, 
        onPrimary: Colors.white,
        secondary: accentOrange, 
        onSecondary: Colors.white,
        surface: surfaceColor,
        onSurface: textMainColor,
        error: Color(0xFFB3261E),
      ),

      extensions: <ThemeExtension<dynamic>>[
        AppCustomColors(
          accentColor: accentOrange,
          accentColorSoft: accentOrangeSoft,
          solidDarkOrange: const Color(0xFFE65C00), // برتقالي داكن صلب
          glassBackgroundDark: Colors.black.withOpacity(0.35),
          glassBackgroundLight: Colors.white.withOpacity(0.15),
          darkGlassStrong: Colors.black.withOpacity(0.45), // درجة غامقة موحدة
        ),
      ],

      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: textMainColor, fontWeight: FontWeight.w700),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: textMainColor, fontWeight: FontWeight.w700),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: textMainColor, fontWeight: FontWeight.w600),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: textSecondaryColor, fontWeight: FontWeight.w500),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: textSecondaryColor, fontWeight: FontWeight.w400),
      ),

      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 1.0,
        shadowColor: const Color(0x14000000), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: blackCtaButtonStyle),
    );
  }
}