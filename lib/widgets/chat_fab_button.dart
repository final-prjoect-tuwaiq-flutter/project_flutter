import 'package:flutter/material.dart';
import 'package:project_flutter/screens/chat_screen.dart';
import 'package:project_flutter/theme/theme.dart';

/// زر دائري عائم في الزاوية اليمنى السفلى يفتح شاشة المساعد الذكي.
/// يوضع داخل [Stack] فوق محتوى الشاشة (وفوق شريط التنقل السفلي عند الحاجة).
class ChatFabButton extends StatelessWidget {
  final double bottomOffset;

  const ChatFabButton({super.key, this.bottomOffset = 118});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppCustomColors>()!;

    return Positioned(
      bottom: bottomOffset,
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
