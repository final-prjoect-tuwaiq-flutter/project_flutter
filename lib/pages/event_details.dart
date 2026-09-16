import 'package:flutter/material.dart';
import 'package:project_flutter/model/event.dart';
import 'package:project_flutter/theme/theme.dart';
import 'package:project_flutter/widget/status_badge.dart';
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
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 20,
              color: Colors.black,
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
    final statusColors = theme.extension<AppStatusColors>()!;

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
                    event.title ?? 'بدون عنوان',
                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.mCategory ?? 'تصنيف غير محدد',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            StatusBadge(
              text: isFree
                  ? 'مجاني'
                  : 'من ${event.priceMin?.toStringAsFixed(0) ?? 0} ر.س',
              backgroundColor: isFree
                  ? statusColors.freeColorBg
                  : statusColors.priceColorBg,
              textColor: isFree
                  ? statusColors.freeColor
                  : statusColors.priceColor,
            ),
          ],
        ),
        const SizedBox(height: 16),
        StatusBadge(
          text: requiresRegistration ? 'يتطلب حجز' : 'لا يتطلب حجز',
          icon: requiresRegistration
              ? Icons.how_to_reg_rounded
              : Icons.event_available_rounded,
          backgroundColor: statusColors.neutralBadgeColorBg,
          textColor: statusColors.neutralBadgeColor,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.06), // لون من الثيم
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.access_time_filled_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text('أوقات وساعات العمل', style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            event.formattedTimesArabic ?? 'أوقات العمل غير متوفرة',
            style: theme.textTheme.bodyMedium,
          ),
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
        Text('عن الفعالية', style: Theme.of(context).textTheme.titleLarge),
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
    final urlString = event.url;
    if (urlString == null || urlString.isEmpty) return;

    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'لا يمكن فتح الخريطة';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذر فتح الخريطة')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // إذا لم تتوفر الإحداثيات يتم إخفاء المربع بالكامل
    if (event.lat == null || event.lng == null || event.url == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchLocation(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.03), // لون خلفية شفاف متناسق
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.black87,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'موقع الفعالية',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'اضغط لعرض الموقع على الخريطة',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                // السهم يدل على القابلية للضغط
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Colors.grey,
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
// المنطقة 6: زر الحجز
// ==========================================
class _BookNowButton extends StatelessWidget {
  final Event event;

  const _BookNowButton({required this.event});

  Future<void> _launchTicketUrl(BuildContext context) async {
    final urlString = event.ticketUrl;
    if (urlString == null || urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رابط الحجز غير متوفر حالياً')),
      );
      return;
    }

    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'لا يمكن فتح الرابط';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذر فتح رابط الحجز')));
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
            onPressed: () => _launchTicketUrl(context),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'للحجز',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
