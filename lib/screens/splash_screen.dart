import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_flutter/theme/theme.dart';
import 'package:project_flutter/widgets/app_ui.dart';

/// شاشة البداية: ترحيب "المعزب" بضيفه قبل الدخول للتطبيق.
class SplashScreen extends StatefulWidget {
  final WidgetBuilder nextBuilder;

  const SplashScreen({super.key, required this.nextBuilder});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  /// الحركة الافتتاحية (مرة واحدة) — عند انتهائها ننتقل للتطبيق.
  late final AnimationController _intro;

  /// الحركة المحيطية المستمرة (الحلقات وذرات الذهب وتدوير الزخرفة).
  late final AnimationController _ambient;

  bool _navigated = false;

  late final Animation<double> _backdrop = _phase(0.00, 0.30, Curves.easeOut);
  late final Animation<double> _logo = _phase(0.08, 0.40, Curves.easeOutBack);
  late final Animation<double> _logoFade = _phase(0.08, 0.28, Curves.easeOut);
  late final Animation<double> _rings = _phase(0.30, 0.55, Curves.easeOut);
  late final Animation<double> _flourish = _phase(
    0.55,
    0.75,
    Curves.easeOutCubic,
  );
  late final Animation<double> _tagline = _phase(0.60, 0.80, Curves.easeOut);
  late final Animation<double> _shimmer = _phase(0.64, 0.88, Curves.easeInOut);
  late final Animation<double> _progress = _phase(0.12, 1.00, Curves.easeInOut);

  Animation<double> _phase(double begin, double end, Curve curve) =>
      CurvedAnimation(
        parent: _intro,
        curve: Interval(begin, end, curve: curve),
      );

  @override
  void initState() {
    super.initState();
    final reduceMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;

    _intro = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: reduceMotion ? 1200 : 3600),
    );
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    _intro.addStatusListener((status) {
      if (status == AnimationStatus.completed) _goNext();
    });
    _intro.forward();
    if (!reduceMotion) _ambient.repeat();
  }

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, _, _) => widget.nextBuilder(context),
        transitionsBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.04, end: 1).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  void _skip() {
    HapticFeedback.selectionClick();
    _goNext();
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: colors.inkColor,
          body: AnimatedBuilder(
            animation: Listenable.merge([_intro, _ambient]),
            builder: (context, _) {
              final t = _ambient.value;

              return Stack(
                fit: StackFit.expand,
                children: [
                  // 1. الخلفية الليلية بإضاءة مركزية دافئة
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.2),
                        radius: 1.1,
                        colors: [
                          Color.lerp(
                            colors.inkColor,
                            colors.inkSoft,
                            _backdrop.value,
                          )!,
                          colors.inkColor,
                        ],
                      ),
                    ),
                  ),

                  // 2. زخرفة هندسية عربية (نجوم ثمانية) تتلاشى نحو الأطراف
                  Opacity(
                    opacity: _backdrop.value,
                    child: ShaderMask(
                      blendMode: BlendMode.dstIn,
                      shaderCallback: (rect) => const RadialGradient(
                        center: Alignment(0, -0.2),
                        radius: 0.75,
                        colors: [Colors.white, Colors.transparent],
                      ).createShader(rect),
                      child: CustomPaint(
                        painter: _StarPatternPainter(
                          color: colors.goldColor.withValues(alpha: 0.07),
                          rotation: t * 2 * math.pi / 8,
                        ),
                      ),
                    ),
                  ),

                  // 3. هالات ضوئية متنفّسة
                  Positioned(
                    top: -140,
                    right: -120,
                    child: Opacity(
                      opacity: _backdrop.value,
                      child: AppGlowBlob(
                        color: colors.accentColor,
                        size: 380 + 30 * math.sin(t * 2 * math.pi),
                        intensity: 0.26,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -160,
                    left: -130,
                    child: Opacity(
                      opacity: _backdrop.value,
                      child: AppGlowBlob(
                        color: colors.accentColorDeep,
                        size: 400 + 30 * math.cos(t * 2 * math.pi),
                        intensity: 0.20,
                      ),
                    ),
                  ),

                  // 4. ذرات ذهبية تصعد ببطء
                  Opacity(
                    opacity: _backdrop.value,
                    child: CustomPaint(
                      painter: _GoldDustPainter(
                        progress: t,
                        color: colors.goldColor,
                      ),
                    ),
                  ),

                  // 5. الشعار والاسم
                  Align(
                    alignment: const Alignment(0, -0.12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildEmblem(colors, t),
                        const SizedBox(height: 18),
                        _buildFlourish(colors),
                        const SizedBox(height: 14),
                        _FadeUp(
                          value: _tagline.value,
                          child: Text(
                            'دليلك للأماكن والفعاليات',
                            style: TextStyle(
                              color: colors.goldColor,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 6. زر التخطي (نحو المركز)
                  PositionedDirectional(
                    top: 0,
                    start: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _SkipButton(onPressed: _skip),
                      ),
                    ),
                  ),

                  // 7. الترحيب وشريط التقدّم
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Opacity(
                          opacity: _tagline.value,
                          child: Column(
                            children: [
                              Text(
                                'حيّاك الله',
                                style: AppTheme.display(
                                  16,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _ProgressLine(
                                value: _progress.value,
                                gradient: colors.accentGradient,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// الشعار مع حلقات ضوئية تتموّج حوله ولمعة تمرّ عليه.
  Widget _buildEmblem(AppCustomColors colors, double t) {
    const logoSize = 138.0;

    return SizedBox(
      width: 280,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(280, 250),
            painter: _RipplePainter(
              progress: t,
              visibility: _rings.value,
              color: colors.goldColor,
              baseRadius: logoSize * 0.62,
            ),
          ),
          Opacity(
            opacity: _logoFade.value,
            child: Transform.scale(
              scale: 0.55 + 0.45 * _logo.value,
              child: Transform.rotate(
                angle: (1 - _logo.value) * -0.35,
                child: ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (rect) {
                    final s = -0.3 + 1.6 * _shimmer.value;
                    return LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                      stops: [
                        (s - 0.15).clamp(0.0, 1.0),
                        s.clamp(0.0, 1.0),
                        (s + 0.15).clamp(0.0, 1.0),
                      ],
                    ).createShader(rect);
                  },
                  child: const AppBrandMark(size: logoSize),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// زخرفة سفلية: خطان يمتدان من ماسة ذهبية في المنتصف.
  Widget _buildFlourish(AppCustomColors colors) {
    final v = _flourish.value;
    Widget line(Alignment from) => SizedBox(
      width: 64,
      child: Align(
        alignment: from,
        child: Container(
          width: 64 * v,
          height: 1.2,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: from,
              end: -from,
              colors: [
                colors.goldColor.withValues(alpha: 0.9),
                colors.goldColor.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );

    return Opacity(
      opacity: v,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          line(Alignment.centerRight),
          const SizedBox(width: 8),
          Transform.rotate(
            angle: math.pi / 4 * (1 + v),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                gradient: colors.accentGradient,
                boxShadow: [
                  BoxShadow(
                    color: colors.goldColor.withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          line(Alignment.centerLeft),
        ],
      ),
    );
  }
}

// ==========================================
// زر التخطي
// ==========================================
class _SkipButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SkipButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'تخطي شاشة البداية',
      child: Material(
        color: Colors.white.withValues(alpha: 0.08),
        shape: StadiumBorder(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 9, 10, 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'تخطي',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// شريط التقدّم
// ==========================================
class _ProgressLine extends StatelessWidget {
  final double value;
  final Gradient gradient;

  const _ProgressLine({required this.value, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 3,
      alignment: AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        widthFactor: value,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

class _FadeUp extends StatelessWidget {
  final double value;
  final Widget child;

  const _FadeUp({required this.value, required this.child});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 14 * (1 - value)),
        child: child,
      ),
    );
  }
}

// ==========================================
// الرسّامون
// ==========================================

/// شبكة من النجوم الثمانية (خاتم سليمان) — زخرفة عربية تقليدية.
class _StarPatternPainter extends CustomPainter {
  final Color color;
  final double rotation;

  _StarPatternPainter({required this.color, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 64.0;
    const half = cell * 0.26;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final square = Rect.fromCenter(
      center: Offset.zero,
      width: half * 2,
      height: half * 2,
    );

    canvas.save();
    canvas.translate(size.width / 2, size.height * 0.4);
    canvas.rotate(rotation);

    final reach = size.longestSide;
    for (double x = -reach; x <= reach; x += cell) {
      for (double y = -reach; y <= reach; y += cell) {
        canvas.save();
        canvas.translate(x, y);
        canvas.drawRect(square, paint);
        canvas.rotate(math.pi / 4);
        canvas.drawRect(square, paint);
        canvas.restore();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StarPatternPainter old) =>
      old.rotation != rotation || old.color != color;
}

/// حلقات ذهبية تنتشر من الشعار كنبض ترحيب.
class _RipplePainter extends CustomPainter {
  final double progress;
  final double visibility;
  final Color color;
  final double baseRadius;

  _RipplePainter({
    required this.progress,
    required this.visibility,
    required this.color,
    required this.baseRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (visibility == 0) return;
    final center = size.center(Offset.zero);
    const count = 3;

    for (var i = 0; i < count; i++) {
      final p = (progress * 2 + i / count) % 1.0;
      final radius = baseRadius + p * baseRadius * 1.1;
      final opacity = (1 - p) * 0.32 * visibility;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = color.withValues(alpha: opacity),
      );
    }

    // حلقة ثابتة منقّطة
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.35 * visibility);
    const dots = 36;
    for (var i = 0; i < dots; i++) {
      final angle = i / dots * 2 * math.pi + progress * math.pi;
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * (baseRadius * 1.45),
        i.isEven ? 1.3 : 0.7,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RipplePainter old) =>
      old.progress != progress || old.visibility != visibility;
}

/// ذرات غبار ذهبي تصعد وتتلألأ.
class _GoldDustPainter extends CustomPainter {
  final double progress;
  final Color color;

  _GoldDustPainter({required this.progress, required this.color});

  static final List<_Particle> _particles = () {
    final random = math.Random(11);
    return List.generate(
      34,
      (_) => _Particle(
        x: random.nextDouble(),
        phase: random.nextDouble(),
        speed: 0.5 + random.nextDouble(),
        size: 0.6 + random.nextDouble() * 1.8,
        drift: (random.nextDouble() - 0.5) * 0.04,
      ),
    );
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);

    for (final particle in _particles) {
      final life = (progress * particle.speed + particle.phase) % 1.0;
      final y = size.height * (1.05 - life * 1.1);
      final x =
          size.width *
          (particle.x +
              math.sin((life + particle.phase) * 2 * math.pi) * particle.drift);
      final twinkle = math.sin(life * math.pi);
      paint.color = color.withValues(alpha: 0.55 * twinkle);
      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(_GoldDustPainter old) => old.progress != progress;
}

class _Particle {
  final double x;
  final double phase;
  final double speed;
  final double size;
  final double drift;

  const _Particle({
    required this.x,
    required this.phase,
    required this.speed,
    required this.size,
    required this.drift,
  });
}
