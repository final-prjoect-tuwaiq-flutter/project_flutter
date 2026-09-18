import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:project_flutter/theme/theme.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxShape shape;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.shape = BoxShape.rectangle,
  });

  /// عتبة الشفافية التي يصبح تحتها الطمس مرئياً فعلاً.
  ///
  /// [BackdropFilter] من أغلى العمليات في فلاتر: يفرض `saveLayer` ويعيد
  /// رسم ما خلفه في كل إطار. وضعه خلف سطح شبه معتم يدفع الثمن كاملاً
  /// مقابل أثر لا يكاد يُرى — والشريط السفلي يظهر في كل شاشة ويعيد الرسم
  /// مع كل تمرير، فالفرق ملموس على الأجهزة المتوسطة.
  static const double _blurVisibilityThreshold = 0.85;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppCustomColors>()!;
    const fillAlpha = 0.92;

    final radius = shape == BoxShape.circle
        ? BorderRadius.circular(999)
        : BorderRadius.circular(borderRadius);

    Widget surface = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: colors.inkColor.withValues(alpha: fillAlpha),
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
          width: 1.0,
        ),
      ),
      child: child,
    );

    // يُدفع ثمن الطمس فقط حين يكون السطح شفافاً بما يكفي لإظهاره.
    if (fillAlpha < _blurVisibilityThreshold) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: surface,
      );
    }

    return Container(
      margin: margin,
      width: width,
      height: height,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(borderRadius: radius, child: surface),
    );
  }
}
