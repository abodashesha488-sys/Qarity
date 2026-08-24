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
  List<Obituary> _obituaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadObituaries();
  }

  Future<void> _loadObituaries() async {
    try {
      final obituaries = await _service.getObituariesList();
      if (!mounted) return;
      setState(() {
        _obituaries = obituaries;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await _loadObituaries();
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : _obituaries.isEmpty
                ? const EmptyContentState(icon: Icons.grade_rounded, message: 'لا توجد تعازي مسجلة')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _obituaries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _buildObituaryCard(context, _obituaries[index]),
                  ),
      ),
    );
  }

  Widget _buildObituaryCard(BuildContext context, Obituary obituary) {
    final theme = Theme.of(context);
    return InfoListCard(
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        child: Icon(Icons.person_rounded, size: 28, color: theme.colorScheme.onSurfaceVariant),
      ),
      title: obituary.name,
      subtitleBuilder: (context) => [
        Row(
          children: [
            Icon(Icons.cake_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text('العمر: ${obituary.age}', style: theme.textTheme.bodySmall),
          ],
        ),
        Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 14, color: theme.colorScheme.error),
            const SizedBox(width: 4),
            Text(obituary.date, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
          ],
        ),
      ],
      trailing: Icon(Icons.chevron_left_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
      onTap: () => Navigator.pushNamed(context, AppRoutes.obituariesDetail, arguments: obituary),
    );
  }
}
