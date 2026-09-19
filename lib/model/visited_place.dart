import 'package:project_flutter/model/event.dart';

/// صف واحد من جدول `user_visited`: زيارة مسجّلة لمكان.
class VisitedVisit {
  final dynamic id;
  final Event event;
  final String? notes;
  final DateTime? visitedAt;

  const VisitedVisit({
    required this.id,
    required this.event,
    this.notes,
    this.visitedAt,
  });

  bool get hasNotes => notes != null && notes!.trim().isNotEmpty;
}

/// مكان واحد مع كل زياراته، مرتّبة من الأحدث للأقدم.
///
/// كل زيارة صف مستقل في `user_visited`، فزيارة المكان مرة أخرى كانت تُنشئ
/// بطاقة ثانية له في "زياراتي" وكأنه مكان جديد. التجميع يُبقي للمكان بطاقة
/// واحدة تسرد زياراته.
class VisitedPlace {
  final Event event;

  /// زيارة واحدة على الأقل، مرتّبة من الأحدث للأقدم.
  final List<VisitedVisit> visits;

  const VisitedPlace({required this.event, required this.visits});

  DateTime? get lastVisitAt => visits.first.visitedAt;

  int get visitCount => visits.length;

  bool get isRepeated => visits.length > 1;

  /// الأحدث أولاً؛ الزيارات بلا تاريخ تُؤخَّر إلى النهاية.
  static int _byNewest(VisitedVisit a, VisitedVisit b) {
    final dateA = a.visitedAt ?? DateTime(0);
    final dateB = b.visitedAt ?? DateTime(0);
    return dateB.compareTo(dateA);
  }

  /// يجمع الصفوف حسب المكان، ويرتّب المجموعات بتاريخ آخر زيارة.
  static List<VisitedPlace> group(List<VisitedVisit> rows) {
    final byPlace = <int, List<VisitedVisit>>{};
    for (final row in rows) {
      byPlace.putIfAbsent(row.event.id, () => <VisitedVisit>[]).add(row);
    }

    final places = byPlace.values.map((visits) {
      final sorted = [...visits]..sort(_byNewest);
      return VisitedPlace(event: sorted.first.event, visits: sorted);
    }).toList();

    places.sort(
      (a, b) => (b.lastVisitAt ?? DateTime(0)).compareTo(
        a.lastVisitAt ?? DateTime(0),
      ),
    );

    return places;
  }

  /// إجمالي الزيارات في كل الأماكن (لا عدد الأماكن).
  static int totalVisits(List<VisitedPlace> places) =>
      places.fold<int>(0, (sum, place) => sum + place.visitCount);

  /// نسخة بلا الزيارة المحذوفة، أو null إذا لم يبقَ للمكان زيارات.
  VisitedPlace? without(dynamic visitId) {
    final remaining = visits.where((visit) => visit.id != visitId).toList();
    if (remaining.isEmpty) return null;
    return VisitedPlace(event: event, visits: remaining);
  }

  /// يزيل زيارة من القائمة كلها، ويُسقط الأماكن التي لم تبقَ لها زيارات.
  static List<VisitedPlace> removeVisit(
    List<VisitedPlace> places,
    dynamic visitId,
  ) => places
      .map((place) => place.without(visitId))
      .whereType<VisitedPlace>()
      .toList();
}
