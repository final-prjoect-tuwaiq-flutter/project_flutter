import 'package:flutter/material.dart';
import 'package:project_flutter/theme/theme.dart';

AppCustomColors appColors(BuildContext context) =>
    Theme.of(context).extension<AppCustomColors>()!;

// ==========================================
// ملفات الأصول الثابتة
// ==========================================
class AppAssets {
  const AppAssets._();

  /// شعار "المعزب" الرسمي.
  static const String logo = 'assets/images/app_logo.png';
}

// ==========================================
// شعار التطبيق (الشعار الرسمي داخل مربّع بزوايا دائرية)
// ==========================================
class AppBrandMark extends StatelessWidget {
  final double size;

  /// يُطفأ الظل الذهبي عندما يوضع الشعار فوق سطح فاتح.
  final bool withGlow;

  const AppBrandMark({super.key, this.size = 46, this.withGlow = true});

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final radius = BorderRadius.circular(size * 0.22);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: withGlow
            ? [
                BoxShadow(
                  color: colors.accentColorDeep.withValues(alpha: 0.35),
                  blurRadius: size * 0.38,
                  offset: Offset(0, size * 0.15),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          AppAssets.logo,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}

// ==========================================
// انتقال مشترك لصورة المكان بين الكرت وصفحة التفاصيل
// ==========================================
/// يلفّ صورة الغلاف بـ [Hero] بوسم موحّد، ويُذوّب زوايا الكرت المستديرة
/// نحو الصورة الممتدة في صفحة التفاصيل أثناء الطيران (والعكس عند الرجوع).
class AppHeroImage extends StatelessWidget {
  final Object tag;
  final BorderRadius borderRadius;
  final Widget child;

  const AppHeroImage({
    super.key,
    required this.tag,
    required this.child,
    this.borderRadius = BorderRadius.zero,
  });

  /// وسم موحّد لصورة المكان حتى تتعرّف الصفحتان على بعضهما.
  static String tagForEvent(int eventId) => 'event-cover-$eventId';

  static BorderRadius _radiusOf(BuildContext heroContext) {
    final host = heroContext.findAncestorWidgetOfExactType<AppHeroImage>();
    return host?.borderRadius ?? BorderRadius.zero;
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      flightShuttleBuilder:
          (context, animation, direction, fromHeroContext, toHeroContext) {
            final fromRadius = _radiusOf(fromHeroContext);
            final toRadius = _radiusOf(toHeroContext);

            // في الرجوع تسير الحركة من 1 إلى 0، فنعكس طرفَي التذويب.
            final isPush = direction == HeroFlightDirection.push;
            final begin = isPush ? fromRadius : toRadius;
            final end = isPush ? toRadius : fromRadius;

            final flying = (toHeroContext.widget as Hero).child;

            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) => ClipRRect(
                borderRadius:
                    BorderRadius.lerp(begin, end, animation.value) ??
                    BorderRadius.zero,
                child: flying,
              ),
            );
          },
      child: ClipRRect(borderRadius: borderRadius, child: child),
    );
  }
}

// ==========================================
// صورة مكان: مصدر واحد لتحميل صور الأماكن في التطبيق كله
// ==========================================

/// تعرض صورة المكان من الشبكة مع بديل محلي عند غياب الرابط أو فشل التحميل.
///
/// كانت الشاشات سابقاً تستعمل روابط `via.placeholder.com` كبديل، وهي خدمة
/// خارجية متوقفة، فكان "البديل" نفسه يفشل ويظهر للمستخدم فراغاً.
/// البديل الآن مرسوم محلياً فلا يحتاج شبكة أصلاً.
///
/// [decodeWidth] يحدّ من أبعاد فك الترميز في الذاكرة: صورة غلاف بعرض 2000px
/// تشغل نحو 16 ميغابايت في ذاكرة الصور، وتقليصها لعرض العنصر الفعلي يخفضها
/// عشرات الأضعاف — وهو الفرق بين تمرير سلس وتقطيع في القوائم الطويلة.
/// مضيفات نثق بأنها تخدم صورها بترويسات CORS صحيحة وسلسلة شهادات كاملة،
/// فلا حاجة لتمريرها عبر وسيط.
const Set<String> _directImageHostSuffixes = {'supabase.co', 'supabase.in'};

/// يعيد صياغة رابط صورة خارجي ليمر عبر وسيط الصور، أو `null` إن كان الرابط
/// غير صالح للوساطة (محلي، أو `data:`، أو مضيف موثوق أصلاً).
///
/// سبب وجود هذه الدالة أن كثيراً من المواقع العربية الإخبارية تخدم صورها
/// بإعدادات ناقصة، وهي تكسر التطبيق بطريقتين مختلفتين حسب المنصة:
///
///  1. **الويب** — لا ترسل ترويسة `Access-Control-Allow-Origin` إطلاقاً،
///     فيمنع المتصفح قراءة الصورة مهما فعلنا في كود Dart.
///  2. **أندرويد** — ترسل شهادة الخادم وحدها بلا الشهادة الوسيطة، وتعتمد
///     على أن يجلبها العميل عبر AIA. المتصفحات وويندوز تفعل ذلك، أما
///     BoringSSL داخل Dart فلا، فتفشل المصافحة قبل وصول أي بايت.
///
/// الوسيط يحل الاثنتين: ينهي TLS عنده بسلسلة كاملة، ويخدم النتيجة بـ
/// `Access-Control-Allow-Origin: *`. وبالمجان يعيد التحجيم إلى العرض
/// المطلوب — صورة غلاف 94 كيلوبايت تنزل إلى نحو 3 عند عرض 800 بكسل.
String? _proxiedUrl(String url, int? width) {
  final uri = Uri.tryParse(url);
  if (uri == null || !uri.hasScheme || !uri.isScheme('https')) return null;
  final host = uri.host.toLowerCase();
  if (host.isEmpty) return null;
  if (_directImageHostSuffixes.any(
    (suffix) => host == suffix || host.endsWith('.$suffix'),
  )) {
    return null;
  }

  return Uri.https('wsrv.nl', '/', {
    'url': url,
    if (width != null) 'w': '$width',
    // لا نكبّر صورة أصغر من المطلوب، فالتكبير يضيف بايتات بلا تفاصيل.
    'we': '1',
    'output': 'webp',
  }).toString();
}

class AppPlaceImage extends StatefulWidget {
  final String? url;
  final BoxFit fit;
  final double? decodeWidth;

  /// حجم أيقونة البديل، يُصغَّر في الصور المصغّرة.
  final double fallbackIconSize;

  const AppPlaceImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.decodeWidth,
    this.fallbackIconSize = 38,
  });

  @override
  State<AppPlaceImage> createState() => _AppPlaceImageState();
}

class _AppPlaceImageState extends State<AppPlaceImage> {
  /// يصبح `true` متى فشل الوسيط، فنعيد المحاولة على الرابط الأصلي مباشرة.
  bool _proxyFailed = false;

  @override
  void didUpdateWidget(AppPlaceImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // القوائم تعيد استعمال عناصرها، فلولا هذا لورث رابطٌ جديد فشلَ سابقه.
    if (oldWidget.url != widget.url) _proxyFailed = false;
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = widget.url?.trim();
    if (trimmed == null || trimmed.isEmpty) return _fallback(context);

    final ratio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1.0;
    final cacheWidth = widget.decodeWidth == null
        ? null
        : (widget.decodeWidth! * ratio).round();

    final source = _proxyFailed
        ? trimmed
        : _proxiedUrl(trimmed, cacheWidth) ?? trimmed;

    return Image.network(
      source,
      fit: widget.fit,
      cacheWidth: cacheWidth,
      // الصورة تظهر بتلاشٍ لطيف بدل أن تقفز فجأة داخل الكرت.
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          child: child,
        );
      },
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _placeholderSurface(context),
      errorBuilder: (context, error, stackTrace) {
        // سقط الوسيط؟ نجرّب المصدر الأصلي مرة واحدة قبل إظهار البديل، فلا
        // يحجب عطلٌ في خدمة خارجية صوراً كانت ستُحمَّل مباشرةً بلا مشكلة.
        if (!_proxyFailed && source != trimmed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _proxyFailed = true);
          });
          return _placeholderSurface(context);
        }
        return _fallback(context);
      },
    );
  }

  Widget _placeholderSurface(BuildContext context) {
    final colors = appColors(context);
    return AppPulse(
      child: ColoredBox(
        color: colors.textPrimary.withValues(alpha: 0.06),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    final colors = appColors(context);
    return ColoredBox(
      color: colors.textPrimary.withValues(alpha: 0.06),
      child: Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          color: colors.textPrimary.withValues(alpha: 0.25),
          size: widget.fallbackIconSize,
        ),
      ),
    );
  }
}

// ==========================================
// هالة ضوئية ناعمة للخلفيات الليلية
// ==========================================
class AppGlowBlob extends StatelessWidget {
  final Color color;
  final double size;
  final double intensity;

  const AppGlowBlob({
    super.key,
    required this.color,
    required this.size,
    this.intensity = 0.30,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: intensity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// زر دائري زجاجي (رجوع / إجراء) فوق الخلفيات الداكنة أو الصور
// ==========================================
class AppCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool light;
  final Color? iconColor;
  final double size;

  const AppCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.light = false,
    this.iconColor,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final button = Material(
      color: light ? colors.surfaceColor : Colors.white.withValues(alpha: 0.10),
      shape: CircleBorder(
        side: BorderSide(
          color: light
              ? colors.borderSoft
              : Colors.white.withValues(alpha: 0.16),
        ),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: size * 0.46,
            color: iconColor ?? (light ? colors.textPrimary : Colors.white),
          ),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

// ==========================================
// ترويسة الصفحات الداخلية (لوحة ليلية بزوايا سفلية دائرية)
// ==========================================
class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final bool showBack;

  /// وجهة زر الرجوع. تُمرَّر في الصفحات التي فُتحت بـ pushReplacement
  /// حيث لا يوجد شيء يُرجَع إليه في المكدّس.
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget? bottom;

  const AppPageHeader({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.showBack = false,
    this.onBack,
    this.trailing,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    const radius = BorderRadius.only(
      bottomLeft: Radius.circular(34),
      bottomRight: Radius.circular(34),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: colors.inkGradient,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            PositionedDirectional(
              top: -80,
              start: -60,
              child: AppGlowBlob(color: colors.accentColor, size: 230),
            ),
            PositionedDirectional(
              bottom: -90,
              end: -50,
              child: AppGlowBlob(
                color: colors.accentColorDeep,
                size: 200,
                intensity: 0.22,
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showBack || trailing != null) ...[
                      Row(
                        children: [
                          if (showBack)
                            AppCircleButton(
                              icon: Icons.arrow_back_rounded,
                              tooltip: 'رجوع',
                              onPressed:
                                  onBack ?? () => Navigator.maybePop(context),
                            ),
                          const Spacer(),
                          ?trailing,
                        ],
                      ),
                      const SizedBox(height: 18),
                    ] else
                      const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: colors.accentGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: colors.accentColor.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 7),
                              ),
                            ],
                          ),
                          child: Icon(icon, color: Colors.white, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.display(
                                  25,
                                  color: Colors.white,
                                  height: 1.25,
                                ),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  subtitle!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    height: 1.5,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.62),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (bottom != null) ...[
                      const SizedBox(height: 20),
                      bottom!,
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// عنوان قسم بخط ذهبي جانبي
// ==========================================
class AppSectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final double fontSize;

  const AppSectionTitle({
    super.key,
    required this.title,
    this.trailing,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return Row(
      children: [
        Container(
          width: 4,
          height: fontSize + 2,
          decoration: BoxDecoration(
            gradient: colors.accentGradient,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.display(fontSize, color: colors.textPrimary),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

// ==========================================
// بطاقة سطح بيضاء بحد دافئ وظل ناعم
// ==========================================
class AppSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const AppSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: colors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor.withValues(alpha: 0.05),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ==========================================
// أيقونة داخل ميدالية دائرية ناعمة
// ==========================================
class AppIconMedallion extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double size;

  const AppIconMedallion({
    super.key,
    required this.icon,
    this.color,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? appColors(context).accentColor;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.36),
      ),
      child: Icon(icon, color: tint, size: size * 0.5),
    );
  }
}

// ==========================================
// عنوان حقل في النماذج (مع تمييز الحقول المطلوبة)
// ==========================================
class AppFieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const AppFieldLabel({super.key, required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8, start: 4),
      child: Text.rich(
        TextSpan(
          text: label,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
          children: [
            TextSpan(
              text: required ? ' *' : '  (اختياري)',
              style: TextStyle(
                color: required ? colors.accentColor : colors.textMuted,
                fontSize: required ? 13.5 : 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// زر رئيسي بالتدرّج الذهبي
// ==========================================
class AppGradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  const AppGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final enabled = onPressed != null && !isLoading;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: onPressed == null && !isLoading ? 0.55 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: colors.accentGradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: colors.accentColor.withValues(alpha: 0.38),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (icon != null) ...[
                            const SizedBox(width: 10),
                            Icon(icon, color: Colors.white, size: 20),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// لوحة حالة (فارغ / خطأ / يتطلب تسجيل دخول)
// ==========================================
class AppStatePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const AppStatePanel({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.accentColorSoft,
              border: Border.all(
                color: colors.accentColor.withValues(alpha: 0.18),
                width: 8,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
            child: Icon(icon, size: 42, color: colors.accentColor),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTheme.display(19, color: colors.textPrimary),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontSize: 13.5),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: 220,
              child: AppGradientButton(
                label: actionLabel!,
                icon: actionIcon,
                onPressed: onAction,
                height: 50,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// هياكل التحميل النابضة
// ==========================================
class AppPulse extends StatefulWidget {
  final Widget child;

  const AppPulse({super.key, required this.child});

  @override
  State<AppPulse> createState() => _AppPulseState();
}

class _AppPulseState extends State<AppPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(
    begin: 0.45,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}

class AppSkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final Color? color;

  const AppSkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 12,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? appColors(context).textPrimary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// هيكل تحميل لقائمة بطاقات صغيرة (صورة + سطرين).
class AppListSkeleton extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry padding;

  const AppListSkeleton({
    super.key,
    this.count = 4,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 20),
  });

  @override
  Widget build(BuildContext context) {
    return AppPulse(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (_, _) => const AppSurfaceCard(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              AppSkeletonBox(width: 76, height: 76, radius: 18),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeletonBox(width: 150, height: 14, radius: 7),
                    SizedBox(height: 10),
                    AppSkeletonBox(width: 100, height: 11, radius: 6),
                    SizedBox(height: 10),
                    AppSkeletonBox(height: 11, radius: 6),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// أسماء الأشهر العربية لعرض التواريخ
// ==========================================
const List<String> kArabicMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

String formatArabicDate(DateTime date) =>
    '${date.day} ${kArabicMonths[date.month - 1]} ${date.year}';

/// يعرض المسافة بالمتر تحت الكيلومتر، وبالكيلومتر بعده: «٤٠٠ م» / «١٫٢ كم».
String formatDistanceMeters(double meters) {
  if (meters < 1000) return '${meters.round()} م';
  return '${(meters / 1000).toStringAsFixed(1)} كم';
}

// ==========================================
// صياغة الأعداد بصيغة عربية سليمة
// ==========================================

/// يصوغ العدد مع معدوده حسب قواعد العربية:
/// واحد (مكان واحد)، مثنّى (مكانين)، جمع قلّة ٣-١٠ (٥ أماكن)،
/// ثم تمييز مفرد منصوب ١١-٩٩ (١٥ مكاناً)، ومفرد مجرور لما بعدها (١٠٠ مكان).
String arabicPlural(
  int count, {
  required String singular,
  required String dual,
  required String plural,
  required String accusative,
  bool feminine = false,
}) {
  if (count <= 0) return 'لا توجد $plural';
  if (count == 1) return '$singular ${feminine ? 'واحدة' : 'واحد'}';
  if (count == 2) return dual;

  final remainder = count % 100;
  if (remainder >= 3 && remainder <= 10) return '$count $plural';
  if (remainder >= 11 && remainder <= 99) return '$count $accusative';
  return '$count $singular';
}

/// عدّاد الأماكن: مكان واحد / مكانين / ٧ أماكن / ١٢ مكاناً.
String arabicPlacesCount(int count) => arabicPlural(
  count,
  singular: 'مكان',
  dual: 'مكانين',
  plural: 'أماكن',
  accusative: 'مكاناً',
);

/// عدّاد الزيارات: زيارة واحدة / زيارتين / ٧ زيارات / ١٢ زيارةً.
String arabicVisitsCount(int count) => arabicPlural(
  count,
  singular: 'زيارة',
  dual: 'زيارتين',
  plural: 'زيارات',
  accusative: 'زيارةً',
  feminine: true,
);
