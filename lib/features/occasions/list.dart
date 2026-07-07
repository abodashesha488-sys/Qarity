import 'package:flutter/material.dart';

import '../../models/data_models.dart';
import '../../routes/app_routes.dart';
import '../../services/occasion_service.dart';
import '../../widgets/common_appbar_actions.dart';

class OccasionsListScreen extends StatefulWidget {
  const OccasionsListScreen({super.key});

  @override
  State<OccasionsListScreen> createState() => _OccasionsListScreenState();
}

class _OccasionsListScreenState extends State<OccasionsListScreen> {
  final OccasionService _service = OccasionService();
  List<Occasion> _occasions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOccasions();
  }

  Future<void> _loadOccasions() async {
    try {
      final occasions = await _service.getOccasionsList();
      if (!mounted) return;
      setState(() {
        _occasions = occasions;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await _loadOccasions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('المناسبات'),
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
            : _occasions.isEmpty
                ? _buildEmptyState(theme)
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _occasions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _buildOccasionCard(theme, _occasions[index]),
                  ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          Icon(Icons.card_giftcard_rounded, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('لا توجد مناسبات مسجلة', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildOccasionCard(ThemeData theme, Occasion occasion) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(context, AppRoutes.occasionsDetail, arguments: occasion),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.celebration_rounded, color: theme.colorScheme.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(occasion.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 14, color: theme.colorScheme.primary),
                        const SizedBox(width: 4),
                        Text(occasion.date, style: theme.textTheme.bodySmall),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(occasion.location, style: theme.textTheme.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
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
