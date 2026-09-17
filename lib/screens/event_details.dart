import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_flutter/model/event.dart';
import 'package:project_flutter/screens/login_page.dart';
import 'package:project_flutter/screens/visited_place_screen.dart';
import 'package:project_flutter/service/supabase_data.dart';
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

                              // المنطقة 5 - مربع الموقع
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

              // المنطقة 6 - زر الحجز (ثابت في الأسفل)
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
  int _currentIndex = 0;
  bool _isFavorite = false;
  bool _isCheckingFavorite = true;
  late final List<String> _images;

  @override
  void initState() {
    super.initState();
    // تجميع الصور المتاحة (الغلاف والمصغرة)
    _images = [
      if (widget.event.coverImageUrl != null) widget.event.coverImageUrl!,
      if (widget.event.thumbnailUrl != null) widget.event.thumbnailUrl!,
    ];
    // إذا لم يكن هناك صور، نضع صورة افتراضية
    if (_images.isEmpty) {
      _images.add('https://via.placeholder.com/600x400?text=لا+توجد+صورة');
    }
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    try {
      final favorites = await SupabaseData().fetchFavorites();
      if (!mounted) return;
      setState(() {
        _isFavorite = favorites.contains(widget.event.id);
        _isCheckingFavorite = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCheckingFavorite = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final wasFavorite = _isFavorite;
    setState(() => _isFavorite = !wasFavorite);

    try {
      if (wasFavorite) {
        await SupabaseData().removeFavorite(widget.event.id);
      } else {
        await SupabaseData().addFavorite(widget.event.id);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isFavorite = wasFavorite);
      final isUnauthenticated = error.toString().toLowerCase().contains(
        'logged in',
      );
      if (isUnauthenticated) {
        _showLoginSnackBar(context, 'يجب تسجيل الدخول للحفظ في المفضلة');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تحديث المفضلة: $error'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
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
                return Image.network(
                  _images[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: colors.inkSoft,
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
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
                      icon: Icons.arrow_forward_rounded,
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
                      onPressed: _isCheckingFavorite ? null : _toggleFavorite,
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
    return 'من ${min?.toStringAsFixed(0) ?? 0} ر.س';
  }

  @override
  Widget build(BuildContext context) {
    final bool requiresRegistration = event.isRegistrationRequired ?? false;
    final colors = appColors(context);
    final hasCategory = event.sCategory != null && event.sCategory!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasCategory) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
// المنطقة 5: مربع الموقع
// ==========================================
class _LocationBoxSection extends StatelessWidget {
  final Event event;
  const _LocationBoxSection({required this.event});

  Future<void> _launchLocation(BuildContext context) async {
    final locationUrl =
        event.url ??
        'https://www.google.com/maps/search/?api=1&query=${event.lat},${event.lng}';
    final uri = Uri.tryParse(locationUrl);

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
                          Icons.chevron_left_rounded,
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
                  isFree ? 'الدخول' : 'يبدأ من',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isFree
                      ? 'مجاني'
                      : '${event.priceMin?.toStringAsFixed(0) ?? 0} ر.س',
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
              child: AppGradientButton(
                label: _hasTicketUrl ? 'احجز الآن' : 'افتح الموقع',
                icon: _hasTicketUrl
                    ? Icons.arrow_back_rounded
                    : Icons.location_on_rounded,
                onPressed: () => _launchAction(context),
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
