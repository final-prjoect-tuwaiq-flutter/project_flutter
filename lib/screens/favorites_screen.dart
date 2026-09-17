import 'package:flutter/material.dart';
import 'package:project_flutter/model/event.dart';
import 'package:project_flutter/screens/categories_screen.dart';
import 'package:project_flutter/screens/account.dart';
import 'package:project_flutter/screens/add_place_screen.dart';
import 'package:project_flutter/service/supabase_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  int _currentIndex = 2;
  late Future<List<Event>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _favoritesFuture = _loadFavorites();
  }

  Future<List<Event>> _loadFavorites() async {
    final favoriteIds = await SupabaseData().fetchFavorites();
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
    });
    await _favoritesFuture;
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9F6),
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: FutureBuilder<List<Event>>(
            future: _favoritesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _FavoritesLoadingView();
              }

              if (snapshot.hasError) {
                return _FavoritesErrorView(
                  onRetry: _refreshFavorites,
                  error: snapshot.error.toString(),
                );
              }

              final events = snapshot.data ?? [];
              if (events.isEmpty) {
                return const _EmptyFavoritesView();
              }

              return RefreshIndicator(
                color: const Color(0xFFFF4B6E),
                onRefresh: _refreshFavorites,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: _FavoritesHeader()),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            EventCard(event: events[index], showPrice: false),
                        childCount: events.length,
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: FloatingBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _handleNavigation,
        ),
      ),
    );
  }
}

class _FavoritesHeader extends StatelessWidget {
  const _FavoritesHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF4B6E),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'المفضلة',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E1E24),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'رجوع',
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF1E1E24),
                  size: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'الأماكن التي اخترتها لك لاحقاً',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 3,
            width: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFF4B6E),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFavoritesView extends StatelessWidget {
  const _EmptyFavoritesView();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: _FavoritesHeader()),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    size: 72,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'لا توجد عناصر في المفضلة بعد',
                    style: TextStyle(
                      color: Color(0xFF1E1E24),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اضغط على القلب لحفظ الأماكن التي تعجبك',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FavoritesLoadingView extends StatelessWidget {
  const _FavoritesLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFFFF4B6E)),
    );
  }
}

class _FavoritesErrorView extends StatelessWidget {
  final Future<void> Function() onRetry;
  final String error;

  const _FavoritesErrorView({required this.onRetry, required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'تعذر تحميل المفضلة',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E24),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
