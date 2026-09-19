import 'package:flutter/material.dart';
import 'package:project_flutter/model/category_model.dart';
import 'package:project_flutter/screens/home_shell.dart';
import 'package:project_flutter/screens/login_page.dart';
import 'package:project_flutter/screens/partner_screen.dart';
import 'package:project_flutter/service/partner_controller.dart';
import 'package:project_flutter/service/supabase_data.dart';
import 'package:project_flutter/theme/theme.dart';
import 'package:project_flutter/widgets/app_bottom_nav_bar.dart';
import 'package:project_flutter/widgets/app_ui.dart';

/// يستخرج الإحداثيات من نص المستخدم: إمّا مكتوبة مباشرة (`24.7136, 46.6753`)
/// أو مضمّنة في رابط خرائط جوجل (`.../@24.7136,46.6753,15z`).
/// يُرجع null إن لم يجدها أو كانت خارج المدى الجغرافي.
({double lat, double lng})? parseLatLng(String input) {
  final match = RegExp(r'(-?\d{1,2}(?:\.\d+)?)\s*,\s*(-?\d{1,3}(?:\.\d+)?)')
      .firstMatch(input.replaceAll('@', ' '));
  if (match == null) return null;

  final lat = double.tryParse(match.group(1)!);
  final lng = double.tryParse(match.group(2)!);
  if (lat == null || lng == null) return null;
  if (lat.abs() > 90 || lng.abs() > 180) return null;

  return (lat: lat, lng: lng);
}

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => AddPlaceScreenState();
}

class AddPlaceScreenState extends State<AddPlaceScreen> {
  final PartnerController _partner = PartnerController.instance;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();

  // حقول إضافية تظهر للشركاء المعتمدين فقط (النشر المباشر).
  final _shortDescriptionController = TextEditingController();
  final _fullDescriptionController = TextEditingController();
  final _coverImageController = TextEditingController();
  final _thumbnailController = TextEditingController();
  final _priceController = TextEditingController();

  Future<List<Category>>? _categoriesFuture;
  int? _selectedCategoryId;
  bool _isFree = true;
  bool _isSaving = false;

  /// أوقات العمل اليومية. تُحفظ في عمود `times` بصيغة `{'times': 'HH:mm-HH:mm'}`
  /// وهي الصيغة التي تقرأها [Event.formattedWorkingHoursArabic].
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;

  /// فترة إتاحة المكان (اختيارية): تُحفظ في `from_date` و`to_date`.
  DateTime? _fromDate;
  DateTime? _toDate;

  /// هل يحتاج الزائر لحجز مسبق؟ إن كان كذلك فرابط الحجز إجباري.
  bool _requiresBooking = false;

  /// النشر المباشر متاح للشريك المعتمد فقط، وإلا فالمسار هو الاقتراح للمراجعة.
  bool get _canPublishDirectly => _partner.canPublishDirectly;

  @override
  void initState() {
    super.initState();
    _partner.addListener(_onPartnerChanged);
    _partner.ensureLoaded();
  }

  @override
  void dispose() {
    _partner.removeListener(_onPartnerChanged);
    _nameController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _shortDescriptionController.dispose();
    _fullDescriptionController.dispose();
    _coverImageController.dispose();
    _thumbnailController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onPartnerChanged() {
    if (!mounted) return;
    setState(() {
      // التصنيفات لازمة فقط في وضع النشر المباشر، فنجلبها عند تفعيله.
      if (_canPublishDirectly) {
        _categoriesFuture ??= SupabaseData().getCategories();
      }
    });
  }

  /// أوقات العمل بصيغة عمود `times`، أو null إن لم يحدّدها الشريك.
  Map<String, dynamic>? get _timesPayload {
    final opening = _openingTime;
    final closing = _closingTime;
    if (opening == null || closing == null) return null;
    return {'times': '${_formatTime(opening)}-${_formatTime(closing)}'};
  }

  static String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_canPublishDirectly && _selectedCategoryId == null) {
      _showSnackBar('اختر تصنيف المكان');
      return;
    }
    // وقت واحد بلا الآخر لا يصنع فترة عمل، فلا يُحفظ بصمت.
    if (_canPublishDirectly &&
        (_openingTime == null) != (_closingTime == null)) {
      _showSnackBar('حدّد وقت الفتح ووقت الإغلاق معاً');
      return;
    }
    if (_canPublishDirectly &&
        _fromDate != null &&
        _toDate != null &&
        _toDate!.isBefore(_fromDate!)) {
      _showSnackBar('تاريخ النهاية يجب أن يكون بعد تاريخ البداية');
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_canPublishDirectly) {
        final coordinates = parseLatLng(_locationController.text);
        await SupabaseData().publishPlace(
          title: _nameController.text,
          categoryId: _selectedCategoryId!,
          shortDescription: _shortDescriptionController.text,
          fullDescription: _fullDescriptionController.text,
          coverImageUrl: _coverImageController.text,
          thumbnailUrl: _thumbnailController.text,
          lat: coordinates?.lat,
          lng: coordinates?.lng,
          isFree: _isFree,
          priceMin: _isFree
              ? null
              : double.tryParse(_priceController.text.trim()),
          ticketUrl: _websiteController.text,
          requiresBooking: _requiresBooking,
          times: _timesPayload,
          fromDate: _fromDate,
          toDate: _toDate,
        );
      } else {
        await SupabaseData().pushPlaceRequest(
          placeName: _nameController.text.trim(),
          location: _locationController.text.trim(),
          url: _websiteController.text.trim().isEmpty
              ? null
              : _websiteController.text.trim(),
        );
      }

      if (!mounted) return;
      _showSnackBar(
        _canPublishDirectly
            ? 'تم نشر المكان في الدليل'
            : 'تم إرسال المكان للمراجعة',
      );
      _resetForm();
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

  void _resetForm() {
    _formKey.currentState!.reset();
    _nameController.clear();
    _locationController.clear();
    _websiteController.clear();
    _shortDescriptionController.clear();
    _fullDescriptionController.clear();
    _coverImageController.clear();
    _thumbnailController.clear();
    _priceController.clear();
    setState(() {
      _selectedCategoryId = null;
      _isFree = true;
      _openingTime = null;
      _closingTime = null;
      _fromDate = null;
      _toDate = null;
      _requiresBooking = false;
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// هل كتب المستخدم شيئاً يستحق التحذير قبل مغادرة الصفحة؟
  bool get _hasUnsavedInput => [
    _nameController,
    _locationController,
    _websiteController,
    _shortDescriptionController,
    _fullDescriptionController,
    _coverImageController,
    _thumbnailController,
    _priceController,
  ].any((controller) => controller.text.trim().isNotEmpty) ||
      _openingTime != null ||
      _closingTime != null ||
      _fromDate != null ||
      _toDate != null;

  /// يؤكّد المغادرة إن كان في النموذج مدخلات لم تُرسل بعد.
  /// كان الرجوع يمسح نموذجاً طويلاً بضغطة واحدة بلا أي تنبيه.
  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedInput || _isSaving) return true;

    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          icon: const AppIconMedallion(icon: Icons.edit_note_rounded, size: 56),
          title: const Text('تجاهل ما كتبته؟'),
          content: const Text(
            'لم تُرسل بيانات المكان بعد، وستُفقد إذا خرجت الآن.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('متابعة التعبئة'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('تجاهل'),
            ),
          ],
        ),
      ),
    );

    return discard == true;
  }

  /// يستأذن قبل مغادرة التبويب. يستدعيها [HomeShell] عند تبديل التبويب
  /// وعند زر رجوع الجهاز، فلا يضيع نموذج ممتلئ بضغطة واحدة.
  Future<bool> confirmLeave() => _confirmDiscard();

  /// زر الرجوع في ترويسة الصفحة: يعود لتبويب الرئيسية.
  Future<void> _goBack() async {
    if (!await _confirmDiscard() || !mounted) return;
    HomeShellController.instance.goToTab(0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final isPartner = _canPublishDirectly;

    // الشاشة تعيش داخل [HomeShell]: الشِّل يملك الـ Scaffold وشريط التنقل
    // ومعالجة زر الرجوع (ويستأذن عبر [confirmLeave] قبل المغادرة).
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.only(
          bottom: AppBottomNavBar.contentBottomPadding(context),
        ),
        children: [
          AppPageHeader(
            title: isPartner ? 'أضف مكانك' : 'اقترح مكاناً',
            icon: Icons.add_location_alt_rounded,
            showBack: true,
            onBack: _goBack,
            subtitle: isPartner
                ? 'بصفتك شريكاً معتمداً، يُنشر المكان في الدليل فور الحفظ.'
                : 'شاركنا وجهة تستحق الزيارة، وسنراجعها ونضيفها للدليل.',
            trailing: isPartner
                ? PartnerStatusChip(status: _partner.account!.status)
                : null,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isPartner)
                  const _DirectPublishBanner()
                else ...[
                  const _StepsStrip(),
                  const SizedBox(height: 20),
                  const _BecomePartnerCard(),
                ],
                const SizedBox(height: 24),
                const AppSectionTitle(title: 'بيانات المكان'),
                const SizedBox(height: 14),
                AppSurfaceCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppFieldLabel(label: 'اسم المكان', required: true),
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
                      AppFieldLabel(
                        label: isPartner
                            ? 'الإحداثيات أو رابط الخريطة'
                            : 'الموقع',
                        required: true,
                      ),
                      TextFormField(
                        controller: _locationController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: isPartner
                              ? '24.7136, 46.6753'
                              : 'العنوان أو رابط الخريطة',
                          prefixIcon: const Icon(Icons.location_on_rounded),
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return 'أدخل موقع المكان';
                          if (isPartner && parseLatLng(text) == null) {
                            return 'تعذّر استخراج الإحداثيات، أدخلها بصيغة lat, lng';
                          }
                          return null;
                        },
                      ),
                      // لدى الشريك بطاقة «الحجز» بأسفل الصفحة، وفيها الرابط
                      // الذي يصبح إجبارياً إذا كان المكان يتطلب حجزاً مسبقاً.
                      if (!isPartner) ...[
                        const SizedBox(height: 18),
                        const AppFieldLabel(label: 'الموقع الإلكتروني'),
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
                    ],
                  ),
                ),
                if (isPartner) ...[
                  const SizedBox(height: 24),
                  const AppSectionTitle(title: 'التصنيف'),
                  const SizedBox(height: 14),
                  _buildCategoryPicker(),
                  const SizedBox(height: 24),
                  const AppSectionTitle(title: 'الوصف والصور'),
                  const SizedBox(height: 14),
                  _buildDescriptionCard(),
                  const SizedBox(height: 24),
                  const AppSectionTitle(title: 'الأوقات والفترة'),
                  const SizedBox(height: 14),
                  _buildWorkingHoursCard(),
                  const SizedBox(height: 24),
                  const AppSectionTitle(title: 'الحجز'),
                  const SizedBox(height: 14),
                  _buildBookingCard(),
                  const SizedBox(height: 24),
                  const AppSectionTitle(title: 'الدخول'),
                  const SizedBox(height: 14),
                  _buildPricingCard(),
                ] else ...[
                  const SizedBox(height: 16),
                  _buildReviewNotice(colors),
                ],
                const SizedBox(height: 24),
                AppGradientButton(
                  label: isPartner ? 'نشر المكان' : 'إرسال للمراجعة',
                  icon: isPartner ? Icons.publish_rounded : Icons.send_rounded,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewNotice(AppCustomColors colors) {
    return Container(
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
    );
  }

  Widget _buildCategoryPicker() {
    final colors = appColors(context);

    return FutureBuilder<List<Category>>(
      future: _categoriesFuture ??= SupabaseData().getCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppSurfaceCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return AppSurfaceCard(
            child: Text(
              'تعذّر تحميل التصنيفات: ${snapshot.error}',
              style: TextStyle(color: colors.textMuted, fontSize: 12.5),
            ),
          );
        }

        final categories = snapshot.data ?? [];
        return AppSurfaceCard(
          padding: const EdgeInsets.all(14),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in categories)
                _CategoryChip(
                  label: category.name,
                  selected: _selectedCategoryId == category.id,
                  onTap: () =>
                      setState(() => _selectedCategoryId = category.id),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDescriptionCard() {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppFieldLabel(label: 'وصف مختصر', required: true),
          TextFormField(
            controller: _shortDescriptionController,
            maxLength: 120,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'سطر واحد يظهر في قائمة الأماكن',
              prefixIcon: Icon(Icons.short_text_rounded),
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'أدخل وصفاً مختصراً'
                : null,
          ),
          const SizedBox(height: 8),
          const AppFieldLabel(label: 'الوصف الكامل'),
          TextFormField(
            controller: _fullDescriptionController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'عرّف الزوار بالمكان وما يميّزه',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 18),
          const AppFieldLabel(label: 'رابط صورة الغلاف', required: true),
          TextFormField(
            controller: _coverImageController,
            keyboardType: TextInputType.url,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              hintText: 'https://...jpg',
              prefixIcon: Icon(Icons.image_rounded),
            ),
            // صورة واحدة على الأقل تكفي: إن ترك الغلاف فارغاً واكتفى
            // بالصورة الثانية فلا داعي لمنع النشر.
            validator: (value) {
              if (_hasAnyImage) return null;
              return 'أضف رابط صورة واحدة على الأقل';
            },
          ),
          const SizedBox(height: 18),
          const AppFieldLabel(label: 'رابط الصورة الثانية'),
          TextFormField(
            controller: _thumbnailController,
            keyboardType: TextInputType.url,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              hintText: 'https://...jpg',
              prefixIcon: Icon(Icons.add_photo_alternate_rounded),
            ),
          ),
        ],
      ),
    );
  }

  /// هل أدخل الشريك رابط صورة واحدة على الأقل (الغلاف أو الثانية)؟
  bool get _hasAnyImage =>
      _coverImageController.text.trim().isNotEmpty ||
      _thumbnailController.text.trim().isNotEmpty;

  Widget _buildWorkingHoursCard() {
    final colors = appColors(context);

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppFieldLabel(label: 'أوقات العمل اليومية'),
          Row(
            children: [
              Expanded(
                child: _TimePickerField(
                  label: 'من',
                  time: _openingTime,
                  onPick: (time) => setState(() => _openingTime = time),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimePickerField(
                  label: 'إلى',
                  time: _closingTime,
                  onPick: (time) => setState(() => _closingTime = time),
                ),
              ),
            ],
          ),
          if (_openingTime != null || _closingTime != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'تُطبَّق هذه الأوقات على كل أيام الأسبوع.',
                    style: TextStyle(color: colors.textMuted, fontSize: 12),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() {
                    _openingTime = null;
                    _closingTime = null;
                  }),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('مسح'),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          const AppFieldLabel(label: 'فترة الإتاحة (تاريخ البداية والنهاية)'),
          Row(
            children: [
              Expanded(
                child: _DatePickerField(
                  label: 'من تاريخ',
                  date: _fromDate,
                  onPick: (date) => setState(() => _fromDate = date),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DatePickerField(
                  label: 'إلى تاريخ',
                  date: _toDate,
                  firstDate: _fromDate,
                  onPick: (date) => setState(() => _toDate = date),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'اتركها فارغة إن كان المكان متاحاً طوال السنة. بعد تاريخ '
                  'النهاية يظهر المكان للزوار كمنتهٍ.',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
              if (_fromDate != null || _toDate != null)
                TextButton.icon(
                  onPressed: () => setState(() {
                    _fromDate = null;
                    _toDate = null;
                  }),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text('مسح'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard() {
    final colors = appColors(context);

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _requiresBooking,
            activeThumbColor: colors.accentColor,
            title: Text(
              'يتطلب حجزاً مسبقاً',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              _requiresBooking
                  ? 'أضف رابط الحجز ليصل إليه الزوار'
                  : 'الدخول بلا حجز مسبق',
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
            onChanged: (value) => setState(() => _requiresBooking = value),
          ),
          const SizedBox(height: 10),
          AppFieldLabel(
            label: _requiresBooking ? 'رابط الحجز' : 'الموقع الإلكتروني',
            required: _requiresBooking,
          ),
          TextFormField(
            controller: _websiteController,
            keyboardType: TextInputType.url,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(
              hintText: 'https://',
              prefixIcon: Icon(Icons.link_rounded),
            ),
            validator: (value) {
              if (!_requiresBooking) return null;
              return value == null || value.trim().isEmpty
                  ? 'أضف رابط الحجز'
                  : null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard() {
    final colors = appColors(context);

    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _isFree,
            activeThumbColor: colors.accentColor,
            title: Text(
              'الدخول مجاني',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              _isFree ? 'لا توجد تذاكر مدفوعة' : 'حدّد سعر التذكرة بالريال',
              style: TextStyle(color: colors.textMuted, fontSize: 12),
            ),
            onChanged: (value) => setState(() => _isFree = value),
          ),
          if (!_isFree) ...[
            const SizedBox(height: 10),
            const AppFieldLabel(label: 'سعر التذكرة (ر.س)', required: true),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                hintText: '50',
                prefixIcon: Icon(Icons.sell_rounded),
              ),
              validator: (value) {
                if (_isFree) return null;
                final price = double.tryParse(value?.trim() ?? '');
                if (price == null || price < 0) return 'أدخل سعراً صحيحاً';
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// شريط يوضّح أن النشر مباشر بلا مراجعة
// ==========================================
class _DirectPublishBanner extends StatelessWidget {
  const _DirectPublishBanner();

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2F9E62).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2F9E62).withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_rounded,
            color: Color(0xFF2F9E62),
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'أنت شريك معتمد — سيُنشر المكان مباشرة دون انتظار المراجعة.',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12.5,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// دعوة للانضمام كشريك (للمستخدم العادي)
// ==========================================
class _BecomePartnerCard extends StatelessWidget {
  const _BecomePartnerCard();

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PartnerScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: colors.inkGradient,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: colors.accentGradient,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.handshake_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'تملك مكاناً أو تنظّم فعاليات؟',
                      style: AppTheme.display(
                        15,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'قدّم على حساب شريك وانشر أماكنك مباشرة.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colors.goldColor,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// حقل اختيار وقت (فتح/إغلاق) بمظهر حقول النموذج
// ==========================================
class _TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final ValueChanged<TimeOfDay> onPick;

  const _TimePickerField({
    required this.label,
    required this.time,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final selected = time;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: selected ?? const TimeOfDay(hour: 9, minute: 0),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.schedule_rounded),
          hintText: label,
        ),
        child: Text(
          selected == null
              ? label
              : '${selected.hour.toString().padLeft(2, '0')}:'
                    '${selected.minute.toString().padLeft(2, '0')}',
          textDirection: TextDirection.ltr,
          style: TextStyle(
            color: selected == null ? colors.textMuted : colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ==========================================
// حقل اختيار تاريخ (بداية/نهاية فترة الإتاحة)
// ==========================================
class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;

  /// أقدم تاريخ يُسمح باختياره؛ يُستخدم لمنع نهاية تسبق البداية.
  final DateTime? firstDate;
  final ValueChanged<DateTime> onPick;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onPick,
    this.firstDate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final selected = date;
    final today = DateTime.now();
    final earliest = firstDate ?? DateTime(today.year - 1);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selected ?? (firstDate ?? today),
          firstDate: earliest,
          lastDate: DateTime(today.year + 5, 12, 31),
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.event_rounded),
          hintText: label,
        ),
        child: Text(
          selected == null
              ? label
              : '${selected.year}/${selected.month.toString().padLeft(2, '0')}'
                    '/${selected.day.toString().padLeft(2, '0')}',
          textDirection: TextDirection.ltr,
          style: TextStyle(
            color: selected == null ? colors.textMuted : colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected ? colors.accentGradient : null,
          color: selected ? null : colors.creamBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? Colors.transparent : colors.borderSoft,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : colors.textPrimary,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
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
