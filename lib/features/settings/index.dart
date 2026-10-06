import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_themes.dart';
import '../../routes/app_routes.dart';
import '../../services/theme_service.dart';
import '../../services/update_service.dart';
import '../../widgets/qurity_app_bar.dart';
import '../../widgets/update_flow.dart';

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
          appBar: const QurityAppBar(title: 'الإعدادات'),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionCard(theme, 'المظهر', Icons.palette_rounded, [
                _familyHeading(theme),
                ...AppThemes.all.map((f) => _ThemeFamilyCard(
                      family: f,
                      selected: f.id == _themeService.family.id,
                      onTap: () => _themeService.setFamily(f),
                    )),
                SwitchListTile(
                  title: Text('الوضع الليلي', style: GoogleFonts.tajawal(fontWeight: FontWeight.w700)),
                  subtitle: Text('تفعيل المظهر الداكن للتطبيق', style: GoogleFonts.tajawal()),
                  value: _themeService.isDarkMode,
                  onChanged: (value) => _themeService.setDarkMode(value),
                  secondary: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      // الأرضية كانت التمييز نفسه معتما والرمز من نفس لونه،
                      // فالرمز غير مرئي إطلاقا في الحالتين. صارت الأرضية تظليلا
                      // خفيفا من التمييز والرمز حبرا مقروءا مشتقا منه.
                      color: (_themeService.isDarkMode
                              ? AppColors.purple
                              : AppColors.warning)
                          .withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _themeService.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      color: AppColors.readableInk(
                          _themeService.isDarkMode
                              ? AppColors.purple
                              : AppColors.warning,
                          theme.brightness),
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
                  trailing: Text('العربية', style: GoogleFonts.tajawal(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
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
              _buildSectionCard(theme, 'التحديثات', Icons.system_update_rounded, [
                const _UpdateTile(),
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

  /// سطر مقدمة لمجموعة بطاقات المظهر، ونصّه حرف ما طلبه صاحبه.
  Widget _familyHeading(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Row(
        children: [
          Icon(Icons.brush_rounded, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'تخصيص مظهر التطبيق',
              style: GoogleFonts.tajawal(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة عائلة مظهر واحدة: دوائر ألوانها ثم اسمها ووصفها، ومارّة تحديد في
/// طرفها. المحدَّدة تحمل إطارًا وعنوانًا من [AppColors.readableInk] لا من لون
/// العائلة الخام.
///
/// القياس الذي فرض ذلك: `family.primary` فوق أرضية عائلتها الفاتحة **9.64 /
/// 17.85 / 7.10** فيكفي، أما فوق أرضية داكنة فخمًا **1.74 / 1.03 / 2.40** — أي
/// أن العنوان والإطار يذوبان في الوضع الداكن إن استُعمل الخام. `readableInk`
/// يزحزح السطوع وحده فيقاس فوق أرضية الكارت الداكنة **10.12 / 6.98 / 7.68**.
/// والتظليل الاختياري `primary@0.06` يترك الخام نفسه **6.46** فأكثر (أدناهُ
/// للتراكوتا)، فلا يتضرر أي نص فوقه.
///
/// أما دائرتا `mint` و`page` فتقيسان **1.01–1.15** مقابل الكارت، أي أنهما تبدوان
/// زائرتين لولا الحدّ؛ فكلٌّ يحمل `scheme.outline` كاملًا (بلا شفافية) فيقاس
/// **3.41 / 3.72 / 3.41** في الفاتح و**4.52 / 4.48 / 4.17** في الداكن — وهذا هو
/// سقف حدود التحكّم المطلوب (3.0). ونفس الحدّ صار لإطار البطاقة غير المحدَّدة،
/// لأن `outlineVariant` (= فاصل العائلة) لا يقيس مقابل سطح الكارت أكثر من
/// **1.27 / 1.29 / 1.31**.
class _ThemeFamilyCard extends StatelessWidget {
  const _ThemeFamilyCard({
    required this.family,
    required this.selected,
    required this.onTap,
  });

  final AppThemeFamily family;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    final ink = AppColors.readableInk(family.primary, theme.brightness);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: selected
                ? family.primary.withValues(alpha: dark ? 0.10 : 0.06)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? ink : scheme.outline,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              ...family.swatch.map(
                (color) => Padding(
                  padding: const EdgeInsetsDirectional.only(end: 6),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: scheme.outline),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      family.title,
                      style: GoogleFonts.tajawal(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: selected ? ink : scheme.onSurface,
                      ),
                    ),
                    Text(
                      family.caption,
                      style: GoogleFonts.tajawal(
                        fontSize: 11.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 22,
                color: selected ? ink : scheme.outline,
              ),
            ],
          ),
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

/// صف التحديثات — يعرض الإصدار الحالي ويفحص يدويًا عند الضغط.
class _UpdateTile extends StatefulWidget {
  const _UpdateTile();

  @override
  State<_UpdateTile> createState() => _UpdateTileState();
}

class _UpdateTileState extends State<_UpdateTile> {
  String _version = '…';
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final p = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = 'الإصدار ${p.version}');
      }
    } catch (_) {}
  }

  Future<void> _checkForUpdate() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final check = await UpdateService().checkForUpdate();
      if (!mounted) return;
      switch (check.status) {
        case UpdateCheckStatus.updateAvailable:
          final info = check.info!;
          final choice = await UpdateService.showUpdateDialog(context, info);
          if (choice != DialogResult.updateNow) return;
          if (!mounted) return;
          await UpdateFlow.install(context, info);
        case UpdateCheckStatus.checkFailed:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تعذّر فحص التحديثات — تحقق من الاتصال وأعد المحاولة'),
            ),
          );
        case UpdateCheckStatus.notSupported:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('التحديث هنا تلقائي عند فتح التطبيق')),
          );
        case UpdateCheckStatus.upToDate:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('أنت على أحدث إصدار')),
          );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: Icons.system_update_alt_rounded,
      title: 'التحقق من التحديثات',
      subtitle: '$_version ${_checking ? '• جاري الفحص…' : '• اضغط للفحص الآن'}',
      onTap: _checkForUpdate,
    );
  }
}
