import 'package:project_flutter/model/catagory_model.dart';
import 'package:project_flutter/model/event.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

 // مسار مودل التصنيف
    // مسار مودل الفعالية

class SupabaseData {
  // أخذ نسخة (Instance) من عميل Supabase
  final supabase = Supabase.instance.client;


  // دالة لجلب جميع التصنيفات
  Future<List<Category>> getCategories() async {
    final response = await supabase.from('catgories').select();
    
    // تحويل البيانات القادمة (List of Maps) إلى (List of Category Objects)
    return response.map((json) => Category.fromJson(json)).toList();
  }

  // دالة لجلب الفعاليات بناءً على رقم التصنيف (s_category)
  Future<List<Event>> getEventsByCategory(int categoryId) async {
    final response = await supabase
        .from('events2')
        .select()
        .eq('m_category', categoryId); // فلترة الفعاليات لتطابق التصنيف
        
    return response.map((json) => Event.fromJson(json)).toList();
  }
}
