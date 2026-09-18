import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';
import 'package:project_flutter/screens/event_details.dart';
import 'package:project_flutter/theme/theme.dart';
import 'package:project_flutter/widgets/app_bottom_nav_bar.dart';
import 'package:project_flutter/widgets/app_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:project_flutter/model/category_model.dart';
import 'package:project_flutter/model/event.dart';
import 'package:project_flutter/model/metro_station.dart';
import 'package:project_flutter/screens/login_page.dart';
import 'package:project_flutter/service/favorites_controller.dart';
import 'package:project_flutter/service/location.dart'; // استيراد ملف الموقع
import 'package:project_flutter/service/metro_controller.dart';
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
  Position? _lastPosition; // آخر موقع معروف، لإعادة الترتيب دون قراءة GPS جديدة
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
    FavoritesController.instance.ensureLoaded();
    MetroController.instance.ensureLoaded();
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
  Future<List<Event>> _fetchEvents(int categoryId) async {
    final response = await supabase
        .from('events3') // تم التغيير من events إلى events3
        .select()
        .eq('m_category', categoryId);
    return response.map((json) => Event.fromJson(json)).toList();
  }

  Future<List<Event>> _fetchAllEvents() async {
    final response = await supabase.from('events3').select();
    return response.map((json) => Event.fromJson(json)).toList();
  }

  // ==========================================
  // زر الترتيب: يشغّل الترتيب حسب الأقرب أو يعيد الترتيب الأصلي
  // ==========================================
  Future<void> _toggleSortByNearest() async {
    if (_isLoadingLocation) return;

    // إطفاء الترتيب يُعيد الترتيب الأصلي دون الحاجة لتحديد الموقع من جديد.
    if (_isSortingByNearest) {
      setState(() => _isSortingByNearest = false);
      return;
    }

    // المسافات محسوبة مسبقاً لنفس التصنيف، فالتشغيل فوري.
    if (_distancesCache.isNotEmpty) {
      setState(() => _isSortingByNearest = true);
      return;
    }

    await _sortByNearest();
  }

  // ==========================================
  // دالة تفعيل الترتيب حسب الأقرب
  // ==========================================
  Future<void> _sortByNearest({bool reuseLastPosition = false}) async {
    // منع الاستدعاء المتكرر أثناء التحميل
    if (_isLoadingLocation) return;

    final requestId = ++_sortRequestId;
    setState(() => _isLoadingLocation = true);

    try {
      // 1. جلب الموقع — عند تغيير التصنيف نكتفي بآخر موقع معروف
      // حتى لا نقرأ الـ GPS من جديد مع كل ضغطة تصنيف.
      final position =
          (reuseLastPosition ? _lastPosition : null) ??
          await determinePosition();
      _lastPosition = position;

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
  String _formatDistance(double distanceInKm) =>
      formatDistanceMeters(distanceInKm * 1000);

  // ==========================================
  // إعادة ضبط حالة الترتيب عند تغيير التصنيف
  // ==========================================
  void _resetSortState() {
    _isSortingByNearest = false;
    _distancesCache = {};
  }

  // ==========================================
  // اختيار تصنيف، أو الرجوع للصفحة الرئيسية بتمرير null
  // ==========================================
  void _selectCategory(Category? category) {
    // الترتيب التلقائي يقتصر على صفحة "الكل"؛ أما داخل بقية التصنيفات
    // فلا يعمل الترتيب حسب الأقرب إلا بضغط المستخدم على الزر.
    final shouldResort =
        category == null && (_isSortingByNearest || _isLoadingLocation);

    setState(() {
      _selectedCategoryId = category?.id;
      _selectedCategoryName = category?.name;
      _eventsFuture = category == null
          ? _fetchAllEvents()
          : _fetchEvents(category.id);
      _loadedEvents = null;
      _sortRequestId++;
      _isLoadingLocation = false;
      _resetSortState();
    });

    if (shouldResort) _sortByNearest(reuseLastPosition: true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppCustomColors>()!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Directionality(
        textDirection: TextDirection.rtl,
        // زر الرجوع في الجهاز يُعيد المستخدم للصفحة الرئيسية بدل الخروج
        // من التطبيق ما دام هناك تصنيف مفتوح.
        child: PopScope(
          canPop: _selectedCategoryId == null,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && _selectedCategoryId != null) _selectCategory(null);
          },
          child: Scaffold(
            backgroundColor: colors.creamBackground,
            extendBody: true,
            body: Stack(
              children: [
                CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    // 1. الواجهة الليلية العلوية (الهوية + التصنيفات)
                    SliverToBoxAdapter(child: _buildHero(colors)),

                    // 2. عنوان القسم + زر الترتيب حسب الأقرب
                    SliverToBoxAdapter(child: _buildSectionHeader(colors)),

                    // 3. قسم الأماكن
                    _buildEventsSliver(colors),
                  ],
                ),
                const ChatFabButton(bottomOffset: 118),
              ],
            ),

            // 4. البوتوم ناف بار العائم
            bottomNavigationBar: FloatingBottomNavBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                if (index == 0) {
                  setState(() => _currentIndex = 0);
                  _selectCategory(null);
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
        ),
      ),
    );
  }

  // ==========================================
  // الواجهة الليلية العلوية
  // ==========================================
  Widget _buildHero(AppCustomColors colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: colors.inkGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(38),
          bottomRight: Radius.circular(38),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(38),
          bottomRight: Radius.circular(38),
        ),
        child: Stack(
          children: [
            // وهج ذهبي خفيف يعطي عمقاً للخلفية الليلية
            Positioned(
              top: -90,
              right: -70,
              child: AppGlowBlob(color: colors.accentColor, size: 260),
            ),
            Positioned(
              bottom: -70,
              left: -60,
              child: AppGlowBlob(color: colors.accentColorDeep, size: 220),
            ),

            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBrandRow(colors),
                          const SizedBox(height: 26),
                          _buildHeadline(colors),
                          const SizedBox(height: 10),
                          Text(
                            'وجهات مختارة بعناية، مرتّبة حسب الأقرب إليك.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.62),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildCategoriesStrip(colors),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandRow(AppCustomColors colors) {
    // الشعار نفسه يحمل اسم التطبيق، فيكفي بجانبه سطر التعريف.
    return Row(
      children: [
        const AppBrandMark(size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'دليلك للأماكن والفعاليات',
                style: AppTheme.display(
                  16.5,
                  color: Colors.white,
                  height: 1.2,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'اختيارات موثوقة قريبة منك',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeadline(AppCustomColors colors) {
    final base = AppTheme.display(29, color: Colors.white, height: 1.45);

    return RichText(
      text: TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'اكتشف '),
          TextSpan(
            text: 'أجمل الفعاليات',
            style: base.copyWith(color: colors.goldColor),
          ),
          const TextSpan(text: '\nوالأماكن من حولك'),
        ],
      ),
    );
  }

  // ==========================================
  // شريط التصنيفات الأفقي داخل الواجهة الليلية
  // ==========================================
  Widget _buildCategoriesStrip(AppCustomColors colors) {
    return SizedBox(
      height: 98,
      child: FutureBuilder<List<Category>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _CategoriesStripSkeleton();
          }
          if (snapshot.hasError) {
            return _buildStripMessage('تعذّر تحميل التصنيفات');
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildStripMessage('لا توجد تصنيفات حالياً');
          }

          final categories = snapshot.data!;

          return CategoriesHeaderContainer(
            categories: categories,
            selectedCategoryId: _selectedCategoryId,
            onCategorySelected: _selectCategory,
          );
        },
      ),
    );
  }

  Widget _buildStripMessage(String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  // ==========================================
  // عنوان القسم وزر الترتيب
  // ==========================================
  Widget _buildSectionHeader(AppCustomColors colors) {
    final inCategory = _selectedCategoryId != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
      child: Row(
        children: [
          // داخل تصنيف: سهم يُعيد للصفحة الرئيسية بدل الشريط الذهبي.
          if (inCategory)
            AppCircleButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'رجوع للرئيسية',
              light: true,
              size: 36,
              onPressed: () => _selectCategory(null),
            )
          else
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                gradient: colors.accentGradient,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          const SizedBox(width: 12),
          // العنوان يتمدّد ليبقى زر الترتيب ملاصقاً للزاوية اليسرى دائماً.
          Expanded(
            child: Text(
              _selectedCategoryName ?? 'الأقرب إليك',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.display(21, color: colors.textPrimary),
            ),
          ),
          const SizedBox(width: 10),
          _buildSortToggle(colors),
        ],
      ),
    );
  }

  Widget _buildSortToggle(AppCustomColors colors) {
    // ألوان الزر مقلوبة: المُطفأ يأخذ التدرّج الملوّن، والمفعّل يأخذ السطح الفاتح.
    final filled = !_isSortingByNearest;

    return GestureDetector(
      onTap: _isLoadingLocation ? null : _toggleSortByNearest,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          gradient: filled ? colors.accentGradient : null,
          color: filled ? null : colors.surfaceColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: filled ? Colors.transparent : colors.borderSoft,
          ),
          boxShadow: [
            BoxShadow(
              color: filled
                  ? colors.accentColor.withValues(alpha: 0.32)
                  : colors.shadowColor.withValues(alpha: 0.05),
              blurRadius: filled ? 14 : 8,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoadingLocation)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: filled ? Colors.white : colors.accentColor,
                ),
              )
            else
              Icon(
                Icons.near_me_rounded,
                size: 15,
                color: filled ? Colors.white : colors.accentColor,
              ),
            const SizedBox(width: 7),
            Text(
              'الأقرب',
              style: TextStyle(
                color: filled ? Colors.white : colors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // قائمة الأماكن
  // ==========================================
  Widget _buildEventsSliver(AppCustomColors colors) {
    return FutureBuilder<List<Event>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        if (_isLoadingLocation) {
          return const _EventsSkeletonSliver();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _EventsSkeletonSliver();
        }

        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: _MessagePanel(
              icon: Icons.cloud_off_rounded,
              title: 'تعذّر تحميل الأماكن',
              subtitle: '${snapshot.error}',
            ),
          );
        }

        if (snapshot.hasData) _loadedEvents = snapshot.data!;
        final rawEvents = snapshot.data ?? _loadedEvents ?? [];

        if (rawEvents.isEmpty) {
          return const SliverToBoxAdapter(
            child: _MessagePanel(
              icon: Icons.travel_explore_rounded,
              title: 'لا توجد أماكن مسجلة لهذا التصنيف',
              subtitle: 'جرّب تصنيفاً آخر، أو أضف مكاناً جديداً للدليل.',
            ),
          );
        }

        // تطبيق الترتيب إذا كان مفعلاً
        final sortedEvents = _getSortedEvents(rawEvents);

        // قائمة كسولة: لا يُبنى إلا ما يظهر على الشاشة، والمفاتيح تحافظ على
        // حالة الكروت عند إعادة الترتيب.
        return SliverPadding(
          padding: const EdgeInsets.only(bottom: 140),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final event = sortedEvents[index];
                final distanceKm = _distancesCache[event.id];

                return EventCard(
                  key: ValueKey(event.id),
                  event: event,
                  // تمرير المسافة فقط إذا كانت محسوبة ومفعلة
                  distanceText: (_isSortingByNearest && distanceKm != null)
                      ? _formatDistance(distanceKm)
                      : null,
                );
              },
              childCount: sortedEvents.length,
              findChildIndexCallback: (key) {
                final id = (key as ValueKey<int>).value;
                final index = sortedEvents.indexWhere((e) => e.id == id);
                return index == -1 ? null : index;
              },
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// شريط التصنيفات الأفقي
// ==========================================
class CategoriesHeaderContainer extends StatelessWidget {
  final List<Category> categories;
  final int? selectedCategoryId;

  /// تمرير null يعني العودة للصفحة الرئيسية (كل الأماكن).
  final ValueChanged<Category?> onCategorySelected;

  const CategoriesHeaderContainer({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  static IconData iconForCategory(String name) {
    if (name.contains('ثقاف')) return Icons.account_balance_rounded;
    if (name.contains('ترفيه')) return Icons.local_activity_rounded;
    if (name.contains('رياض')) return Icons.sports_soccer_rounded;
    if (name.contains('مؤتمر')) return Icons.business_center_rounded;
    if (name.contains('تخييم') || name.contains('طبيع')) {
      return Icons.landscape_rounded;
    }
    if (name.contains('مطاعم') || name.contains('مطعم')) {
      return Icons.restaurant_rounded;
    }
    if (name.contains('تسوق') || name.contains('سوق')) {
      return Icons.shopping_bag_rounded;
    }
    if (name.contains('مهرجان')) return Icons.celebration_rounded;
    if (name.contains('معرض') || name.contains('معارض')) {
      return Icons.museum_rounded;
    }
    if (name.contains('عائل') || name.contains('أطفال')) {
      return Icons.family_restroom_rounded;
    }
    return Icons.explore_rounded;
  }

  @override
  Widget build(BuildContext context) {
    // العنصر الأول "الكل" هو طريق العودة للصفحة الرئيسية بعد اختيار تصنيف.
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: categories.length + 1,
      separatorBuilder: (_, _) => const SizedBox(width: 14),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _CategoryChip(
            label: 'الكل',
            icon: Icons.grid_view_rounded,
            isSelected: selectedCategoryId == null,
            onTap: () => onCategorySelected(null),
          );
        }

        final category = categories[index - 1];

        return _CategoryChip(
          label: category.name,
          icon: iconForCategory(category.name),
          isSelected: category.id == selectedCategoryId,
          onTap: () => onCategorySelected(category),
        );
      },
    );
  }
}

// ==========================================
// عنصر واحد داخل شريط التصنيفات
// ==========================================
class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppCustomColors>()!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 74,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOut,
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: isSelected ? colors.accentGradient : null,
                color: isSelected ? null : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.14),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: colors.accentColor.withValues(alpha: 0.45),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.7),
                size: 25,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// نص شارة المترو على الكرت: «العليا · ٤٢٠ م»، أو المسافة وحدها
/// إن كان صف المحطة بلا اسم ولا رمز.
String _metroPillLabel(NearbyStation nearest) {
  final distance = formatDistanceMeters(nearest.distanceMeters);
  final name = nearest.station.displayName;
  return name.isEmpty ? 'المترو $distance' : '$name · $distance';
}

// ==========================================
// كرت المكان
// ==========================================
class EventCard extends StatelessWidget {
  final Event event;
  final String? distanceText;
  final bool showPrice;

  /// يُمرَّر من صفحة المفضلة فقط، حيث يجب أن يختفي الكرت بعد الإزالة.
  /// وإلا يتكفّل الكرت بنفسه بالإضافة/الإزالة عبر [FavoritesController].
  final VoidCallback? onRemoveFavorite;

  const EventCard({
    super.key,
    required this.event,
    this.distanceText,
    this.showPrice = true,
    this.onRemoveFavorite,
  });

  Future<void> _toggleFavorite(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final isNowFavorite = await FavoritesController.instance.toggle(event.id);
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isNowFavorite
                ? 'تمت إضافة المكان إلى المفضلة'
                : 'تمت إزالة المكان من المفضلة',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } on NotSignedInException {
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: const Text('يجب تسجيل الدخول للحفظ في المفضلة'),
          action: SnackBarAction(
            label: 'تسجيل الدخول',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            ),
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('تعذر تحديث المفضلة: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isFree = event.isFree ?? false;
    final theme = Theme.of(context);
    final colors = theme.extension<AppCustomColors>()!;
    final workingHours = event.formattedTimesArabic;

    void _navigateToDetails() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventDetailsScreen(event: event),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _navigateToDetails,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.borderSoft),
            boxShadow: [
              BoxShadow(
                color: colors.shadowColor.withValues(alpha: 0.07),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  // طرف الانتقال المشترك: الصورة تطير من الكرت إلى صفحة التفاصيل.
                  AppHeroImage(
                    tag: AppHeroImage.tagForEvent(event.id),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(27),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.network(
                        event.coverImageUrl ??
                            'https://via.placeholder.com/400x250',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: colors.textPrimary.withValues(alpha: 0.06),
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            color: colors.textPrimary.withValues(alpha: 0.25),
                            size: 38,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // تدرّج داكن أسفل الصورة ليبرز الشارات فوقها
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(27),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                            colors: [
                              colors.inkColor.withValues(alpha: 0.58),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  if (showPrice)
                    PositionedDirectional(
                      top: 12,
                      start: 12,
                      child: _FrostedPill(
                        icon: isFree
                            ? Icons.local_activity_rounded
                            : Icons.sell_rounded,
                        label: isFree ? 'مجاني' : 'مدفوع',
                        background: Colors.white.withValues(alpha: 0.94),
                        foreground: isFree
                            ? colors.accentColorDeep
                            : colors.accentColor,
                      ),
                    ),

                  // زر المفضلة في الزاوية اليمنى العلوية (أو زر الإزالة من المفضلة)
                  PositionedDirectional(
                    top: 12,
                    end: 12,
                    child: ListenableBuilder(
                      listenable: FavoritesController.instance,
                      builder: (context, _) {
                        // في صفحة المفضلة الكرت محفوظ دائماً حتى تتم إزالته.
                        final isFavorited =
                            onRemoveFavorite != null ||
                            FavoritesController.instance.isFavorite(event.id);

                        return Semantics(
                          button: true,
                          label: isFavorited
                              ? 'إزالة من المفضلة'
                              : 'إضافة إلى المفضلة',
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: colors.inkColor.withValues(
                                    alpha: 0.18,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.white.withValues(alpha: 0.94),
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap:
                                    onRemoveFavorite ??
                                    () => _toggleFavorite(context),
                                child: SizedBox(
                                  width: 38,
                                  height: 38,
                                  child: Icon(
                                    isFavorited
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: const Color(0xFFFF4B6E),
                                    size: 19,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // شارات أسفل الصورة: المسافة عنك + قرب المترو
                  PositionedDirectional(
                    bottom: 12,
                    start: 12,
                    end: 12,
                    child: ListenableBuilder(
                      listenable: MetroController.instance,
                      builder: (context, _) {
                        final metro = MetroController.instance.accessForEvent(
                          event,
                        );

                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (distanceText != null)
                              _FrostedPill(
                                icon: Icons.near_me_rounded,
                                label: 'يبعد عنك $distanceText',
                                background: colors.inkColor.withValues(
                                  alpha: 0.55,
                                ),
                                foreground: Colors.white,
                              ),
                            if (metro != null && metro.isWalkable)
                              _FrostedPill(
                                icon: Icons.directions_subway_rounded,
                                label: _metroPillLabel(metro.nearest),
                                background: Colors.white.withValues(
                                  alpha: 0.94,
                                ),
                                foreground:
                                    metro.nearest.station.lineColor ??
                                    colors.accentColorDeep,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title ?? 'بدون عنوان',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.display(18.5, color: colors.textPrimary),
                    ),
                    if (event.shortDescription != null &&
                        event.shortDescription!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        event.shortDescription!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Divider(height: 1, thickness: 1, color: colors.borderSoft),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: workingHours == null
                              ? const SizedBox.shrink()
                              : Row(
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 15,
                                      color: colors.accentColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        workingHours,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EventDetailsScreen(event: event),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              gradient: colors.accentGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.accentColor.withValues(
                                    alpha: 0.34,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'التفاصيل',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
// شارة زجاجية صغيرة تُعرض فوق صورة الكرت
// ==========================================
class _FrostedPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  const _FrostedPill({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: 5),
          // أسماء المحطات قد تطول، فتُقصّ بدل أن تتجاوز عرض الكرت
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoriesStripSkeleton extends StatelessWidget {
  const _CategoriesStripSkeleton();

  @override
  Widget build(BuildContext context) {
    final base = Colors.white.withValues(alpha: 0.09);

    return AppPulse(
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (_, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSkeletonBox(width: 60, height: 60, radius: 22, color: base),
            const SizedBox(height: 9),
            AppSkeletonBox(width: 46, height: 10, radius: 5, color: base),
          ],
        ),
      ),
    );
  }
}

class _EventsSkeletonSliver extends StatelessWidget {
  const _EventsSkeletonSliver();

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, _) => const _EventCardSkeleton(),
        childCount: 3,
      ),
    );
  }
}

class _EventCardSkeleton extends StatelessWidget {
  const _EventCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppCustomColors>()!;
    final base = colors.textPrimary.withValues(alpha: 0.07);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.borderSoft),
      ),
      child: AppPulse(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSkeletonBox(height: 160, radius: 20, color: base),
            const SizedBox(height: 16),
            AppSkeletonBox(width: 180, height: 16, radius: 8, color: base),
            const SizedBox(height: 10),
            AppSkeletonBox(width: 240, height: 11, radius: 6, color: base),
            const SizedBox(height: 18),
            Row(
              children: [
                AppSkeletonBox(width: 110, height: 12, radius: 6, color: base),
                const Spacer(),
                AppSkeletonBox(width: 92, height: 38, radius: 16, color: base),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// لوحة رسالة (خطأ / لا توجد نتائج)
// ==========================================
class _MessagePanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _MessagePanel({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppCustomColors>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(36, 48, 36, 140),
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: colors.accentColorSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: colors.accentColor),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTheme.display(17, color: colors.textPrimary),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(fontSize: 12.5),
            ),
          ],
        ],
      ),
    );
  }
}

// ==========================================
// البوتوم ناف بار العائم (نفس الشريط الموحّد للتطبيق)
// ==========================================
class FloatingBottomNavBar extends AppBottomNavBar {
  const FloatingBottomNavBar({
    super.key,
    required super.currentIndex,
    required super.onTap,
  });
}
