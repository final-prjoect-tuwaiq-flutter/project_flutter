import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:project_flutter/app_locale.dart';
import 'package:project_flutter/screens/account.dart';
import 'package:project_flutter/screens/add_place_screen.dart';
import 'package:project_flutter/screens/categories_screen.dart';
import 'package:project_flutter/screens/home_shell.dart';
import 'package:project_flutter/theme/theme.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      publishableKey: 'test-publishable-key',
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
    );
  });

  Widget app() => MaterialApp(
    theme: AppTheme.lightTheme,
    locale: kAppLocale,
    localizationsDelegates: kAppLocalizationsDelegates,
    supportedLocales: kAppSupportedLocales,
    home: const HomeShell(),
  );

  testWidgets('يبدأ على تبويب الرئيسية ولا يبني بقية التبويبات', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pump();

    expect(find.byType(CategoriesScreen), findsOneWidget);
    // البناء الكسول: التبويبات غير المزارة لا تُنشأ أصلاً (لا مخفيّة فقط)،
    // فلا تُطلق طلبات شبكتها عند الإقلاع. skipOffstage: false يشمل المخفي.
    expect(find.byType(AddPlaceScreen, skipOffstage: false), findsNothing);
    expect(find.byType(AccountScreen, skipOffstage: false), findsNothing);
  });

  testWidgets('التنقل بين التبويبات يُبقي الرئيسية حيّة', (tester) async {
    await tester.pumpWidget(app());
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('إضافة مكان'));
    await tester.pump();

    expect(find.byType(AddPlaceScreen), findsOneWidget);
    // الرئيسية ما زالت حيّة في الشجرة (مخفيّة داخل IndexedStack) لا مهدومة،
    // فالعودة إليها لا تُعيد تحميلها. كانت pushReplacement تهدمها بالكامل.
    expect(find.byType(CategoriesScreen, skipOffstage: false), findsOneWidget);
  });

  testWidgets('زر رجوع الجهاز يعيد للتبويب الرئيسي بدل إغلاق التطبيق', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pump();

    await tester.tap(find.bySemanticsLabel('إضافة مكان'));
    await tester.pump();
    expect(find.byType(AddPlaceScreen), findsOneWidget);

    // محاكاة زر الرجوع في النظام.
    final popped = await tester.binding.handlePopRoute();
    await tester.pump();

    // لم يخرج من التطبيق، وعاد للرئيسية.
    expect(popped, isTrue);
    expect(find.byType(HomeShell), findsOneWidget);
    // عاد للتبويب الرئيسي: الرئيسية ظاهرة والإضافة مخفيّة.
    expect(find.byType(CategoriesScreen), findsOneWidget);
    expect(find.byType(AddPlaceScreen), findsNothing);
  });
}
