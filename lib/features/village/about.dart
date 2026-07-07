import 'package:flutter/material.dart';

import '../../widgets/common_appbar_actions.dart';

class VillageScreen extends StatelessWidget {
  const VillageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('عن القرية'),
          centerTitle: true,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Theme.of(context).colorScheme.surface,
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(text: 'عن القرية'),
              Tab(text: 'تاريخ'),
              Tab(text: 'أرشيف'),
              Tab(text: 'منشآت'),
            ],
          ),
          actions: CommonAppBarActions.actions(context),
        ),
        body: const TabBarView(
          children: [
            _AboutTab(),
            _HistoryTab(),
            _ArchiveTab(),
            _InstitutionsTab(),
          ],
        ),
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('عن قرية أبوديشيشة', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
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
              children: [
                _buildInfoRow(theme, 'السكان', '[عدد السكان]'),
                _buildInfoRow(theme, 'المساحة', '[المساحة الكيلومترية المربعية]'),
                _buildInfoRow(theme, 'تأسيس', '[سنة التأسيس]'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'قرية أبوديشيشة هي قرية تقع في محافظة [المحافظة] على طول خط العرض [خط العرض]. تتميز القرية بطبيعتها الجميلة وموقعها الاستراتيجي البليدي.',
          style: TextStyle(height: 1.6, color: theme.colorScheme.onSurface),
        ),
      ],
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value) {
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
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('تاريخ قرية أبوديشيشة', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        _buildHistoryItem(theme, '1900', 'تأسيس القرية كمجتمع نقدي'),
        _buildHistoryItem(theme, '1950', 'بدء بناء المدارس والمستشفيات'),
        _buildHistoryItem(theme, '1980', 'تطوير البنية التحتية'),
        _buildHistoryItem(theme, '2000', 'تأسيس المراكز الصحية'),
        _buildHistoryItem(theme, '2020', 'مشاريع التوثيق الرقمي'),
      ],
    );
  }

  Widget _buildHistoryItem(ThemeData theme, String year, String event) {
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
  const _ArchiveTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('أرشيف القرية', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        _buildArchiveCard(theme, 'الوثائق التاريخية', Icons.picture_as_pdf_rounded),
        _buildArchiveCard(theme, 'صور قديمة', Icons.image_rounded),
        _buildArchiveCard(theme, 'سجلات المواليد', Icons.document_scanner_rounded),
        _buildArchiveCard(theme, 'سجلات الوفيات', Icons.document_scanner_rounded),
      ],
    );
  }

  Widget _buildArchiveCard(ThemeData theme, String title, IconData icon) {
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
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        trailing: Icon(Icons.chevron_left_rounded, color: theme.colorScheme.onSurfaceVariant, size: 18),
      ),
    );
  }
}

class _InstitutionsTab extends StatelessWidget {
  const _InstitutionsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('منشآت القرية', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        _buildInstitution(theme, 'مدرسة الأمل الابتدائية', Icons.school_rounded, 'حي الوسط'),
        _buildInstitution(theme, 'مستشفى القرية المركزي', Icons.local_hospital_rounded, 'وسط القرية'),
        _buildInstitution(theme, 'مسجد الفلاح', Icons.mosque_rounded, 'حي الفلاح'),
        _buildInstitution(theme, 'المركز الثقافي', Icons.theater_comedy_rounded, 'وسط القرية'),
        _buildInstitution(theme, 'الجمعية الزراعية', Icons.agriculture_rounded, 'حي الفلاح'),
      ],
    );
  }

  Widget _buildInstitution(ThemeData theme, String name, IconData icon, String location) {
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
          child: Icon(icon, color: theme.colorScheme.primary, size: 22),
        ),
        title: Text(name, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
        subtitle: Text(location, style: theme.textTheme.bodySmall),
        trailing: Icon(Icons.chevron_left_rounded, color: theme.colorScheme.onSurfaceVariant, size: 18),
      ),
    );
  }
}
