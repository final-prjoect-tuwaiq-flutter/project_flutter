import 'package:flutter/material.dart';
import 'package:project_flutter/theme/theme.dart';
import 'package:project_flutter/widgets/glass_container.dart';

/// شريط التنقل السفلي العائم الموحّد لكل الشاشات.
class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  /// المسافة الثابتة بين الشريط وحافة الشاشة، فوق أي حشوة نظام.
  static const double _bottomGap = 22;

  /// ارتفاع الشريط تقريباً مع هامشه، لوضع العناصر العائمة فوقه.
  /// Scaffold لا يحشو `bottomNavigationBar` تلقائياً، فنقرأ حشوة النظام هنا.
  static double heightWithInsets(BuildContext context) =>
      76 + _bottomGap + MediaQuery.viewPaddingOf(context).bottom;

  /// الحشوة السفلية التي تحتاجها القوائم حتى لا يختفي آخر عنصر خلف الشريط.
  /// كانت أرقاماً ثابتة (130/140) لا تعرف شيئاً عن حشوة النظام.
  static double contentBottomPadding(BuildContext context) =>
      heightWithInsets(context) + 44;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppCustomColors>()!;

    // على أجهزة الإيماءات يقع شريط الإيماءة أسفل الشاشة؛ بلا هذه الحشوة
    // كان الشريط يلامسه فتتداخل لمسات التنقل مع إيماءة النظام.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      margin: EdgeInsets.only(
        left: 30,
        right: 30,
        bottom: _bottomGap + bottomInset,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: colors.inkColor.withValues(alpha: 0.30),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: GlassContainer(
        borderRadius: 34.0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavItem(
              icon: Icons.explore_rounded,
              label: 'الرئيسية',
              selected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            Semantics(
              button: true,
              label: 'إضافة مكان',
              child: GestureDetector(
                onTap: () => onTap(1),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: colors.accentGradient,
                    shape: BoxShape.circle,
                    border: currentIndex == 1
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: colors.accentColor.withValues(alpha: 0.5),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 29,
                  ),
                ),
              ),
            ),
            _NavItem(
              icon: Icons.person_rounded,
              label: 'حسابي',
              selected: currentIndex == 2,
              onTap: () => onTap(2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppCustomColors>()!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? colors.accentColor.withValues(alpha: 0.45)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected
                  ? colors.goldColor
                  : Colors.white.withValues(alpha: 0.55),
              size: 23,
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: colors.goldColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
