import 'package:flutter_test/flutter_test.dart';
import 'package:project_flutter/model/event.dart';
import 'package:project_flutter/model/visited_place.dart';

Event _place(int id, String title) => Event(id: id, title: title);

VisitedVisit _visit(int visitId, Event place, {DateTime? on, String? notes}) =>
    VisitedVisit(id: visitId, event: place, visitedAt: on, notes: notes);

void main() {
  final riyadhBoulevard = _place(1, 'بوليفارد الرياض');
  final diriyah = _place(2, 'الدرعية');

  group('تجميع الزيارات حسب المكان', () {
    test('زيارة المكان مرتين تبقى بطاقة واحدة', () {
      // كان كل صف يظهر كمكان مستقل، فتتكرّر بطاقة المكان بعدد زياراته.
      final places = VisitedPlace.group([
        _visit(10, riyadhBoulevard, on: DateTime(2026, 3, 1)),
        _visit(11, riyadhBoulevard, on: DateTime(2026, 5, 20)),
      ]);

      expect(places, hasLength(1));
      expect(places.single.visitCount, 2);
      expect(places.single.isRepeated, isTrue);
      expect(places.single.event.title, 'بوليفارد الرياض');
    });

    test('الأماكن المختلفة تبقى منفصلة', () {
      final places = VisitedPlace.group([
        _visit(10, riyadhBoulevard, on: DateTime(2026, 3, 1)),
        _visit(11, diriyah, on: DateTime(2026, 4, 1)),
      ]);

      expect(places, hasLength(2));
      expect(places.every((place) => place.isRepeated), isFalse);
    });

    test('زيارات المكان مرتّبة من الأحدث للأقدم', () {
      final places = VisitedPlace.group([
        _visit(10, riyadhBoulevard, on: DateTime(2026, 1, 5)),
        _visit(11, riyadhBoulevard, on: DateTime(2026, 6, 9)),
        _visit(12, riyadhBoulevard, on: DateTime(2026, 3, 2)),
      ]);

      expect(places.single.visits.map((visit) => visit.id).toList(), [
        11,
        12,
        10,
      ]);
      expect(places.single.lastVisitAt, DateTime(2026, 6, 9));
    });

    test('الأماكن مرتّبة بآخر زيارة', () {
      final places = VisitedPlace.group([
        _visit(10, riyadhBoulevard, on: DateTime(2026, 1, 1)),
        _visit(11, diriyah, on: DateTime(2026, 2, 1)),
        _visit(12, riyadhBoulevard, on: DateTime(2026, 3, 1)),
      ]);

      expect(places.first.event.id, riyadhBoulevard.id);
      expect(places.last.event.id, diriyah.id);
    });

    test('الزيارات بلا تاريخ تُؤخَّر داخل المكان', () {
      final places = VisitedPlace.group([
        _visit(10, riyadhBoulevard),
        _visit(11, riyadhBoulevard, on: DateTime(2026, 2, 2)),
      ]);

      expect(places.single.visits.first.id, 11);
      expect(places.single.visits.last.visitedAt, isNull);
    });

    test('العدّاد يحسب الزيارات لا الأماكن', () {
      final places = VisitedPlace.group([
        _visit(10, riyadhBoulevard, on: DateTime(2026, 1, 1)),
        _visit(11, riyadhBoulevard, on: DateTime(2026, 2, 1)),
        _visit(12, diriyah, on: DateTime(2026, 3, 1)),
      ]);

      expect(places, hasLength(2));
      expect(VisitedPlace.totalVisits(places), 3);
    });

    test('قائمة فارغة تُنتج مجموعات فارغة', () {
      expect(VisitedPlace.group(const []), isEmpty);
      expect(VisitedPlace.totalVisits(const []), 0);
    });
  });

  group('حذف زيارة واحدة', () {
    test('يبقى المكان ما دامت له زيارة أخرى', () {
      final places = VisitedPlace.group([
        _visit(10, riyadhBoulevard, on: DateTime(2026, 1, 1)),
        _visit(11, riyadhBoulevard, on: DateTime(2026, 2, 1)),
      ]);

      final after = VisitedPlace.removeVisit(places, 11);

      expect(after, hasLength(1));
      expect(after.single.visitCount, 1);
      expect(after.single.visits.single.id, 10);
      expect(after.single.isRepeated, isFalse);
    });

    test('يختفي المكان عند حذف آخر زياراته', () {
      final places = VisitedPlace.group([
        _visit(10, riyadhBoulevard, on: DateTime(2026, 1, 1)),
        _visit(11, diriyah, on: DateTime(2026, 2, 1)),
      ]);

      final after = VisitedPlace.removeVisit(places, 10);

      expect(after, hasLength(1));
      expect(after.single.event.id, diriyah.id);
    });

    test('حذف معرّف غير موجود لا يغيّر شيئاً', () {
      final places = VisitedPlace.group([
        _visit(10, riyadhBoulevard, on: DateTime(2026, 1, 1)),
      ]);

      expect(VisitedPlace.removeVisit(places, 999), hasLength(1));
    });
  });

  group('الملاحظات', () {
    test('hasNotes يتجاهل الفراغ', () {
      expect(_visit(1, diriyah, notes: 'مكان جميل').hasNotes, isTrue);
      expect(_visit(1, diriyah, notes: '   ').hasNotes, isFalse);
      expect(_visit(1, diriyah).hasNotes, isFalse);
    });
  });
}
