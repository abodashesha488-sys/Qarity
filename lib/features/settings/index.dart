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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              _buildHeroBanner(theme),
              _buildSectionCard(
                theme,
                'المظهر',
                Icons.palette_rounded,
                [
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

class _CustomThemeBuilderSheet extends StatefulWidget {
  const _CustomThemeBuilderSheet();

  @override
  State<_CustomThemeBuilderSheet> createState() =>
      _CustomThemeBuilderSheetState();
}

class _CustomThemeBuilderSheetState extends State<_CustomThemeBuilderSheet> {
  final _nameController = TextEditingController(text: 'ثيمي الخاص');
  Color _selectedPrimary = const Color(0xFF1B4D3E);
  Color _selectedAccent = const Color(0xFF10B981);
  bool _saving = false;

  static const List<MapEntry<String, Color>> _primaryChoices = [
    MapEntry('أخضر زمردي', Color(0xFF1B4D3E)),
    MapEntry('أزرق كحلي', Color(0xFF0F172A)),
    MapEntry('تراكوتا قرميدي', Color(0xFF9A3412)),
    MapEntry('أرجواني ملكي', Color(0xFF4A148C)),
    MapEntry('توت عنابي', Color(0xFF880E4F)),
    MapEntry('كهرمان ذهبي', Color(0xFF78350F)),
    MapEntry('فيروزي هادئ', Color(0xFF0F5147)),
    MapEntry('نيلي عميق', Color(0xFF1E3A8A)),
    MapEntry('غابة صنوبرية', Color(0xFF14532D)),
    MapEntry('خوخي ليلي', Color(0xFF581C87)),
    MapEntry('ياقوتي أحمر', Color(0xFF7F1D1D)),
    MapEntry('برونزي صحراوي', Color(0xFF7C2D12)),
    MapEntry('سيان قطبي', Color(0xFF164E63)),
    MapEntry('بني قهوة', Color(0xFF431407)),
    MapEntry('رمادي أردوازي', Color(0xFF334155)),
    MapEntry('وردي داكن', Color(0xFF701A75)),
  ];

  static const List<MapEntry<String, Color>> _accentChoices = [
    MapEntry('زمردي مشرق', Color(0xFF10B981)),
    MapEntry('سماوي ناصع', Color(0xFF0EA5E9)),
    MapEntry('كهرماني ذهبي', Color(0xFFF59E0B)),
    MapEntry('وردي ياقوتي', Color(0xFFF43F5E)),
    MapEntry('بنفسجي ناعم', Color(0xFF8B5CF6)),
    MapEntry('برتقالي متوهج', Color(0xFFF97316)),
    MapEntry('تركوازي بحري', Color(0xFF14B8A6)),
    MapEntry('ليموني حيوي', Color(0xFF84CC16)),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveAndApply() async {
    final name = _nameController.text.trim().isEmpty
        ? 'ثيمي الخاص'
        : _nameController.text.trim();
    setState(() => _saving = true);
    final customFamily = AppThemeFamily.fromUserPalette(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      title: name,
      caption: 'ثيم مخصص من تصميمك',
      primary: _selectedPrimary,
      accent: _selectedAccent,
    );
    await ThemeService().saveCustomTheme(customFamily);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'تم حفظ وتطبيق ثيم "$name" بنجاح',
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
        maxHeight: MediaQuery.of(context).size.height * 0.9,
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
                  child: Icon(Icons.palette_rounded,
                      color: _selectedPrimary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تصميم ثيم مخصص',
                        style: GoogleFonts.tajawal(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'اختر الألوان الأساسية وثانويتك لتوليد مظهر متناسق',
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
            TextField(
              controller: _nameController,
              style: GoogleFonts.tajawal(fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                labelText: 'اسم الثيم',
                labelStyle: GoogleFonts.tajawal(fontSize: 13.5),
                prefixIcon: const Icon(Icons.edit_rounded, size: 20),
                filled: true,
                fillColor:
                    scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: scheme.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: scheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _selectedPrimary, width: 1.8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'معاينة حية للمظهر',
              style: GoogleFonts.tajawal(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: scheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    color: _selectedPrimary,
                    child: Row(
                      children: [
                        const Icon(Icons.menu_rounded,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _nameController.text.trim().isEmpty
                                ? 'قرية أبوديشيشة'
                                : _nameController.text.trim(),
                            style: GoogleFonts.tajawal(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                            ),
                          ),
                        ),
                        const Icon(Icons.search_rounded,
                            color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(14),
                    color: theme.brightness == Brightness.dark
                        ? const Color(0xFF141922)
                        : const Color(0xFFF8FAFC),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _selectedPrimary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.nature_people_rounded,
                              color: _selectedPrimary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'بطاقة تجريبية لمعاينة الألوان',
                            style: GoogleFonts.tajawal(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _selectedAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'زر تمييز',
                            style: GoogleFonts.tajawal(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'اللون الأساسي (للهيدر والبطاقات القيادية)',
              style: GoogleFonts.tajawal(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _primaryChoices.map((entry) {
                final isSelected = _selectedPrimary == entry.value;
                return Tooltip(
                  message: entry.key,
                  child: InkWell(
                    onTap: () => setState(() => _selectedPrimary = entry.value),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: entry.value,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : scheme.outline,
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: entry.value.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 20)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Text(
              'اللون الثانوي (للأزرار المميزة والتمييز البصري)',
              style: GoogleFonts.tajawal(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _accentChoices.map((entry) {
                final isSelected = _selectedAccent == entry.value;
                return Tooltip(
                  message: entry.key,
                  child: InkWell(
                    onTap: () => setState(() => _selectedAccent = entry.value),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: entry.value,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : scheme.outline,
                          width: isSelected ? 2.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: entry.value.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 20)
                          : null,
                    ),
                  ),
                );
              }).toList(),
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
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(
                  _saving ? 'جاري الحفظ...' : 'حفظ وتطبيق الثيم',
                  style: GoogleFonts.tajawal(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _selectedPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
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
