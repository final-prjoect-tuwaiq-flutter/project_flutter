import 'package:flutter/material.dart';

/// صف من جدول `metro_stations`.
class MetroStation {
  final String stationCode;
  final String stationName;
  final String lineName;
  final double lat;
  final double lng;

  const MetroStation({
    required this.stationCode,
    required this.stationName,
    required this.lineName,
    required this.lat,
    required this.lng,
  });

  /// يُرجع null للصفوف الناقصة (بدون إحداثيات) بدل أن يرمي استثناءً.
  static MetroStation? tryFromJson(Map<String, dynamic> json) {
    final lat = (json['lat'] as num?)?.toDouble();
    final lng = (json['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;

    return MetroStation(
      stationCode: json['station_code']?.toString() ?? '',
      stationName: json['station_name']?.toString() ?? '',
      lineName: json['line_name']?.toString() ?? '',
      lat: lat,
      lng: lng,
    );
  }

  /// الاسم المعروض: الاسم إن وُجد، وإلا رمز المحطة.
  String get displayName =>
      stationName.trim().isNotEmpty ? stationName.trim() : stationCode.trim();

  /// لون المسار حسب اسمه. أسماء المسارات تختلف بين المصادر (رقم أو لون،
  /// عربي أو إنجليزي)، فنطابق بالكلمات المفتاحية ونرجع null عند عدم التعرّف
  /// ليستخدم الاستدعاء لون التطبيق الافتراضي.
  Color? get lineColor {
    final name = lineName.toLowerCase();

    bool has(List<String> keywords) =>
        keywords.any((keyword) => name.contains(keyword));

    if (has(['أزرق', 'ازرق', 'blue', '1'])) return const Color(0xFF1B67B2);
    if (has(['أحمر', 'احمر', 'red', '2'])) return const Color(0xFFD23B3B);
    if (has(['برتقال', 'orange', '3'])) return const Color(0xFFE8782B);
    if (has(['أصفر', 'اصفر', 'yellow', '4'])) return const Color(0xFFE0B117);
    if (has(['أخضر', 'اخضر', 'green', '5'])) return const Color(0xFF2F9E62);
    if (has(['بنفسج', 'purple', 'violet', '6'])) return const Color(0xFF7B4BA8);
    return null;
  }
}

/// محطة قريبة من مكان معيّن، مع المسافة بينهما بالمتر.
class NearbyStation {
  final MetroStation station;
  final double distanceMeters;

  const NearbyStation({required this.station, required this.distanceMeters});

  /// تقدير زمن المشي على أساس ٨٠ متراً في الدقيقة.
  int get walkMinutes => (distanceMeters / 80).ceil().clamp(1, 999);
}

/// خلاصة إمكانية الوصول للمكان بالمترو.
class MetroAccess {
  /// أقرب محطة مهما كانت بعيدة (لإظهار معلومة مفيدة حتى لو تعذّر المشي).
  final NearbyStation nearest;

  /// المحطات داخل نطاق المشي، مرتّبة من الأقرب للأبعد.
  final List<NearbyStation> withinWalk;

  const MetroAccess({required this.nearest, required this.withinWalk});

  bool get isWalkable => withinWalk.isNotEmpty;
}
