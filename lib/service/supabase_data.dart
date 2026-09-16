import 'package:project_flutter/model/catagory_model.dart';
import 'package:project_flutter/model/event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseData {
  // أخذ نسخة (Instance) من عميل Supabase
  final supabase = Supabase.instance.client;

  // ==========================================
  // دوال البيانات (تم الحفاظ عليها كما هي)
  // ==========================================
  
  Future<List<Category>> getCategories() async {
    final response = await supabase.from('catgories').select();
    return response.map((json) => Category.fromJson(json)).toList();
  }

  Future<List<Event>> getEventsByCategory(int categoryId) async {
    final response = await supabase
        .from('events3')
        .select()
        .eq('m_category', categoryId);
    return response.map((json) => Event.fromJson(json)).toList();
  }

  // ==========================================
  // دوال المصادقة (Authentication) الجديدة
  // ==========================================

  // دالة إنشاء حساب جديد
  Future<AuthResponse> signUp({required String email, required String password}) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow; // إعادة رمي الخطأ للكنترولر للتعامل معه وعرضه للمستخدم
    }
  }

  // دالة تسجيل الدخول
  Future<AuthResponse> login({required String email, required String password}) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}