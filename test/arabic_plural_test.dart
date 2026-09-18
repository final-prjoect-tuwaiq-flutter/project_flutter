import 'package:flutter_test/flutter_test.dart';
import 'package:project_flutter/widgets/app_ui.dart';

void main() {
  group('arabicPlacesCount', () {
    test('المفرد والمثنى', () {
      expect(arabicPlacesCount(1), 'مكان واحد');
      expect(arabicPlacesCount(2), 'مكانين');
    });

    test('جمع القلّة من ٣ إلى ١٠', () {
      expect(arabicPlacesCount(3), '3 أماكن');
      expect(arabicPlacesCount(7), '7 أماكن');
      expect(arabicPlacesCount(10), '10 أماكن');
    });

    test('التمييز المنصوب من ١١ إلى ٩٩', () {
      expect(arabicPlacesCount(11), '11 مكاناً');
      expect(arabicPlacesCount(42), '42 مكاناً');
      expect(arabicPlacesCount(99), '99 مكاناً');
    });

    test('المئات تعود للمفرد', () {
      expect(arabicPlacesCount(100), '100 مكان');
      expect(arabicPlacesCount(101), '101 مكان');
    });

    test('تتكرر القاعدة بعد المئة', () {
      expect(arabicPlacesCount(103), '103 أماكن');
      expect(arabicPlacesCount(111), '111 مكاناً');
    });

    test('الصفر والقيم غير الصالحة', () {
      expect(arabicPlacesCount(0), 'لا توجد أماكن');
      expect(arabicPlacesCount(-1), 'لا توجد أماكن');
    });
  });

  group('arabicVisitsCount', () {
    test('المفرد المؤنث والمثنى', () {
      expect(arabicVisitsCount(1), 'زيارة واحدة');
      expect(arabicVisitsCount(2), 'زيارتين');
    });

    test('بقية الصيغ', () {
      expect(arabicVisitsCount(5), '5 زيارات');
      expect(arabicVisitsCount(20), '20 زيارةً');
      expect(arabicVisitsCount(100), '100 زيارة');
      expect(arabicVisitsCount(0), 'لا توجد زيارات');
    });
  });
}
