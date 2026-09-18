import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// إعدادات اللغة للتطبيق كله.
///
/// بدون هذه المندوبين تعود ودجتس مكتبة ماتيريال إلى الإنجليزية فقط، وكان
/// `showDatePicker` بلغة عربية يرمي «No MaterialLocalizations found» ويُسقط
/// الحوار عند اختيار تاريخ زيارة مخصّص.
const List<LocalizationsDelegate<dynamic>> kAppLocalizationsDelegates =
    <LocalizationsDelegate<dynamic>>[
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

/// العربية أولاً: هي لغة الواجهة، والإنجليزية بديل احتياطي.
const List<Locale> kAppSupportedLocales = <Locale>[Locale('ar'), Locale('en')];

/// التطبيق عربي بالكامل مهما كانت لغة الجهاز، فنثبّت اللغة بدل تركها للنظام.
const Locale kAppLocale = Locale('ar');
