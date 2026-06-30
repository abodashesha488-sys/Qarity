import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../routes/app_routes.dart';
import '../../services/theme_service.dart';
import '../../widgets/common_appbar_actions.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ThemeService _themeService = ThemeService();

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('الإعدادات'),
            actions: CommonAppBarActions.actions(context),
          ),
          body: ListView(
            children: [
              _buildSectionHeader('المظهر'),
              SwitchListTile(
                title: const Text('الوضع الليلي'),
                subtitle: const Text('تفعيل المظهر الداكن للتطبيق'),
                value: _themeService.isDarkMode,
                onChanged: (value) => _themeService.setDarkMode(value),
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _themeService.isDarkMode
                        ? AppColors.purple.withValues(alpha: 1.0)
                        : AppColors.warning.withValues(alpha: 1.0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _themeService.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: _themeService.isDarkMode ? AppColors.purple : AppColors.warning,
                  ),
                ),
              ),
              const Divider(),
              _buildSectionHeader('الإشعارات'),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 1.0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_active_rounded, color: AppColors.info),
                ),
                title: const Text('إعدادات الإشعارات'),
                subtitle: const Text('تخصيص الإشعارات التي تصلك'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {},
              ),
              const Divider(),
              _buildSectionHeader('اللغة'),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 1.0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.language_rounded, color: AppColors.success),
                ),
                title: const Text('تغيير اللغة'),
                trailing: const Text('العربية'),
                onTap: () {},
              ),
              const Divider(),
              _buildSectionHeader('الحساب'),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 1.0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_rounded, color: AppColors.primary),
                ),
                title: const Text('حساب المستخدم'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {},
              ),
              const Divider(),
              _buildSectionHeader('عن التطبيق'),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 1.0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.info_rounded, color: AppColors.teal),
                ),
                title: const Text('معلومات التطبيق'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () => Navigator.pushNamed(context, AppRoutes.aboutApp),
              ),
              const Divider(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}