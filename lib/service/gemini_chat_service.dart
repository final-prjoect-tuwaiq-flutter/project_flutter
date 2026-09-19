import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:project_flutter/model/category_model.dart';
import 'package:project_flutter/model/event.dart';
import 'package:project_flutter/service/supabase_data.dart';

class GeminiChatService {
  GeminiChatService._internal();

  static final GeminiChatService instance = GeminiChatService._internal();

  /// اسم النموذج قابل للضبط من `.env` حتى لا يحتاج تغييره إلى إصدار جديد
  /// من التطبيق عند تحديث أسماء نماذج Gemini.
  static const _fallbackModelName = 'gemini-2.5-flash';

  String get _modelName {
    final configured = dotenv.env['GEMINI_MODEL']?.trim();
    return configured == null || configured.isEmpty
        ? _fallbackModelName
        : configured;
  }

  final SupabaseData _data = SupabaseData();

  ChatSession? _chatSession;
  bool _isReady = false;

  /// الجلسة مبنية على بيانات مستخدم بعينه (مفضّلته)، فتُلغى عند تغيّر الحساب.
  String? _sessionUserId;

  bool get isReady => _isReady;

  /// يجهّز الجلسة إن لم تكن جاهزة، ويعيد استخدامها فيما عدا ذلك.
  ///
  /// بناء الجلسة يحمّل جدول الأماكن كاملاً ويضعه في تعليمات النظام؛ تكراره
  /// مع كل فتح للمحادثة كان يعني طلب شبكة ثقيلاً وفاتورة رموز كاملة في كل
  /// مرة، مع ضياع سياق الحوار السابق.
  Future<void> ensureSession() async {
    final currentUserId = _data.supabase.auth.currentUser?.id;
    if (_isReady && _chatSession != null && _sessionUserId == currentUserId) {
      return;
    }
    await startNewSession();
  }

  Future<void> startNewSession() async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw Exception(
        'لم يتم ضبط مفتاح Gemini API. أضف GEMINI_API_KEY في ملف .env',
      );
    }

    final systemPrompt = await _buildSystemPrompt();

    final model = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      systemInstruction: Content.system(systemPrompt),
      generationConfig: GenerationConfig(temperature: 0.6),
    );

    _chatSession = model.startChat();
    _sessionUserId = _data.supabase.auth.currentUser?.id;
    _isReady = true;
  }

  Future<String> sendMessage(String text) async {
    await ensureSession();

    final response = await _chatSession!.sendMessage(Content.text(text));
    final reply = response.text?.trim();
    if (reply == null || reply.isEmpty) {
      return 'عذراً، لم أتمكن من فهم طلبك. هل يمكنك إعادة صياغته؟';
    }
    return reply;
  }

  Future<String> _buildSystemPrompt() async {
    final results = await Future.wait([
      _data.getCategories(),
      _fetchAllPlaces(),
      // fetchFavorites تُرجع قائمة فارغة للزائر غير المسجّل، فالمرشد
      // يعمل بلا تسجيل دخول أيضاً.
      _data.fetchFavorites(),
    ]);

    final categories = results[0] as List<Category>;
    final places = results[1] as List<Event>;
    final favoriteIds = results[2] as List<int>;

    final categoryNames = {
      for (final category in categories) category.id.toString(): category.name,
    };

    final placesJson = places
        .map((place) => _placeToContext(place, categoryNames))
        .toList();
    final favoritePlaces = places
        .where((place) => favoriteIds.contains(place.id))
        .toList();
    final favoritesJson = favoritePlaces
        .map((place) => _placeToContext(place, categoryNames))
        .toList();

    return '''
أنت "مرشد المعزب"، مساعد ذكي داخل تطبيق "المعزب" لاستكشاف الأماكن والفعاليات.
مهمتك مساعدة المستخدم على اختيار أفضل مكان يناسبه، بالاعتماد على ميزانيته، اهتماماته، وأماكنه المفضلة.

قواعد مهمة:
- تحدث دائماً باللغة العربية، بأسلوب ودود ومختصر ومباشر.
- استخدم فقط الأماكن الموجودة في القائمة أدناه عند تقديم أي توصية. لا تخترع أماكن غير موجودة فيها.
- إذا لم تكن تعرف ميزانية المستخدم أو نوع الأماكن التي يفضلها، اسأله عنها بلطف قبل أن تقدّم توصية نهائية.
- عند التوصية بمكان، اذكر اسمه، لماذا يناسبه (السعر/الفئة/القرب من اهتماماته)، وأوقات العمل إن وُجدت.
- يمكنك اقتراح أكثر من مكان مع ترتيبها حسب الأنسب للمستخدم.
- إن لم توجد أي أماكن مطابقة لطلب المستخدم، أخبره بذلك بصراحة واقترح أقرب بديل متاح.
- لا ترشّح مكاناً قيمة `is_open` فيه false إلا إذا سأل المستخدم عنه بالاسم، وحينها نبّهه أنه مغلق حالياً واذكر `availability_note`.

قائمة الأماكن المتوفرة حالياً في التطبيق (JSON):
${jsonEncode(placesJson)}

الأماكن التي أضافها المستخدم إلى المفضلة حالياً (استخدمها لفهم ذوقه وتفضيلاته):
${favoritesJson.isEmpty ? 'لا توجد أماكن مفضلة بعد.' : jsonEncode(favoritesJson)}
''';
  }

  Future<List<Event>> _fetchAllPlaces() async {
    final supabase = _data.supabase;
    final response = await supabase.from('events3').select();
    return response.map((json) => Event.fromJson(json)).toList();
  }

  Map<String, dynamic> _placeToContext(
    Event place,
    Map<String, String> categoryNames,
  ) {
    return {
      'id': place.id,
      'title': place.title,
      'description': place.shortDescription,
      'category': place.sCategory ?? categoryNames[place.mCategory],
      'is_free': place.isFree,
      'price_min': place.priceMin,
      'price_max': place.priceMax,
      'working_hours': place.formattedWorkingHoursArabic,
      'closed_days': place.formattedClosedDaysArabic,
      // بلا هذه الحقول كان المساعد يرشّح أماكن مغلقة أو انتهت فترتها.
      'is_open': place.availability == PlaceAvailability.open,
      'availability_note': place.availabilityNote,
      'available_period': place.formattedDateRangeArabic,
    };
  }
}
