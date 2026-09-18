import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project_flutter/model/event.dart';
import 'package:project_flutter/screens/event_details.dart';
import 'package:project_flutter/screens/login_page.dart';
import 'package:project_flutter/service/supabase_data.dart';
import 'package:project_flutter/theme/theme.dart';
import 'package:project_flutter/widgets/app_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _VisitedItem {
  final dynamic id;
  final Event event;
  final String? notes;
  final DateTime? visitedAt;

  const _VisitedItem({
    required this.id,
    required this.event,
    this.notes,
    this.visitedAt,
  });
}

class VisitedPlacesScreen extends StatefulWidget {
  const VisitedPlacesScreen({super.key});

  @override
  State<VisitedPlacesScreen> createState() => _VisitedPlacesScreenState();
}

class _VisitedPlacesScreenState extends State<VisitedPlacesScreen> {
  late Future<List<_VisitedItem>> _visitedFuture;

  @override
  void initState() {
    super.initState();
    _visitedFuture = _loadVisited();
  }

  Future<List<_VisitedItem>> _loadVisited() async {
    final rows = await SupabaseData().pullForCurrentUser();
    if (rows.isEmpty) return [];

    final placeIds = rows.map((row) => row['place_id'] as int).toSet().toList();

    final response = await Supabase.instance.client
        .from('events3')
        .select()
        .inFilter('id', placeIds);

    final eventsById = {
      for (final json in response) (json['id'] as int): Event.fromJson(json),
    };

    final items = <_VisitedItem>[];
    for (final row in rows) {
      final event = eventsById[row['place_id'] as int];
      if (event == null) continue;
      items.add(
        _VisitedItem(
          id: row['id'],
          event: event,
          notes: row['notes'] as String?,
          visitedAt: row['visited_at'] != null
              ? DateTime.tryParse(row['visited_at'].toString())
              : null,
        ),
      );
    }

    items.sort((a, b) {
      final dateA = a.visitedAt ?? DateTime(0);
      final dateB = b.visitedAt ?? DateTime(0);
      return dateB.compareTo(dateA);
    });

    return items;
  }

  Future<void> _refresh() async {
    setState(() {
      _visitedFuture = _loadVisited();
    });
    await _visitedFuture;
  }

  Future<void> _deleteVisit(_VisitedItem item) async {
    // الحذف نهائي ولا يمكن التراجع عنه، وكان يقع بضغطة واحدة بلا تأكيد.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          icon: const AppIconMedallion(
            icon: Icons.delete_outline_rounded,
            color: AppTheme.errorColor,
            size: 56,
          ),
          title: const Text('حذف الزيارة'),
          content: Text(
            'سيُحذف سجل زيارتك لـ"${item.event.title ?? 'هذا المكان'}" '
            'وملاحظاتك عنها نهائياً.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('حذف'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await SupabaseData().delete(id: item.id);
      if (!mounted) return;
      setState(() {
        _visitedFuture = _visitedFuture.then(
          (items) => items.where((it) => it.id != item.id).toList(),
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تعذر حذف الزيارة')));
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
          body: FutureBuilder<List<_VisitedItem>>(
            future: _visitedFuture,
            builder: (context, snapshot) {
              // القائمة تُبنى ككشّاف (sliver) كسول: لا تُنشأ إلا الكروت الظاهرة.
              Widget bodySliver;
              int? count;
              DateTime? lastVisit;

              Widget boxed(Widget child) => SliverToBoxAdapter(child: child);

              if (snapshot.connectionState == ConnectionState.waiting) {
                bodySliver = boxed(
                  const SizedBox(height: 520, child: AppListSkeleton()),
                );
              } else if (snapshot.hasError) {
                final isUnauthenticated = snapshot.error
                    .toString()
                    .toLowerCase()
                    .contains('authenticated');
                bodySliver = boxed(
                  isUnauthenticated
                      ? AppStatePanel(
                          icon: Icons.lock_outline_rounded,
                          title: 'سجّل الدخول لعرض الأماكن التي زرتها',
                          actionLabel: 'تسجيل الدخول',
                          actionIcon: Icons.login_rounded,
                          onAction: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            );
                          },
                        )
                      : AppStatePanel(
                          icon: Icons.cloud_off_rounded,
                          title: 'تعذر تحميل الأماكن التي زرتها',
                          subtitle: snapshot.error.toString(),
                          actionLabel: 'إعادة المحاولة',
                          actionIcon: Icons.refresh_rounded,
                          onAction: _refresh,
                        ),
                );
              } else {
                final items = snapshot.data ?? [];
                count = items.length;
                lastVisit = items.isEmpty ? null : items.first.visitedAt;
                bodySliver = items.isEmpty
                    ? boxed(
                        const AppStatePanel(
                          icon: Icons.explore_rounded,
                          title: 'لم تسجّل زيارة أي مكان بعد',
                          subtitle: 'بعد زيارتك لمكان، سجّلها من صفحة تفاصيل المكان لتظهر هنا.',
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) => _VisitedCard(
                            key: ValueKey(items[index].id),
                            item: items[index],
                            isLast: index == items.length - 1,
                            onDelete: () => _deleteVisit(items[index]),
                          ),
                        ),
                      );
              }

              return RefreshIndicator(
                color: colors.accentColor,
                onRefresh: _refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: AppPageHeader(
                        title: 'زياراتي',
                        icon: Icons.verified_rounded,
                        subtitle: lastVisit != null
                            ? 'آخر زيارة: ${formatArabicDate(lastVisit)}'
                            : 'سجل الأماكن التي زرتها وملاحظاتك عنها',
                        showBack: true,
                        trailing: count == null || count == 0
                            ? null
                            : _CountPill(count: count),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 22)),
                    bodySliver,
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  final int count;

  const _CountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Text(
        arabicVisitsCount(count),
        style: TextStyle(
          color: colors.goldColor,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// بطاقة زيارة على شكل خط زمني: التاريخ على الجانب والتفاصيل في البطاقة.
class _VisitedCard extends StatelessWidget {
  final _VisitedItem item;
  final bool isLast;
  final VoidCallback onDelete;

  const _VisitedCard({
    super.key,
    required this.item,
    required this.isLast,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final event = item.event;
    final colors = appColors(context);
    final date = item.visitedAt;
    final hasNotes = item.notes != null && item.notes!.trim().isNotEmpty;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // عمود الخط الزمني
          SizedBox(
            width: 54,
            child: Column(
              children: [
                Container(
                  width: 54,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    gradient: date == null ? null : colors.accentGradient,
                    color: date == null ? colors.borderSoft : null,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        date == null ? '—' : '${date.day}',
                        style: AppTheme.display(
                          20,
                          color: date == null ? colors.textMuted : Colors.white,
                          height: 1.1,
                        ),
                      ),
                      if (date != null)
                        Text(
                          kArabicMonths[date.month - 1],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (date != null)
                        Text(
                          '${date.year}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.borderSoft,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // البطاقة
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: AppSurfaceCard(
                padding: EdgeInsets.zero,
                radius: 22,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailsScreen(event: event),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: AppPlaceImage(
                                    url: event.coverImageUrl,
                                    // مصغّرة 64px: فك ترميز الصورة كاملة هنا
                                    // كان يهدر ذاكرة الصور بلا فائدة.
                                    decodeWidth: 64,
                                    fallbackIconSize: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title ?? 'بدون عنوان',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.display(
                                        15.5,
                                        color: colors.textPrimary,
                                        height: 1.35,
                                      ),
                                    ),
                                    if (date != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        'زرته في ${formatArabicDate(date)}',
                                        style: TextStyle(
                                          color: colors.textMuted,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'حذف الزيارة',
                                onPressed: onDelete,
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  color: colors.textMuted,
                                  size: 21,
                                ),
                              ),
                            ],
                          ),
                          if (hasNotes) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                10,
                                12,
                                10,
                              ),
                              decoration: BoxDecoration(
                                color: colors.accentColorDeep.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.format_quote_rounded,
                                    size: 16,
                                    color: colors.accentColorDeep,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.notes!,
                                      style: TextStyle(
                                        color: colors.textPrimary.withValues(
                                          alpha: 0.85,
                                        ),
                                        fontSize: 13,
                                        height: 1.7,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
