import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_flutter/screens/account.dart';
import 'package:project_flutter/screens/add_place_screen.dart';
import 'package:project_flutter/screens/categories_screen.dart';
import 'package:project_flutter/theme/theme.dart';
import 'package:project_flutter/widgets/app_bottom_nav_bar.dart';

/// طلب فتح تبويب من خارج الشِّل (من صفحة مدفوعة فوقه مثلاً).
///
/// الشِّل جذر المكدّس، فالصفحات المدفوعة فوقه ليست في شجرته ولا تصل إليه
/// بـ `findAncestorStateOfType`؛ هذا المُبلِّغ هو القناة بينها وبينه.
class HomeShellController extends ValueNotifier<int> {
  HomeShellController._() : super(0);

  static final HomeShellController instance = HomeShellController._();

  /// ينتقل للتبويب المطلوب. على المُستدعي أن يُفرغ ما فوق الشِّل بنفسه
  /// (`Navigator.popUntil(... isFirst)`) حتى يظهر التبويب.
  void goToTab(int index) => value = index;
}

/// الهيكل الرئيسي: التبويبات الثلاثة تحت شريط تنقل واحد.
///
/// كانت كل نقرة على الشريط تستبدل الصفحة الجذر بـ `pushReplacement`، فتُهدم
/// الشاشة السابقة بكل حالتها: يضيع موضع التمرير والتصنيف المفتوح، وتُعاد كل
/// طلبات الشبكة من الصفر، ويصبح زر رجوع الجهاز مخرجاً من التطبيق.
/// [IndexedStack] يُبقي التبويبات حيّة، فالعودة إليها فورية بلا إعادة تحميل.
class HomeShell extends StatefulWidget {
  final int initialIndex;

  const HomeShell({super.key, this.initialIndex = 0});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final GlobalKey<CategoriesScreenState> _categoriesKey =
      GlobalKey<CategoriesScreenState>();
  final GlobalKey<AddPlaceScreenState> _addPlaceKey =
      GlobalKey<AddPlaceScreenState>();

  late int _index = widget.initialIndex;

  /// التبويبات التي زارها المستخدم فعلاً. البقية لا تُبنى بعد، فلا تُطلق
  /// طلبات شبكتها عند الإقلاع.
  late final Set<int> _built = {widget.initialIndex};

  /// هل في الصفحة الرئيسية تصنيف مفتوح؟ يحدّد وجهة زر الرجوع.
  bool _categoryOpen = false;

  @override
  void initState() {
    super.initState();
    HomeShellController.instance.addListener(_onExternalTabRequest);
  }

  @override
  void dispose() {
    HomeShellController.instance.removeListener(_onExternalTabRequest);
    super.dispose();
  }

  void _onExternalTabRequest() {
    final requested = HomeShellController.instance.value;
    if (requested != _index) _select(requested);
  }

  Future<void> _select(int index) async {
    if (index == _index) {
      // النقر على التبويب الحالي: الرئيسية تعود من التصنيف إلى "الكل".
      if (index == 0) _categoriesKey.currentState?.resetToAll();
      return;
    }

    // مغادرة "أضف مكاناً" بنموذج ممتلئ تحتاج تأكيداً قبل فقدان ما كُتب.
    if (_index == 1) {
      final mayLeave = await _addPlaceKey.currentState?.confirmLeave() ?? true;
      if (!mayLeave || !mounted) {
        // الطلب قد يكون جاء من خارج الشِّل، فنُعيد المُبلِّغ لحالته الفعلية
        // حتى لا يبقى مخالفاً للتبويب المعروض.
        HomeShellController.instance.value = _index;
        return;
      }
    }

    setState(() {
      _index = index;
      _built.add(index);
    });
    HomeShellController.instance.value = index;
  }

  /// زر رجوع الجهاز: التصنيف أولاً، ثم التبويب الرئيسي، ثم الخروج.
  bool get _canPop => _index == 0 && !_categoryOpen;

  void _handleBack() {
    if (_index != 0) {
      _select(0);
      return;
    }
    if (_categoryOpen) _categoriesKey.currentState?.resetToAll();
  }

  Widget _tab(int index, Widget Function() build) =>
      _built.contains(index) ? build() : const SizedBox.shrink();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppCustomColors>()!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
        canPop: _canPop,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _handleBack();
        },
        child: Scaffold(
          backgroundColor: colors.creamBackground,
          extendBody: true,
          body: IndexedStack(
            index: _index,
            children: [
              _tab(
                0,
                () => CategoriesScreen(
                  key: _categoriesKey,
                  onCategoryOpenChanged: (open) {
                    if (open != _categoryOpen) {
                      setState(() => _categoryOpen = open);
                    }
                  },
                ),
              ),
              _tab(1, () => AddPlaceScreen(key: _addPlaceKey)),
              _tab(2, () => const AccountScreen()),
            ],
          ),
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: _index,
            onTap: _select,
          ),
        ),
      ),
    );
  }
}
