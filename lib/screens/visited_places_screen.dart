import 'package:flutter/material.dart';
import 'package:project_flutter/model/event.dart';
import 'package:project_flutter/screens/event_details.dart';
import 'package:project_flutter/screens/login_page.dart';
import 'package:project_flutter/service/supabase_data.dart';
import 'package:project_flutter/theme/theme.dart';
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

  String _formatDate(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF9F6),
        body: SafeArea(
          child: Column(
            children: [
              _Header(onBack: () => Navigator.maybePop(context)),
              Expanded(
                child: FutureBuilder<List<_VisitedItem>>(
                  future: _visitedFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF17A2A2),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      final isUnauthenticated = snapshot.error
                          .toString()
                          .toLowerCase()
                          .contains('authenticated');
                      if (isUnauthenticated) {
                        return _SignInPrompt();
                      }
                      return _ErrorView(
                        error: snapshot.error.toString(),
                        onRetry: _refresh,
                      );
                    }

                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return const _EmptyVisitedView();
                    }

                    return RefreshIndicator(
                      color: const Color(0xFF17A2A2),
                      onRefresh: _refresh,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _VisitedCard(
                            item: item,
                            formattedDate: item.visitedAt != null
                                ? _formatDate(item.visitedAt!)
                                : null,
                            onDelete: () => _deleteVisit(item),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onBack;

  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFF17A2A2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'الأماكن التي زرتها',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E1E24),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'رجوع',
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_forward_rounded,
              color: Color(0xFF1E1E24),
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitedCard extends StatelessWidget {
  final _VisitedItem item;
  final String? formattedDate;
  final VoidCallback onDelete;

  const _VisitedCard({
    required this.item,
    required this.formattedDate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final event = item.event;
    final theme = Theme.of(context);
    final customColors = theme.extension<AppCustomColors>()!;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventDetailsScreen(event: event)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 72,
                      height: 72,
                      child: Image.network(
                        event.coverImageUrl ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: theme.colorScheme.surface,
                          child: Icon(
                            Icons.broken_image,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium,
                        ),
                        if (formattedDate != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.event_available_rounded,
                                size: 14,
                                color: customColors.accentColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'تمت الزيارة في $formattedDate',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'حذف الزيارة',
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.notes!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF1D1D1D),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyVisitedView extends StatelessWidget {
  const _EmptyVisitedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.explore_off_rounded, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'لم تسجّل زيارة أي مكان بعد',
              style: TextStyle(
                color: Color(0xFF1E1E24),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'بعد زيارتك لمكان، سجّلها من صفحة تفاصيل المكان لتظهر هنا',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'سجّل الدخول لعرض الأماكن التي زرتها',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.baseBlack,
              ),
              child: const Text('تسجيل الدخول'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final Future<void> Function() onRetry;

  const _ErrorView({required this.error, required this.onRetry});

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
              'تعذر تحميل الأماكن التي زرتها',
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
