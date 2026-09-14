import 'dart:convert';

class Event {
  final int id;
  final String? title;
  final String? shortDescription;
  final String? fullDescription;
  final String? coverImageUrl;
  final String? thumbnailUrl;
  final bool? sameTimes;
  final Map<dynamic, dynamic>? times;
  final List<dynamic>? closedDays;
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

  static const Map<String, String> _dayNamesArabic = {
    'sun': 'الأحد',
    'mon': 'الإثنين',
    'tue': 'الثلاثاء',
    'wed': 'الأربعاء',
    'thu': 'الخميس',
    'fri': 'الجمعة',
    'sat': 'السبت',
  };

  static String _formatTimeRangeArabic(String timeRange) {
    // Format "10:00-15:00" or "08:00 - 21:00" into Arabic format "من 10:00 إلى 15:00"
    final parts = timeRange.split('-');
    if (parts.length == 2) {
      final start = parts[0].trim();
      final end = parts[1].trim();
      if (start.isNotEmpty && end.isNotEmpty) {
        return 'من $start إلى $end';
      }
    }
    return timeRange;
  }

  String? get formattedTimesArabic {
    if (times == null || times!.isEmpty) return null;

    // Case 1: Same time for all days (same_times: true or key is 'times')
    if (times!.containsKey('times')) {
      final timeStr = times!['times'].toString().trim();
      return _formatTimeRangeArabic(timeStr);
    }

    // Case 2: Schedule per day
    final List<String> schedule = [];
    final dayOrder = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
    for (final dayKey in dayOrder) {
      if (times!.containsKey(dayKey)) {
        final arDay = _dayNamesArabic[dayKey] ?? dayKey;
        final timeStr = times![dayKey].toString().trim();
        final formattedRange = _formatTimeRangeArabic(timeStr);
        schedule.add('$arDay: $formattedRange');
      }
    }

    // Also include any other days not in dayOrder if any
    for (final entry in times!.entries) {
      final key = entry.key.toString().toLowerCase();
      if (!dayOrder.contains(key) && key != 'times') {
        final arDay = _dayNamesArabic[key] ?? entry.key.toString();
        final formattedRange = _formatTimeRangeArabic(entry.value.toString().trim());
        schedule.add('$arDay: $formattedRange');
      }
    }

    return schedule.isNotEmpty ? schedule.join('\n') : null;
  }

  Event({
    //title fulldescription priceMin priceMax isFree  isregistrationRequired ticketUrl sCategory
    required this.id,
    this.title,
    this.shortDescription,
    this.fullDescription,
    this.coverImageUrl,
    this.thumbnailUrl,
    this.sameTimes,
    this.times,
    this.closedDays,
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
      sameTimes: json['same_time'] as bool?,
      times: _parseTimes(json['times']),
      closedDays: _parseClosedDays(json['closed_days']),
      isFree: json['is_free'] as bool?,
      priceMin: json['price_min'] != null
          ? (json['price_min'] as num).toDouble()
          : null,
      priceMax: json['price_max'] != null
          ? (json['price_max'] as num).toDouble()
          : null,
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
      'same_time': sameTimes,
      'times': times,
      'closed_days': closedDays,
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
