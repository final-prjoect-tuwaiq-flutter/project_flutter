import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_flutter/app_locale.dart';

/// يبني MaterialApp بنفس إعدادات اللغة المستعملة في [MyApp].
Widget _appUnderTest({required Widget home}) => MaterialApp(
  locale: kAppLocale,
  localizationsDelegates: kAppLocalizationsDelegates,
  supportedLocales: kAppSupportedLocales,
  home: home,
);

void main() {
  testWidgets('منتقي التاريخ العربي يفتح دون استثناء', (tester) async {
    // بلا مندوبي الترجمة كان يرمي «No MaterialLocalizations found» ويُسقط
    // حوار إضافة الزيارة عند اختيار «تاريخ آخر».
    await tester.pumpWidget(
      _appUnderTest(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDatePicker(
              context: context,
              initialDate: DateTime(2026, 1, 1),
              firstDate: DateTime(2000),
              lastDate: DateTime(2030),
              locale: const Locale('ar'),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });

  testWidgets('اللغة العربية تجعل اتجاه الواجهة من اليمين لليسار', (
    tester,
  ) async {
    late TextDirection direction;

    await tester.pumpWidget(
      _appUnderTest(
        home: Builder(
          builder: (context) {
            direction = Directionality.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(direction, TextDirection.rtl);
  });

  testWidgets('نصوص ماتيريال تُترجَم للعربية', (tester) async {
    late MaterialLocalizations localizations;

    await tester.pumpWidget(
      _appUnderTest(
        home: Builder(
          builder: (context) {
            localizations = MaterialLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    // البديل الافتراضي إنجليزي ('Cancel'). نتحقق من كونه عربياً بدل مطابقة
    // نص بعينه، فصياغة ماتيريال قد تتغيّر بين إصدارات فلاتر.
    expect(localizations.cancelButtonLabel, isNot('Cancel'));
    expect(
      RegExp('[؀-ۿ]').hasMatch(localizations.cancelButtonLabel),
      isTrue,
      reason: 'يجب أن يكون نص الإلغاء بالعربية',
    );
  });
}
