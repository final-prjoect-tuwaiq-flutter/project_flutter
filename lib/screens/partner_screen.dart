import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_flutter/model/partner_account.dart';
import 'package:project_flutter/screens/add_place_screen.dart';
import 'package:project_flutter/screens/login_page.dart';
import 'package:project_flutter/service/partner_controller.dart';
import 'package:project_flutter/theme/theme.dart';
import 'package:project_flutter/widgets/app_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// شاشة "حساب شريك": يتقدّم المستخدم كمنظّم فعاليات أو مالك منشأة،
/// وبعد الاعتماد تُفتح له إضافة الأماكن مباشرة بدون مراجعة.
class PartnerScreen extends StatefulWidget {
  const PartnerScreen({super.key});

  @override
  State<PartnerScreen> createState() => _PartnerScreenState();
}

class _PartnerScreenState extends State<PartnerScreen> {
  final PartnerController _partner = PartnerController.instance;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();

  PartnerRole _selectedRole = PartnerRole.venueOwner;
  bool _isSubmitting = false;

  /// يظهر النموذج بدل بطاقة الحالة عند إعادة تقديم طلب مرفوض.
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _partner.addListener(_onPartnerChanged);
    _partner.ensureLoaded();
    _prefillFromAccount();
  }

  @override
  void dispose() {
    _partner.removeListener(_onPartnerChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onPartnerChanged() {
    if (!mounted) return;
    setState(_prefillFromAccount);
  }

  void _prefillFromAccount() {
    final account = _partner.account;
    if (account == null || _nameController.text.isNotEmpty) return;

    _selectedRole = account.role;
    _nameController.text = account.displayName;
    _phoneController.text = account.contactPhone ?? '';
    _websiteController.text = account.website ?? '';
    _notesController.text = account.notes ?? '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _partner.submit(
        role: _selectedRole,
        displayName: _nameController.text,
        contactPhone: _phoneController.text,
        website: _websiteController.text,
        notes: _notesController.text,
      );
      if (!mounted) return;
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال طلبك، سنراجعه ونوافيك بالنتيجة')),
      );
    } catch (error) {
      if (!mounted) return;
      final isUnauthenticated = error.toString().toLowerCase().contains(
        'authenticated',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUnauthenticated
                ? 'يجب تسجيل الدخول لتقديم الطلب'
                : 'تعذر إرسال الطلب: $error',
          ),
          action: isUnauthenticated
              ? SnackBarAction(
                  label: 'تسجيل الدخول',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                )
              : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final isSignedIn = Supabase.instance.client.auth.currentUser != null;
    final account = _partner.account;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: colors.creamBackground,
          body: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              AppPageHeader(
                title: 'حساب شريك',
                icon: Icons.handshake_rounded,
                subtitle: 'انضم كمنظّم فعاليات أو مالك منشأة وأضف أماكنك بنفسك.',
                showBack: true,
                trailing: account == null
                    ? null
                    : PartnerStatusChip(status: account.status),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: _buildBody(isSignedIn, account),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isSignedIn, PartnerAccount? account) {
    if (!isSignedIn) {
      return AppStatePanel(
        icon: Icons.lock_person_rounded,
        title: 'سجّل الدخول أولاً',
        subtitle: 'حساب الشريك مرتبط بحسابك في المعزب.',
        actionLabel: 'تسجيل الدخول',
        actionIcon: Icons.login_rounded,
        onAction: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
          if (mounted) setState(() {});
        },
      );
    }

    if (!_partner.isLoaded) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // الطلب المرفوض يمكن تعديله وإعادة إرساله، أما المعتمد والمعلّق فيعرضان الحالة.
    final showForm = account == null || (account.isRejected && _isEditing);
    if (showForm) return _buildForm(account);

    return _buildStatusView(account);
  }

  // ==========================================
  // نموذج التقديم
  // ==========================================
  Widget _buildForm(PartnerAccount? account) {
    final colors = appColors(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PartnerBenefits(),
          const SizedBox(height: 24),
          const AppSectionTitle(title: 'نوع الشراكة'),
          const SizedBox(height: 14),
          for (final role in PartnerRole.values) ...[
            _RoleOption(
              role: role,
              selected: _selectedRole == role,
              onTap: () => setState(() => _selectedRole = role),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 14),
          const AppSectionTitle(title: 'بيانات التواصل'),
          const SizedBox(height: 14),
          AppSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppFieldLabel(
                  label: _selectedRole == PartnerRole.organizer
                      ? 'اسم الجهة المنظِّمة'
                      : 'اسم المنشأة',
                  required: true,
                ),
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: _selectedRole == PartnerRole.organizer
                        ? 'مثال: شركة ليالي الرياض'
                        : 'مثال: مقهى الدرعية',
                    prefixIcon: Icon(_selectedRole.icon),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'أدخل الاسم'
                      : null,
                ),
                const SizedBox(height: 18),
                const AppFieldLabel(label: 'رقم التواصل', required: true),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: '05xxxxxxxx',
                    prefixIcon: Icon(Icons.phone_rounded),
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'أدخل رقم التواصل';
                    if (text.replaceAll(RegExp(r'\D'), '').length < 9) {
                      return 'أدخل رقماً صحيحاً';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                const AppFieldLabel(label: 'الموقع الإلكتروني أو حساب التواصل'),
                TextFormField(
                  controller: _websiteController,
                  keyboardType: TextInputType.url,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'https://',
                    prefixIcon: Icon(Icons.link_rounded),
                  ),
                ),
                const SizedBox(height: 18),
                const AppFieldLabel(label: 'نبذة عنك وعن نشاطك'),
                TextFormField(
                  controller: _notesController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'ما نوع الأماكن أو الفعاليات التي ستضيفها؟',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.accentColorSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_rounded, size: 18, color: colors.accentColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'نراجع الطلب يدوياً للتأكد من صحة البيانات. بعد الاعتماد ستتمكن من نشر أماكنك مباشرة في الدليل.',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 12.5,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          AppGradientButton(
            label: account == null ? 'إرسال الطلب' : 'إعادة إرسال الطلب',
            icon: Icons.send_rounded,
            isLoading: _isSubmitting,
            onPressed: _isSubmitting ? null : _submit,
          ),
          if (account != null) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _isEditing = false),
                child: const Text('إلغاء'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // عرض حالة الطلب بعد إرساله
  // ==========================================
  Widget _buildStatusView(PartnerAccount account) {
    final colors = appColors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSurfaceCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              AppIconMedallion(
                icon: switch (account.status) {
                  PartnerStatus.approved => Icons.verified_rounded,
                  PartnerStatus.pending => Icons.hourglass_top_rounded,
                  PartnerStatus.rejected => Icons.error_outline_rounded,
                },
                color: _statusColor(account.status, colors),
                size: 72,
              ),
              const SizedBox(height: 16),
              Text(
                switch (account.status) {
                  PartnerStatus.approved => 'حسابك معتمد كـ${account.role.label}',
                  PartnerStatus.pending => 'طلبك قيد المراجعة',
                  PartnerStatus.rejected => 'لم يتم اعتماد الطلب',
                },
                textAlign: TextAlign.center,
                style: AppTheme.display(19, color: colors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                switch (account.status) {
                  PartnerStatus.approved =>
                    'يمكنك الآن إضافة أماكنك ونشرها في الدليل مباشرة بدون انتظار المراجعة.',
                  PartnerStatus.pending =>
                    'سنتواصل معك على ${account.contactPhone ?? 'رقمك المسجّل'} فور انتهاء المراجعة.',
                  PartnerStatus.rejected =>
                    account.reviewNote ??
                        'يمكنك تعديل بياناتك وإعادة إرسال الطلب.',
                },
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 13,
                  height: 1.7,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const AppSectionTitle(title: 'بيانات الشراكة'),
        const SizedBox(height: 14),
        AppSurfaceCard(
          child: Column(
            children: [
              _DetailRow(
                icon: account.role.icon,
                label: 'نوع الشراكة',
                value: account.role.label,
              ),
              _DetailRow(
                icon: Icons.badge_rounded,
                label: 'الاسم',
                value: account.displayName,
              ),
              if (account.contactPhone != null)
                _DetailRow(
                  icon: Icons.phone_rounded,
                  label: 'رقم التواصل',
                  value: account.contactPhone!,
                ),
              if (account.website != null)
                _DetailRow(
                  icon: Icons.link_rounded,
                  label: 'الرابط',
                  value: account.website!,
                ),
              if (account.createdAt != null)
                _DetailRow(
                  icon: Icons.event_rounded,
                  label: 'تاريخ الطلب',
                  value: formatArabicDate(account.createdAt!),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (account.isApproved)
          AppGradientButton(
            label: 'أضف مكاناً الآن',
            icon: Icons.add_location_alt_rounded,
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AddPlaceScreen()),
            ),
          )
        else if (account.isRejected)
          AppGradientButton(
            label: 'تعديل وإعادة الإرسال',
            icon: Icons.edit_rounded,
            onPressed: () => setState(() => _isEditing = true),
          ),
      ],
    );
  }
}

Color _statusColor(PartnerStatus status, AppCustomColors colors) {
  return switch (status) {
    PartnerStatus.approved => const Color(0xFF2F9E62),
    PartnerStatus.pending => colors.accentColor,
    PartnerStatus.rejected => AppTheme.errorColor,
  };
}

/// شارة صغيرة تعرض حالة حساب الشريك (تُستخدم هنا وفي صفحة الحساب).
class PartnerStatusChip extends StatelessWidget {
  final PartnerStatus status;
  final bool onDark;

  const PartnerStatusChip({
    super.key,
    required this.status,
    this.onDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final color = onDark
        ? (status == PartnerStatus.approved ? colors.goldColor : Colors.white)
        : _statusColor(status, colors);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.10)
            : _statusColor(status, colors).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: onDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.14))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            switch (status) {
              PartnerStatus.approved => Icons.verified_rounded,
              PartnerStatus.pending => Icons.hourglass_top_rounded,
              PartnerStatus.rejected => Icons.error_outline_rounded,
            },
            size: 14,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// مزايا الشراكة
// ==========================================
class _PartnerBenefits extends StatelessWidget {
  const _PartnerBenefits();

  @override
  Widget build(BuildContext context) {
    const benefits = [
      (Icons.bolt_rounded, 'نشر مباشر', 'أضف أماكنك دون انتظار المراجعة'),
      (Icons.edit_location_alt_rounded, 'تحديث فوري', 'عدّل الأوقات والأسعار وقتما تشاء'),
      (Icons.verified_rounded, 'شارة موثّقة', 'يظهر حسابك كشريك معتمد في المعزب'),
    ];
    final colors = appColors(context);

    return AppSurfaceCard(
      child: Column(
        children: [
          for (var i = 0; i < benefits.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            Row(
              children: [
                AppIconMedallion(icon: benefits[i].$1, size: 42),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        benefits[i].$2,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        benefits[i].$3,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// خيار نوع الشراكة
// ==========================================
class _RoleOption extends StatelessWidget {
  final PartnerRole role;
  final bool selected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.role,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return Semantics(
      button: true,
      selected: selected,
      label: role.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? colors.accentColorSoft : colors.surfaceColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? colors.accentColor : colors.borderSoft,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              AppIconMedallion(
                icon: role.icon,
                size: 46,
                color: selected ? colors.accentColor : colors.textMuted,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role.label,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      role.description,
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? colors.accentColor : colors.borderSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.accentColor),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
