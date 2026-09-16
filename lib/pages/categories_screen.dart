import 'package:flutter/material.dart';
import 'package:project_flutter/model/catagory_model.dart';
import 'package:project_flutter/model/event.dart';
import 'package:project_flutter/pages/event_details.dart';
import 'package:project_flutter/screens/account.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});
  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}
class _CategoriesScreenState extends State<CategoriesScreen> {
  int _currentIndex = 0;
  int? _selectedCategoryId; // التصنيف المختار (يبدأ كـ null)
  String? _selectedCategoryName;
  final supabase = Supabase.instance.client;
  // جلب التصنيفات
  Future<List<Category>> _fetchCategories() async {
    final response = await supabase.from('catgories').select(); // تأكد من اسم الجدول
    return response.map((json) => Category.fromJson(json)).toList();
  }
  // جلب الفعاليات بناءً على التصنيف المختار فقط
  Future<List<Event>> _fetchEvents(int categoryId) async {
    final response = await supabase
        .from('events') // تأكد من اسم الجدول
        .select()
        .eq('s_category', categoryId);
    return response.map((json) => Event.fromJson(json)).toList();
  }
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // دعم اللغة العربية RTL
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9F6),
        extendBody: true, // لجعل النافبار عائماً
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              // 1. قسم التصنيفات العلوي
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: FutureBuilder<List<Category>>(
                    future: _fetchCategories(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('لا توجد تصنيفات حالياً'));
                      }
                      final categories = snapshot.data!;
                      return CategoriesHeaderContainer(
                        categories: categories,
                        selectedCategoryId: _selectedCategoryId,
                        onCategorySelected: (category) {
                          setState(() {
                            _selectedCategoryId = category.id;
                            _selectedCategoryName = category.name;
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
              // 2. عنوان القسم في حال اختيار تصنيف
              if (_selectedCategoryName != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Text(
                      'فعاليات: $_selectedCategoryName',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E24),
                      ),
                    ),
                  ),
                ),
              // 3. قسم الفعاليات (لا يُعرض إلا عند اختيار تصنيف)
              if (_selectedCategoryId == null)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_outlined, size: 55, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'الرجاء اختيار تصنيف من الأعلى\nلعرض الفعاليات الخاصة به',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 80),
                      ],
                    ),
                  ),
                )
              else
                FutureBuilder<List<Event>>(
                  future: _fetchEvents(_selectedCategoryId!),
                  builder: (context, snapshot) {
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
                        child: Center(child: Text('حدث خطأ أثناء جلب الفعاليات: ${snapshot.error}')),
                      );
                    }
                    final events = snapshot.data ?? [];
                    if (events.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Center(
                            child: Text(
                              'لا توجد فعاليات مسجلة لهذا التصنيف',
                              style: TextStyle(fontSize: 15, color: Colors.grey),
                            ),
                          ),
                        ),
                      );
                    }
                    // عرض قائمة كروت الفعاليات
                    return SliverPadding(
                      padding: const EdgeInsets.only(bottom: 110),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return EventCard(event: events[index]);
                          },
                          childCount: events.length,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        // 4. البوتوم ناف بار العائم
        bottomNavigationBar: FloatingBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            if (index == 3) {
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
// 1. ويدجت حاوية التصنيفات العلوية
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
    if (name.contains('تخييم') || name.contains('طبيع')) return Icons.landscape_rounded;
    return Icons.category_rounded;
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.08),
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
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFF4B6E) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isSelected ? 0.2 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getIconForCategory(category.name),
                    color: isSelected ? Colors.white : Colors.black87,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? const Color(0xFFFF4B6E) : Colors.black87,
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
// 2. كرت الفعالية (Event Card المطابق للتصميم)
// ==========================================
class EventCard extends StatelessWidget {
  final Event event;
  final bool showPrice;

  const EventCard({
    super.key,
    required this.event,
    this.showPrice = true,
  });
  @override
  Widget build(BuildContext context) {
    final bool isFree = event.isFree ?? false;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // صورة الغلاف بحواف دائرية
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  event.coverImageUrl ?? 'https://via.placeholder.com/400x225',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey, size: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // البيانات تحت الصورة: العنوان، السعر/مجاني، زر السهم الدائري
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // جهة العنوان والوصف
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title ?? 'بدون عنوان',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E1E24),
                        ),
                      ),
                      if (event.shortDescription != null && event.shortDescription!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          event.shortDescription!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showPrice) ...[
                  const SizedBox(width: 8),
                  // جهة السعر / مجاني
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isFree) ...[
                        Text(
                          'من',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${event.priceMin?.toStringAsFixed(0) ?? 0} ر.س',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFD35400),
                          ),
                        ),
                      ] else ...[
                        const Text(
                          'مجاني',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF27AE60),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(width: 12),
                ],
                // زر السهم الدائري الأسود للانتقال لصفحة التفاصيل
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventDetailsScreen(event: event),
                      ),
                    );
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF191D21),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
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
// 3. البوتوم ناف بار العائم
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
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem(0, Icons.home_rounded, 'الرئيسية'),
          _buildNavItem(1, Icons.explore_rounded, 'استكشف'),
          _buildNavItem(2, Icons.calendar_today_rounded, 'الفعاليات'),
          _buildNavItem(3, Icons.person_rounded, 'حسابي'),
        ],
      ),
    );
  }
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF4B6E) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black54,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}