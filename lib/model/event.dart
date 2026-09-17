import 'dart:convert';

class Event {
  final int id;
  final String? title;
  final String? shortDescription;
  final String? fullDescription;
  final String? coverImageUrl;
  final String? thumbnailUrl;

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

  // الحقول الجديدة لأيام الإغلاق والأوقات
  final List<dynamic>? closedDays;
  final Map<dynamic, dynamic>? times;

  String? get latLng => lat != null && lng != null ? '$lat,$lng' : null;

  static String _formatTime(String timeStr) {
    List<String> parts = timeStr.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return timeStr;
  }

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

  // --- دالة ترجمة الأيام من الإنجليزية للعربية ---
  String _translateDay(String day) {
    switch (day.toLowerCase().trim()) {
      case '0':
      case 'sun':
        return 'الأحد';
      case '1':
      case 'mon':
        return 'الاثنين';
      case '2':
      case 'tue':
        return 'الثلاثاء';
      case '3':
      case 'wed':
        return 'الأربعاء';
      case '4':
      case 'thu':
        return 'الخميس';
      case '5':
      case 'fri':
        return 'الجمعة';
      case '6':
      case 'sat':
        return 'السبت';
      default:
        return day;
    }
  }

  int? _dayIndex(String day) {
    switch (day.toLowerCase().trim()) {
      case '0':
      case 'sun':
      case 'الأحد':
        return 0;
      case '1':
      case 'mon':
      case 'الاثنين':
        return 1;
      case '2':
      case 'tue':
      case 'الثلاثاء':
        return 2;
      case '3':
      case 'wed':
      case 'الأربعاء':
        return 3;
      case '4':
      case 'thu':
      case 'الخميس':
        return 4;
      case '5':
      case 'fri':
      case 'الجمعة':
        return 5;
      case '6':
      case 'sat':
      case 'السبت':
        return 6;
      default:
        return null;
    }
  }

  String _formatDayGroup(List<String> days) {
    final sortedDays = days.toSet().toList()
      ..sort((first, second) {
        final firstIndex = _dayIndex(first) ?? 7;
        final secondIndex = _dayIndex(second) ?? 7;
        return firstIndex.compareTo(secondIndex);
      });

    final ranges = <String>[];
    var rangeStart = 0;

    for (var index = 1; index <= sortedDays.length; index++) {
      final isConsecutive =
          index < sortedDays.length &&
          (_dayIndex(sortedDays[index]) ?? -1) ==
              (_dayIndex(sortedDays[index - 1]) ?? -2) + 1;

      if (isConsecutive) continue;

      final rangeLength = index - rangeStart;
      if (rangeLength >= 3) {
        ranges.add('من ${sortedDays[rangeStart]} إلى ${sortedDays[index - 1]}');
      } else if (rangeLength == 2 &&
          (_dayIndex(sortedDays[rangeStart + 1]) ?? -1) ==
              (_dayIndex(sortedDays[rangeStart]) ?? -2) + 1) {
        ranges.add('${sortedDays[rangeStart]} و ${sortedDays[index - 1]}');
      } else {
        ranges.add(sortedDays.sublist(rangeStart, index).join('، '));
      }
      rangeStart = index;
    }

    return ranges.join('، ');
  }

  String _formatScheduleValue(dynamic value) {
    final text = value.toString().trim();
    if (!RegExp(r'[-–—]').hasMatch(text)) return text;

    final intervals = text
        .split(RegExp(r'[,،;]'))
        .map((interval) => interval.trim())
        .where((interval) => interval.isNotEmpty)
        .toList();

    intervals.sort((first, second) {
      final firstStart = first.split(RegExp(r'[-–—]')).first.trim();
      final secondStart = second.split(RegExp(r'[-–—]')).first.trim();
      return firstStart.compareTo(secondStart);
    });

    final formattedIntervals = intervals.map((interval) {
      final parts = interval.trim().split(RegExp(r'[-–—]'));
      if (parts.length < 2) return interval.trim();

      final start = _formatTime(parts[0].replaceAll(' ', ''));
      final end = _formatTime(parts[1].replaceAll(' ', ''));
      if (start == end) return 'مغلق';
      return 'من $start إلى $end';
    }).toList();

    return formattedIntervals.join('، ');
  }

  // --- جلب أوقات العمل مترجمة ومرتبة ---
  String? get formattedWorkingHoursArabic {
    if (times == null || times!.isEmpty) return null;

    if (times!.length == 1 && times!.containsKey('times')) {
      final t = times!['times'].toString().trim();
      final formattedSchedule = _formatScheduleValue(t);
      if (closedDays?.isNotEmpty != true) {
        return 'من الأحد إلى السبت: $formattedSchedule';
      }
      return formattedSchedule;
    }

    final grouped = <String, List<String>>{};
    times!.forEach((key, value) {
      final translatedDay = _translateDay(key.toString());
      final formattedValue = _formatScheduleValue(value);
      grouped.putIfAbsent(formattedValue, () => []).add(translatedDay);
    });

    final sortedGroups = grouped.entries.toList()
      ..sort((first, second) {
        final firstDay = first.value
            .map(_dayIndex)
            .whereType<int>()
            .fold(7, (min, value) => value < min ? value : min);
        final secondDay = second.value
            .map(_dayIndex)
            .whereType<int>()
            .fold(7, (min, value) => value < min ? value : min);
        return firstDay.compareTo(secondDay);
      });

    return sortedGroups
        .map((entry) => '${_formatDayGroup(entry.value)}: ${entry.key}')
        .join('\n');
  }

  // --- جلب أيام الإغلاق مترجمة ---
  String? get formattedClosedDaysArabic {
    if (closedDays == null || closedDays!.isEmpty) {
      return 'لا توجد أيام إغلاق';
    }

    final names = closedDays!
        .map((day) => _translateDay(day.toString()))
        .where((day) => _dayIndex(day) != null)
        .toSet()
        .toList();

    if (names.isEmpty) return 'لا توجد أيام إغلاق';
    return '${_formatDayGroup(names)} مغلق';
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
    this.closedDays,
    this.times,
  });

  factory Event.fromJson(Map<dynamic, dynamic> json) {
    return Event(
      id: json['id'] as int,
      title: json['title'] as String?,
      shortDescription: json['short_description'] as String?,
      fullDescription: json['full_description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      startAt: json['start_at']?.toString(),
      endAt: json['end_at']?.toString(),
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

      // التعديل هنا لقراءة البيانات بشكل صحيح من Supabase
      closedDays: _parseClosedDays(json['closed_days']),
      times: _parseTimes(json['times']),
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
      } on FormatException {}
      return {'times': text};
    }
    if (value is Map)
      return value.map(
        (key, time) => MapEntry(key.toString(), time.toString()),
      );
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
      'closed_days': closedDays,
      'times': times,
    };
  }
}
