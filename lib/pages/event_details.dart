import 'package:flutter/material.dart';
import 'package:project_flutter/model/event.dart';
import 'package:url_launcher/url_launcher.dart'; // ستحتاج لإضافة حزمة url_launcher في pubspec.yaml


class EventDetailsScreen extends StatefulWidget {
  final Event event;

  const EventDetailsScreen({
    super.key,
    required this.event,
  });

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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                    
                    // مسافة إضافية في الأسفل لتجنب تغطية الزر السفلي
                    const SizedBox(height: 80), 
                  ],
                ),
              ),
            ),
            
            // المنطقة 5 - زر الحجز (ثابت في الأسفل)
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
                  child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                ),
              );
            },
          ),
        ),

        // تدرج لوني علوي لتحسين وضوح الأزرار
        Positioned(
          top: 0, left: 0, right: 0,
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
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
                ],
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20, color: Colors.black),
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
            child: const Icon(Icons.favorite_border_rounded, size: 20, color: Colors.black),
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
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان والتصنيف (يمين)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title ?? 'بدون عنوان',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1E24),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.mCategory ?? 'تصنيف غير محدد',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // السعر / مجاني (يسار)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isFree ? const Color(0xFF27AE60).withOpacity(0.1) : const Color(0xFFE74C3C).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isFree ? 'مجاني' : 'من ${event.priceMin?.toStringAsFixed(0) ?? 0} ر.س',
                style: TextStyle(
                  color: isFree ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // يتطلب حجز / لا يتطلب حجز
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.04), // رمادي شفاف أنيق
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                requiresRegistration ? Icons.how_to_reg_rounded : Icons.event_available_rounded,
                size: 18,
                color: Colors.black87,
              ),
              const SizedBox(width: 8),
              Text(
                requiresRegistration ? 'يتطلب حجز' : 'لا يتطلب حجز',
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
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
    // نستخدم الـ getter الجاهز في الموديل
    final String timesText = event.formattedTimesArabic ?? 'أوقات العمل غير متوفرة';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5),
                  ],
                ),
                child: const Icon(Icons.access_time_filled_rounded, color: Colors.black87, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'أوقات وساعات العمل',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            timesText,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
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
    // نعتمد الوصف الكامل وإلا الوصف القصير وإلا رسالة افتراضية
    final description = event.fullDescription ?? event.shortDescription ?? 'لا يوجد وصف متاح لهذه الفعالية.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'عن الفعالية',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E1E24),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            height: 1.8,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// المنطقة 5: زر الحجز 
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح رابط الحجز')),
        );
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
            onPressed: () => _launchTicketUrl(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF191D21), // لون أسود داكن مشابه للتصميم
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16), // حواف دائرية أنيقة
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'للحجز',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded, // سهم بجانب النص
                  color: Colors.white,
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