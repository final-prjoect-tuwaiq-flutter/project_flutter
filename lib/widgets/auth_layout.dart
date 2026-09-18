import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_flutter/theme/theme.dart';
import 'package:project_flutter/widgets/app_ui.dart';

/// الهيكل المشترك لصفحتي الدخول والتسجيل.
class AuthLayout extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final canPop = Navigator.of(context).canPop();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: colors.inkColor,
          body: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: colors.inkGradient),
                child: Stack(
                  children: [
                    Positioned(
                      top: -100,
                      right: -80,
                      child: AppGlowBlob(color: colors.accentColor, size: 300),
                    ),
                    Positioned(
                      top: 120,
                      left: -120,
                      child: AppGlowBlob(
                        color: colors.accentColorDeep,
                        size: 260,
                        intensity: 0.18,
                      ),
                    ),
                    Column(
                      children: [
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 44,
                                  child: canPop
                                      ? Align(
                                          alignment:
                                              AlignmentDirectional.centerStart,
                                          child: AppCircleButton(
                                            icon: Icons.arrow_back_rounded,
                                            tooltip: 'رجوع',
                                            onPressed: () =>
                                                Navigator.maybePop(context),
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                const AppBrandMark(size: 72),
                                const SizedBox(height: 18),
                                Text(
                                  title,
                                  textAlign: TextAlign.center,
                                  style: AppTheme.display(
                                    27,
                                    color: Colors.white,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  subtitle,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.62),
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.sizeOf(context).height * 0.62,
                          ),
                          decoration: BoxDecoration(
                            color: colors.creamBackground,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(34),
                            ),
                          ),
                          padding: EdgeInsets.fromLTRB(
                            22,
                            30,
                            22,
                            24 + MediaQuery.paddingOf(context).bottom,
                          ),
                          child: child,
                        ),
                      ],
                    ),
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

/// عنوان حقل في نماذج الدخول والتسجيل.
class AuthFieldLabel extends StatelessWidget {
  final String text;

  const AuthFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        text,
        style: TextStyle(
          color: appColors(context).textPrimary,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
