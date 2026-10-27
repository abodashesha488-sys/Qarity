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
  bool _appearanceExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, child) {
        final theme = Theme.of(context);
        return Scaffold(
          appBar: const QurityAppBar(title: 'الإعدادات'),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              _buildHeroBanner(theme),
              _buildAppearanceSection(theme, context),
              _buildSectionCard(
                theme,
                'التحديثات',
                Icons.system_update_rounded,
                [
                  const _UpdateTile(),
                ],
              ),
              _buildSectionCard(
                theme,
                'الإشعارات',
                Icons.notifications_active_rounded,
                [
                  _SettingsTile(
                    icon: Icons.notifications_rounded,
                    title: 'إعدادات الإشعارات',
                    subtitle: 'تخصيص التنبيهات وقنوات الأخبار والخدمات',
                    onTap: () => Navigator.pushNamed(
                        context, AppRoutes.notificationsSettings),
                  ),
                ],
              ),
              _buildSectionCard(
                theme,
                'اللغة',
                Icons.language_rounded,
                [
                  _SettingsTile(
                    icon: Icons.translate_rounded,
                    title: 'لغة التطبيق',
                    subtitle: 'اللغة المعتمدة لواجهات النظام',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        'العربية',
                        style: GoogleFonts.tajawal(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    onTap: () => _showLanguageModal(context),
                  ),
                ],
              ),
              _buildSectionCard(
                theme,
                'الحساب',
                Icons.person_rounded,
                [
                  _SettingsTile(
                    icon: Icons.account_circle_rounded,
                    title: 'حساب المستخدم',
                    subtitle: 'الملف الشخصي والبيانات المسجلة',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.profileMain),
                  ),
                ],
              ),
              _buildSectionCard(
                theme,
                'عن التطبيق',
                Icons.info_rounded,
                [
                  _SettingsTile(
                    icon: Icons.app_settings_alt_rounded,
                    title: 'معلومات التطبيق',
                    subtitle: 'الإصدار، الرؤية، والمطورين',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.aboutApp),
                  ),
                ],
              ),
              _buildFooter(theme),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroBanner(ThemeData theme) {
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: isDark
              ? [
                  primary.withValues(alpha: 0.22),
                  primary.withValues(alpha: 0.08),
                ]
              : [
                  primary.withValues(alpha: 0.12),
                  primary.withValues(alpha: 0.03),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primary.withValues(alpha: isDark ? 0.25 : 0.18),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary,
                  primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إعدادات المنظومة',
                  style: GoogleFonts.tajawal(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'تخصيص الواجهة والإشعارات ومتابعة التحديثات الرسمية',
                  style: GoogleFonts.tajawal(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(ThemeData theme, BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final currentFamily = _themeService.family;
    final primary = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outlineVariant
              .withValues(alpha: isDark ? 0.30 : 0.40),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: isDark ? 0.22 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _appearanceExpanded = !_appearanceExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: isDark ? 0.16 : 0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.palette_rounded, color: primary, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'المظهر',
                                style: GoogleFonts.tajawal(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2.5),
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: isDark ? 0.20 : 0.10),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  currentFamily.title,
                                  style: GoogleFonts.tajawal(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!_appearanceExpanded) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                ...currentFamily.swatch.map(
                                  (color) => Container(
                                    margin: const EdgeInsetsDirectional.only(end: 4),
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: color,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.outlineVariant,
                                        width: 0.8,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _themeService.isDarkMode
                                      ? 'الوضع الليلي مفعّل'
                                      : 'الوضع الفاتح مفعّل',
                                  style: GoogleFonts.tajawal(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      _appearanceExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, thickness: 0.8),
                  const SizedBox(height: 10),
                  _familyHeading(theme),
                  ...AppThemes.all.map((f) => _ThemeFamilyCard(
                        family: f,
                        selected: f.id == _themeService.family.id,
                        onTap: () => _themeService.setFamily(f),
                      )),
                  if (_themeService.customFamilies.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _customThemesHeading(theme),
                    ..._themeService.customFamilies.map((f) => _ThemeFamilyCard(
                          family: f,
                          selected: f.id == _themeService.family.id,
                          onTap: () => _themeService.setFamily(f),
                          onDelete: () => _confirmDeleteCustomTheme(context, f),
                        )),
                  ],
                  const SizedBox(height: 8),
                  _buildCreateThemeButton(theme, context),
                  const SizedBox(height: 6),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.25),
                      ),
                    ),
                    child: SwitchListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      title: Text(
                        'الوضع الليلي',
                        style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                      subtitle: Text(
                        'تفعيل المظهر الداكن المريح للعين',
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      value: _themeService.isDarkMode,
                      onChanged: (value) => _themeService.setDarkMode(value),
                      secondary: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (_themeService.isDarkMode
                                  ? AppColors.purple
                                  : AppColors.warning)
                              .withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _themeService.isDarkMode
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: AppColors.readableInk(
                              _themeService.isDarkMode
                                  ? AppColors.purple
                                  : AppColors.warning,
                              theme.brightness),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: _appearanceExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    ThemeData theme,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outlineVariant
              .withValues(alpha: isDark ? 0.30 : 0.40),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: isDark ? 0.22 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary
                      .withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.tajawal(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  void _showLanguageModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final t = Theme.of(ctx);
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: t.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(Icons.translate_rounded, color: t.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    'لغة المنظومة',
                    style: GoogleFonts.tajawal(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: t.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: t.colorScheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.success),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'اللغة العربية (الفصحى)',
                            style: GoogleFonts.tajawal(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),
                          Text(
                            'اللغة الأساسية والمعتمدة لكافة خدمات المنظومة',
                            style: GoogleFonts.tajawal(
                              fontSize: 12,
                              color: t.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  Icons.favorite_rounded,
                  color: AppColors.error.withValues(alpha: 0.7),
                  size: 15,
                ),
              ),
              Container(
                width: 24,
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'تطبيق قرية أبوديشيشة الرقمي',
            style: GoogleFonts.tajawal(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'صُنع بكل إتقان لخدمة أهالينا الكرام',
            style: GoogleFonts.tajawal(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
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

  Widget _customThemesHeading(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Row(
        children: [
          Icon(Icons.palette_outlined, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'الثيمات المخصصة من تصميمك',
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

  Widget _buildCreateThemeButton(ThemeData theme, BuildContext context) {
    final primary = theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showCustomThemeBuilder(context),
          icon: const Icon(Icons.palette_outlined, size: 18),
          label: Text(
            'تصميم ثيم جديد بألوانك الخاصة',
            style: GoogleFonts.tajawal(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: BorderSide(color: primary.withValues(alpha: 0.35), width: 1.2),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteCustomTheme(BuildContext context, AppThemeFamily family) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'حذف الثيم المخصص',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: Text(
          'هل تريد بالتأكيد حذف ثيم "${family.title}"؟',
          style: GoogleFonts.tajawal(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'إلغاء',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w700),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await _themeService.deleteCustomTheme(family.id);
            },
            child: Text(
              'حذف',
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomThemeBuilder(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _CustomThemeBuilderSheet(),
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
    this.onDelete,
  });

  final AppThemeFamily family;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

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
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: AppColors.error,
                  tooltip: 'حذف الثيم المخصص',
                  onPressed: onDelete,
                ),
              const SizedBox(width: 4),
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

/// نافذة منبثقة لاختيار أي درجة لون من الطيف الكامل (16.7 مليون لون) مع درجات السطوع والتشبع وإدخال كود الـ Hex.
class _FullColorPickerDialog extends StatefulWidget {
  const _FullColorPickerDialog({
    required this.initialColor,
    required this.title,
  });

  final Color initialColor;
  final String title;

  @override
  State<_FullColorPickerDialog> createState() => _FullColorPickerDialogState();
}

class _FullColorPickerDialogState extends State<_FullColorPickerDialog> {
  late HSVColor _hsv;
  late final TextEditingController _hexController;

  static const List<Color> _quickPalette = [
    Color(0xFF1B4D3E), Color(0xFF10B981), Color(0xFF059669), Color(0xFF14532D),
    Color(0xFF0F172A), Color(0xFF1D4ED8), Color(0xFF0284C7), Color(0xFF0EA5E9),
    Color(0xFF0F5147), Color(0xFF14B8A6), Color(0xFF4A148C), Color(0xFF8B5CF6),
    Color(0xFF880E4F), Color(0xFFC2185B), Color(0xFFF43F5E), Color(0xFF9A3412),
    Color(0xFFC2410C), Color(0xFFD97706), Color(0xFF78350F), Color(0xFFF59E0B),
    Color(0xFFFFFFFF), Color(0xFFF8FAFC), Color(0xFFF4F6F4), Color(0xFF1E293B),
  ];

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initialColor);
    final hex = widget.initialColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
    _hexController = TextEditingController(text: hex);
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _updateFromHsv(HSVColor hsv) {
    setState(() {
      _hsv = hsv;
      final hex = _hsv.toColor().toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
      _hexController.value = TextEditingValue(
        text: hex,
        selection: TextSelection.collapsed(offset: hex.length),
      );
    });
  }

  void _onHexChanged(String value) {
    final clean = value.replaceAll('#', '').trim();
    if (clean.length == 6) {
      final parsed = int.tryParse('FF$clean', radix: 16);
      if (parsed != null) {
        setState(() {
          _hsv = HSVColor.fromColor(Color(parsed));
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final curColor = _hsv.toColor();
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: scheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: curColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: curColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: GoogleFonts.tajawal(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // معاينة اللون ومربع الـ Hex
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: curColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: curColor.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'كود اللون المختار:',
                        style: GoogleFonts.tajawal(
                          color: curColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (curColor.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                              .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${_hexController.text}',
                          style: GoogleFonts.tajawal(
                            color: curColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // إدخال كود اللون مباشرة
                TextField(
                  controller: _hexController,
                  onChanged: _onHexChanged,
                  maxLength: 6,
                  textCapitalization: TextCapitalization.characters,
                  style: GoogleFonts.tajawal(fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    labelText: 'كود اللون Hex (مثال: 1B4D3E)',
                    prefixText: '# ',
                    counterText: '',
                    prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),
                // شريط تدرج الألوان (طيف كامل 360 درجة)
                Text(
                  'درجة اللون (طيف كامل)',
                  style: GoogleFonts.tajawal(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF0000), Color(0xFFFFFF00), Color(0xFF00FF00),
                        Color(0xFF00FFFF), Color(0xFF0000FF), Color(0xFFFF00FF),
                        Color(0xFFFF0000),
                      ],
                    ),
                  ),
                ),
                Slider(
                  value: _hsv.hue,
                  max: 360,
                  activeColor: curColor,
                  onChanged: (v) => _updateFromHsv(_hsv.withHue(v)),
                ),
                // شريط التشبع
                Text(
                  'التشبع (نقاء اللون)',
                  style: GoogleFonts.tajawal(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
                Slider(
                  value: _hsv.saturation,
                  activeColor: curColor,
                  onChanged: (v) => _updateFromHsv(_hsv.withSaturation(v)),
                ),
                // شريط السطوع والإضاءة
                Text(
                  'السطوع (الدرجة الفاتحة والداكنة)',
                  style: GoogleFonts.tajawal(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
                Slider(
                  value: _hsv.value,
                  activeColor: curColor,
                  onChanged: (v) => _updateFromHsv(_hsv.withValue(v)),
                ),
                const SizedBox(height: 8),
                Text(
                  'ألوان مختارة سريعة',
                  style: GoogleFonts.tajawal(fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickPalette.map((color) {
                    final isSel = curColor.toARGB32() == color.toARGB32();
                    return InkWell(
                      onTap: () => _updateFromHsv(HSVColor.fromColor(color)),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? scheme.primary : scheme.outline,
                            width: isSel ? 2.5 : 1,
                          ),
                          boxShadow: isSel
                              ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
                              : null,
                        ),
                        child: isSel
                            ? Icon(
                                Icons.check_rounded,
                                size: 16,
                                color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'إلغاء',
                        style: GoogleFonts.tajawal(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, curColor),
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark ? scheme.primary : AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      child: Text(
                        'اختيار هذا اللون',
                        style: GoogleFonts.tajawal(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ورقة تصميم ثيم مخصص قابلة لتخصيص كل شيء: الخط، لونه، الأساسي، الثانوي،
/// وخلفية الصفحات والكروت مع إتاحة جميع ألوان الطيف دون قيود.
class _CustomThemeBuilderSheet extends StatefulWidget {
  const _CustomThemeBuilderSheet();

  @override
  State<_CustomThemeBuilderSheet> createState() =>
      _CustomThemeBuilderSheetState();
}

class _CustomThemeBuilderSheetState extends State<_CustomThemeBuilderSheet> {
  final _nameController = TextEditingController(text: 'ثيمي الخاص');
  String _selectedFontFamily = 'Tajawal';
  Color _selectedPrimary = const Color(0xFF1B4D3E);
  Color _selectedAccent = const Color(0xFF10B981);
  Color _selectedPageBackground = const Color(0xFFF4F6F4);
  Color _selectedCardBackground = const Color(0xFFFFFFFF);
  Color _selectedTextColor = const Color(0xFF102A22);
  bool _saving = false;

  static const List<MapEntry<String, String>> _availableFonts = [
    MapEntry('Tajawal', 'تجوال (الافتراضي الأنيق)'),
    MapEntry('Cairo', 'كايرو (عصري وحيوي)'),
    MapEntry('Almarai', 'المراعي (هندسي متوازن)'),
    MapEntry('Amiri', 'أميري (كلاسيكي تراثي)'),
    MapEntry('El Messiri', 'المسيري (جذاب ناعم)'),
    MapEntry('Readex Pro', 'ريدكس برو (تقني حديث)'),
    MapEntry('Changa', 'تشانغا (عريض ومميز)'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<Color?> _pickColor(BuildContext context, Color current, String title) async {
    return showDialog<Color>(
      context: context,
      builder: (ctx) => _FullColorPickerDialog(
        initialColor: current,
        title: title,
      ),
    );
  }

  TextStyle _previewFont({FontWeight? fontWeight, Color? color, double? fontSize}) {
    try {
      return GoogleFonts.getFont(
        _selectedFontFamily,
        fontWeight: fontWeight,
        color: color,
        fontSize: fontSize,
      );
    } catch (_) {
      return GoogleFonts.tajawal(
        fontWeight: fontWeight,
        color: color,
        fontSize: fontSize,
      );
    }
  }

  Future<void> _saveAndApply() async {
    final name = _nameController.text.trim().isEmpty
        ? 'ثيمي الخاص'
        : _nameController.text.trim();
    setState(() => _saving = true);
    final customFamily = AppThemeFamily.fromFullCustomization(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: name,
      caption: 'ثيم مخصص من تصميمك',
      fontFamily: _selectedFontFamily,
      primary: _selectedPrimary,
      secondary: _selectedAccent,
      page: _selectedPageBackground,
      surface: _selectedCardBackground,
      textPrimary: _selectedTextColor,
    );
    await ThemeService().saveCustomTheme(customFamily);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم حفظ وتطبيق ثيم "$name" بنجاح بكامل تخصيصاتك',
          style: GoogleFonts.tajawal(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: _selectedPrimary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.palette_rounded, color: _selectedPrimary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تصميم وتخصيص ثيم كامل',
                        style: GoogleFonts.tajawal(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'خصّص نوع ولون الخط، والأساسي، والثانوي، وخلفيات الصفحات والكروت',
                        style: GoogleFonts.tajawal(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // اسم الثيم
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: 'اسم الثيم',
                labelStyle: GoogleFonts.tajawal(fontSize: 13.5),
                prefixIcon: const Icon(Icons.edit_rounded, size: 20),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _selectedPrimary, width: 1.8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // معاينة حية متكاملة
            Text(
              'معاينة حية شاملة لكل التخصيصات',
              style: GoogleFonts.tajawal(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: _selectedPageBackground,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: scheme.outlineVariant),
                boxShadow: const [
                  BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3)),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    color: _selectedPrimary,
                    child: Row(
                      children: [
                        const Icon(Icons.menu_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _nameController.text.trim().isEmpty ? 'قرية أبوديشيشة' : _nameController.text.trim(),
                            style: _previewFont(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedCardBackground,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _selectedPrimary.withValues(alpha: 0.15)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _selectedPrimary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.palette_rounded, color: _selectedPrimary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'عنوان البطاقة بهذا الخط واللون',
                                  style: _previewFont(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: _selectedTextColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'خلفية الصفحة والكارت تظهر بتصميمك',
                                  style: _previewFont(
                                    fontSize: 11,
                                    color: _selectedTextColor.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _selectedAccent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'زر تمييز',
                              style: _previewFont(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            // قسم اختيار نوع الخط
            Text(
              'نوع الخط (Typography)',
              style: GoogleFonts.tajawal(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _availableFonts.map((entry) {
                  final isSelected = _selectedFontFamily == entry.key;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedFontFamily = entry.key),
                      label: Text(
                        entry.value,
                        style: GoogleFonts.getFont(
                          entry.key,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 12.5,
                          color: isSelected ? scheme.onPrimary : scheme.onSurface,
                        ),
                      ),
                      selectedColor: _selectedPrimary,
                      backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),
            // تخصيص الألوان الخمسة مع إتاحة الطيف الكامل
            Text(
              'تخصيص الألوان (يتيح الطيف اللوني الكامل)',
              style: GoogleFonts.tajawal(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            _buildColorTile(
              title: 'اللون الأساسي',
              subtitle: 'للهيدر، الأشرطة، والأزرار القيادية',
              color: _selectedPrimary,
              onTap: () async {
                final c = await _pickColor(context, _selectedPrimary, 'اختيار اللون الأساسي');
                if (c != null) setState(() => _selectedPrimary = c);
              },
            ),
            _buildColorTile(
              title: 'اللون الثانوي',
              subtitle: 'لأزرار التمييز، الشارات، والأيقونات البارزة',
              color: _selectedAccent,
              onTap: () async {
                final c = await _pickColor(context, _selectedAccent, 'اختيار اللون الثانوي');
                if (c != null) setState(() => _selectedAccent = c);
              },
            ),
            _buildColorTile(
              title: 'خلفية الصفحات',
              subtitle: 'أرضية التطبيق العامة والشاشات الرئيسية',
              color: _selectedPageBackground,
              onTap: () async {
                final c = await _pickColor(context, _selectedPageBackground, 'اختيار خلفية الصفحات');
                if (c != null) setState(() => _selectedPageBackground = c);
              },
            ),
            _buildColorTile(
              title: 'خلفية الكروت والبطاقات',
              subtitle: 'أرضية الحاويات والبطاقات والعناصر التفاعلية',
              color: _selectedCardBackground,
              onTap: () async {
                final c = await _pickColor(context, _selectedCardBackground, 'اختيار خلفية الكروت');
                if (c != null) setState(() => _selectedCardBackground = c);
              },
            ),
            _buildColorTile(
              title: 'لون الخط والنصوص',
              subtitle: 'لون النصوص والعناوين داخل التطبيق',
              color: _selectedTextColor,
              onTap: () async {
                final c = await _pickColor(context, _selectedTextColor, 'اختيار لون الخط');
                if (c != null) setState(() => _selectedTextColor = c);
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveAndApply,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(
                  _saving ? 'جاري الحفظ...' : 'حفظ وتطبيق الثيم المخصص',
                  style: GoogleFonts.tajawal(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _selectedPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorTile({
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final hex = color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.tajawal(fontSize: 13.5, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Text(
                  '#$hex',
                  style: GoogleFonts.tajawal(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.colorize_rounded, size: 18),
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
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary
                      .withValues(alpha: isDark ? 0.14 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 19),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.tajawal(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.tajawal(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// كارت التحديثات المطور — يعرض تفاصيل الإصدار ويفحص التحديثات مباشرة ويفتح المثبت بعد التحميل.
class _UpdateTile extends StatefulWidget {
  const _UpdateTile();

  @override
  State<_UpdateTile> createState() => _UpdateTileState();
}

class _UpdateTileState extends State<_UpdateTile> {
  String _version = '…';
  String _buildNumber = '';
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
        setState(() {
          _version = 'v${p.version}';
          _buildNumber = p.buildNumber;
        });
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
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              backgroundColor: AppColors.error,
              content: Row(
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'تعذّر فحص التحديثات — تحقق من الاتصال وأعد المحاولة',
                      style: GoogleFonts.tajawal(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          );
        case UpdateCheckStatus.notSupported:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              content: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'التحديث هنا تلقائي عند فتح التطبيق',
                      style: GoogleFonts.tajawal(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          );
        case UpdateCheckStatus.upToDate:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              backgroundColor: AppColors.success,
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'أنت على أحدث إصدار',
                      style: GoogleFonts.tajawal(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.08 : 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: primary.withValues(alpha: isDark ? 0.22 : 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_sync_rounded,
                  color: primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الإصدار الحالي المثبت',
                      style: GoogleFonts.tajawal(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _version,
                          style: GoogleFonts.tajawal(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (_buildNumber.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'بناء $_buildNumber',
                              style: GoogleFonts.tajawal(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'نشط',
                      style: GoogleFonts.tajawal(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'يتم فحص وتثبيت التحديثات الجديدة تلقائيًا لضمان الأمان وفاعلية الخدمات.',
            style: GoogleFonts.tajawal(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _checking ? null : _checkForUpdate,
              icon: _checking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.system_update_alt_rounded, size: 19),
              label: Text(
                _checking ? 'جاري فحص التحديثات...' : 'التحقق من التحديثات',
                style: GoogleFonts.tajawal(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
