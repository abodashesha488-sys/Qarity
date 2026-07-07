import 'package:flutter/material.dart';

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
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : _obituaries.isEmpty
                ? _buildEmptyState(theme)
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _obituaries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _buildObituaryCard(theme, _obituaries[index]),
                  ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.grade_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('لا توجد تعازي مسجلة', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildObituaryCard(ThemeData theme, Obituary obituary) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, AppRoutes.obituariesDetail, arguments: obituary),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                child: Icon(Icons.person_rounded, size: 28, color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(obituary.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
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
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
