import 'package:flutter/material.dart';

import '../../models/data_models.dart';
import '../../services/cache_service.dart';
import '../../services/village_info_service.dart';
import '../../widgets/offline_stream_builder.dart';
import '../../widgets/qurity_app_bar.dart';

class VillageScreen extends StatefulWidget {
  const VillageScreen({super.key});

  @override
  State<VillageScreen> createState() => _VillageScreenState();
}

class _VillageScreenState extends State<VillageScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final VillageInfoService _service = VillageInfoService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _service.seedIfEmpty().catchError((_) {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QurityAppBar(
        title: 'عن القرية',
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          tabs: const [
            Tab(text: 'عن القرية'),
            Tab(text: 'تاريخ'),
            Tab(text: 'أرشيف'),
            Tab(text: 'منشآت'),
          ],
        ),
      ),
      body: OfflineStreamBuilder<VillageInfo?>(
        stream: _service.getInfoStream(),
        onlineBuilder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          final info = snapshot.data;
          return TabBarView(
            controller: _tabController,
            children: [
              _AboutTab(info: info),
              _HistoryTab(history: info?.history ?? []),
              _ArchiveTab(archive: info?.archive ?? []),
              _InstitutionsTab(institutions: info?.institutions ?? []),
            ],
          );
        },
        cacheBuilder: (context) => FutureBuilder(
          future: CacheService.getVillageInfo(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2));
            final json = snapshot.data;
            final info = json != null ? VillageInfo.fromJson(json, 'main') : null;
             return Scaffold(
               body: ColoredBox(
                 color: Theme.of(context).colorScheme.surface,
                 child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.3),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off, size: 16, color: Colors.grey),
                          SizedBox(width: 8),
                          Text('وضع غير متصل', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Expanded(child: TabBarView(
                      controller: _tabController,
                      children: [
                        _AboutTab(info: info),
                        _HistoryTab(history: info?.history ?? []),
                        _ArchiveTab(archive: info?.archive ?? []),
                        _InstitutionsTab(institutions: info?.institutions ?? []),
                      ],
                    )),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  final VillageInfo? info;
  const _AboutTab({this.info});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = [
      ('السكان', info?.population ?? '—'),
      ('المساحة', info?.area ?? '—'),
      ('تأسيس', info?.founded ?? '—'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(info?.name ?? 'قرية أبوديشيشة', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rows.map((r) => _InfoRow(theme: theme, label: r.$1, value: r.$2)).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          info?.description ?? '',
          style: TextStyle(height: 1.6, color: theme.colorScheme.onSurface),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final String value;
  const _InfoRow({required this.theme, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.info_rounded, size: 16, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Text('$label: ', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  const _HistoryTab({this.history = const []});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (history.isEmpty) return _EmptyState(theme: theme, icon: Icons.history_rounded, message: 'لا يوجد سجل تاريخي');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('تاريخ قرية أبوديشيشة', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        ...history.map((item) => _HistoryItem(
              theme: theme,
              year: item['year']?.toString() ?? '',
              event: item['event']?.toString() ?? '',
            )),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final ThemeData theme;
  final String year;
  final String event;
  const _HistoryItem({required this.theme, required this.year, required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(year, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: theme.colorScheme.primary)),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(event, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}

class _ArchiveTab extends StatelessWidget {
  final List<String> archive;
  const _ArchiveTab({this.archive = const []});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (archive.isEmpty) return _EmptyState(theme: theme, icon: Icons.archive_rounded, message: 'لا يوجد أرشيف');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('أرشيف القرية', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        ...archive.map((title) => _ArchiveCard(theme: theme, title: title)),
      ],
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  final ThemeData theme;
  final String title;
  const _ArchiveCard({required this.theme, required this.title});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.picture_as_pdf_rounded, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        trailing: Icon(Icons.chevron_left_rounded, color: theme.colorScheme.onSurfaceVariant, size: 18),
      ),
    );
  }
}

class _InstitutionsTab extends StatelessWidget {
  final List<Map<String, dynamic>> institutions;
  const _InstitutionsTab({this.institutions = const []});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (institutions.isEmpty) return _EmptyState(theme: theme, icon: Icons.account_balance_rounded, message: 'لا توجد منشآت مسجلة');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('منشآت القرية', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        ...institutions.map((item) => _InstitutionCard(
              theme: theme,
              name: item['name']?.toString() ?? '',
              location: item['location']?.toString() ?? '',
            )),
      ],
    );
  }
}

class _InstitutionCard extends StatelessWidget {
  final ThemeData theme;
  final String name;
  final String location;
  const _InstitutionCard({required this.theme, required this.name, required this.location});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.location_city_rounded, color: theme.colorScheme.primary, size: 22),
        ),
        title: Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        subtitle: location.isNotEmpty ? Text(location, style: theme.textTheme.bodySmall) : null,
        trailing: Icon(Icons.chevron_left_rounded, color: theme.colorScheme.onSurfaceVariant, size: 18),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ThemeData theme;
  final IconData icon;
  final String message;
  const _EmptyState({required this.theme, required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
