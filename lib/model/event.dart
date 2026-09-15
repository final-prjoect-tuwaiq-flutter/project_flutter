import 'dart:convert';

class Event {
  final int id;
  final String? title;
  final String? shortDescription;
  final String? fullDescription;
  final String? coverImageUrl;
  final String? thumbnailUrl;
  
  // الحقول الفعلية في Supabase
  final String? startAt; 
  final String? endAt;
  
  final bool? isFree;
  final double? priceMin;
  final double? priceMax;
  final bool? isRegistrationRequired;
  final bool? temp;
  final String? ticketUrl;
  final String? sCategory;
  final double? lat;
  final double? lng;
  final String? mCategory;
   String? url;

  String? get latLng => lat != null && lng != null ? '$lat,$lng' : null;

  // دالة لتنظيف الوقت وإزالة الثواني (تحويل 10:00:00 إلى 10:00)
  static String _formatTime(String timeStr) {
    List<String> parts = timeStr.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return timeStr;
  }

  // الجيتر الذي ستستخدمه الشاشة لعرض الوقت
  String? get formattedTimesArabic {
    if (startAt != null && endAt != null) {
      return 'من ${_formatTime(startAt!)} إلى ${_formatTime(endAt!)}';
    } else if (startAt != null) {
      return 'يبدأ من ${_formatTime(startAt!)}';
    } else if (endAt != null) {
      return 'ينتهي في ${_formatTime(endAt!)}';
    }
    return null;
  }

  Event({
    required this.id,
    this.title,
    this.shortDescription,
    this.fullDescription,
    this.coverImageUrl,
    this.thumbnailUrl,
    this.startAt,
    this.endAt,
    this.isFree,
    this.priceMin,
    this.priceMax,
    this.isRegistrationRequired,
    this.temp,
    this.ticketUrl,
    this.sCategory,
    this.lat,
    this.lng,
    this.mCategory,
    this.url,
  });

  factory Event.fromJson(Map<dynamic, dynamic> json) {
    return Event(
      id: json['id'] as int,
      title: json['title'] as String?,
      shortDescription: json['short_description'] as String?,
      fullDescription: json['full_description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      
      // قراءة الحقول الصحيحة الموجودة في قاعدة البيانات
      startAt: json['start_at']?.toString(),
      endAt: json['end_at']?.toString(),
      
      isFree: json['is_free'] as bool?,
      priceMin: json['price_min'] != null ? (json['price_min'] as num).toDouble() : null,
      priceMax: json['price_max'] != null ? (json['price_max'] as num).toDouble() : null,
      isRegistrationRequired: json['is_registration_required'] as bool?,
      temp: json['temp'] as bool?,
      ticketUrl: json['ticket_url'] as String?,
      sCategory: json['s_category']?.toString(),
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      mCategory: json['m_category']?.toString(),
      url: "https://www.google.com/maps/place/${json['lat']},${json['lng']}",
    );
  }

  static Map<dynamic, dynamic>? _parseTimes(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return null;

      try {
        final cleaned = text.replaceAll(RegExp(r',\s*}'), '}');
        final decoded = jsonDecode(cleaned);
        if (decoded is Map) return _parseTimes(decoded);
      } on FormatException {
        // Store non-JSON text as one shared time range.
      }

      return {'times': text};
    }
    if (value is Map) {
      return value.map(
        (key, time) => MapEntry(key.toString(), time.toString()),
      );
    }
    return null;
  }

  static List<dynamic>? _parseClosedDays(dynamic value) {
    if (value == null) return null;
    if (value is List) return List<dynamic>.from(value);
    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return null;
      try {
        final decoded = jsonDecode(text);
        if (decoded is List) return List<dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }


  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'short_description': shortDescription,
      'full_description': fullDescription,
      'cover_image_url': coverImageUrl,
      'thumbnail_url': thumbnailUrl,
      'start_at': startAt,
      'end_at': endAt,
      'is_free': isFree,
      'price_min': priceMin,
      'price_max': priceMax,
      'is_registration_required': isRegistrationRequired,
      'temp': temp,
      'ticket_url': ticketUrl,
      's_category': sCategory,
      'lat': lat,
      'lng': lng,
      'm_category': mCategory,
    };
  }
}