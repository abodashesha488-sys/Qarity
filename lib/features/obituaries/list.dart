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
      body: StreamBuilder<List<Obituary>>(
        stream: _service.getObituariesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('تعذر تحميل التعازي'));
          }
          final obituaries = snapshot.data ?? [];
          if (obituaries.isEmpty) {
            return const EmptyContentState(icon: Icons.grade_rounded, message: 'لا توجد تعازي مسجلة');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: obituaries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _buildObituaryCard(context, obituaries[index]),
          );
        },
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
