import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages

import 'package:project_flutter/pages/categories_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
 // مسار شاشة التصنيفات

void main() async {
  // التأكد من تهيئة الفلاتر أولاً
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Supabase (استبدل القيم ببيانات مشروعك من إعدادات Supabase API)
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
    return MaterialApp(
      title: 'Events App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(
        
          
      ),
      home:  CategoriesScreen(), // جعل شاشة التصنيفات هي الشاشة الرئيسية
    );
  }
}


