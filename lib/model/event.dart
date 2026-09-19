import 'dart:convert';

/// حالة إتاحة المكان كما تُعرض للزائر.
enum PlaceAvailability {
  /// مفتوح ضمن فترة إتاحته.
  open,

  /// أغلقه صاحبه (`is_open = false`).
  closed,

  /// لم تبدأ فترة إتاحته بعد (`from_date` في المستقبل).
  notStarted,

  /// انتهت فترة إتاحته (`to_date` في الماضي).
  ended,
}

class Event {
  final int id;
  final String? title;
  final String? shortDescription;
  final String? fullDescription;
  final String? coverImageUrl;
  final String? thumbnailUrl;

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

  /// هل المكان مفتوح؟ `false` تعني أن صاحبه أغلقه، و null تعني أن الحالة
  /// غير مسجّلة فنعامله كمفتوح.
  final bool? isOpen;

  /// فترة إتاحة المكان (اختيارية): من تاريخ وإلى تاريخ.
  final DateTime? fromDate;
  final DateTime? toDate;

  /// الحالة المعروضة للزائر: الإغلاق اليدوي أولاً، ثم فترة الإتاحة.
  PlaceAvailability get availability {
    if (isOpen == false) return PlaceAvailability.closed;

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    if (toDate != null && startOfToday.isAfter(_dateOnly(toDate!))) {
      return PlaceAvailability.ended;
    }
    if (fromDate != null && startOfToday.isBefore(_dateOnly(fromDate!))) {
      return PlaceAvailability.notStarted;
    }
    return PlaceAvailability.open;
  }

  /// هل يجب تنبيه الزائر إلى أن المكان غير متاح الآن؟
  bool get isUnavailable => availability != PlaceAvailability.open;

  /// كلمة مختصرة تُعرض على البطاقة وفي صفحة التفاصيل، أو null إن كان متاحاً.
  String? get availabilityLabel => switch (availability) {
    PlaceAvailability.open => null,
    PlaceAvailability.closed => 'مغلق',
    PlaceAvailability.notStarted => 'لم يفتح بعد',
    PlaceAvailability.ended => 'انتهى',
  };

  /// جملة توضّح سبب عدم الإتاحة، أو null إن كان المكان متاحاً.
  String? get availabilityNote => switch (availability) {
    PlaceAvailability.open => null,
    PlaceAvailability.closed => 'المكان مغلق حالياً.',
    PlaceAvailability.notStarted =>
      'يفتح المكان في ${_formatDateArabic(fromDate!)}.',
    PlaceAvailability.ended =>
      'انتهت فترة إتاحة المكان في ${_formatDateArabic(toDate!)}.',
  };

  /// فترة الإتاحة بالعربية، أو null إن لم تُسجَّل تواريخ.
  String? get formattedDateRangeArabic {
    if (fromDate == null && toDate == null) return null;
    if (fromDate != null && toDate != null) {
      return 'من ${_formatDateArabic(fromDate!)} إلى ${_formatDateArabic(toDate!)}';
    }
    if (fromDate != null) return 'يبدأ ${_formatDateArabic(fromDate!)}';
    return 'ينتهي ${_formatDateArabic(toDate!)}';
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static const List<String> _arabicMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];

  static String _formatDateArabic(DateTime date) =>
      '${date.day} ${_arabicMonths[date.month - 1]} ${date.year}';

  String? get latLng => lat != null && lng != null ? '$lat,$lng' : null;

  static String _formatTime(String timeStr) {
    List<String> parts = timeStr.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return timeStr;
  }

  /// سطر واحد مختصر لأوقات العمل يصلح لبطاقة القائمة، ولا يُعرض إلا حين
  /// تتساوى أوقات كل الأيام (`{"times": "..."}`)، فالجدول المفصّل يحتاج
  /// أسطراً متعددة تظهر في صفحة التفاصيل.
  String? get formattedTimesArabic {
    if (times == null || times!.length != 1) return null;
    final value = times!['times']?.toString().trim();
    if (value == null || value.isEmpty) return null;
    return _formatScheduleValue(value);
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
    this.isOpen,
    this.fromDate,
    this.toDate,
  });

  factory Event.fromJson(Map<dynamic, dynamic> json) {
    return Event(
      id: json['id'] as int,
      title: json['title'] as String?,
      shortDescription: json['short_description'] as String?,
      fullDescription: json['full_description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
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
      // بلا إحداثيات لا يوجد رابط خرائط صالح؛ تركه null يجعل الواجهة
      // تعرض «الموقع غير متوفر» بدل فتح الخرائط على موقع خاطئ.
      url: _mapsUrl(json['lat'], json['lng']),

      // التعديل هنا لقراءة البيانات بشكل صحيح من Supabase
      closedDays: _parseClosedDays(json['closed_days']),
      times: _parseTimes(json['times']),
      isOpen: _parseBool(json['is_open']),
      fromDate: _parseDate(json['from_date']),
      toDate: _parseDate(json['to_date']),
    );
  }

  /// العمود قد يعود منطقياً أو نصاً (`"true"`/`"false"`) حسب نوعه في القاعدة.
  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    final text = value.toString().trim().toLowerCase();
    if (text == 'true' || text == 't' || text == '1') return true;
    if (text == 'false' || text == 'f' || text == '0') return false;
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text);
  }

  static String? _mapsUrl(dynamic lat, dynamic lng) {
    if (lat == null || lng == null) return null;
    return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
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
        // النص ليس JSON صالحاً، فيُعامل كنص أوقات حر.
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
      'is_open': isOpen,
      'from_date': fromDate?.toIso8601String(),
      'to_date': toDate?.toIso8601String(),
    };
  }
}
