import 'package:flutter/material.dart';
import 'package:project_flutter/pages/categories_screen.dart';
import 'package:project_flutter/pages/sign_up_page.dart';
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
// كلاس لفحص حالة المستخدم عند فتح التطبيق
// ==========================================
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // اختياري: يمكنك وضع مستمع (Listener) لحالة المستخدم هنا لتسجيل الخروج التلقائي وغيره
  }

  @override
  Widget build(BuildContext context) {
    // التحقق مما إذا كان لدى المستخدم جلسة (Session) نشطة في Supabase
    final session = Supabase.instance.client.auth.currentSession;

    // إذا لم يكن لديه جلسة (غير مسجل دخول) -> وجّهه لصفحة إنشاء الحساب
    if (session == null) {
      return const SignUpPage(); // سيفتح على صفحة التسجيل كما طلبت
    }

    // إذا كان مسجل دخول مسبقاً -> افتح له صفحة التصنيفات مباشرة
    return const CategoriesScreen();
  }
}
