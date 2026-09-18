import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_flutter/model/metro_station.dart';
import 'package:project_flutter/widgets/app_ui.dart';

void main() {
  group('MetroStation.tryFromJson', () {
    test('يقرأ صفاً كاملاً', () {
      final station = MetroStation.tryFromJson({
        'station_code': '1A1',
        'station_name': 'محطة العليا',
        'line_name': 'المسار الأزرق',
        'lat': 24.6911,
        'lng': 46.6853,
      });

      expect(station, isNotNull);
      expect(station!.stationName, 'محطة العليا');
      expect(station.lineName, 'المسار الأزرق');
      expect(station.lat, closeTo(24.6911, 1e-6));
    });

    test('يتجاهل الصفوف بلا إحداثيات بدل أن يرمي استثناءً', () {
      expect(
        MetroStation.tryFromJson({'station_code': 'X', 'lat': null, 'lng': 1.0}),
        isNull,
      );
      expect(MetroStation.tryFromJson({'station_code': 'X'}), isNull);
    });

    test('يتحمّل الأعمدة النصية الناقصة', () {
      final station = MetroStation.tryFromJson({'lat': 24.0, 'lng': 46.0});
      expect(station, isNotNull);
      expect(station!.stationName, '');
      expect(station.lineName, '');
    });
  });

  group('ألوان المسارات', () {
    MetroStation withLine(String line) => MetroStation(
      stationCode: 'c',
      stationName: 'n',
      lineName: line,
      lat: 0,
      lng: 0,
    );

    test('يتعرّف على الاسم العربي والإنجليزي والرقم', () {
      expect(withLine('المسار الأزرق').lineColor, const Color(0xFF1B67B2));
      expect(withLine('Blue Line').lineColor, const Color(0xFF1B67B2));
      expect(withLine('Line 5').lineColor, const Color(0xFF2F9E62));
    });

    test('يرجع null للمسار غير المعروف ليستخدم اللون الافتراضي', () {
      expect(withLine('مسار جديد').lineColor, isNull);
      expect(withLine('').lineColor, isNull);
    });
  });

  group('NearbyStation.walkMinutes', () {
    NearbyStation at(double meters) => NearbyStation(
      station: MetroStation(
        stationCode: 'c',
        stationName: 'n',
        lineName: 'l',
        lat: 0,
        lng: 0,
      ),
      distanceMeters: meters,
    );

    test('يقرّب لأعلى ولا ينزل عن دقيقة', () {
      expect(at(10).walkMinutes, 1);
      expect(at(80).walkMinutes, 1);
      expect(at(81).walkMinutes, 2);
      expect(at(850).walkMinutes, 11);
    });
  });

  group('MetroAccess.isWalkable', () {
    final station = MetroStation(
      stationCode: 'c',
      stationName: 'n',
      lineName: 'l',
      lat: 0,
      lng: 0,
    );

    test('يكون قريباً عند وجود محطة ضمن النطاق', () {
      final nearby = NearbyStation(station: station, distanceMeters: 400);
      final access = MetroAccess(nearest: nearby, withinWalk: [nearby]);
      expect(access.isWalkable, isTrue);
    });

    test('يكون بعيداً عند خلو النطاق', () {
      final far = NearbyStation(station: station, distanceMeters: 2300);
      final access = MetroAccess(nearest: far, withinWalk: const []);
      expect(access.isWalkable, isFalse);
    });
  });

  group('displayName', () {
    MetroStation named(String name, String code) => MetroStation(
      stationCode: code,
      stationName: name,
      lineName: 'l',
      lat: 0,
      lng: 0,
    );

    test('يفضّل الاسم على الرمز', () {
      expect(named('محطة العليا', '1A1').displayName, 'محطة العليا');
    });

    test('يرجع للرمز عند غياب الاسم', () {
      expect(named('', '1A1').displayName, '1A1');
      expect(named('   ', '1A1').displayName, '1A1');
    });

    test('فارغ إذا غاب الاثنان', () {
      expect(named('', '').displayName, '');
    });
  });

  group('formatDistanceMeters', () {
    test('بالمتر تحت الكيلومتر وبالكيلومتر بعده', () {
      expect(formatDistanceMeters(0), '0 م');
      expect(formatDistanceMeters(412.6), '413 م');
      expect(formatDistanceMeters(999), '999 م');
      expect(formatDistanceMeters(1000), '1.0 كم');
      expect(formatDistanceMeters(2350), '2.4 كم');
    });
  });
}
