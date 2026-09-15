import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/cache_service.dart';
import '../../services/occasion_service.dart';
import '../../widgets/offline_stream_builder.dart';
import '../../widgets/qurity_app_bar.dart';

class OccasionsListScreen extends StatefulWidget {
  const OccasionsListScreen({super.key});

  @override
  State<OccasionsListScreen> createState() => _OccasionsListScreenState();
}

class _OccasionsListScreenState extends State<OccasionsListScreen> {
  final OccasionService _service = OccasionService();
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'الكل';
  String _searchQuery = '';

  static const List<String> _filters = ['الكل', 'القادمة', 'المنتهية'];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() {});
    try {
      await _service.getOccasionsList(forceRefresh: true);
    } catch (_) {}
  }

  Widget _buildOccasionsContent(ThemeData theme, List<Occasion> occasions) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        _buildFilterHeader(theme),
        if (occasions.isEmpty)
          _buildEmpty(theme)
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Column(
              children: [
                for (var i = 0; i < occasions.length; i++)
                  Padding(
                    padding: EdgeInsets.only(bottom: i == occasions.length - 1 ? 0 : 12),
                    child: _buildOccasionCard(theme, occasions[i], i),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  DateTime? _parse(String raw) {
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw.replaceAll('/', '-'));
  }

  List<Occasion> _applyFilters(List<Occasion> all) {
    final today = DateTime.now();
    var list = List<Occasion>.of(all);
    if (_filter == 'القادمة') {
      list = list.where((o) {
        final d = _parse(o.date);
        return d != null && !d.isBefore(today.subtract(const Duration(days: 1)));
      }).toList();
    } else if (_filter == 'المنتهية') {
      list = list.where((o) {
        final d = _parse(o.date);
        return d != null && d.isBefore(today.subtract(const Duration(days: 1)));
      }).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where((o) =>
          o.title.toLowerCase().contains(_searchQuery) ||
          o.location.toLowerCase().contains(_searchQuery) ||
          o.description.toLowerCase().contains(_searchQuery)).toList();
    }
    // القادمة أولاً مرتبة تصاعدياً بالتاريخ، ثم المنتهية الأحدث.
    list.sort((a, b) {
      final da = _parse(a.date);
      final db = _parse(b.date);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return _filter == 'المنتهية' ? db.compareTo(da) : da.compareTo(db);
    });
    return list;
  }

  bool _isSoon(Occasion o) {
    final d = _parse(o.date);
    if (d == null) return false;
    final diff = d.difference(DateTime.now());
    return !diff.isNegative && diff.inDays <= 7;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const QurityAppBar(title: 'مناسبات القرية'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.occasionsAdd),
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة مناسبة', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: OfflineStreamBuilder<List<Occasion>>(
        stream: _service.getOccasionsStream(),
        onlineBuilder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const _OccasionsSkeleton();
          }
          if (snapshot.hasError) {
            return _CenteredStateView(
              child: _ErrorStateView(message: 'تعذر تحميل المناسبات', onRetry: _refresh),
            );
          }
          final occasions = _applyFilters(snapshot.data ?? const []);
          return _buildOccasionsContent(theme, occasions);
        },
        cacheBuilder: (context) => FutureBuilder(
          future: CacheService.getOccasions(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const _OccasionsSkeleton();
            final all = (snapshot.data ?? []).map((j) => Occasion.fromJson(j, 'cache')).toList();
            final occasions = _applyFilters(all);
             return Scaffold(
               body: ColoredBox(
                 color: theme.colorScheme.surface,
                 child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off, size: 16, color: Colors.grey),
                          SizedBox(width: 8),
                          Text('وضع غير متصل', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Expanded(child: _buildOccasionsContent(theme, occasions)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3))),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث عن مناسبة أو مكان...',
              hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6)),
              prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(onPressed: _searchController.clear, icon: const Icon(Icons.clear_rounded))
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _filters.map((f) {
              final selected = f == _filter;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(f),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _filter = f),
                  selectedColor: theme.colorScheme.primary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOccasionCard(ThemeData theme, Occasion occasion, int index) {
    final soon = _isSoon(occasion);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.occasionsDetail, arguments: occasion),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(width: 64, height: 64, child: _thumb(occasion, theme)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(occasion.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                        ),
                        if (soon)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('قريباً',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.event_rounded, size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(occasion.date,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.place_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(occasion.location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                        ),
                      ],
                    ),
                    if (occasion.organizer != null && occasion.organizer!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 13, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(occasion.organizer!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 40).ms).fadeIn(duration: 300.ms).slideY(begin: 0.08);
  }

  Widget _thumb(Occasion occasion, ThemeData theme) {
    final url = occasion.imageUrl ?? '';
    if (url.isEmpty) {
      return DecoratedBox(
        decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5)),
        child: Icon(Icons.celebration_rounded, color: theme.colorScheme.primary),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (c, u) => ColoredBox(color: theme.colorScheme.surfaceContainerHighest),
      errorWidget: (c, u, e) => DecoratedBox(
        decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5)),
        child: Icon(Icons.celebration_rounded, color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.card_giftcard_rounded, size: 48, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(_filter == 'الكل' ? 'لا توجد مناسبات بعد' : 'لا توجد مناسبات في هذا التصنيف',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _OccasionsSkeleton extends StatelessWidget {
  const _OccasionsSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.colorScheme.surfaceContainerHighest;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Shimmer.fromColors(
          baseColor: base,
          highlightColor: theme.colorScheme.surface,
          child: Container(
            height: 88,
            decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(18)),
          ),
        ),
      ),
    );
  }
}

class _CenteredStateView extends StatelessWidget {
  const _CenteredStateView({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: Padding(padding: const EdgeInsets.all(24), child: child)),
        ),
      ),
    );
  }
}

class _ErrorStateView extends StatelessWidget {
  const _ErrorStateView({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.wifi_off_rounded, size: 44, color: theme.colorScheme.error),
        ),
        const SizedBox(height: 20),
        Text(message, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('إعادة المحاولة'),
        ),
      ],
    );
  }
}
