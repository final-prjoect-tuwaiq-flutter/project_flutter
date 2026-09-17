import 'package:flutter/material.dart';
import 'package:project_flutter/model/event.dart';
import 'package:project_flutter/screens/login_page.dart';
import 'package:project_flutter/screens/visited_place_screen.dart';
import 'package:project_flutter/service/supabase_data.dart';
import 'package:project_flutter/theme/theme.dart';
import 'package:project_flutter/widgets/status_badge.dart';
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
    return Directionality(
      textDirection: TextDirection.rtl, // دعم اللغة العربية بشكل افتراضي
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9F6), // لون الخلفية العام
        body: Column(
          children: [
            // المنطقة 1 - معرض الصور
            _ImageGallerySection(event: widget.event),

            // المحتوى القابل للتمرير
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // المنطقة 2 - معلومات أساسية
                    _HeaderInfoSection(event: widget.event),

                    const SizedBox(height: 24),

                    // المنطقة 3 - أوقات العمل والأيام
                    _WorkingHoursSection(event: widget.event),

                    const SizedBox(height: 24),

                    // المنطقة 4 - الوصف الكامل
                    _DescriptionSection(event: widget.event),

                    // ==============================
                    // المنطقة 5 - مربع الموقع (مضاف حديثاً)
                    // ==============================
                    _LocationBoxSection(event: widget.event),

                    const SizedBox(height: 16),
                    _VisitedPlaceButton(event: widget.event),

                    // مسافة إضافية في الأسفل لتجنب تغطية الزر السفلي
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // المنطقة السادسة - زر الحجز (ثابت في الأسفل)
            _BookNowButton(event: widget.event),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// المنطقة 1: معرض الصور (Image Gallery)
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // PageView للصور
        SizedBox(
          height: 320, // ارتفاع المعرض
          width: double.infinity,
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
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.broken_image,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          ),
        ),

        // تدرج لوني علوي لتحسين وضوح الأزرار
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 100,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // زر الرجوع (يمين - بسبب RTL)
        Positioned(
          top: 48,
          right: 20,
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: Colors.black,
              ),
            ),
          ),
        ),

        // زر المفضلة (يسار)
        Positioned(
          top: 48,
          left: 20,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
              ],
            ),
            child: IconButton(
              onPressed: _isCheckingFavorite
                  ? null
                  : () async {
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
                        final isUnauthenticated = error
                            .toString()
                            .toLowerCase()
                            .contains('logged in');
                        if (isUnauthenticated) {
                          final messenger = ScaffoldMessenger.of(context);
                          messenger
                            ..clearSnackBars()
                            ..showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'يجب تسجيل الدخول للحفظ في المفضلة',
                                        maxLines: 2,
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const LoginPage(),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.amberAccent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'تسجيل الدخول الآن',
                                        style: TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                                duration: const Duration(seconds: 3),
                                behavior: SnackBarBehavior.floating,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            );
                          Future<void>.delayed(const Duration(seconds: 3), () {
                            if (mounted) messenger.hideCurrentSnackBar();
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تعذر تحديث المفضلة: $error'),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 20, height: 20),
              icon: Icon(
                _isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 20,
                color: Colors.black,
              ),
            ),
          ),
        ),

        // مؤشر عدد الصور (يسار أسفل الصورة)
        if (_images.length > 1)
          Positioned(
            bottom: 16,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentIndex + 1}/${_images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ==========================================
// المنطقة 2: المعلومات الأساسية
// ==========================================
class _HeaderInfoSection extends StatelessWidget {
  final Event event;
  const _HeaderInfoSection({required this.event});

  @override
  Widget build(BuildContext context) {
    final bool isFree = event.isFree ?? false;
    final bool requiresRegistration = event.isRegistrationRequired ?? false;
    final theme = Theme.of(context);
    final customColors = theme.extension<AppCustomColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title ?? 'عنوان المكان غير متوفر',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.sCategory ?? 'تصنيف غير محدد',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: customColors.accentColor,
                    ),
                  ),
                ],
              ),
              // ... نفس النص السابق للعنوان والتصنيف ...
            ),
            const SizedBox(width: 16),
            StatusBadge(
              text: isFree
                  ? 'مجاني'
                  : 'من ${event.priceMin?.toStringAsFixed(0) ?? 0} ر.س',
              backgroundColor: customColors.accentColorSoft,
              textColor: customColors.accentColor, // البرتقالي الفاتح الزجاجي
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: customColors.accentColorSoft, // برتقالي داكن وصلب
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                requiresRegistration
                    ? Icons.how_to_reg_rounded
                    : Icons.event_available_rounded,
                size: 16,
                color: Colors.black,
              ),
              const SizedBox(width: 6),
              Text(
                requiresRegistration ? 'يتطلب حجز' : 'لا يتطلب حجز',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ), // نص أسود عريض
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==========================================
// المنطقة 3: أوقات العمل والأيام
// ==========================================
class _WorkingHoursSection extends StatelessWidget {
  final Event event;
  const _WorkingHoursSection({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppCustomColors>()!;

    final String workingHoursText =
        event.formattedWorkingHoursArabic ?? 'أوقات العمل غير متوفرة';
    final hasClosedDays = event.closedDays?.isNotEmpty == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // الخلفية برتقالية شفافة كما طلبت
        color: customColors.solidDarkOrange.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // الأيقونة برتقالية
              Icon(
                Icons.access_time_filled_rounded,
                color: customColors.accentColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'أوقات وساعات العمل',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // جميع النصوص باللون الأسود
          Text(
            workingHoursText,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (hasClosedDays) ...[
            const SizedBox(height: 8),
            Text(
              event.formattedClosedDaysArabic!,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(), // سيأخذ الستايل تلقائياً من الثيم
        Text('عن المكان', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(
          event.fullDescription ??
              event.shortDescription ??
              'لا يوجد وصف متاح.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

// ==========================================
// المنطقة 5: مربع الموقع (Location Box)
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

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black, // أسود صلب تماماً (No Glass)
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: () => _launchLocation(context),
          borderRadius: BorderRadius.circular(20),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 28,
                ), // أيقونة بيضاء
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'موقع المكان',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'اضغط لعرض الموقع على الخريطة',
                        style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.white54,
                ),
              ],
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
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Expanded(
                  child: Text(
                    'يجب تسجيل الدخول لحفظ الزيارة',
                    maxLines: 2,
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.amberAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'تسجيل الدخول الآن',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );
      Future<void>.delayed(const Duration(seconds: 3), () {
        if (context.mounted) messenger.hideCurrentSnackBar();
      });
      return;
    }

    await showDialog<bool>(
      context: context,
      builder: (_) => VisitedPlaceScreen(event: event),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _openDialog(context),
        icon: const Icon(Icons.check_circle_outline_rounded),
        label: const Text('سجلت زيارة هذا المكان'),
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
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            // تم مسح الألوان اليدوية من هنا ليعتمد على الثيم!
            onPressed: () => _launchAction(context),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _hasTicketUrl ? 'للحجز' : 'الموقع',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _hasTicketUrl
                      ? Icons.arrow_forward_rounded
                      : Icons.location_on_rounded,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
