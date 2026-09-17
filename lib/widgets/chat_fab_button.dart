import 'package:flutter/material.dart';
import 'package:project_flutter/screens/chat_screen.dart';
import 'package:project_flutter/theme/theme.dart';

/// زر دائري عائم في الزاوية اليمنى السفلى يفتح شاشة المساعد الذكي.
/// يوضع داخل [Stack] فوق محتوى الشاشة (وفوق شريط التنقل السفلي عند الحاجة).
class ChatFabButton extends StatelessWidget {
  final double bottomOffset;

  const ChatFabButton({super.key, this.bottomOffset = 100});

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;

    return Positioned(
      bottom: bottomOffset,
      right: 16,
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
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: customColors.accentColor,
            boxShadow: [
              BoxShadow(
                color: customColors.accentColor.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.smart_toy_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
