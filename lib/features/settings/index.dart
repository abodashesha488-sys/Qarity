import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(
            title: const Text('الإعدادات'),
            centerTitle: true,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: theme.colorScheme.surface,
            actions: CommonAppBarActions.actions(context),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionCard(theme, 'المظهر', Icons.palette_rounded, [
                SwitchListTile(
                  title: Text('الوضع الليلي', style: GoogleFonts.cairo(fontWeight: FontWeight.w700)),
                  subtitle: Text('تفعيل المظهر الداكن للتطبيق', style: GoogleFonts.cairo()),
                  value: _themeService.isDarkMode,
                  onChanged: (value) => _themeService.setDarkMode(value),
                  secondary: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _themeService.isDarkMode ? AppColors.purple.withValues(alpha: 1.0) : AppColors.warning.withValues(alpha: 1.0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _themeService.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: _themeService.isDarkMode ? AppColors.purple : AppColors.warning,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              _buildSectionCard(theme, 'الإشعارات', Icons.notifications_active_rounded, [
                _SettingsTile(
                  icon: Icons.notifications_rounded,
                  title: 'إعدادات الإشعارات',
                  subtitle: 'تخصيص الإشعارات التي تصلك',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.notificationsSettings),
                ),
              ]),
              const SizedBox(height: 16),
              _buildSectionCard(theme, 'اللغة', Icons.language_rounded, [
                _SettingsTile(
                  icon: Icons.translate_rounded,
                  title: 'تغيير اللغة',
                  trailing: Text('العربية', style: GoogleFonts.cairo(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 16),
              _buildSectionCard(theme, 'الحساب', Icons.person_rounded, [
                _SettingsTile(
                  icon: Icons.account_circle_rounded,
                  title: 'حساب المستخدم',
                  subtitle: 'الملف الشخصي وتسجيلات الدخول',
                  onTap: () {},
                ),
              ]),
              const SizedBox(height: 16),
              _buildSectionCard(theme, 'عن التطبيق', Icons.info_rounded, [
                _SettingsTile(
                  icon: Icons.app_settings_alt_rounded,
                  title: 'معلومات التطبيق',
                  subtitle: 'الإصدار والحقوق',
                  onTap: () => Navigator.pushNamed(context, AppRoutes.aboutApp),
                ),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionCard(ThemeData theme, String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 18),
                ),
                const SizedBox(width: 10),
                Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  if (subtitle != null)
                    Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else
              Icon(Icons.chevron_left_rounded, color: theme.colorScheme.onSurfaceVariant, size: 18),
          ],
        ),
      ),
    );
  }
}
