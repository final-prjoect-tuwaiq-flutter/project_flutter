import 'package:flutter_test/flutter_test.dart';
import 'package:project_flutter/screens/add_place_screen.dart';

void main() {
  group('parseLatLng', () {
    test('يقرأ الإحداثيات المكتوبة مباشرة', () {
      final result = parseLatLng('24.7136, 46.6753');
      expect(result?.lat, closeTo(24.7136, 1e-6));
      expect(result?.lng, closeTo(46.6753, 1e-6));
    });

    test('يستخرج الإحداثيات من رابط خرائط جوجل', () {
      final result = parseLatLng(
        'https://www.google.com/maps/place/@24.7136,46.6753,15z',
      );
      expect(result?.lat, closeTo(24.7136, 1e-6));
      expect(result?.lng, closeTo(46.6753, 1e-6));
    });

    test('يقبل الإحداثيات السالبة', () {
      final result = parseLatLng('-33.8688,151.2093');
      expect(result?.lat, closeTo(-33.8688, 1e-6));
      expect(result?.lng, closeTo(151.2093, 1e-6));
    });

    test('يرفض النص الذي لا يحتوي إحداثيات', () {
      expect(parseLatLng('حي الملقا، الرياض'), isNull);
    });

    test('يرفض القيم خارج المدى الجغرافي', () {
      expect(parseLatLng('99.0, 46.0'), isNull);
    });
  });
}
