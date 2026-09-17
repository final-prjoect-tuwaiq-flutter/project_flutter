import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:project_flutter/screens/categories_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_flutter/screens/splash_screen.dart';
import 'package:project_flutter/theme/theme.dart'; // مسار ملف الثيم الجديد
import 'package:project_flutter/theme/theme_controller.dart';

// استيراد الصفحات الخاصة بك (تأكد من تعديل المسارات لتطابق مشروعك)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تحميل متغيرات البيئة (مفتاح Gemini API وغيره)
  await dotenv.load(fileName: '.env');

  // تهيئة Supabase (تأكد من وضع روابط مشروعك هنا)
  await Supabase.initialize(
    url: 'https://rzeetjsmiakievpthjxy.supabase.co/',
    anonKey: 'sb_publishable_QGi8lP0L6UvblvlmGXElEQ_QFU9ASxN',
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
    return const CategoriesScreen();
  }
}
