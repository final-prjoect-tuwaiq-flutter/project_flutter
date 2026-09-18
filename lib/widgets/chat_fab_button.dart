import 'package:flutter/material.dart';
import 'package:project_flutter/screens/chat_screen.dart';
import 'package:project_flutter/theme/theme.dart';
import 'package:project_flutter/widgets/app_bottom_nav_bar.dart';

/// زر دائري عائم في الزاوية اليمنى السفلى يفتح شاشة المساعد الذكي.
/// يوضع داخل [Stack] فوق محتوى الشاشة (وفوق شريط التنقل السفلي عند الحاجة).
class ChatFabButton extends StatelessWidget {
  /// ارتفاع مخصّص فوق الحافة. يُترك فارغاً في الشاشات التي تحمل شريط تنقل
  /// فيُحسب من ارتفاع الشريط وحشوة النظام بدل رقم ثابت كان يزيح الزر فوق
  /// الشريط على أجهزة الإيماءات.
  final double? bottomOffset;

  const ChatFabButton({super.key, this.bottomOffset});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppCustomColors>()!;
    final bottom =
        bottomOffset ?? AppBottomNavBar.heightWithInsets(context) + 20;

    return Positioned(
      bottom: bottom,
      right: 18,
      child: Tooltip(
        message: 'مرشد المعزب',
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChatScreen()),
            );
          },
          child: Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: colors.accentGradient,
              boxShadow: [
                BoxShadow(
                  color: colors.accentColor.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.inkColor,
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: colors.goldColor,
                size: 25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
