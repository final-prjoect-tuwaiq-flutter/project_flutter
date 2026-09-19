import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_flutter/model/event.dart';
import 'package:project_flutter/screens/categories_screen.dart';
import 'package:project_flutter/screens/account.dart';
import 'package:project_flutter/screens/add_place_screen.dart';
import 'package:project_flutter/service/favorites_controller.dart';
import 'package:project_flutter/widgets/app_ui.dart';
import 'package:project_flutter/widgets/chat_fab_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  int _currentIndex = 2;
  late Future<List<Event>> _favoritesFuture;
  List<Event>? _events;

  @override
  void initState() {
    super.initState();
    _favoritesFuture = _loadFavorites();
  }

  Future<List<Event>> _loadFavorites() async {
    await FavoritesController.instance.refresh();
    final favoriteIds = FavoritesController.instance.ids.toList();
    if (favoriteIds.isEmpty) return [];

    final response = await Supabase.instance.client
        .from('events3')
        .select()
        .inFilter('id', favoriteIds);

    return response.map<Event>((json) => Event.fromJson(json)).toList();
  }

  Future<void> _refreshFavorites() async {
    setState(() {
      _favoritesFuture = _loadFavorites();
      _events = null;
    });
    await _favoritesFuture;
  }

  Future<void> _removeFavorite(Event event) async {
    final previousEvents = _events;
    setState(() {
      _events = (_events ?? []).where((e) => e.id != event.id).toList();
    });

    try {
      await FavoritesController.instance.remove(event.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _events = previousEvents;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر إزالة المكان من المفضلة')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تمت إزالة المكان من المفضلة')),
    );
  }

  void _handleNavigation(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CategoriesScreen()),
      );
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
          body: Stack(
            children: [
              FutureBuilder<List<Event>>(
                future: _favoritesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _FavoritesLayout(
                      count: null,
                      child: SizedBox(height: 520, child: AppListSkeleton()),
                    );
                  }

                  if (snapshot.hasError) {
                    return _FavoritesLayout(
                      count: null,
                      child: AppStatePanel(
                        icon: Icons.cloud_off_rounded,
                        title: 'تعذر تحميل المفضلة',
                        subtitle: snapshot.error.toString(),
                        actionLabel: 'إعادة المحاولة',
                        actionIcon: Icons.refresh_rounded,
                        onAction: _refreshFavorites,
                      ),
                    );
                  }

                  _events ??= snapshot.data ?? [];
                  final events = _events!;
                  if (events.isEmpty) {
                    return const _FavoritesLayout(
                      count: 0,
                      child: AppStatePanel(
                        icon: Icons.favorite_border_rounded,
                        title: 'لا توجد عناصر في المفضلة بعد',
                        subtitle: 'اضغط على القلب في صفحة أي مكان لحفظه هنا والرجوع إليه لاحقاً.',
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: colors.accentColor,
                    onRefresh: _refreshFavorites,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: _FavoritesHeader(count: events.length),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 10)),
                        SliverList.builder(
                          itemCount: events.length,
                          itemBuilder: (context, index) => EventCard(
                            key: ValueKey(events[index].id),
                            event: events[index],
                            showPrice: false,
                            onRemoveFavorite: () =>
                                _removeFavorite(events[index]),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 140)),
                      ],
                    ),
                  );
                },
              ),
              const ChatFabButton(),
            ],
          ),
          bottomNavigationBar: FloatingBottomNavBar(
            currentIndex: _currentIndex,
            onTap: _handleNavigation,
          ),
        ),
      ),
    );
  }
}

class _FavoritesLayout extends StatelessWidget {
  final int? count;
  final Widget child;

  const _FavoritesLayout({required this.count, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 140),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _FavoritesHeader(count: count),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _FavoritesHeader extends StatelessWidget {
  final int? count;

  const _FavoritesHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return AppPageHeader(
      title: 'المفضلة',
      icon: Icons.favorite_rounded,
      subtitle: 'أماكنك المحفوظة في مكان واحد',
      showBack: true,
      trailing: count == null || count == 0
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Text(
                arabicPlacesCount(count!),
                style: TextStyle(
                  color: colors.goldColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
    );
  }
}
