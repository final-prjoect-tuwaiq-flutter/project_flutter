import 'package:flutter/foundation.dart' show debugPrint;
import 'package:project_flutter/model/category_model.dart';
import 'package:project_flutter/model/event.dart';
import 'package:project_flutter/model/partner_account.dart';
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

  String? get _currentUserId => supabase.auth.currentUser?.id;

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

  /// يحذف سجل زيارة يخصّ المستخدم الحالي.
  ///
  /// الترشيح بـ user_id دفاع ثانٍ إلى جانب سياسات RLS: الحذف بالمعرّف وحده
  /// كان يعتمد كلياً على وجود السياسة على الخادم.
  Future<void> delete({required dynamic id, String idColumn = 'id'}) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('No authenticated user found.');

    await supabase
        .from('user_visited')
        .delete()
        .eq(idColumn, id)
        .eq('user_id', userId);
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

  // ==========================================
  // حسابات الشركاء (منظّم فعاليات / مالك منشأة)
  // ==========================================

  /// يجلب طلب الشراكة الخاص بالمستخدم الحالي، أو null إن لم يتقدّم بطلب.
  Future<PartnerAccount?> fetchPartnerAccount() async {
    final userId = _currentUserId;
    if (userId == null) return null;

    final response = await supabase
        .from('partner_accounts')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return PartnerAccount.fromJson(Map<String, dynamic>.from(response));
  }

  /// يرسل طلب شراكة جديد، أو يعيد إرسال طلب سابق مرفوض (يعود إلى قيد المراجعة).
  Future<PartnerAccount> submitPartnerApplication({
    required PartnerRole role,
    required String displayName,
    String? contactPhone,
    String? website,
    String? notes,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('No authenticated user found.');

    String? clean(String? value) {
      final text = value?.trim();
      return text == null || text.isEmpty ? null : text;
    }

    final response = await supabase
        .from('partner_accounts')
        .upsert({
          'user_id': userId,
          'partner_type': role.code,
          'display_name': displayName.trim(),
          'contact_phone': clean(contactPhone),
          'website': clean(website),
          'notes': clean(notes),
          'status': PartnerStatus.pending.code,
          'review_note': null,
          'reviewed_at': null,
        }, onConflict: 'user_id')
        .select()
        .single();

    return PartnerAccount.fromJson(Map<String, dynamic>.from(response));
  }

  /// ينشر مكاناً مباشرة في الدليل. متاح للشركاء المعتمدين فقط،
  /// وسياسات RLS على `events3` هي التي تفرض ذلك فعلياً على الخادم.
  Future<Map<String, dynamic>> publishPlace({
    required String title,
    required int categoryId,
    String? shortDescription,
    String? fullDescription,
    String? coverImageUrl,
    String? thumbnailUrl,
    double? lat,
    double? lng,
    bool isFree = true,
    double? priceMin,
    String? ticketUrl,
    bool requiresBooking = false,
    Map<String, dynamic>? times,
    DateTime? fromDate,
    DateTime? toDate,
    String? startAt,
    String? endAt,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('No authenticated user found.');

    String? clean(String? value) {
      final text = value?.trim();
      return text == null || text.isEmpty ? null : text;
    }

    String? dateOnly(DateTime? date) => date == null
        ? null
        : '${date.year.toString().padLeft(4, '0')}-'
              '${date.month.toString().padLeft(2, '0')}-'
              '${date.day.toString().padLeft(2, '0')}';

    final placeData = <String, dynamic>{
      'title': title.trim(),
      'm_category': categoryId,
      'short_description': clean(shortDescription),
      'full_description': clean(fullDescription),
      'cover_image_url': clean(coverImageUrl),
      'thumbnail_url': clean(thumbnailUrl),
      'lat': lat,
      'lng': lng,
      'is_free': isFree,
      'price_min': isFree ? null : priceMin,
      'ticket_url': clean(ticketUrl),
      'is_registration_required': requiresBooking,
      'times': times,
      // تاريخ فقط بلا وقت، فالعمودان يمثّلان فترة إتاحة لا لحظة زمنية.
      'from_date': dateOnly(fromDate),
      'to_date': dateOnly(toDate),
      'start_at': clean(startAt),
      'end_at': clean(endAt),
      'created_by': userId,
    };

    final response = await supabase
        .from('events3')
        .insert(placeData)
        .select()
        .single();

    return Map<String, dynamic>.from(response);
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
