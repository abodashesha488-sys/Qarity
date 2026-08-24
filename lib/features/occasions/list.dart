import 'package:flutter/material.dart';

import '../../core/widgets/shared_cards.dart';
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.occasionsAdd),
        tooltip: 'إضافة مناسبة',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
            : _occasions.isEmpty
                ? const EmptyContentState(icon: Icons.card_giftcard_rounded, message: 'لا توجد مناسبات مسجلة')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _occasions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _buildOccasionCard(context, _occasions[index]),
                  ),
      ),
    );
  }

  Widget _buildOccasionCard(BuildContext context, Occasion occasion) {
    final theme = Theme.of(context);
    return InfoListCard(
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.celebration_rounded, color: theme.colorScheme.primary, size: 26),
      ),
      title: occasion.title,
      subtitleBuilder: (context) => [
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
      trailing: Icon(Icons.chevron_left_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
      onTap: () => Navigator.pushNamed(context, AppRoutes.occasionsDetail, arguments: occasion),
    );
  }
}
