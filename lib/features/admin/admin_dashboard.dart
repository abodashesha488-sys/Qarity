import 'package:flutter/material.dart';
import '../../widgets/common_appbar_actions.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _selectedTab = 'news';

  final List<PendingNews> _pendingNews = List.generate(
    5,
    (i) => PendingNews(
      id: i + 1,
      title: 'عاصمة القرية تفتح سوقاً جديداً للمنتجات الحسائية',
      content: 'تم افتتاح سوق جديد في قرية أبوديشيشة يضم مائة منتج محلي...',
      author: 'أحمد محمد',
      createdAt: '2024/6/24',
    ),
  );

  final List<PendingObituary> _pendingObituaries = List.generate(
    3,
    (i) => PendingObituary(
      id: i + 1,
      name: 'محمد أحمد محمد',
      date: '2024/6/23',
      place: 'مسجد الفلاح',
      details: 'توفي بعد رحلة طويلة',
      submittedBy: 'ابنة المتوفي',
    ),
  );

  final List<PendingPhone> _pendingPhones = List.generate(
    4,
    (i) => PendingPhone(
      id: i + 1,
      name: 'أحمد محمد',
      title: 'أستاذ',
      phone: '01234567890',
      submittedBy: 'مريم أحمد',
    ),
  );

  final List<PendingServiceProvider> _pendingServices = List.generate(
    3,
    (i) => PendingServiceProvider(
      id: i + 1,
      typeName: 'إصلاح',
      providerName: 'يوسف علي',
      phone: '01012345678',
      submittedBy: 'سعيد محمد',
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة مراجعة المحتوى'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: ColoredBox(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTab('news', 'الأخبار'),
                _buildTab('obituaries', 'العزاء'),
                _buildTab('phone', 'دليل الهاتف'),
                _buildTab('services', 'الخدمات'),
              ],
            ),
          ),
        ),
        actions: CommonAppBarActions.actions(context),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildTab(String tab, String title) {
    final isSelected = _selectedTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = tab),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedTab) {
      case 'news':
        return _buildNewsList();
      case 'obituaries':
        return _buildObituariesList();
      case 'phone':
        return _buildPhoneList();
      case 'services':
        return _buildServicesList();
      default:
        return _buildNewsList();
    }
  }

  Widget _buildNewsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingNews.length,
      itemBuilder: (context, index) {
        final item = _pendingNews[index];
        return _buildNewsCard(item);
      },
    );
  }

  Widget _buildNewsCard(PendingNews item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(item.content, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              'الكاتب: ${item.author}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check, color: Colors.green),
                  label: const Text('موافقة'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('حذف'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObituariesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingObituaries.length,
      itemBuilder: (context, index) {
        final item = _pendingObituaries[index];
        return _buildObituaryCard(item);
      },
    );
  }

  Widget _buildObituaryCard(PendingObituary item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'المتوفي: ${item.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'تاريخ الوفاة: ${item.date}',
              style: const TextStyle(color: Colors.grey),
            ),
            Text(
              'مكان العزاء: ${item.place}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text('التفاصيل: ${item.details}'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check, color: Colors.green),
                  label: const Text('موافقة'),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text('رفض'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingPhones.length,
      itemBuilder: (context, index) {
        final item = _pendingPhones[index];
        return _buildPhoneCard(item);
      },
    );
  }

  Widget _buildPhoneCard(PendingPhone item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(item.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الصفة: ${item.title}'),
            Text('الهاتف: ${item.phone}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServicesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingServices.length,
      itemBuilder: (context, index) {
        final item = _pendingServices[index];
        return _buildServiceCard(item);
      },
    );
  }

  Widget _buildServiceCard(PendingServiceProvider item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(item.providerName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الخدمة: ${item.typeName}'),
            Text('الهاتف: ${item.phone}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class PendingNews {
  final int id;
  final String title;
  final String content;
  final String author;
  final String createdAt;

  PendingNews({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.createdAt,
  });
}

class PendingObituary {
  final int id;
  final String name;
  final String date;
  final String place;
  final String details;
  final String submittedBy;

  PendingObituary({
    required this.id,
    required this.name,
    required this.date,
    required this.place,
    required this.details,
    required this.submittedBy,
  });
}

class PendingPhone {
  final int id;
  final String name;
  final String title;
  final String phone;
  final String submittedBy;

  PendingPhone({
    required this.id,
    required this.name,
    required this.title,
    required this.phone,
    required this.submittedBy,
  });
}

class PendingServiceProvider {
  final int id;
  final String typeName;
  final String providerName;
  final String phone;
  final String submittedBy;

  PendingServiceProvider({
    required this.id,
    required this.typeName,
    required this.providerName,
    required this.phone,
    required this.submittedBy,
  });
}