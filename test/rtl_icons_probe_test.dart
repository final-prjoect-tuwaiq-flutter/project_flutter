import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// يتحقق أن أيقونات الأسهم تنعكس تلقائياً في الاتجاه من اليمين لليسار،
/// أي أن Icons.arrow_back (زر الرجوع) يشير فعلياً إلى اليمين في الواجهة العربية.
bool isMirrored(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find.descendant(of: find.byType(Icon), matching: find.byType(Transform)),
  );
  return transform.transform.getRow(0)[0] == -1.0;
}

Future<void> pump(WidgetTester tester, IconData icon, TextDirection dir) {
  return tester.pumpWidget(
    Directionality(textDirection: dir, child: Icon(icon)),
  );
}

void main() {
  testWidgets('arrow_back ينعكس في RTL', (tester) async {
    await pump(tester, Icons.arrow_back_rounded, TextDirection.rtl);
    expect(isMirrored(tester), isTrue, reason: 'يجب أن يشير لليمين');
  });

  testWidgets('arrow_forward ينعكس في RTL', (tester) async {
    await pump(tester, Icons.arrow_forward_rounded, TextDirection.rtl);
    expect(isMirrored(tester), isTrue, reason: 'يجب أن يشير لليسار');
  });

  testWidgets('chevron_right ينعكس في RTL', (tester) async {
    await pump(tester, Icons.chevron_right_rounded, TextDirection.rtl);
    expect(isMirrored(tester), isTrue, reason: 'يجب أن يشير لليسار');
  });

  testWidgets('لا انعكاس في LTR', (tester) async {
    await pump(tester, Icons.arrow_back_rounded, TextDirection.ltr);
    // في LTR لا يُضاف Transform أصلاً، فالأيقونة تُرسم كما هي.
    expect(
      find.descendant(of: find.byType(Icon), matching: find.byType(Transform)),
      findsNothing,
    );
  });
}
