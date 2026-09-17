import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_flutter/screens/account.dart';
import 'package:project_flutter/screens/categories_screen.dart';
import 'package:project_flutter/screens/login_page.dart';
import 'package:project_flutter/service/supabase_data.dart';
import 'package:project_flutter/widgets/app_bottom_nav_bar.dart';
import 'package:project_flutter/widgets/app_ui.dart';

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await SupabaseData().pushPlaceRequest(
        placeName: _nameController.text.trim(),
        location: _locationController.text.trim(),
        url: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إرسال المكان للمراجعة')));
      _formKey.currentState!.reset();
      _nameController.clear();
      _locationController.clear();
      _websiteController.clear();
    } catch (error) {
      if (!mounted) return;
      final isUnauthenticated = error.toString().toLowerCase().contains(
        'authenticated',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isUnauthenticated
                ? 'يجب تسجيل الدخول لإرسال مكان جديد'
                : 'تعذر إرسال المكان: $error',
          ),
          action: isUnauthenticated
              ? SnackBarAction(
                  label: 'تسجيل الدخول',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                )
              : null,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _handleNavigation(int index) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CategoriesScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AccountScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: colors.creamBackground,
          extendBody: true,
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 130),
              children: [
                const AppPageHeader(
                  title: 'اقترح مكاناً',
                  icon: Icons.add_location_alt_rounded,
                  subtitle:
                      'شاركنا وجهة تستحق الزيارة، وسنراجعها ونضيفها للدليل.',
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _StepsStrip(),
                      const SizedBox(height: 24),
                      const AppSectionTitle(title: 'بيانات المكان'),
                      const SizedBox(height: 14),
                      AppSurfaceCard(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel(
                              label: 'اسم المكان',
                              required: true,
                            ),
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: 'مثال: حديقة الملك عبدالله',
                                prefixIcon: Icon(Icons.storefront_rounded),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'أدخل اسم المكان'
                                  : null,
                            ),
                            const SizedBox(height: 18),
                            const _FieldLabel(label: 'الموقع', required: true),
                            TextFormField(
                              controller: _locationController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: 'العنوان أو رابط الخريطة',
                                prefixIcon: Icon(Icons.location_on_rounded),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'أدخل موقع المكان'
                                  : null,
                            ),
                            const SizedBox(height: 18),
                            const _FieldLabel(label: 'الموقع الإلكتروني'),
                            TextFormField(
                              controller: _websiteController,
                              keyboardType: TextInputType.url,
                              textDirection: TextDirection.ltr,
                              decoration: const InputDecoration(
                                hintText: 'https://',
                                prefixIcon: Icon(Icons.link_rounded),
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
                            Icon(
                              Icons.info_rounded,
                              size: 18,
                              color: colors.accentColor,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'يتطلب الإرسال تسجيل الدخول. ستظهر الأماكن المقبولة لجميع المستخدمين بعد المراجعة.',
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
                        label: 'إرسال للمراجعة',
                        icon: Icons.send_rounded,
                        isLoading: _isSaving,
                        onPressed: _isSaving ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: 1,
            onTap: _handleNavigation,
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool required;

  const _FieldLabel({required this.label, this.required = false});

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
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

class _StepsStrip extends StatelessWidget {
  const _StepsStrip();

  @override
  Widget build(BuildContext context) {
    const steps = [
      (Icons.edit_note_rounded, 'أدخل البيانات'),
      (Icons.fact_check_rounded, 'نراجعها'),
      (Icons.public_rounded, 'تُنشر للجميع'),
    ];
    final colors = appColors(context);

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 1.5,
                margin: const EdgeInsets.only(bottom: 22),
                color: colors.borderSoft,
              ),
            ),
          Column(
            children: [
              AppIconMedallion(icon: steps[i].$1, size: 42),
              const SizedBox(height: 6),
              Text(
                steps[i].$2,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
