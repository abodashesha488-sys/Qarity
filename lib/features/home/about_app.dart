import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/contact_links.dart';
import '../../core/utils/launch_link.dart';
import '../../models/service_provider_model.dart';
import '../../routes/app_routes.dart';
import '../../widgets/qurity_app_bar.dart';
import '../../widgets/whatsapp_mark.dart';

/// أزرق فيسبوك الرسمي — لا يوجد في الثيم، فلا يُكرَّر نصيًا في الموضعين.
const Color kFacebookBlue = Color(0xFF1877F2);

/// أحمر الإعلان عن الفشل داخل البطاقة (نفس المستعمل في بطاقة دليل الهاتف).
const Color kContactFailureRed = Color(0xFFB71C1C);

/// شعار القرية — نفس الأصل المستعمل في الدخول والإقلاع والهيدر.
const String _kVillageLogoAsset = 'assets/images/Qurity.png';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  /// بيانات المطور والمصمم — تظهر كما هي وتُستعمل في الاتصالات الثلاث.
  static const String developerName = 'م محمد العراقي';
  static const String developerRole = 'مهندس برمجيات ';
  static const String developerPhone = '01032231330';
  static const String developerFacebookUrl =
      'https://www.facebook.com/eleraki2010?locale=ar_AR';

  /// النبذة تحلّ محلّ كتابة الأرقام نصًا: الرموز على الأزرار هي الدليل،
  /// والكلام عن العمل هو ما يُقرأ.
  static const String developerBio =
      'مطور ومصمم تطبيقات ، مهتم بتحويل الأفكار الإبداعية إلى تطبيقات '
      'رقمية عملية وجميلة. أسعى دائماً لتقديم تجربة مستخدم سلسة وعالية '
      'الجودة في كل مشروع أقدمه.';

  static const String developerPhotoAsset = 'assets/images/leader.jpg';

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '…';

  /// الفشل يُعلن داخل بطاقة المطور نفسها (رسالة واحدة لكل حالة)، فلا شريط
  /// سفلي يمرّ بلا قارئ ولا فشل صامت بعد ضغطة زر.
  String? _contactError;

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
    } catch (_) {
      if (mounted) setState(() => _version = 'الإصدار الحالي');
    }
  }

  Future<void> _call(String number) async {
    if (number.isEmpty) {
      _fail('لا يوجد رقم هاتف للاتصال.');
      return;
    }
    final error = await launchContactUrl(
        Uri(scheme: 'tel', path: number).toString(),
        unavailable: 'لا يمكن الاتصال على هذا الجهاز.',
        failed: 'تعذّر بدء المكالمة — أعد المحاولة.',
        mode: LaunchMode.platformDefault);
    if (error == null) {
      _clearError();
    } else {
      _fail(error);
    }
  }

  Future<void> _openWhatsApp(String rawPhone) async {
    final url = egyptianWhatsAppUrl(rawPhone);
    if (url == null) {
      _fail('رقم واتساب غير صالح للمراسلة.');
      return;
    }
    await _openExternal(url,
        unavailable: 'واتساب غير متاح على هذا الجهاز.',
        failed: 'تعذّر فتح المراسلة — تحقّق من الاتصال ثم أعد المحاولة.');
  }

  Future<void> _openFacebook() async {
    await _openExternal(AboutScreen.developerFacebookUrl,
        unavailable: 'فيسبوك غير متاح على هذا الجهاز.',
        failed: 'تعذّر فتح صفحة فيسبوك — تحقّق من الاتصال ثم أعد المحاولة.');
  }

  /// فتح خارجي بلا بوّابة `canLaunchUrl`: الفحص القبلي كان يرجع false على
  /// أندرويد 11+ لأن رؤية حزم واتساب/فيسبوك غير مصرّحة بها، فكان الزر يظهر
  /// «غير متاح على هذا الجهاز» وهو يعمل — والمحاولة المباشرة وحدها دليل صادق.
  Future<void> _openExternal(String url,
      {required String unavailable, required String failed}) async {
    final error = await launchContactUrl(url,
        unavailable: unavailable, failed: failed);
    if (error == null) {
      _clearError();
    } else {
      _fail(error);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() => _contactError = message);
  }

  void _clearError() {
    if (!mounted) return;
    setState(() => _contactError = null);
  }

  /// الصورة تُرى بالحجم الكامل بالسحب والتوسيع — نفس ممرّ شعار الرئيسية.
  void _showDeveloperPhoto() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.86),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Expanded(
              child: InteractiveViewer(
                key: const Key('dev-photo-viewer'),
                maxScale: 4,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset(AboutScreen.developerPhotoAsset,
                        fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white24),
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: const QurityAppBar(title: 'عن التطبيق'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _hero(theme),
          const SizedBox(height: 22),
          _sectionTitle(theme, 'أقسام التطبيق', Icons.grid_view_rounded),
          const SizedBox(height: 10),
          _sectionsGrid(theme),
          const SizedBox(height: 22),
          _sectionTitle(
              theme, 'أحدث ما أُضيف إلى التطبيق', Icons.auto_awesome_rounded),
          const SizedBox(height: 10),
          _changelogCard(theme),
          const SizedBox(height: 22),
          _sectionTitle(theme, 'روابط', Icons.link_rounded),
          const SizedBox(height: 10),
          _linkCard(theme,
              icon: Icons.policy_rounded,
              color: theme.colorScheme.primary,
              title: 'سياسة الخصوصية',
              subtitle: 'كيف نحفظ بياناتك',
              onTap: _showPrivacyDialog),
          const SizedBox(height: 10),
          _linkCard(theme,
              icon: Icons.villa_rounded,
              color: const Color(0xFF5D4037),
              title: 'تعرف على القرية',
              subtitle: 'تاريخها وأرشيفها ومنشآتها',
              onTap: () => Navigator.pushNamed(context, AppRoutes.about)),
          // «بيانات المطور» آخر كارت في الصفحة كما طلب المستخدم.
          const SizedBox(height: 22),
          _sectionTitle(theme, 'بيانات المطور', Icons.code_rounded),
          const SizedBox(height: 10),
          _developerCard(theme),
          const SizedBox(height: 24),
          _footer(theme),
        ],
      ),
    );
  }

  Widget _hero(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE3B873), width: 2.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(_kVillageLogoAsset,
                  fit: BoxFit.contain, cacheWidth: 280),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'تطبيق قرية أبوديشيشة',
            style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w900,
                height: 1.2),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            _version,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3),
          ),
          const SizedBox(height: 14),
          const Text(
            'منصة الخدمات الرقمية للقرية: تاريخ القرية , الأخبار والسوق وحوارات المندرةوالخدمات الطبية والتعليمية '
            'والترفيهية للأطفال — في مكان واحد وبالعربية.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                height: 1.65),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 19, color: theme.colorScheme.primary),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface),
          ),
        ),
      ],
    );
  }

  /// بطاقة المطور: صورته تُكبّر بالضغط، والنبذة تحلّ محلّ الأرقام المكتوبة،
  /// والاتصالات الثلاثة أزرار فعلية برموزها.
  Widget _developerCard(ThemeData theme) {
    final wa = egyptianWhatsAppUrl(AboutScreen.developerPhone);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFFE3B873).withValues(alpha: 0.7), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _developerPhoto(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AboutScreen.developerName,
                      style: TextStyle(
                          fontSize: 17.5,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AboutScreen.developerRole,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _Divider(),
          const SizedBox(height: 12),
          Text(
            AboutScreen.developerBio,
            textAlign: TextAlign.start,
            style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.75,
                color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _action(
                  keyName: 'dev-call',
                  background: kCallButtonColor,
                  onPressed: () => _call(AboutScreen.developerPhone),
                  icon: const Icon(Icons.call_rounded,
                      size: 19, color: Colors.white),
                  label: 'اتصال',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _action(
                  keyName: 'dev-whatsapp',
                  background: kWhatsAppGreen,
                  onPressed: wa == null
                      ? null
                      : () => _openWhatsApp(AboutScreen.developerPhone),
                  icon: const WhatsAppMark(size: 19),
                  label: 'واتساب',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _action(
                  keyName: 'dev-facebook',
                  background: kFacebookBlue,
                  onPressed: _openFacebook,
                  icon: const Icon(Icons.facebook_rounded,
                      size: 20, color: Colors.white),
                  label: 'فيسبوك',
                ),
              ),
            ],
          ),
          if (_contactError != null) ...[
            const SizedBox(height: 12),
            Text(
              _contactError!,
              key: const Key('dev-contact-error'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  /// صورة المطور — الضغط عليها يفتحها بالحجم الكامل قابلة للسحب والتكبير.
  /// البطاقة `Container` بلا `Material`، فاللمس بـ`GestureDetector` لا بـ`InkWell`.
  Widget _developerPhoto() {
    const double side = 68;
    return GestureDetector(
      key: const Key('dev-photo'),
      behavior: HitTestBehavior.opaque,
      onTap: _showDeveloperPhoto,
      child: SizedBox(
        width: side,
        height: side,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: side,
              height: side,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE3B873), width: 2.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  AboutScreen.developerPhotoAsset,
                  fit: BoxFit.cover,
                  cacheWidth: 240,
                ),
              ),
            ),
            PositionedDirectional(
              bottom: 0,
              end: 0,
              child: Container(
                padding: const EdgeInsets.all(3.5),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.6),
                ),
                child: const Icon(Icons.zoom_in_rounded,
                    size: 11, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _action({
    required String keyName,
    required Color background,
    required VoidCallback? onPressed,
    required Widget icon,
    required String label,
  }) {
    return FilledButton.icon(
      key: Key(keyName),
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      icon: icon,
      // الفزرّ يلفّ التسمية بـFlexible بنفسه — تلفيفها ثانيةً يُسقط الشاشة
      // (Competing ParentDataWidgets)، فالتسميات هنا قصيرة عمدًا.
      label: Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
    );
  }

  Widget _sectionsGrid(ThemeData theme) {
    const sections = <_AppSection>[
      _AppSection(AppRoutes.about, 'تعرف على القرية',
          Icons.account_balance_rounded, Color(0xFF5D4037)),
      _AppSection(AppRoutes.newsList, 'أخبار القرية', Icons.newspaper_rounded,
          Color(0xFFD32F2F)),
      _AppSection(AppRoutes.forumPosts, 'مندرة القرية',
          Icons.chat_bubble_rounded, Color(0xFF6A1B9A)),
      _AppSection(AppRoutes.marketTabs, 'سوق القرية', Icons.storefront_rounded,
          Color(0xFFEF6C00)),
      _AppSection(AppRoutes.techniciansDirectory, 'فنيين القرية',
          Icons.plumbing_rounded, Color(0xFF455A64)),
      _AppSection(AppRoutes.legalAdvisor, 'مستشار القرية', Icons.gavel_rounded,
          Color(0xFF006064)),
      _AppSection(AppRoutes.medical, 'الخدمات الطبية',
          Icons.medical_services_rounded, Color(0xFF00897B)),
      _AppSection(AppRoutes.educationalServices, 'الخدمات التعليمية',
          Icons.school_rounded, Color(0xFF1565C0)),
      _AppSection(AppRoutes.farmerServices, 'خدمات المزارع',
          Icons.agriculture_rounded, Color(0xFFAD1457)),
      _AppSection(AppRoutes.villageAds, 'إعلانات القرية',
          Icons.campaign_rounded, Color(0xFF311B92)),
      _AppSection(AppRoutes.lostItems, 'المفقودات', Icons.search_rounded,
          Color(0xFF5E35B1)),
      _AppSection(AppRoutes.phoneDirectory, 'دليل الهاتف',
          Icons.contact_page_rounded, Color(0xFF37474F)),
      _AppSection(AppRoutes.occasionsList, 'المناسبات',
          Icons.celebration_rounded, Color(0xFF00897B)),
      _AppSection(AppRoutes.obituariesList, 'سجل العزاء',
          Icons.volunteer_activism_rounded, Color(0xFF455A64)),
      _AppSection(AppRoutes.children, 'ركن الأطفال', Icons.child_care_rounded,
          Color(0xFFF9A825)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: sections.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 76,
      ),
      itemBuilder: (context, index) {
        final section = sections[index];
        return InkWell(
          key: Key('about-section-${section.route}'),
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(context, section.route),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color:
                      theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: section.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(section.icon, color: section.color, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    section.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _changelogCard(ThemeData theme) {
    final additions = <(IconData, String, Color)>[
      (
        Icons.campaign_rounded,
        'صفحة «إعلانات القرية»: إعلانات تجارية وخدمية وإنشائية بصفحة تفاصيل لكل إعلان.',
        const Color(0xFF311B92)
      ),
      (
        Icons.gavel_rounded,
        'صفحة «مستشار القرية»: سجل محامين واستشارات قانونية ومرجع «نظم القضاء المصري».',
        const Color(0xFF006064)
      ),
      (
        Icons.medical_services_rounded,
        'قسم «المستلزمات الطبية» في الخدمات الطبية، مع النظارات ومعامل التحاليل.',
        const Color(0xFF0097A7)
      ),
      (
        Icons.contact_page_rounded,
        'دليل الهاتف: ترتيب أبجدي عربي، وبطاقة لكل سجل، وزر واتساب برمز واتساب.',
        const Color(0xFF37474F)
      ),
      (
        Icons.volunteer_activism_rounded,
        'سجل العزاء: بطاقة مشاركة مُصمَّمة بخلفيات اختيارية، ومواعيد الصلاة والعزاء، وقرابة تُكتب يدويًا.',
        const Color(0xFF455A64)
      ),
      (
        Icons.school_rounded,
        'خدمات تعليمية: تسجيل كمدرس أو مدرسة مع اختيار المواد والمراحل و«امكانية تدريس خاص».',
        const Color(0xFF1565C0)
      ),
      (
        Icons.storefront_rounded,
        'سوق القرية: المحلات ككرتين في السطر، وعروض تنتهي تلقائيًا، ومنتجات لكل محل.',
        const Color(0xFFEF6C00)
      ),
      (
        Icons.child_care_rounded,
        'ركن الأطفال: تسعة أنشطة تعليمية — حروف وأرقام ووضوء وصلاة وقصص وأخلاق وتلوين.',
        const Color(0xFFF9A825)
      ),
      (
        Icons.edit_note_rounded,
        'المالك يعدّل ويحذف إضافاته في كل قسم، والتعديل يعود إلى مراجعة الإدارة.',
        AppColors.primary
      ),
      (
        Icons.notifications_active_rounded,
        'إشعار فوري عند الموافقة أو النشر، وإعجابات المندرة تصل صاحب المنشور.',
        const Color(0xFFD32F2F)
      ),
      (
        Icons.system_update_alt_rounded,
        'زر «تحديث الآن» ينزّل التحديث ويثبّته فعليًا على الجهاز.',
        const Color(0xFF00897B)
      ),
      (
        Icons.dashboard_customize_rounded,
        'لوحة التحكم: تبويبات مراجعة مصنّفة — المستلزمات الطبية وثلاث تبويبات لدليل الخدمات.',
        const Color(0xFF5E35B1)
      ),
      (
        Icons.view_quilt_rounded,
        'هيدر موحّد لكل الصفحات، وزر إضافة أخضر في الأعلى، وشبكة رئيسية بستة عشر قسمًا.',
        const Color(0xFF6A1B9A)
      ),
      (
        Icons.wifi_off_rounded,
        'العمل بلا اتصال: المحتوى محفوظ محليًا ويظهر فور عودة الشبكة.',
        const Color(0xFF455A64)
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        children: [
          for (var i = 0; i < additions.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: additions[i].$3.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child:
                        Icon(additions[i].$1, size: 17, color: additions[i].$3),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      additions[i].$2,
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          height: 1.6,
                          color: theme.colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
            if (i != additions.length - 1)
              Divider(
                  height: 1,
                  thickness: 1,
                  color: theme.dividerColor.withValues(alpha: 0.35)),
          ],
        ],
      ),
    );
  }

  Widget _linkCard(ThemeData theme,
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12.5,
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded,
                  size: 20, color: theme.hintColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer(ThemeData theme) {
    return Column(
      children: [
        const _Divider(),
        const SizedBox(height: 12),
        Text(
          'صُمّم ونُفّذ بعناية لخدمة أهالي قرية أبوديشيشة\n${AboutScreen.developerRole}: ${AboutScreen.developerName}',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.7,
              color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('سياسة الخصوصية'),
        content: const Text(
          'نحرص على حماية بياناتك الشخصية؛ تُستخدم اسمك وصورتك ورقمك لإظهار إضافاتك والتواصل داخل القرية فقط، '
          'ولا تُشارك مع أطراف خارجية دون موافقتك.',
          style: TextStyle(height: 1.7),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('حسناً')),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Divider(height: 1, thickness: 1);
}

class _AppSection {
  const _AppSection(this.route, this.title, this.icon, this.color);
  final String route;
  final String title;
  final IconData icon;
  final Color color;
}
