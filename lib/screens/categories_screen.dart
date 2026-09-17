import 'package:flutter/material.dart';
import 'package:project_flutter/screens/event_details.dart';
import 'package:project_flutter/theme/theme.dart';
import 'package:project_flutter/widgets/status_badge.dart';
import 'package:project_flutter/widgets/glass_container.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_flutter/model/category_model.dart';
import 'package:project_flutter/model/event.dart';
import 'package:project_flutter/service/location.dart'; // استيراد ملف الموقع
import 'package:project_flutter/screens/account.dart';
import 'package:project_flutter/screens/add_place_screen.dart';
import 'package:project_flutter/widgets/chat_fab_button.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int _currentIndex = 0;
  int? _selectedCategoryId;
  String? _selectedCategoryName;

  // ==========================================
  // متغيرات ميزة الترتيب حسب الأقرب
  // ==========================================
  bool _isSortingByNearest = false; // هل تم تفعيل الترتيب؟
  bool _isLoadingLocation = false; // هل يجري تحديد الموقع الآن؟
  Map<int, double> _distancesCache = {}; // خزن المسافات لتجنب إعادة الحساب
  int _sortRequestId = 0;

  final supabase = Supabase.instance.client;

  late final Future<List<Category>> _categoriesFuture;
  Future<List<Event>>? _eventsFuture;
  List<Event>? _loadedEvents;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _fetchCategories();
    _eventsFuture = _fetchAllEvents();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sortByNearest();
    });
  }

  // جلب التصنيفات
  Future<List<Category>> _fetchCategories() async {
    final response = await supabase.from('catgories').select();
    return response.map((json) => Category.fromJson(json)).toList();
  }

  // جلب الأماكن بناءً على التصنيف المختار
  // جلب الأماكن بناءً على التصنيف المختار
  Future<List<Event>> _fetchEvents(int categoryId) async {
    final response = await supabase
        .from('events3') // تم التغيير من events إلى events3
        .select()
        .eq('m_category', categoryId); // وتأكد من أنك تفلتر بـ m_category إذا كان هو المستخدم في الجدول الجديد
    return response.map((json) => Event.fromJson(json)).toList();
  }

  Future<List<Event>> _fetchAllEvents() async {
    final response = await supabase.from('events3').select();
    return response.map((json) => Event.fromJson(json)).toList();
  }

  // ==========================================
  // دالة تفعيل الترتيب حسب الأقرب
  // ==========================================
  Future<void> _sortByNearest() async {
    // منع الاستدعاء المتكرر أثناء التحميل
    if (_isLoadingLocation) return;

    final requestId = ++_sortRequestId;
    setState(() => _isLoadingLocation = true);

    try {
      // 1. جلب الموقع
      final position = await determinePosition();

      // 2. جلب الأماكن مباشرة بدل الاعتماد على FutureBuilder
      final events = _selectedCategoryId == null
          ? await _fetchAllEvents()
          : await _fetchEvents(_selectedCategoryId!);

      if (!mounted || requestId != _sortRequestId) return;

      // 3. حساب المسافات وتخزينها في الـ Cache
      final Map<int, double> newDistances = {};
      for (final event in events) {
        if (event.lat != null && event.lng != null) {
          final distInMeters = distance(
            position.latitude,
            position.longitude,
            event.lat!,
            event.lng!,
          );
          newDistances[event.id] = distInMeters / 1000; // تحويل لكيلومتر
        }
      }

      setState(() {
        _distancesCache = newDistances;
        _isSortingByNearest = true;
        _isLoadingLocation = false;
      });
    } catch (e) {
      if (!mounted || requestId != _sortRequestId) return;
      setState(() => _isLoadingLocation = false);

      // عرض الخطأ الحقيقي + رسالة واضحة
      final errorStr = e.toString().toLowerCase();
      String errorMessage;

      if (errorStr.contains('disabled')) {
        errorMessage = 'خدمة الموقع مغلقة. يرجى تفعيلها من الإعدادات.';
      } else if (errorStr.contains('permanently denied')) {
        errorMessage =
            'تم رفض صلاحية الموقع نهائياً. يرجى السماح من إعدادات التطبيق.';
      } else if (errorStr.contains('denied')) {
        errorMessage = 'تم رفض صلاحية الموقع. يرجى السماح بالوصول.';
      } else if (errorStr.contains('timeout') ||
          errorStr.contains('timelimit')) {
        errorMessage = 'انتهت مهلة تحديد الموقع. يرجى المحاولة مرة أخرى.';
      } else {
        // عرض الخطأ الفعلي لمساعدتك في التشخيص
        errorMessage = 'خطأ: ${e.toString()}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5), // مدة أطول لقراءة الخطأ
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // ==========================================
  // دالة ترتيب الأماكن حسب المسافة
  // ==========================================
  List<Event> _getSortedEvents(List<Event> events) {
    if (!_isSortingByNearest || _distancesCache.isEmpty) return events;

    final List<Event> withLocation = [];
    final List<Event> withoutLocation = [];

    for (final event in events) {
      if (_distancesCache.containsKey(event.id)) {
        withLocation.add(event);
      } else {
        withoutLocation.add(event); // الأماكن بدون موقع تُوضع في النهاية
      }
    }

    // ترتيب الأماكن التي لها موقع من الأقرب للأبعد
    withLocation.sort((a, b) {
      final distA = _distancesCache[a.id] ?? double.maxFinite;
      final distB = _distancesCache[b.id] ?? double.maxFinite;
      return distA.compareTo(distB);
    });

    return [...withLocation, ...withoutLocation];
  }

  // ==========================================
  // دالة تنسيق عرض المسافة
  // ==========================================
  // ==========================================
  // دالة تنسيق عرض المسافة (محدثة)
  // ==========================================
  String _formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      // أقل من 1 كم -> تحويل إلى متر
      final meters = (distanceInKm * 1000).toInt();
      return 'يبعد عنك $meters م';
    } else {
      // 1 كم أو أكثر -> رقم عشري واحد
      return 'يبعد عنك ${distanceInKm.toStringAsFixed(1)} كم';
    }
  }

  // ==========================================
  // إعادة ضبط حالة الترتيب عند تغيير التصنيف
  // ==========================================
  void _resetSortState() {
    _isSortingByNearest = false;
    _distancesCache = {};
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9F6),
        extendBody: true,
        body: Stack(
          children: [
            SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  // 1. قسم التصنيفات العلوي
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: FutureBuilder<List<Category>>(
                        future: _categoriesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('حدث خطأ: ${snapshot.error}'),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text('لا توجد تصنيفات حالياً'),
                            );
                          }

                          final categories = snapshot.data!;

                          return CategoriesHeaderContainer(
                            categories: categories,
                            selectedCategoryId: _selectedCategoryId,
                            onCategorySelected: (category) {
                              setState(() {
                                _selectedCategoryId = category.id;
                                _selectedCategoryName = category.name;
                                _eventsFuture = _fetchEvents(category.id);
                                _loadedEvents = null;
                                _sortRequestId++;
                                _isLoadingLocation = false;
                                _resetSortState();
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  // 2. عنوان الأماكن المرتبة حسب القرب
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCategoryName ?? 'الأقرب',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1E24),
                            ),
                          ),
                          if (_selectedCategoryId != null)
                            GestureDetector(
                              onTap: _isLoadingLocation ? null : _sortByNearest,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: _isSortingByNearest
                                      ? const Color(0xFF191D21)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _isSortingByNearest
                                        ? const Color(0xFF191D21)
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  'ترتيب حسب الأقرب',
                                  style: TextStyle(
                                    color: _isSortingByNearest
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // 3. قسم الأماكن
                  FutureBuilder<List<Event>>(
                    future: _eventsFuture,
                    builder: (context, snapshot) {
                      if (_isLoadingLocation) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return SliverToBoxAdapter(
                          child: Center(
                            child: Text('حدث خطأ: ${snapshot.error}'),
                          ),
                        );
                      }

                      if (snapshot.hasData) _loadedEvents = snapshot.data!;
                      final rawEvents = snapshot.data ?? _loadedEvents ?? [];

                      if (rawEvents.isEmpty) {
                        return const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Center(
                              child: Text(
                                'لا توجد أماكن مسجلة لهذا التصنيف',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      // تطبيق الترتيب إذا كان مفعلاً
                      final sortedEvents = _getSortedEvents(rawEvents);

                      return SliverPadding(
                        padding: const EdgeInsets.only(bottom: 110),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final event = sortedEvents[index];
                            final distanceKm = _distancesCache[event.id];

                            return EventCard(
                              event: event,
                              // تمرير المسافة فقط إذا كانت محسوبة ومفعلة
                              distanceText:
                                  (_isSortingByNearest && distanceKm != null)
                                  ? _formatDistance(distanceKm)
                                  : null,
                            );
                          }, childCount: sortedEvents.length),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const ChatFabButton(),
          ],
        ),

        // 4. البوتوم ناف بار العائم
        bottomNavigationBar: FloatingBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 0) {
              setState(() {
                _currentIndex = 0;
                _selectedCategoryId = null;
                _selectedCategoryName = null;
                _eventsFuture = _fetchAllEvents();
                _loadedEvents = null;
                _sortRequestId++;
                _isLoadingLocation = false;
                _resetSortState();
              });
            } else if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AddPlaceScreen()),
              );
            } else if (index == 2) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const AccountScreen()),
              );
            }
          },
        ),
      ),
    );
  }
}

// ==========================================
// ويدجت حاوية التصنيفات (بدون تعديل)
// ==========================================
class CategoriesHeaderContainer extends StatelessWidget {
  final List<Category> categories;
  final int? selectedCategoryId;
  final ValueChanged<Category> onCategorySelected;

  const CategoriesHeaderContainer({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  IconData _getIconForCategory(String name) {
    if (name.contains('ثقاف')) return Icons.account_balance_rounded;
    if (name.contains('ترفيه')) return Icons.local_activity_rounded;
    if (name.contains('رياض')) return Icons.sports_soccer_rounded;
    if (name.contains('مؤتمر')) return Icons.business_center_rounded;
    if (name.contains('تخييم') || name.contains('طبيع'))
      return Icons.landscape_rounded;
    return Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppCustomColors>()!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: customColors.solidDarkOrange.withOpacity(
          0.9,
        ), // الحاوية الأساسية رمادي داكن
        borderRadius: BorderRadius.circular(24),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        spacing: 20,
        runSpacing: 20,
        children: categories.map((category) {
          final isSelected = category.id == selectedCategoryId;

          return GestureDetector(
            onTap: () => onCategorySelected(category),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    // الخلفية برتقالية صلبة إذا كان محدداً، وبدون لون إذا لم يكن
                    color: isSelected
                        ? customColors.accentColor
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      _getIconForCategory(category.name),
                      // الأيقونة سوداء إذا كان محدداً، وإلا بيضاء شفافة
                      color: isSelected ? Colors.white : Colors.white70,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    // النص أسود إذا كان محدداً، وإلا أبيض شفاف
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ==========================================
// كرت المكان (محدث - يستقبل distanceText)
// ==========================================
// ==========================================
// كرت المكان (محدث)
// ==========================================
class EventCard extends StatelessWidget {
  final Event event;
  final String? distanceText;
  final bool showPrice;
  final VoidCallback? onRemoveFavorite;

  const EventCard({
    super.key,
    required this.event,
    this.distanceText,
    this.showPrice = true,
    this.onRemoveFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final bool isFree = event.isFree ?? false;
    final theme = Theme.of(context);
    final customColors = theme.extension<AppCustomColors>()!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      event.coverImageUrl ??
                          'https://via.placeholder.com/400x225',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: theme.colorScheme.surfaceVariant,
                        child: Icon(
                          Icons.broken_image,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                if (onRemoveFavorite != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onRemoveFavorite,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Color(0xFFFF4B6E),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            if (distanceText != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    distanceText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title ?? 'بدون عنوان',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge,
                      ),
                      if (event.shortDescription != null &&
                          event.shortDescription!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.shortDescription!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                if (showPrice) ...[
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusBadge(
                        text: isFree ? 'مجاني' : 'مدفوع',
                        backgroundColor: customColors.accentColorSoft,
                        textColor: customColors.accentColor,
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                ],
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailsScreen(event: event),
                    ),
                  ),
                  child: Container(
                    width: 44,
                    height: 44,
                    // الزر الأسود يعبر عن العمل الرئيسي
                    decoration: BoxDecoration(
                      color: customColors.accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: theme.colorScheme.onPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// البوتوم ناف بار العائم (بدون تعديل)
// ==========================================
class FloatingBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const FloatingBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppCustomColors>()!;

    return Container(
      margin: const EdgeInsets.only(left: 40, right: 40, bottom: 24),
      // استخدمنا GlassContainer هنا
      child: GlassContainer(
        borderRadius: 35.0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(context, 0, Icons.home_rounded, 'الرئيسية'),
            GestureDetector(
              onTap: () => onTap(1),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: customColors.accentColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            _buildNavItem(context, 2, Icons.person_rounded, 'حسابي'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
  ) {
    final isSelected = currentIndex == index;
    final theme = Theme.of(context);
    final customColors = theme.extension<AppCustomColors>()!;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          // خلفية خفيفة برتقالية عند التحديد
          color: isSelected ? customColors.accentColorSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              // لون برتقالي عند الاختيار، وإلا أبيض شفاف للزجاج
              color: isSelected ? customColors.accentColor : Colors.white70,
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: customColors.accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
