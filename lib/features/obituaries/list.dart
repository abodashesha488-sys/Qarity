import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/widgets/shared_cards.dart';
import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/obituary_service.dart';
import '../../widgets/common_appbar_actions.dart';

class ObituariesListScreen extends StatefulWidget {
  const ObituariesListScreen({super.key});

  @override
  State<ObituariesListScreen> createState() => _ObituariesListScreenState();
}

class _ObituariesListScreenState extends State<ObituariesListScreen> {
  final ObituaryService _service = ObituaryService();
  late Stream<List<Obituary>> _obituariesStream;

  @override
  void initState() {
    super.initState();
    _obituariesStream = _service.getObituariesStream();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _obituariesStream = _service.getObituariesStream());
    try {
      await _service.getObituariesList();
    } catch (_) {
      // The stream builder surfaces any load failure in the UI.
    }
  }

  List<Obituary> _sorted(List<Obituary> obituaries) {
    final list = List<Obituary>.of(obituaries);
    list.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل العزاء'),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: CommonAppBarActions.actions(context),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.obituariesAdd),
        tooltip: 'إضافة تعزية',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: StreamBuilder<List<Obituary>>(
          stream: _obituariesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const _CenteredStateView(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            if (snapshot.hasError) {
              return _CenteredStateView(
                child: _ErrorStateView(
                  message: 'تعذر تحميل التعازي',
                  onRetry: _refresh,
                ),
              );
            }
            final obituaries = _sorted(snapshot.data ?? const []);
            if (obituaries.isEmpty) {
              return const _CenteredStateView(
                child: EmptyContentState(
                  icon: Icons.grade_rounded,
                  message: 'لا توجد تعازي مسجلة',
                ),
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: obituaries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _buildObituaryCard(context, obituaries[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildObituaryCard(BuildContext context, Obituary obituary) {
    final theme = Theme.of(context);
    final place = obituary.place;
    return InfoListCard(
      leading: _ObituaryThumb(imageUrl: obituary.imageUrl),
      title: obituary.name,
      subtitleBuilder: (context) => [
        Text(
          obituary.name,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        if (obituary.age.isNotEmpty)
          _MetaRow(
            icon: Icons.cake_rounded,
            text: 'العمر: ${obituary.age}',
            iconColor: theme.colorScheme.onSurfaceVariant,
          ),
        if (obituary.date.isNotEmpty)
          _MetaRow(
            icon: Icons.calendar_today_rounded,
            text: obituary.date,
            iconColor: theme.colorScheme.error,
            textColor: theme.colorScheme.error,
          ),
        if (place != null && place.isNotEmpty)
          _MetaRow(
            icon: Icons.location_on_rounded,
            text: place,
            iconColor: theme.colorScheme.onSurfaceVariant,
          ),
      ],
      trailing: Icon(Icons.chevron_left_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
      onTap: () => Navigator.pushNamed(context, AppRoutes.obituariesDetail, arguments: obituary),
    );
  }
}

class _ObituaryThumb extends StatelessWidget {
  const _ObituaryThumb({this.imageUrl});

  final String? imageUrl;

  static const double _size = 56;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallback = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(Icons.person_rounded, size: 28, color: theme.colorScheme.onSurfaceVariant),
    );

    final url = imageUrl;
    if (url == null || url.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: CachedNetworkImage(
        imageUrl: url,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: _size,
          height: _size,
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          child: const Center(
            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
        errorWidget: (context, url, error) => fallback,
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text, this.iconColor, this.textColor});

  final IconData icon;
  final String text;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor ?? theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Keeps loading/empty/error states scrollable so pull-to-refresh keeps working.
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
          child: Center(
            child: Padding(padding: const EdgeInsets.all(24), child: child),
          ),
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
        const SizedBox(height: 8),
        Text(
          'تحقق من اتصالك بالإنترنت ثم أعد المحاولة',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
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
