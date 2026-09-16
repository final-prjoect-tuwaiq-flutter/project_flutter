import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ==========================================
// 1. Theme Extension (ألوان حالات الفعاليات: مجاني، مدفوع، الخ)
// ==========================================
class AppStatusColors extends ThemeExtension<AppStatusColors> {
  final Color freeColor;
  final Color freeColorBg;
  final Color priceColor;
  final Color priceColorBg;
  final Color neutralBadgeColor;
  final Color neutralBadgeColorBg;

  const AppStatusColors({
    required this.freeColor,
    required this.freeColorBg,
    required this.priceColor,
    required this.priceColorBg,
    required this.neutralBadgeColor,
    required this.neutralBadgeColorBg,
  });

  @override
  AppStatusColors copyWith({
    Color? freeColor, Color? freeColorBg,
    Color? priceColor, Color? priceColorBg,
    Color? neutralBadgeColor, Color? neutralBadgeColorBg,
  }) {
    return AppStatusColors(
      freeColor: freeColor ?? this.freeColor,
      freeColorBg: freeColorBg ?? this.freeColorBg,
      priceColor: priceColor ?? this.priceColor,
      priceColorBg: priceColorBg ?? this.priceColorBg,
      neutralBadgeColor: neutralBadgeColor ?? this.neutralBadgeColor,
      neutralBadgeColorBg: neutralBadgeColorBg ?? this.neutralBadgeColorBg,
    );
  }

  @override
  AppStatusColors lerp(ThemeExtension<AppStatusColors>? other, double t) {
    if (other is! AppStatusColors) return this;
    return AppStatusColors(
      freeColor: Color.lerp(freeColor, other.freeColor, t)!,
      freeColorBg: Color.lerp(freeColorBg, other.freeColorBg, t)!,
      priceColor: Color.lerp(priceColor, other.priceColor, t)!,
      priceColorBg: Color.lerp(priceColorBg, other.priceColorBg, t)!,
      neutralBadgeColor: Color.lerp(neutralBadgeColor, other.neutralBadgeColor, t)!,
      neutralBadgeColorBg: Color.lerp(neutralBadgeColorBg, other.neutralBadgeColorBg, t)!,
    );
  }
}

// ==========================================
// 2. الهوية البصرية الأساسية (AppTheme)
// ==========================================
class AppTheme {
  static const Color primaryColor = Color(0xFF5E35B1); // بنفسجي داكن
  static const Color secondaryColor = Color(0xFFFF4081); // وردي زاهي
  static const Color backgroundColor = Color(0xFFF8F9FA); // خلفية التطبيق رمادي فاتح
  static const Color surfaceColor = Color(0xFFFFFFFF); // البطاقات بيضاء
  static const Color errorColor = Color(0xFFB3261E); // أحمر للأخطاء
  
  static const Color textMainColor = Color(0xFF1D1D1D); // نصوص رئيسية
  static const Color textSecondaryColor = Color(0xFF757575); // نصوص فرعية

  // ستايل زر أسود كبديل في حال أردت زر الحجز أسود
  static ButtonStyle get blackCtaButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF191D21), 
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
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: secondaryColor,
        onSecondary: Colors.white,
        surface: surfaceColor,
        onSurface: textMainColor,
        error: errorColor,
        onError: Colors.white,
        surfaceTint: Colors.transparent, 
      ),

      extensions: <ThemeExtension<dynamic>>[
        AppStatusColors(
          freeColor: const Color(0xFF2E7D32), 
          freeColorBg: const Color(0xFF2E7D32).withOpacity(0.12),
          priceColor: const Color(0xFFD84315), 
          priceColorBg: const Color(0xFFD84315).withOpacity(0.12),
          neutralBadgeColor: Colors.black87,
          neutralBadgeColorBg: Colors.black.withOpacity(0.04),
        ),
      ],

      textTheme: baseTextTheme.copyWith(
        displayLarge: baseTextTheme.displayLarge?.copyWith(color: textMainColor, fontWeight: FontWeight.w700),
        titleLarge: baseTextTheme.titleLarge?.copyWith(color: textMainColor, fontWeight: FontWeight.w700),
        titleMedium: baseTextTheme.titleMedium?.copyWith(color: textMainColor, fontWeight: FontWeight.w600),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: textSecondaryColor, fontWeight: FontWeight.w500),
        bodySmall: baseTextTheme.bodySmall?.copyWith(color: textSecondaryColor, fontWeight: FontWeight.w400),
        labelSmall: baseTextTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
      ),

             // أضفنا كلمة Data ليصبح CardThemeData
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 1,
        shadowColor: const Color(0x14000000), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F1F3),
        hintStyle: const TextStyle(color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: errorColor, width: 1.5)),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: textMainColor,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      
      dividerTheme: DividerThemeData(color: Colors.grey.withOpacity(0.2), thickness: 1, space: 24),
    );
  }
}