import 'package:flutter/foundation.dart' show debugPrint;
import 'package:project_flutter/model/category_model.dart';
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
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
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
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
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
        debugPrint('Item already favorited');
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
        .select('place_id')
        .eq('user_id', userId);

    return List<int>.from(response.map((row) => row['place_id'] as int));
  }

  Future<void> removeFavorite(int placeId) async {
    final userId = _currentUserId;
    if (userId == null) return;

    await supabase.from('user_favorites').delete().match({
      'user_id': userId,
      'place_id': placeId,
    });
  }

  Future<Map<String, dynamic>> push({
    required Map<String, dynamic> visitedData,
  }) async {
    final response = await supabase
        .from('user_visited')
        .insert(visitedData)
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  Future<List<Map<String, dynamic>>> pullForCurrentUser({
    String userIdColumn = 'user_id',
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final response = await supabase
        .from('user_visited')
        .select()
        .eq(userIdColumn, user.id);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> pushForCurrentUser({
    required Map<String, dynamic> visitedData,
    String userIdColumn = 'user_id',
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final data = <String, dynamic>{...visitedData, userIdColumn: user.id};

    return push(visitedData: data);
  }

  Future<void> delete({required dynamic id, String idColumn = 'id'}) async {
    await supabase.from('user_visited').delete().eq(idColumn, id);
  }

  Future<Map<String, dynamic>> pushRequest({
    required Map<String, dynamic> requestData,
  }) async {
    final response = await supabase
        .from('users_requests')
        .insert(requestData)
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  Future<Map<String, dynamic>> pushPlaceRequest({
    required String placeName,
    required String location,
    String? url,
  }) async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final requestData = <String, dynamic>{
      'user_id': user.id,
      'place_name': placeName,
      'location': location,
    };
    if (url != null && url.trim().isNotEmpty) requestData['url'] = url.trim();

    return pushRequest(requestData: requestData);
  }

  Future<Map<String, dynamic>> addVisitedPlace({
    required int placeId,
    required String notes,
    required DateTime visitedAt,
  }) {
    return pushForCurrentUser(
      visitedData: {
        'place_id': placeId,
        'notes': notes,
        'visited_at': visitedAt.toIso8601String(),
      },
    );
  }
}
