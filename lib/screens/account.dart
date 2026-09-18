import 'dart:async';

import 'package:flutter/material.dart';
import 'package:project_flutter/model/partner_account.dart';
import 'package:project_flutter/screens/favorites_screen.dart';
import 'package:project_flutter/screens/partner_screen.dart';
import 'package:project_flutter/screens/login_page.dart';
import 'package:project_flutter/screens/visited_places_screen.dart';
import 'package:project_flutter/service/partner_controller.dart';
import 'package:project_flutter/theme/theme.dart';
import 'package:project_flutter/theme/theme_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_flutter/widgets/app_bottom_nav_bar.dart';
import 'package:project_flutter/widgets/app_ui.dart';
import 'package:project_flutter/widgets/chat_fab_button.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isSigningOut = false;
  late final StreamSubscription<AuthState> _authSubscription;

  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _authSubscription = _supabase.auth.onAuthStateChange.listen((_) {
      if (mounted) setState(() {});
    });
    PartnerController.instance.ensureLoaded();
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  /// يفتح تسجيل الدخول ويُرجع ما إذا صار المستخدم مسجّلاً بعده.
  Future<bool> _openAuth() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    if (!mounted) return false;
    setState(() {});
    return _supabase.auth.currentUser != null;
  }

  /// يفتح صفحة تتطلب تسجيل الدخول: يطلبه أولاً ثم يُكمل إلى الوجهة.
  /// كان الزائر يُعاد إلى صفحة الحساب بعد الدخول وعليه الضغط مرة أخرى.
  Future<void> _openGated(WidgetBuilder builder) async {
    if (_supabase.auth.currentUser == null) {
      final signedIn = await _openAuth();
      if (!signedIn || !mounted) return;
    }
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(builder: builder));
    if (mounted) setState(() {});
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          icon: const AppIconMedallion(
            icon: Icons.logout_rounded,
            color: AppTheme.errorColor,
            size: 56,
          ),
          title: const Text('تسجيل الخروج'),
          content: const Text(
            'هل تريد تسجيل الخروج من حسابك؟',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تسجيل الخروج'),
            ),
          ],
        ),
      ),
    );

    if (shouldSignOut != true) return;

    setState(() {
      _isSigningOut = true;
    });
    try {
      await _supabase.auth.signOut();
      if (mounted) setState(() {});
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final isSignedIn = user != null;
    final colors = appColors(context);

    // الشاشة تعيش داخل [HomeShell]: الشِّل يملك الـ Scaffold وشريط التنقل
    // ومعالجة زر الرجوع.
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.only(
            bottom: AppBottomNavBar.contentBottomPadding(context),
          ),
          children: [
            _AccountHero(user: user, onSignIn: isSignedIn ? null : _openAuth),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSectionTitle(title: 'اختصاراتي'),
                  const SizedBox(height: 14),
                  _TileGroup(
                    children: [
                      _AccountTile(
                        icon: Icons.favorite_rounded,
                        title: 'مفضلتي',
                        subtitle: 'الأماكن التي حفظتها',
                        color: const Color(0xFFE5566F),
                        onTap: () => _openGated((_) => const FavoritesScreen()),
                      ),
                      _AccountTile(
                        icon: Icons.verified_rounded,
                        title: 'الأماكن التي زرتها',
                        subtitle: 'سجل زياراتك وملاحظاتك',
                        color: colors.accentColorDeep,
                        onTap: () =>
                            _openGated((_) => const VisitedPlacesScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const AppSectionTitle(title: 'الشراكة'),
                  const SizedBox(height: 14),
                  _PartnerSection(
                    onOpen: () => _openGated((_) => const PartnerScreen()),
                  ),
                  const SizedBox(height: 28),
                  const AppSectionTitle(title: 'المظهر'),
                  const SizedBox(height: 14),
                  const _AppearanceSelector(),
                  const SizedBox(height: 28),
                  const AppSectionTitle(title: 'التفضيلات'),
                  const SizedBox(height: 14),
                  _TileGroup(
                    children: [
                      _AccountTile(
                        icon: Icons.notifications_rounded,
                        title: 'التنبيهات',
                        subtitle: 'ستظهر هنا تنبيهاتك قريباً',
                        color: colors.accentColor,
                        badge: 'قريباً',
                        onTap: () => _showComingSoon(context),
                      ),
                      _AccountTile(
                        icon: Icons.tune_rounded,
                        title: 'الإعدادات',
                        subtitle: 'تخصيص تجربتك في التطبيق',
                        color: colors.textMuted,
                        badge: 'قريباً',
                        onTap: () => _showComingSoon(context),
                      ),
                    ],
                  ),
                  if (isSignedIn) ...[
                    const SizedBox(height: 28),
                    const AppSectionTitle(title: 'الحساب'),
                    const SizedBox(height: 14),
                    _TileGroup(
                      children: [
                        _AccountTile(
                          icon: Icons.logout_rounded,
                          title: 'تسجيل الخروج',
                          subtitle: 'الخروج من هذا الجهاز',
                          color: AppTheme.errorColor,
                          isDestructive: true,
                          isLoading: _isSigningOut,
                          onTap: _isSigningOut ? null : _signOut,
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 28),
                  Center(
                    child: Text(
                      'المعزب · دليلك للأماكن والفعاليات',
                      style: TextStyle(
                        color: colors.textMuted.withValues(alpha: 0.7),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const ChatFabButton(),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('هذه الميزة ستتوفر قريباً')));
  }
}

// ==========================================
// بطاقة حساب الشريك (منظّم فعاليات / مالك منشأة)
// ==========================================
class _PartnerSection extends StatelessWidget {
  /// يفتح صفحة الشراكة، ويطلب تسجيل الدخول أولاً للزائر ثم يُكمل إليها.
  final VoidCallback onOpen;

  const _PartnerSection({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return ListenableBuilder(
      listenable: PartnerController.instance,
      builder: (context, _) {
        final account = PartnerController.instance.account;

        return _TileGroup(
          children: [
            _AccountTile(
              icon: account?.isApproved == true
                  ? Icons.verified_rounded
                  : Icons.handshake_rounded,
              title: switch (account?.status) {
                PartnerStatus.approved => 'حساب شريك · ${account!.role.label}',
                PartnerStatus.pending => 'طلب الشراكة قيد المراجعة',
                PartnerStatus.rejected => 'لم يتم اعتماد طلب الشراكة',
                null => 'انضم كشريك',
              },
              subtitle: switch (account?.status) {
                PartnerStatus.approved => 'أضف أماكنك وانشرها مباشرة',
                PartnerStatus.pending => 'سنوافيك بالنتيجة قريباً',
                PartnerStatus.rejected => 'عدّل بياناتك وأعد الإرسال',
                null => 'منظّم فعاليات أو مالك منشأة؟ أضف أماكنك بنفسك',
              },
              color: account?.isApproved == true
                  ? const Color(0xFF2F9E62)
                  : colors.accentColorDeep,
              badge: account == null ? 'جديد' : account.status.label,
              onTap: () => onOpen(),
            ),
          ],
        );
      },
    );
  }
}

// ==========================================
// ترويسة الحساب
// ==========================================
class _AccountHero extends StatelessWidget {
  final User? user;
  final VoidCallback? onSignIn;

  const _AccountHero({required this.user, required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final isSignedIn = user != null;
    final email = user?.email ?? '';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : null;

    return AppPageHeader(
      title: 'حسابي',
      icon: Icons.person_rounded,
      subtitle: 'إدارة مفضلتك وزياراتك وتفضيلاتك',
      bottom: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: colors.accentGradient,
              ),
              child: CircleAvatar(
                radius: 27,
                backgroundColor: colors.inkSoft,
                child: initial != null
                    ? Text(
                        initial,
                        style: AppTheme.display(
                          22,
                          color: colors.goldColor,
                          height: 1.2,
                        ),
                      )
                    : Icon(
                        Icons.person_rounded,
                        color: colors.goldColor,
                        size: 28,
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSignedIn ? 'مرحباً بعودتك' : 'أهلاً بك يا ضيفنا',
                    style: AppTheme.display(
                      18,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isSignedIn ? email : 'سجل الدخول لحفظ مفضلاتك',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (!isSignedIn)
              GestureDetector(
                onTap: onSignIn,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: colors.accentGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'دخول',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.goldColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 14,
                      color: colors.goldColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'عضو',
                      style: TextStyle(
                        color: colors.goldColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// اختيار المظهر: فاتح / داكن / حسب النظام
// ==========================================
class _AppearanceSelector extends StatelessWidget {
  const _AppearanceSelector();

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.instance;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: controller,
      builder: (context, mode, _) {
        return AppSurfaceCard(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              _ModeOption(
                icon: Icons.light_mode_rounded,
                label: 'فاتح',
                selected: mode == ThemeMode.light,
                onTap: () => controller.setMode(ThemeMode.light),
              ),
              _ModeOption(
                icon: Icons.dark_mode_rounded,
                label: 'داكن',
                selected: mode == ThemeMode.dark,
                onTap: () => controller.setMode(ThemeMode.dark),
              ),
              _ModeOption(
                icon: Icons.brightness_auto_rounded,
                label: 'تلقائي',
                selected: mode == ThemeMode.system,
                onTap: () => controller.setMode(ThemeMode.system),
              ),
            ].map((option) => Expanded(child: option)).toList(),
          ),
        );
      },
    );
  }
}

class _ModeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return Semantics(
      button: true,
      selected: selected,
      label: 'المظهر $label',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: selected ? colors.accentGradient : null,
            borderRadius: BorderRadius.circular(18),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: colors.accentColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? Colors.white : colors.textMuted,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : colors.textPrimary,
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
// مجموعة عناصر داخل بطاقة واحدة بفواصل
// ==========================================
class _TileGroup extends StatelessWidget {
  final List<Widget> children;

  const _TileGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 74),
                  child: Divider(height: 1, color: colors.borderSoft),
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isDestructive;
  final String? badge;

  const _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isLoading = false,
    this.isDestructive = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              AppIconMedallion(icon: icon, color: color, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDestructive ? color : colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null && !isLoading) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accentColorSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: colors.accentColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: colors.textMuted.withValues(alpha: 0.7),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
