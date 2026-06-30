import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/common_appbar_actions.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('عن التطبيق'),
        actions: CommonAppBarActions.actions(context),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.villa, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const Text(
              'تطبيق قرية أبوديشيشة',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('إصدار 1.0.0', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            const Text(
              'الوصف',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'قرية أبوديشيشة منصة الخدمات الرقمية للقرية، تجمع الأخبار، السوق، المنتدى، الطوارئ وخدمات المجتمع.',
              style: TextStyle(height: 1.6),
            ),
            const SizedBox(height: 24),
            const Text(
              'الميزات',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: const [
                  _FeatureItem(
                    icon: Icons.home,
                    text: 'الرئيسية وخدمات القرية',
                  ),
                  _FeatureItem(
                    icon: Icons.newspaper,
                    text: 'أخبار القرية والمناسبات',
                  ),
                  _FeatureItem(
                    icon: Icons.store,
                    text: 'سوق القرية الإلكتروني',
                  ),
                  _FeatureItem(icon: Icons.forum, text: 'منتدى المجتمع المحلي'),
                  _FeatureItem(
                    icon: Icons.contact_phone,
                    text: 'دليل الهاتف وحالات الطوارئ',
                  ),
                  _FeatureItem(
                    icon: Icons.add_task,
                    text: 'طلب الخدمات العامة',
                  ),
                  _FeatureItem(
                    icon: Icons.person,
                    text: 'الملف الشخصي والإعدادات',
                  ),
                  _FeatureItem(
                    icon: Icons.admin_panel_settings,
                    text: 'لوحة تحكم المسؤول',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

