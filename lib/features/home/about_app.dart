import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../widgets/common_appbar_actions.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const List<_Feature> _features = [
    _Feature(icon: Icons.home_rounded, text: 'الرئيسية وخدمات القرية'),
    _Feature(icon: Icons.newspaper_rounded, text: 'أخبار القرية والمناسبات'),
    _Feature(icon: Icons.store_rounded, text: 'سوق القرية الإلكتروني'),
    _Feature(icon: Icons.forum_rounded, text: 'منتدى المجتمع المحلي'),
    _Feature(icon: Icons.contact_phone_rounded, text: 'دليل الهاتف وحالات الطوارئ'),
    _Feature(icon: Icons.add_task_rounded, text: 'طلب الخدمات العامة'),
    _Feature(icon: Icons.person_rounded, text: 'الملف الشخصي والإعدادات'),
    _Feature(icon: Icons.admin_panel_settings_rounded, text: 'لوحة تحكم المسؤول'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('عن التطبيق'),
        centerTitle: true,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: theme.colorScheme.surface,
        actions: CommonAppBarActions.actions(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  child: const Icon(Icons.villa_rounded, size: 44, color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                const Text('تطبيق قرية أبوديشيشة', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2), textAlign: TextAlign.center),
                const SizedBox(height: 6),
                const Text('إصدار 1.0.0', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4))),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('الوصف', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'قرية أبوديشيشة منصة الخدمات الرقمية للقرية، تجمع الأخبار، السوق، المنتدى، الطوارئ وخدمات المجتمع في مكان واحد.',
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.6, color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('الميزات', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ..._features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4))),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.12), shape: BoxShape.circle),
                  child: Icon(f.icon, color: AppColors.primary, size: 20),
                ),
                title: Text(f.text, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              ),
            ),
          )),
          const SizedBox(height: 8),
          Text('روابط', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4))),
            child: ListTile(
              leading: Icon(Icons.policy_rounded, color: theme.colorScheme.primary),
              title: Text('سياسة الخصوصية', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_left_rounded, size: 18),
              onTap: () => showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('سياسة الخصوصية'),
                  content: const Text('نحن نحرص على حماية بياناتك الشخصية ولا تتم مشاركتها مع أطراف خارجية دون موافقتك.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً'))],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4))),
            child: ListTile(
              leading: Icon(Icons.villa_rounded, color: theme.colorScheme.primary),
              title: Text('عن القرية', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              trailing: const Icon(Icons.chevron_left_rounded, size: 18),
              onTap: () => Navigator.pushNamed(context, AppRoutes.about),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Feature {
  final IconData icon;
  final String text;
  const _Feature({required this.icon, required this.text});
}
