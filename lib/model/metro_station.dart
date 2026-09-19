import 'package:flutter/material.dart';

/// صف من جدول `metro_stations`.
///
/// المحطات التبادلية (مثل "قصر الحكم" الذي يخدمه المسار البرتقالي والأزرق)
/// تصل من الخادم كصف مستقل لكل مسار. [MetroStation.merged] تدمج تلك الصفوف
/// في محطة واحدة تحمل مساراتها كلها، فلا تتكرر المحطة في الواجهة.
class MetroStation {
  final String stationCode;
  final String stationName;
  final String lineName;
  final double lat;
  final double lng;

  /// المسارات الإضافية للمحطة المدمجة. تبقى فارغة للصف الخام الواحد،
  /// و[serviceLines] هي المدخل الموحّد للقراءة في الحالتين.
  final List<String> lines;

  const MetroStation({
    required this.stationCode,
    required this.stationName,
    required this.lineName,
    required this.lat,
    required this.lng,
    this.lines = const [],
  });

  /// يدمج صفوف المحطة التبادلية: المحطة التي تخدمها عدة مسارات تصل من
  /// الخادم كصف لكل مسار، فكانت تظهر مكرّرة في قائمة المحطات القريبة
  /// (مثل "قصر الحكم" مرة للبرتقالي ومرة للأزرق) وتضخّم عدّادها.
  ///
  /// المطابقة بالاسم المُطبَّع، فإن غاب الاسم فبالرمز، فإن غاب الاثنان
  /// فبالإحداثيات — حتى لا تنهار الصفوف المجهولة كلها في محطة واحدة.
  static List<MetroStation> mergeRows(List<MetroStation> rows) {
    final groups = <String, List<MetroStation>>{};

    for (final row in rows) {
      final name = normalizeArabic(row.stationName);
      final code = row.stationCode.trim().toLowerCase();
      final key = name.isNotEmpty
          ? 'n:$name'
          : code.isNotEmpty
          ? 'c:$code'
          : 'p:${row.lat.toStringAsFixed(5)},${row.lng.toStringAsFixed(5)}';

      groups.putIfAbsent(key, () => <MetroStation>[]).add(row);
    }

    return groups.values.map(merged).toList(growable: false);
  }

  /// يدمج صفوف المحطة الواحدة في محطة تحمل كل مساراتها.
  ///
  /// الإحداثيات تؤخذ كمركز أرصفة المحطة، لأن كل مسار في المحطة التبادلية
  /// يُسجَّل بإحداثيات رصيفه، والفرق بينها أمتار لا تؤثر على نطاق المشي.
  static MetroStation merged(List<MetroStation> rows) {
    assert(rows.isNotEmpty);
    if (rows.length == 1) return rows.first;

    final seen = <String>{};
    final lines = <String>[];
    for (final row in rows) {
      final line = row.lineName.trim();
      if (line.isEmpty) continue;
      // مفتاح المقارنة مُطبَّع حتى لا يتكرر المسار باختلاف الهمزة أو المسافات.
      if (seen.add(normalizeArabic(line))) lines.add(line);
    }

    // نفضّل الصف الذي يحمل اسماً ورمزاً حتى لا تفقد المحطة المدمجة بياناتها.
    final named = rows.firstWhere(
      (row) => row.stationName.trim().isNotEmpty,
      orElse: () => rows.first,
    );
    final coded = rows.firstWhere(
      (row) => row.stationCode.trim().isNotEmpty,
      orElse: () => rows.first,
    );

    return MetroStation(
      stationCode: coded.stationCode,
      stationName: named.stationName,
      lineName: lines.isEmpty ? rows.first.lineName : lines.first,
      lat: rows.map((row) => row.lat).reduce((a, b) => a + b) / rows.length,
      lng: rows.map((row) => row.lng).reduce((a, b) => a + b) / rows.length,
      lines: lines,
    );
  }

  /// تطبيع عربي خفيف للمقارنة فقط: يوحّد الألف والياء والتاء المربوطة،
  /// ويحذف التطويل والتشكيل والمسافات الزائدة.
  static String normalizeArabic(String value) {
    final buffer = StringBuffer();
    for (final rune in value.trim().toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      // التشكيل والتطويل لا يغيّران هوية الاسم.
      if (rune >= 0x064B && rune <= 0x0652) continue;
      if (char == 'ـ') continue;
      if (char == 'أ' || char == 'إ' || char == 'آ') {
        buffer.write('ا');
      } else if (char == 'ة') {
        buffer.write('ه');
      } else if (char == 'ى') {
        buffer.write('ي');
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ');
  }

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

  /// كل المسارات التي تخدم المحطة، بمسار واحد على الأقل للصف الخام.
  /// هذا هو المدخل الذي تقرأ منه الواجهة، فلا تحتاج لمعرفة إن كانت المحطة
  /// مدمجة أم لا.
  List<String> get serviceLines {
    if (lines.isNotEmpty) return lines;
    final single = lineName.trim();
    return single.isEmpty ? const [] : [single];
  }

  /// هل تخدم المحطة أكثر من مسار (محطة تبادلية)؟
  bool get isInterchange => serviceLines.length > 1;

  /// ألوان [serviceLines] بالترتيب نفسه، وقد يكون العنصر null لمسار مجهول.
  List<Color?> get serviceLineColors =>
      serviceLines.map(colorForLine).toList(growable: false);

  /// لون المسار حسب اسمه. أسماء المسارات تختلف بين المصادر (رقم أو لون،
  /// عربي أو إنجليزي)، فنطابق بالكلمات المفتاحية ونرجع null عند عدم التعرّف
  /// ليستخدم الاستدعاء لون التطبيق الافتراضي.
  Color? get lineColor => colorForLine(lineName);

  /// لون مسار بعينه بالاسم.
  static Color? colorForLine(String line) {
    final name = line.toLowerCase();

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
