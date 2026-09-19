import 'package:flutter/material.dart';
import 'package:project_flutter/app_locale.dart';
import 'package:project_flutter/screens/home_shell.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_flutter/screens/splash_screen.dart';
import 'package:project_flutter/theme/theme.dart'; // مسار ملف الثيم الجديد
import 'package:project_flutter/theme/theme_controller.dart';

// استيراد الصفحات الخاصة بك (تأكد من تعديل المسارات لتطابق مشروعك)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Supabase (تأكد من وضع روابط مشروعك هنا)
  await Supabase.initialize(
    url: 'https://rzeetjsmiakievpthjxy.supabase.co/',
    publishableKey: 'sb_publishable_QGi8lP0L6UvblvlmGXElEQ_QFU9ASxN',
  );

  // تحميل المظهر المحفوظ (فاتح / داكن / حسب النظام)
  await ThemeController.instance.load();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, themeMode, _) => MaterialApp(
        title: 'المعزب',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        // لغة الواجهة عربية ثابتة، ومندوبو الترجمة يجعلون ودجتس ماتيريال
        // (منتقي التاريخ، قوائم نسخ/لصق، أزرار الحوارات) عربية أيضاً.
        locale: kAppLocale,
        localizationsDelegates: kAppLocalizationsDelegates,
        supportedLocales: kAppSupportedLocales,
        // الواجهة مبنية على ارتفاعات ثابتة (شرائح التصنيفات، الشارات،
        // الشريط السفلي)، وتكبير خط النظام بلا حدّ يكسرها بأشرطة التجاوز.
        // الحدّ الأعلى يحفظ التخطيط مع احترام تكبير معقول للمستخدم؛ ورفعه
        // يتطلب جعل تلك الارتفاعات مرنة أولاً.
        builder: (context, child) => MediaQuery.withClampedTextScaling(
          minScaleFactor: 0.9,
          maxScaleFactor: 1.3,
          child: child ?? const SizedBox.shrink(),
        ),
        home: SplashScreen(nextBuilder: (_) => const AuthWrapper()),
      ),
    );
  }
}

// ==========================================
// شاشة البداية: التصفح متاح بدون تسجيل دخول
// ==========================================
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeShell();
  }
}
