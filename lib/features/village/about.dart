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
          bottom: const TabBar(
            tabs: [
              Tab(text: 'عن القرية'),
              Tab(text: 'تاريخ'),
              Tab(text: 'أرشيف'),
              Tab(text: 'منشآت'),
            ],
          ),
          actions: CommonAppBarActions.actions(context),
        ),
        body: TabBarView(
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
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'عن قرية أبوديشيشة',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        const Text(
          'قرية أبوديشيشة هي قرية تقع في محافظة [المحافظة] على طول خط العرض [خط العرض]. تتميز القرية بطبيعتها الجميلة وموقعها الاستراتيجي البليدي.',
          style: TextStyle(height: 1.6),
        ),
        const SizedBox(height: 20),
        const Text(
          'السكان: [عدد السكان]',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const Text('المساحة: [المساحة الكيلومترية المربعية]'),
        const Text('تأسيس: [سنة التأسيس]'),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'تاريخ قرية أبوديشيشة',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        _buildHistoryItem('1900', 'تأسيس القرية كمجتمع نقدي'),
        _buildHistoryItem('1950', 'بدء بناء المدارس والمستشفيات'),
        _buildHistoryItem('1980', 'تطوير البنية التحتية'),
        _buildHistoryItem('2000', 'تأسيس المراكز الصحية'),
        _buildHistoryItem('2020', 'مشاريع التوثيق الرقمي'),
      ],
    );
  }

  Widget _buildHistoryItem(String year, String event) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  year,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(event)),
          ],
        ),
      ),
    );
  }
}

class _ArchiveTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('أرشيف القرية', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        const ListTile(
          title: Text('الوثائق التاريخية'),
          trailing: Icon(Icons.picture_as_pdf),
        ),
        const ListTile(title: Text('صور قديمة'), trailing: Icon(Icons.image)),
        const ListTile(
          title: Text('سجلات المواليد'),
          trailing: Icon(Icons.document_scanner),
        ),
        const ListTile(
          title: Text('سجلات الوفيات'),
          trailing: Icon(Icons.document_scanner),
        ),
      ],
    );
  }
}

class _InstitutionsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('منشآت القرية', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        _buildInstitution('مدرسة الأمل الابتدائية', Icons.school, 'حي الوسط'),
        _buildInstitution(
          'مستشفى القرية المركزي',
          Icons.local_hospital,
          'وسط القرية',
        ),
        _buildInstitution('مسجد الفلاح', Icons.mosque, 'حي الفلاح'),
        _buildInstitution('المركز الثقافي', Icons.theater_comedy, 'وسط القرية'),
        _buildInstitution('الجمعية الزراعية', Icons.agriculture, 'حي الفلاح'),
      ],
    );
  }

  Widget _buildInstitution(String name, IconData icon, String location) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, size: 40),
        title: Text(name),
        subtitle: Text(location),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }
}

