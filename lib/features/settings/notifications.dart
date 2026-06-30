import 'package:flutter/material.dart';
import '../../widgets/common_appbar_actions.dart';

class NotificationsSettingsScreen extends StatelessWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الإشعارات'),
        actions: CommonAppBarActions.actions(context),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('إشعارات الأخبار'),
            subtitle: const Text('تلقي إشعارات عند نشر أخبار جديدة'),
            value: true,
            onChanged: (v) {},
          ),
          SwitchListTile(
            title: const Text('إشعارات المناسبات'),
            subtitle: const Text('تلقي إشعارات عن المناسبات القادمة'),
            value: true,
            onChanged: (v) {},
          ),
          SwitchListTile(
            title: const Text('إشعارات السوق'),
            subtitle: const Text('تلقي إشعارات عن المنتجات الجديدة'),
            value: false,
            onChanged: (v) {},
          ),
          SwitchListTile(
            title: const Text('إشعارات الطوارئ'),
            subtitle: const Text('تلقي إشعارات الطوارئ المهمة'),
            value: true,
            onChanged: (v) {},
          ),
        ],
      ),
    );
  }
}
