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
        .from('events3')
        .select()
        .eq('m_category', categoryId); // فلترة الفعاليات لتطابق التصنيف
        
    return response.map((json) => Event.fromJson(json)).toList();
  }



  dynamic get _currentUserId => supabase.auth.currentUser?.id;

  Future<void> addFavorite(int placeId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not logged in');

    try {
      await supabase.from('user_favorites').insert({
        'user_id': userId,
        'place_id': placeId,
      });
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        print('Item already favorited');
      } else {
        rethrow;
      }
    }
  }

  Future<List<int>> fetchFavorites() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    final response = await supabase
        .from('user_favorites')
        .select('place_id');

    return List<int>.from(response.map((row) => row['place_id'] as int));
  }

  Future<void> removeFavorite(int placeId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    await supabase
        .from('user_favorites')
        .delete()
        .match({'user_id': userId, 'place_id': placeId});
  }


  

}
