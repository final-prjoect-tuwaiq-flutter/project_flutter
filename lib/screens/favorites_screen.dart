import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_flutter/model/event.dart';
import 'package:project_flutter/screens/categories_screen.dart' show EventCard;
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
    final messenger = ScaffoldMessenger.of(context);

    try {
      // الكنترولر يزيلها تفاؤلياً ويتراجع عند الفشل، والقائمة تُرشَّح منه،
      // فلا حاجة لنسخة محلية ثانية كانت تتعارض معه.
      await FavoritesController.instance.remove(event.id);
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('تعذر إزالة المكان من المفضلة')),
        );
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('تمت إزالة المكان من المفضلة')),
      );
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
              ListenableBuilder(
                listenable: FavoritesController.instance,
                builder: (context, _) => FutureBuilder<List<Event>>(
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
                    // ترشيح بحالة الكنترولر: إزالة مكان من صفحة تفاصيله كانت
                    // تترك بطاقته معروضة هنا حتى إعادة التحميل.
                    final events = _events!
                        .where(
                          (e) => FavoritesController.instance.isFavorite(e.id),
                        )
                        .toList();
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
                          const SliverToBoxAdapter(child: SizedBox(height: 40)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const ChatFabButton(bottomOffset: 26),
            ],
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
      padding: const EdgeInsets.only(bottom: 40),
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
