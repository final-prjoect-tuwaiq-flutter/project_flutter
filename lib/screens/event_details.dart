import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_flutter/model/event.dart';
import 'package:project_flutter/model/metro_station.dart';
import 'package:project_flutter/screens/login_page.dart';
import 'package:project_flutter/screens/visited_place_screen.dart';
import 'package:project_flutter/service/favorites_controller.dart';
import 'package:project_flutter/service/metro_controller.dart';
import 'package:project_flutter/theme/theme.dart';
import 'package:project_flutter/widgets/app_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailsScreen extends StatefulWidget {
  final Event event;

  const EventDetailsScreen({super.key, required this.event});

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: colors.creamBackground,
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // المنطقة 1 - معرض الصور
                      _ImageGallerySection(event: widget.event),

                      // لوحة المحتوى تتداخل قليلاً مع الصورة
                      Transform.translate(
                        offset: const Offset(0, -28),
                        child: Container(
                          decoration: BoxDecoration(
                            color: colors.creamBackground,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(32),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(20, 26, 20, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // المنطقة 2 - معلومات أساسية
                              _HeaderInfoSection(event: widget.event),
                              const SizedBox(height: 26),

                              // المنطقة 3 - أوقات العمل والأيام
                              _WorkingHoursSection(event: widget.event),
                              const SizedBox(height: 26),

                              // المنطقة 4 - الوصف الكامل
                              _DescriptionSection(event: widget.event),

                              // المنطقة 5 - الوصول بالمترو
                              _MetroAccessSection(event: widget.event),

                              // المنطقة 6 - مربع الموقع
                              _LocationBoxSection(event: widget.event),

                              const SizedBox(height: 14),
                              _VisitedPlaceButton(event: widget.event),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // المنطقة 7 - زر الحجز (ثابت في الأسفل)
              _BookNowButton(event: widget.event),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// المنطقة 1: معرض الصور
// ==========================================
class _ImageGallerySection extends StatefulWidget {
  final Event event;

  const _ImageGallerySection({required this.event});

  @override
  State<_ImageGallerySection> createState() => _ImageGallerySectionState();
}

class _ImageGallerySectionState extends State<_ImageGallerySection> {
  final FavoritesController _favorites = FavoritesController.instance;

  int _currentIndex = 0;
  bool _isTogglingFavorite = false;
  late final List<String> _images;

  bool get _isFavorite => _favorites.isFavorite(widget.event.id);

  @override
  void initState() {
    super.initState();
    // تجميع الصور المتاحة (الغلاف والمصغرة)
    // الغلاف والمصغّرة قد يحملان الرابط نفسه، فينتج صفحتان متطابقتان
    // ومؤشّر صور لا معنى له.
    _images = <String>{
      if (widget.event.coverImageUrl?.trim().isNotEmpty ?? false)
        widget.event.coverImageUrl!.trim(),
      if (widget.event.thumbnailUrl?.trim().isNotEmpty ?? false)
        widget.event.thumbnailUrl!.trim(),
    }.toList();
    // بلا صور نترك القائمة بعنصر فارغ واحد، فيرسم AppPlaceImage البديل
    // محلياً بدل الاعتماد على خدمة صور خارجية.
    if (_images.isEmpty) _images.add('');
    _favorites.addListener(_onFavoritesChanged);
    _favorites.ensureLoaded();
  }

  @override
  void dispose() {
    _favorites.removeListener(_onFavoritesChanged);
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleFavorite() async {
    setState(() => _isTogglingFavorite = true);

    try {
      await _favorites.toggle(widget.event.id);
    } on NotSignedInException {
      if (!mounted) return;
      _showLoginSnackBar(context, 'يجب تسجيل الدخول للحفظ في المفضلة');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر تحديث المفضلة: $error'),
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isTogglingFavorite = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return SizedBox(
      height: 380,
      width: double.infinity,
      child: Stack(
        children: [
          // PageView للصور
          Positioned.fill(
            child: PageView.builder(
              itemCount: _images.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final image = AppPlaceImage(
                  url: _images[index],
                  decodeWidth: MediaQuery.sizeOf(context).width,
                  fallbackIconSize: 48,
                );

                // صورة الغلاف فقط هي الطرف الثاني للانتقال المشترك مع الكرت.
                if (index != 0) return image;

                return AppHeroImage(
                  tag: AppHeroImage.tagForEvent(widget.event.id),
                  child: SizedBox.expand(child: image),
                );
              },
            ),
          ),

          // تدرّج علوي لوضوح الأزرار وتدرّج سفلي لعمق الصورة
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.35),
                    ],
                    stops: const [0.0, 0.32, 0.65, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // الأزرار العلوية
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    AppCircleButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'رجوع',
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    AppCircleButton(
                      icon: _isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      iconColor: _isFavorite
                          ? const Color(0xFFFF5A76)
                          : Colors.white,
                      tooltip: _isFavorite
                          ? 'إزالة من المفضلة'
                          : 'حفظ في المفضلة',
                      onPressed: _isTogglingFavorite ? null : _toggleFavorite,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // مؤشر الصور
          if (_images.length > 1)
            Positioned(
              bottom: 44,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_images.length, (index) {
                  final active = index == _currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 22 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active
                          ? colors.goldColor
                          : Colors.white.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// ==========================================
// المنطقة 2: المعلومات الأساسية
// ==========================================
class _HeaderInfoSection extends StatelessWidget {
  final Event event;
  const _HeaderInfoSection({required this.event});

  String get _priceText {
    if (event.isFree ?? false) return 'مجاني';
    final min = event.priceMin;
    final max = event.priceMax;
    if (min != null && max != null && max > min) {
      return '${min.toStringAsFixed(0)} – ${max.toStringAsFixed(0)} ر.س';
    }
    // مكان مدفوع بلا سعر مسجّل: عرض «من 0 ر.س» كان يُفهم على أنه مجاني.
    if (min == null) return 'غير محدد';
    return 'من ${min.toStringAsFixed(0)} ر.س';
  }

  @override
  Widget build(BuildContext context) {
    final bool requiresRegistration = event.isRegistrationRequired ?? false;
    final colors = appColors(context);
    final hasCategory = event.sCategory != null && event.sCategory!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasCategory || event.isUnavailable) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (hasCategory)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accentColorSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    event.sCategory!,
                    style: TextStyle(
                      color: colors.accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              // شارة حمراء صريحة: المكان مغلق أو خارج فترة إتاحته.
              if (event.availabilityLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.do_not_disturb_on_rounded,
                        size: 14,
                        color: AppTheme.errorColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        event.availabilityLabel!,
                        style: const TextStyle(
                          color: AppTheme.errorColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        Text(
          event.title ?? 'عنوان المكان غير متوفر',
          style: AppTheme.display(26, color: colors.textPrimary, height: 1.3),
        ),
        if (event.shortDescription != null &&
            event.shortDescription!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            event.shortDescription!,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontSize: 13.5),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _FactTile(
                icon: Icons.confirmation_number_rounded,
                label: 'السعر',
                value: _priceText,
                highlight: event.isFree ?? false,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FactTile(
                icon: requiresRegistration
                    ? Icons.how_to_reg_rounded
                    : Icons.event_available_rounded,
                label: 'الحجز',
                value: requiresRegistration ? 'يتطلب حجز' : 'لا يتطلب حجز',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _FactTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return AppSurfaceCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          AppIconMedallion(
            icon: icon,
            size: 38,
            color: highlight ? colors.accentColorDeep : colors.accentColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// المنطقة 3: أوقات العمل والأيام
// ==========================================
class _WorkingHoursSection extends StatelessWidget {
  final Event event;
  const _WorkingHoursSection({required this.event});

  /// يقسّم "الأيام: الأوقات" إلى صفوف منظّمة.
  List<(String?, String)> _rows(String text) {
    return text.split('\n').where((line) => line.trim().isNotEmpty).map((line) {
      final separator = line.indexOf(': ');
      if (separator == -1) return (null, line.trim());
      return (
        line.substring(0, separator).trim(),
        line.substring(separator + 2).trim(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final workingHours = event.formattedWorkingHoursArabic;
    final dateRange = event.formattedDateRangeArabic;
    final hasClosedDays = event.closedDays?.isNotEmpty == true;
    final rows = workingHours == null
        ? const <(String?, String)>[]
        : _rows(workingHours);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle(title: 'أوقات العمل'),
        const SizedBox(height: 14),
        AppSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              // الإغلاق يتصدّر البطاقة: أوقات عمل مكان مغلق تضلّل الزائر.
              if (event.availabilityNote != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.do_not_disturb_on_rounded,
                        color: AppTheme.errorColor,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          event.availabilityNote!,
                          style: const TextStyle(
                            color: AppTheme.errorColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (dateRange != null) ...[
                if (event.availabilityNote != null)
                  Divider(height: 1, color: colors.borderSoft),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range_rounded,
                        color: colors.accentColor,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'فترة الإتاحة: $dateRange',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: colors.borderSoft),
              ],
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: colors.textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'أوقات العمل غير متوفرة',
                        style: TextStyle(
                          color: colors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) Divider(height: 1, color: colors.borderSoft),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: colors.accentColor,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      if (rows[i].$1 != null) ...[
                        Expanded(
                          child: Text(
                            rows[i].$1!,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Flexible(
                        flex: rows[i].$1 == null ? 1 : 0,
                        child: Text(
                          rows[i].$2,
                          textAlign: rows[i].$1 == null
                              ? TextAlign.start
                              : TextAlign.end,
                          style: TextStyle(
                            color: rows[i].$2 == 'مغلق'
                                ? AppTheme.errorColor
                                : colors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (hasClosedDays) ...[
                Divider(height: 1, color: colors.borderSoft),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.event_busy_rounded,
                              size: 15,
                              color: AppTheme.errorColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              event.formattedClosedDaysArabic!,
                              style: const TextStyle(
                                color: AppTheme.errorColor,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// المنطقة 4: الوصف الكامل
// ==========================================
class _DescriptionSection extends StatelessWidget {
  final Event event;
  const _DescriptionSection({required this.event});

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionTitle(title: 'عن المكان'),
        const SizedBox(height: 12),
        Text(
          event.fullDescription ??
              event.shortDescription ??
              'لا يوجد وصف متاح.',
          style: TextStyle(
            color: colors.textPrimary.withValues(alpha: 0.82),
            fontSize: 14.5,
            height: 1.9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// الوصول بالمترو
// ==========================================
class _MetroAccessSection extends StatefulWidget {
  final Event event;
  const _MetroAccessSection({required this.event});

  @override
  State<_MetroAccessSection> createState() => _MetroAccessSectionState();
}

class _MetroAccessSectionState extends State<_MetroAccessSection> {
  final MetroController _metro = MetroController.instance;

  @override
  void initState() {
    super.initState();
    _metro.addListener(_onMetroChanged);
    _metro.ensureLoaded();
  }

  @override
  void dispose() {
    _metro.removeListener(_onMetroChanged);
    super.dispose();
  }

  void _onMetroChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openStationInMaps(MetroStation station) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${station.lat},${station.lng}'
      '&destination=${widget.event.lat},${widget.event.lng}'
      '&travelmode=walking',
    );

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Unable to launch directions');
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر فتح الاتجاهات من المحطة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final access = _metro.accessForEvent(widget.event);

    // لا نعرض القسم إطلاقاً إن لم تتوفر بيانات المحطات أو إحداثيات المكان.
    if (access == null) return const SizedBox.shrink();

    final colors = appColors(context);
    final isWalkable = access.isWalkable;
    final nearest = access.nearest;

    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionTitle(
            title: 'الوصول بالمترو',
            trailing: _MetroVerdictBadge(isWalkable: isWalkable),
          ),
          const SizedBox(height: 14),
          AppSurfaceCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWalkable
                      ? 'يمكنك الوصول لهذا المكان مشياً من المحطة خلال ${nearest.walkMinutes} دقيقة تقريباً.'
                      : 'أقرب محطة تبعد ${formatDistanceMeters(nearest.distanceMeters)}، وهي خارج نطاق المشي المريح (${kMetroWalkRadiusMeters.round()} م).',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 13,
                    height: 1.7,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 14),
                Divider(height: 1, color: colors.borderSoft),
                const SizedBox(height: 6),

                // المحطات داخل نطاق المشي، وإلا فأقرب محطة كمرجع
                for (final entry
                    in (isWalkable ? access.withinWalk : [nearest]))
                  _MetroStationRow(
                    entry: entry,
                    isNearest: entry == nearest,
                    onTap: () => _openStationInMaps(entry.station),
                  ),

                if (isWalkable && access.withinWalk.length > 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${arabicPlural(access.withinWalk.length, singular: 'محطة', dual: 'محطتين', plural: 'محطات', accusative: 'محطةً', feminine: true)} ضمن ${kMetroWalkRadiusMeters.round()} متر من المكان.',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.directions_walk_rounded,
                size: 14,
                color: colors.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'المسافات محسوبة بخط مستقيم وقد تختلف عن مسار المشي الفعلي.',
                  style: TextStyle(
                    color: colors.textMuted.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// شارة «قريب من المترو» / «بعيد عن المترو» بجانب عنوان القسم.
class _MetroVerdictBadge extends StatelessWidget {
  final bool isWalkable;

  const _MetroVerdictBadge({required this.isWalkable});

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final color = isWalkable ? const Color(0xFF2F9E62) : colors.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isWalkable
                ? Icons.directions_subway_rounded
                : Icons.directions_car_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            isWalkable ? 'قريب من المترو' : 'يفضّل السيارة',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// اسم مسار واحد مع نقطة بلونه. المحطة التبادلية تعرض عدة وسوم في سطر واحد.
class _MetroLineTag extends StatelessWidget {
  final String label;
  final Color color;

  const _MetroLineTag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// صف محطة واحدة: اللون والمسار والمسافة وزمن المشي.
class _MetroStationRow extends StatelessWidget {
  final NearbyStation entry;
  final bool isNearest;
  final VoidCallback onTap;

  const _MetroStationRow({
    required this.entry,
    required this.isNearest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final station = entry.station;
    final lineColors = [
      for (final color in station.serviceLineColors)
        color ?? colors.accentColor,
    ];
    final barColors = lineColors.isEmpty ? [colors.accentColor] : lineColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              // شريط ألوان المسارات: قطعة لكل مسار يخدم المحطة، فتُقرأ
              // المحطة التبادلية من الشريط وحده.
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 4,
                  height: 34,
                  child: Column(
                    children: [
                      for (final color in barColors)
                        Expanded(child: ColoredBox(color: color)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            station.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (isNearest) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.accentColorSoft,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'الأقرب',
                              style: TextStyle(
                                color: colors.accentColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    if (station.serviceLines.isEmpty)
                      Text(
                        station.stationCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          for (var i = 0; i < station.serviceLines.length; i++)
                            _MetroLineTag(
                              label: station.serviceLines[i],
                              color: lineColors[i],
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatDistanceMeters(entry.distanceMeters),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${entry.walkMinutes} د مشياً',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colors.textMuted.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// المنطقة 6: مربع الموقع
// ==========================================
class _LocationBoxSection extends StatelessWidget {
  final Event event;
  const _LocationBoxSection({required this.event});

  Future<void> _launchLocation(BuildContext context) async {
    // بلا إحداثيات لا يوجد رابط صالح؛ البناء بـ "null,null" كان يفتح
    // الخرائط على موقع عشوائي بدل إخبار المستخدم بأن الموقع غير متوفر.
    final hasCoordinates = event.lat != null && event.lng != null;
    final uri = hasCoordinates
        ? Uri.tryParse(
            event.url ??
                'https://www.google.com/maps/search/?api=1'
                    '&query=${event.lat},${event.lng}',
          )
        : null;

    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('موقع المكان غير متوفر حالياً')),
      );
      return;
    }

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Unable to launch location');
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تعذر فتح موقع المكان')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (event.lat == null || event.lng == null) return const SizedBox.shrink();
    final colors = appColors(context);

    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Container(
        decoration: BoxDecoration(
          gradient: colors.inkGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colors.shadowColor.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _launchLocation(context),
              child: Stack(
                children: [
                  PositionedDirectional(
                    top: -50,
                    end: -40,
                    child: AppGlowBlob(color: colors.accentColor, size: 160),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: colors.accentGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.map_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'موقع المكان',
                                style: AppTheme.display(
                                  17,
                                  color: Colors.white,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'اضغط لعرض الموقع على الخريطة',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 26,
                          color: colors.goldColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VisitedPlaceButton extends StatelessWidget {
  final Event event;

  const _VisitedPlaceButton({required this.event});

  Future<void> _openDialog(BuildContext context) async {
    if (Supabase.instance.client.auth.currentUser == null) {
      _showLoginSnackBar(context, 'يجب تسجيل الدخول لحفظ الزيارة');
      return;
    }

    await showDialog<bool>(
      context: context,
      builder: (_) => VisitedPlaceScreen(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return Material(
      color: colors.surfaceColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _openDialog(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.accentColorDeep.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              AppIconMedallion(
                icon: Icons.verified_rounded,
                color: colors.accentColorDeep,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'زرت هذا المكان؟',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'سجّله كمكان مُزار مع ملاحظاتك',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.add_rounded, color: colors.accentColorDeep),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// المنطقة 6: زر الحجز
// ==========================================
class _BookNowButton extends StatelessWidget {
  final Event event;

  const _BookNowButton({required this.event});

  bool get _hasTicketUrl {
    final ticketUri = Uri.tryParse(event.ticketUrl?.trim() ?? '');
    return ticketUri != null && ticketUri.hasScheme && ticketUri.hasAuthority;
  }

  Uri? _getActionUri() {
    final ticketUri = Uri.tryParse(event.ticketUrl?.trim() ?? '');
    if (_hasTicketUrl) {
      return ticketUri;
    }

    if (event.lat == null || event.lng == null) return null;

    final locationUri = Uri.tryParse(
      event.url ??
          'https://www.google.com/maps/search/?api=1&query=${event.lat},${event.lng}',
    );
    if (locationUri != null &&
        locationUri.hasScheme &&
        locationUri.hasAuthority) {
      return locationUri;
    }

    return null;
  }

  Future<void> _launchAction(BuildContext context) async {
    final url = _getActionUri();
    if (url == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رابط الحجز أو موقع المكان غير متوفر حالياً'),
        ),
      );
      return;
    }

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Unable to launch event action');
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر فتح رابط المكان')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final isFree = event.isFree ?? false;
    final hasPrice = event.priceMin != null;
    final hasAction = _getActionUri() != null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        border: Border(top: BorderSide(color: colors.borderSoft)),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFree ? 'الدخول' : (hasPrice ? 'يبدأ من' : 'السعر'),
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  // بلا سعر مسجّل كان يظهر «0 ر.س» فيبدو المكان مجانياً.
                  isFree
                      ? 'مجاني'
                      : (hasPrice
                            ? '${event.priceMin!.toStringAsFixed(0)} ر.س'
                            : 'غير محدد'),
                  style: AppTheme.display(
                    20,
                    color: colors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 18),
            Expanded(
              // المكان المغلق لا يُحجز: الزر يُعطَّل ويعلن الحالة بدل أن
              // يرسل الزائر إلى صفحة حجز لا تعمل.
              child: event.isUnavailable
                  ? AppGradientButton(
                      label: event.availabilityLabel!,
                      icon: Icons.do_not_disturb_on_rounded,
                      onPressed: null,
                    )
                  : AppGradientButton(
                      // زر يفتح حواراً بالخطأ في كل مرة ليس زراً؛ يُعطَّل بعنوان
                      // صريح حين لا يوجد رابط حجز ولا إحداثيات للمكان.
                      label: _hasTicketUrl
                          ? 'احجز الآن'
                          : (hasAction ? 'افتح الموقع' : 'لا يوجد رابط'),
                      icon: _hasTicketUrl
                          ? Icons.arrow_forward_rounded
                          : (hasAction
                                ? Icons.location_on_rounded
                                : Icons.link_off_rounded),
                      onPressed: hasAction
                          ? () => _launchAction(context)
                          : null,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showLoginSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'تسجيل الدخول',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          },
        ),
      ),
    );
  // الرسائل ذات الإجراء لا تختفي تلقائياً، لذا نخفيها يدوياً
  Future<void>.delayed(const Duration(seconds: 3), () {
    if (context.mounted) messenger.hideCurrentSnackBar();
  });
}
