import 'package:flutter/material.dart';
import 'package:project_flutter/screens/categories_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_flutter/theme/theme.dart'; // مسار ملف الثيم الجديد

// استيراد الصفحات الخاصة بك (تأكد من تعديل المسارات لتطابق مشروعك)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Supabase (تأكد من وضع روابط مشروعك هنا)
  await Supabase.initialize(
    url: 'https://rzeetjsmiakievpthjxy.supabase.co/',
    anonKey: 'sb_publishable_QGi8lP0L6UvblvlmGXElEQ_QFU9ASxN',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // داخل دالة build
    return MaterialApp(
      title: 'المعزب',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // <<--- هذا السطر هو الأهم
      home: const AuthWrapper(),
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
