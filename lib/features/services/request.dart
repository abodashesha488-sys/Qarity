import 'package:flutter/material.dart';
import '../../widgets/common_appbar_actions.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('طلب الخدمة'),
          actions: CommonAppBarActions.actions(context),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'طلب جديد'),
              Tab(text: 'طلباتي'),
            ],
          ),
        ),
        body: TabBarView(children: [_RequestTab(), _MyRequestsTab()]),
      ),
    );
  }
}

class _RequestTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'نوع الطلب'),
            readOnly: true,
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: 'وصف الطلب'),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextFormField(decoration: const InputDecoration(labelText: 'الموقع')),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: () {}, child: const Text('إرسال الطلب')),
          ),
        ],
      ),
    );
  }
}

class _MyRequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.local_shipping),
            title: const Text('إصلاح ماء'),
            subtitle: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text('الحالة: قيد المعالجة'), Text('2024/6/20')],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        );
      },
    );
  }
}