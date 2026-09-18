import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ==========================================================
/// هوية التطبيق: "ليل وذهب"
/// أسود ليلي عميق + تدرّج غروب برتقالي نحو ذهبي.
/// خط العناوين: El Messiri (أنيق وفخم) — خط الواجهة: Cairo (واضح وعصري).
/// كل الألوان تُقرأ من [AppCustomColors] لتعمل الواجهات في الوضعين الفاتح والداكن.
/// ==========================================================
class AppCustomColors extends ThemeExtension<AppCustomColors> {
  final Color accentColor; // برتقالي الغروب (لون العلامة)
  final Color accentColorSoft; // خلفية خفيفة للشارات
  final Color accentColorDeep; // نهاية التدرّج الذهبية
  final Color solidDarkOrange; // برتقالي داكن صلب
  final Color glassBackgroundDark;
  final Color glassBackgroundLight;
  final Color darkGlassStrong;
  final Color inkColor; // لون اللوحات الليلية (الترويسات والشريط السفلي)
  final Color inkSoft; // درجة أفتح منه للتدرّجات
  final Color goldColor; // ذهبي فاتح للنصوص فوق الداكن
  final Color borderSoft; // خط فاصل خفيف
  final Color creamBackground; // خلفية الصفحات
  final Color surfaceColor; // خلفية البطاقات
  final Color textPrimary; // النصوص الرئيسية
  final Color textMuted; // النصوص الثانوية
  final Color shadowColor; // لون الظلال

  const AppCustomColors({
    required this.accentColor,
    required this.accentColorSoft,
    required this.accentColorDeep,
    required this.solidDarkOrange,
    required this.glassBackgroundDark,
    required this.glassBackgroundLight,
    required this.darkGlassStrong,
    required this.inkColor,
    required this.inkSoft,
    required this.goldColor,
    required this.borderSoft,
    required this.creamBackground,
    required this.surfaceColor,
    required this.textPrimary,
    required this.textMuted,
    required this.shadowColor,
  });

  /// التدرّج المميّز للهوية: من برتقالي الغروب إلى الذهبي.
  LinearGradient get accentGradient => LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [accentColor, accentColorDeep],
  );

  /// تدرّج اللوحات الليلية الفاخرة.
  LinearGradient get inkGradient => LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [inkSoft, inkColor],
  );

  @override
  AppCustomColors copyWith({
    Color? accentColor,
    Color? accentColorSoft,
    Color? accentColorDeep,
    Color? solidDarkOrange,
    Color? glassBackgroundDark,
    Color? glassBackgroundLight,
    Color? darkGlassStrong,
    Color? inkColor,
    Color? inkSoft,
    Color? goldColor,
    Color? borderSoft,
    Color? creamBackground,
    Color? surfaceColor,
    Color? textPrimary,
    Color? textMuted,
    Color? shadowColor,
  }) {
    return AppCustomColors(
      accentColor: accentColor ?? this.accentColor,
      accentColorSoft: accentColorSoft ?? this.accentColorSoft,
      accentColorDeep: accentColorDeep ?? this.accentColorDeep,
      solidDarkOrange: solidDarkOrange ?? this.solidDarkOrange,
      glassBackgroundDark: glassBackgroundDark ?? this.glassBackgroundDark,
      glassBackgroundLight: glassBackgroundLight ?? this.glassBackgroundLight,
      darkGlassStrong: darkGlassStrong ?? this.darkGlassStrong,
      inkColor: inkColor ?? this.inkColor,
      inkSoft: inkSoft ?? this.inkSoft,
      goldColor: goldColor ?? this.goldColor,
      borderSoft: borderSoft ?? this.borderSoft,
      creamBackground: creamBackground ?? this.creamBackground,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      shadowColor: shadowColor ?? this.shadowColor,
    );
  }

  @override
  AppCustomColors lerp(ThemeExtension<AppCustomColors>? other, double t) {
    if (other is! AppCustomColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppCustomColors(
      accentColor: l(accentColor, other.accentColor),
      accentColorSoft: l(accentColorSoft, other.accentColorSoft),
      accentColorDeep: l(accentColorDeep, other.accentColorDeep),
      solidDarkOrange: l(solidDarkOrange, other.solidDarkOrange),
      glassBackgroundDark: l(glassBackgroundDark, other.glassBackgroundDark),
      glassBackgroundLight: l(glassBackgroundLight, other.glassBackgroundLight),
      darkGlassStrong: l(darkGlassStrong, other.darkGlassStrong),
      inkColor: l(inkColor, other.inkColor),
      inkSoft: l(inkSoft, other.inkSoft),
      goldColor: l(goldColor, other.goldColor),
      borderSoft: l(borderSoft, other.borderSoft),
      creamBackground: l(creamBackground, other.creamBackground),
      surfaceColor: l(surfaceColor, other.surfaceColor),
      textPrimary: l(textPrimary, other.textPrimary),
      textMuted: l(textMuted, other.textMuted),
      shadowColor: l(shadowColor, other.shadowColor),
    );
  }
}

class AppTheme {
  // ألوان العلامة (ثابتة في الوضعين)
  static const Color accentOrange = Color(0xFFF2743A);
  static const Color accentGold = Color(0xFFD9A441);
  static const Color accentGoldLight = Color(0xFFE7BE77);
  static const Color accentOrangeSoft = Color(0x1FF2743A);
  static const Color errorColor = Color(0xFFD64545);

  // الوضع الفاتح
  static const Color baseBlack = Color(0xFF0F1319);
  static const Color inkSoft = Color(0xFF1C222C);
  static const Color backgroundColor = Color(0xFFFAF7F2);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color borderColor = Color(0xFFEDE6DC);
  static const Color textMainColor = Color(0xFF14171E);
  static const Color textSecondaryColor = Color(0xFF7C8290);

  // الوضع الداكن
  static const Color darkBackground = Color(0xFF0A0D12);
  static const Color darkSurface = Color(0xFF141922);
  static const Color darkBorder = Color(0xFF242B36);
  static const Color darkInk = Color(0xFF121720);
  static const Color darkInkSoft = Color(0xFF212835);
  static const Color darkTextMain = Color(0xFFF3EFE8);
  static const Color darkTextSecondary = Color(0xFF9AA1AD);

  /// خط العناوين الفاخر. مرّر [color] من [AppCustomColors.textPrimary]
  /// عند استخدامه فوق خلفيات الصفحات ليتوافق مع الوضع الداكن.
  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color color = textMainColor,
    double height = 1.35,
    double letterSpacing = -0.2,
  }) {
    return GoogleFonts.elMessiri(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static ButtonStyle get blackCtaButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: baseBlack,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2),
  );

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final background = isDark ? darkBackground : backgroundColor;
    final surface = isDark ? darkSurface : surfaceColor;
    final border = isDark ? darkBorder : borderColor;
    final textMain = isDark ? darkTextMain : textMainColor;
    final textMuted = isDark ? darkTextSecondary : textSecondaryColor;
    final ink = isDark ? darkInk : baseBlack;

    final colors = AppCustomColors(
      accentColor: accentOrange,
      accentColorSoft: isDark ? const Color(0x2EF2743A) : accentOrangeSoft,
      accentColorDeep: accentGold,
      solidDarkOrange: const Color(0xFFE65C00),
      glassBackgroundDark: const Color(0x59000000),
      glassBackgroundLight: const Color(0x26FFFFFF),
      darkGlassStrong: const Color(0x73000000),
      inkColor: ink,
      inkSoft: isDark ? darkInkSoft : inkSoft,
      goldColor: accentGoldLight,
      borderSoft: border,
      creamBackground: background,
      surfaceColor: surface,
      textPrimary: textMain,
      textMuted: textMuted,
      shadowColor: isDark ? Colors.black : baseBlack,
    );

    final cairo = GoogleFonts.cairoTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );
    TextStyle heading(double size, {double height = 1.35}) =>
        display(size, color: textMain, height: height);

    OutlineInputBorder outline(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      splashFactory: InkRipple.splashFactory,

      colorScheme: ColorScheme(
        brightness: brightness,
        primary: isDark ? accentOrange : baseBlack,
        onPrimary: Colors.white,
        secondary: accentOrange,
        onSecondary: Colors.white,
        tertiary: accentGold,
        onTertiary: baseBlack,
        surface: surface,
        onSurface: textMain,
        onSurfaceVariant: textMuted,
        surfaceContainerHighest: isDark
            ? const Color(0xFF1B212B)
            : const Color(0xFFF3EEE6),
        outline: border,
        outlineVariant: border,
        error: errorColor,
        onError: Colors.white,
      ),

      extensions: <ThemeExtension<dynamic>>[colors],

      textTheme: cairo.copyWith(
        displayLarge: heading(34),
        displayMedium: heading(28),
        displaySmall: heading(24),
        headlineMedium: heading(22),
        headlineSmall: heading(20),
        titleLarge: heading(20, height: 1.3),
        titleMedium: cairo.titleMedium?.copyWith(
          color: textMain,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: cairo.bodyLarge?.copyWith(
          color: textMain,
          fontWeight: FontWeight.w500,
          height: 1.6,
        ),
        bodyMedium: cairo.bodyMedium?.copyWith(
          color: textMuted,
          fontWeight: FontWeight.w500,
          height: 1.6,
        ),
        bodySmall: cairo.bodySmall?.copyWith(
          color: textMuted,
          fontWeight: FontWeight.w500,
          height: 1.5,
        ),
        labelLarge: cairo.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        labelSmall: cairo.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),

      iconTheme: IconThemeData(color: textMain),

      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: const Color(0x14000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: colors.accentColorSoft,
        checkmarkColor: accentOrange,
        side: BorderSide(color: border),
        labelStyle: GoogleFonts.cairo(
          color: textMain,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textMain,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: heading(20),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        hintStyle: GoogleFonts.cairo(
          color: textMuted.withValues(alpha: 0.8),
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: GoogleFonts.cairo(
          color: textMuted,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: GoogleFonts.cairo(
          color: accentOrange,
          fontWeight: FontWeight.w700,
        ),
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) =>
              states.contains(WidgetState.focused) ? accentOrange : textMuted,
        ),
        suffixIconColor: textMuted,
        border: outline(border),
        enabledBorder: outline(border),
        focusedBorder: outline(accentOrange, 1.6),
        errorBorder: outline(errorColor),
        focusedErrorBorder: outline(errorColor, 1.6),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: isDark ? accentOrange : baseBlack,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textMain,
          minimumSize: const Size(0, 50),
          side: BorderSide(color: border),
          backgroundColor: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentOrange,
          textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(style: blackCtaButtonStyle),

      dialogTheme: DialogThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        titleTextStyle: heading(20),
        contentTextStyle: GoogleFonts.cairo(
          color: textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.6,
        ),
      ),

      datePickerTheme: DatePickerThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: ink,
        headerForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        dayBackgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? accentOrange : null,
        ),
        todayForegroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : accentOrange,
        ),
        todayBorder: const BorderSide(color: accentOrange),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? accentOrange : null,
        ),
        side: BorderSide(color: textMuted.withValues(alpha: 0.5), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentOrange,
      ),

      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? darkInkSoft : baseBlack,
        actionTextColor: accentGoldLight,
        contentTextStyle: GoogleFonts.cairo(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
