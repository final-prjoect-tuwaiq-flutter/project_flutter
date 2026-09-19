import 'package:flutter_test/flutter_test.dart';
import 'package:project_flutter/model/event.dart';

Event _event(Map<String, dynamic> overrides) =>
    Event.fromJson({'id': 1, ...overrides});

void main() {
  group('رابط الخريطة', () {
    test('يبقى فارغاً بلا إحداثيات', () {
      // كان يُبنى دائماً فينتج "maps/place/null,null" ويفتح موقعاً خاطئاً
      // بدل إخبار المستخدم بأن الموقع غير متوفر.
      expect(_event({}).url, isNull);
      expect(_event({'lat': 24.7}).url, isNull);
      expect(_event({'lng': 46.6}).url, isNull);
    });

    test('يُبنى برابط بحث صالح عند وجود الإحداثيات', () {
      final url = _event({'lat': 24.7136, 'lng': 46.6753}).url;

      expect(url, isNotNull);
      final uri = Uri.parse(url!);
      expect(uri.hasScheme, isTrue);
      expect(uri.hasAuthority, isTrue);
      expect(uri.queryParameters['query'], '24.7136,46.6753');
    });

    test('latLng يتبع الإحداثيات نفسها', () {
      expect(_event({}).latLng, isNull);
      expect(_event({'lat': 1.5, 'lng': 2.5}).latLng, '1.5,2.5');
    });
  });

  group('قراءة أوقات العمل', () {
    test('يقرأ خريطة أيام', () {
      final event = _event({
        'times': {'sun': '08:00:00-22:00:00'},
      });

      expect(event.formattedWorkingHoursArabic, contains('الأحد'));
      expect(event.formattedWorkingHoursArabic, contains('من 08:00 إلى 22:00'));
    });

    test('يتحمّل JSON بفاصلة زائدة', () {
      final event = _event({'times': '{"mon": "09:00-17:00",}'});

      expect(event.formattedWorkingHoursArabic, contains('الاثنين'));
    });

    test('يعامل النص غير الصالح كأوقات حرّة بدل أن يرمي', () {
      final event = _event({'times': 'طوال اليوم'});

      expect(event.formattedWorkingHoursArabic, contains('طوال اليوم'));
    });

    test('بلا أوقات يُرجع null', () {
      expect(_event({}).formattedWorkingHoursArabic, isNull);
      expect(_event({'times': '   '}).formattedWorkingHoursArabic, isNull);
    });
  });

  group('أيام الإغلاق', () {
    test('يترجم ويجمع الأيام المتتالية', () {
      final event = _event({
        'closed_days': ['fri', 'sat'],
      });

      expect(event.formattedClosedDaysArabic, contains('الجمعة'));
      expect(event.formattedClosedDaysArabic, contains('السبت'));
    });

    test('بلا أيام إغلاق يوضّح ذلك صراحة', () {
      expect(_event({}).formattedClosedDaysArabic, 'لا توجد أيام إغلاق');
      expect(
        _event({'closed_days': []}).formattedClosedDaysArabic,
        'لا توجد أيام إغلاق',
      );
    });

    test('يتجاهل القيم غير المعروفة', () {
      final event = _event({
        'closed_days': ['غير معروف'],
      });

      expect(event.formattedClosedDaysArabic, 'لا توجد أيام إغلاق');
    });
  });

  group('حالة الإتاحة', () {
    String iso(DateTime date) =>
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    final today = DateTime.now();

    test('بلا بيانات يُعتبر المكان مفتوحاً', () {
      final event = _event({});

      expect(event.availability, PlaceAvailability.open);
      expect(event.isUnavailable, isFalse);
      expect(event.availabilityLabel, isNull);
    });

    test('is_open = false يجعله مغلقاً', () {
      final event = _event({'is_open': false});

      expect(event.availability, PlaceAvailability.closed);
      expect(event.availabilityLabel, 'مغلق');
      expect(event.availabilityNote, isNotNull);
    });

    test('العمود النصي "false" يُقرأ إغلاقاً كذلك', () {
      expect(_event({'is_open': 'false'}).isUnavailable, isTrue);
      expect(_event({'is_open': 'true'}).isUnavailable, isFalse);
    });

    test('تاريخ نهاية مضى يعني انتهاء الفترة', () {
      final event = _event({
        'to_date': iso(today.subtract(const Duration(days: 1))),
      });

      expect(event.availability, PlaceAvailability.ended);
      expect(event.availabilityLabel, 'انتهى');
    });

    test('تاريخ بداية قادم يعني أنه لم يفتح بعد', () {
      final event = _event({
        'from_date': iso(today.add(const Duration(days: 3))),
      });

      expect(event.availability, PlaceAvailability.notStarted);
      expect(event.availabilityLabel, 'لم يفتح بعد');
    });

    test('اليوم داخل الفترة يبقى مفتوحاً', () {
      final event = _event({
        'from_date': iso(today.subtract(const Duration(days: 2))),
        'to_date': iso(today.add(const Duration(days: 2))),
      });

      expect(event.availability, PlaceAvailability.open);
      expect(event.formattedDateRangeArabic, startsWith('من '));
    });

    test('آخر يوم في الفترة لا يُعدّ منتهياً', () {
      final event = _event({'to_date': iso(today)});

      expect(event.availability, PlaceAvailability.open);
    });
  });
}
