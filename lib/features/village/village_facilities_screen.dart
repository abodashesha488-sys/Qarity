import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/launch_link.dart';
import '../../models/village_content_models.dart';
import '../../services/share_service.dart';
import '../../services/village_content_service.dart';
import '../../widgets/qurity_app_bar.dart';
import 'village_content_admin.dart';

/// بيانات المنشأة الأساسية الثابتة في قرية أبوديشيشة
class FacilityInfo {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> services;
  final String workingHours;
  final String location;
  final String phone;
  final String typeKey;

  const FacilityInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.services,
    required this.workingHours,
    required this.location,
    required this.phone,
    required this.typeKey,
  });
}

/// قائمة المنشآت الثمانية المعتمدة لقرية أبوديشيشة
const List<FacilityInfo> kVillageFacilities = [
  FacilityInfo(
    id: 'youth_center',
    title: 'مركز الشباب',
    subtitle: 'أنشطة رياضية وثقافية',
    description:
        'مركز شباب قرية أبوديشيشة، الملاذ الرياضي والثقافي لشباب وأشبال القرية، يضم ملاعب لممارسة كرة القدم والأنشطة الرياضية، وينظم الدورات والمسابقات الثقافية والاجتماعية على مدار العام.',
    icon: Icons.sports_soccer_rounded,
    color: Color(0xFF2E7D32),
    typeKey: InstitutionType.youth,
    services: [
      'تنظيم الدورات الرمضانية والبطولات الرياضية',
      'تدريب فرق كرة القدم للناشئين والشباب',
      'ندوات توعوية وأنشطة ثقافية واجتماعية',
      'استضافة الفعاليات والمبادرات الشبابية بالقرية',
    ],
    workingHours: 'يومياً: ٨:٠٠ ص - ١٠:٠٠ م',
    location: 'قرية أبوديشيشة - المنطقة الرياضية',
    phone: '',
  ),
  FacilityInfo(
    id: 'health_unit',
    title: 'الوحدة الصحية',
    subtitle: 'رعاية صحية وطب أسرة',
    description:
        'الوحدة الصحية لقرية أبوديشيشة، تقدم خدمات الرعاية الصحية الأولية والتطعيمات الدورية للأطفال ومتابعة الحوامل وصرف الأدوية الأساسية والمبادرات الرئاسية الصحية لأهالي القرية.',
    icon: Icons.local_hospital_rounded,
    color: Color(0xFFC62828),
    typeKey: InstitutionType.health,
    services: [
      'التطعيمات الدورية الإلزامية للأطفال وحديثي الولادة',
      'متابعة صحة ورعاية السيدات الحوامل والولادة',
      'صرف الألبان المدعمة والأدوية الأساسية',
      'مبادرات فحص الأمراض المزمنة وصحة المرأة والاعتلال الكلوي',
      'خدمات الإسعاف الأولي والعيادات العامة',
    ],
    workingHours: 'السبت - الخميس: ٨:٠٠ ص - ٢:٠٠ م (طوارئ على مدار الساعة)',
    location: 'قرية أبوديشيشة - بجوار الكوبري وطريق القرية الرئيسي',
    phone: '',
  ),
  FacilityInfo(
    id: 'post_office',
    title: 'مكتب البريد',
    subtitle: 'خدمات بريدية وحكومية ومالية',
    description:
        'مكتب بريد قرية أبوديشيشة، يقدم كافة المعاملات المالية والبريدية، وصرف المعاشات وتكافل وكرامة، وفتح حسابات التوفير، ودفع فواتير الخدمات العامة واستخراج بطاقات الدفع الإلكتروني.',
    icon: Icons.local_post_office_rounded,
    color: Color(0xFF1565C0),
    typeKey: InstitutionType.post,
    services: [
      'صرف المعاشات الشهرية ومعاشات تكافل وكرامة',
      'خدمات حسابات التوفير والإيداع والسحب البريدي',
      'إرسال واستلام الحوالات المالية الفورية والفورية الدولية',
      'سداد فواتير الكهرباء والغاز والمياه وشحن الكروت',
      'إرسال واستقبال الطرود والخطابات المسجلة',
    ],
    workingHours: 'الأحد - الخميس: ٨:٠٠ ص - ٣:٠٠ م',
    location: 'قرية أبوديشيشة - الشارع العام',
    phone: '16789',
  ),
  FacilityInfo(
    id: 'agricultural_coop',
    title: 'الجمعية الزراعية',
    subtitle: 'خدمات الفلاح ومستلزمات الإنتاج',
    description:
        'الجمعية التعاونية الزراعية بقرية أبوديشيشة، مظلة المزارع والفلاح، توفر الأسمدة الزراعية المدعمة، وبطاقات الحيازة الإلكترونية (كارت الفلاح)، وتقدم الإرشاد الزراعي لمكافحة الآفات وتحسين الإنتاجية.',
    icon: Icons.agriculture_rounded,
    color: Color(0xFFEF6C00),
    typeKey: InstitutionType.agri,
    services: [
      'توزيع حصص الأسمدة المدعومة للمزارعين',
      'إصدار وتجديد وتسليم كارت الفلاح الذكي',
      'توفير التقاوي المعتمدة والمبيدات الحشرية الآمنة',
      'حصر المساحات المنزرعة وتسجيل الحيازات الزراعية',
      'الإرشاد الزراعي الدوري للمحاصيل الشتوية والصيفية',
    ],
    workingHours: 'السبت - الخميس: ٨:٠٠ ص - ٢:٠٠ م',
    location: 'قرية أبوديشيشة - وسط القرية بجوار الأراضي الزراعية',
    phone: '',
  ),
  FacilityInfo(
    id: 'schools',
    title: 'مدارس القرية',
    subtitle: 'التعليم العام والأساسي',
    description:
        'مدارس التعليم العام والأساسي بقرية أبوديشيشة، تشتمل على المدارس الابتدائية والإعدادية لتعليم أبناء وبنات القرية، وترعى الأنشطة المدرسية والتعليمية والمسابقات التربوية.',
    icon: Icons.school_rounded,
    color: Color(0xFF0277BD),
    typeKey: InstitutionType.schools,
    services: [
      'التعليم الابتدائي والإعدادي المعتمد',
      'تسجيل وقبول التلاميذ الجدد ورياض الأطفال',
      'رعاية الموهوبين والأنشطة الرياضية والمدرسية',
      'مجموعات التقوية المدرسية ودعم الطلاب',
      'مجالس الآباء والمعلمين لتعزيز التواصل المجتمعي',
    ],
    workingHours: 'خلال العام الدراسي: ٧:٣٠ ص - ٢:٠٠ م',
    location: 'قرية أبوديشيشة - مجمع المدارس',
    phone: '',
  ),
  FacilityInfo(
    id: 'azhar_institutes',
    title: 'المعاهد الدينية',
    subtitle: 'التعليم الأزهري الشريف',
    description:
        'المعاهد الأزهرية ومكاتب تحفيظ القرآن الكريم بقرية أبوديشيشة، تخرّج أجيالاً حافظين لكتاب الله متسلحين بالعلوم الشرعية والعربية والعلوم العامة على منهج الأزهر الشريف الوسطي المستنير.',
    icon: Icons.menu_book_rounded,
    color: Color(0xFF00695C),
    typeKey: InstitutionType.azhar,
    services: [
      'التعليم الأزهري (الابتدائي والإعدادي)',
      'تحفيظ وتجويد القرآن الكريم والحديث النبوي الشريف',
      'تدريس العلوم الشرعية والعربية واللغات',
      'المسابقات السنوية في حفظ وتلاوة كتاب الله',
    ],
    workingHours: 'الأحد - الخميس: ٧:٣٠ ص - ٢:٠٠ م',
    location: 'قرية أبوديشيشة - مجمع المعاهد الأزهرية',
    phone: '',
  ),
  FacilityInfo(
    id: 'mosques',
    title: 'مساجد القرية',
    subtitle: 'بيوت الله ومجالس الذكر',
    description:
        'مساجد ومصليات قرية أبوديشيشة، منارات الهدى والسكينة والعبادة، تقام فيها الصلوات الخمس والجمعة، وحلقات تحفيظ القرآن ودروس العلم، وملتقيات الخير والمواساة لأهل القرية.',
    icon: Icons.mosque_rounded,
    color: Color(0xFF00897B),
    typeKey: InstitutionType.mosque,
    services: [
      'إقامة الصلوات الخمس وصلاة الجمعة والتراويح',
      'دروس الوعظ والإرشاد وخطب الجمعة المعتمدة',
      'مكاتب وحلقات تحفيظ القرآن الكريم للأطفال',
      'مصليات العيدين والأنشطة الدينية والمجتمعية',
    ],
    workingHours: 'مفتوحة طوال اليوم لأوقات الصلوات',
    location: 'موزعة في كافة أنحاء وأحياء قرية أبوديشيشة',
    phone: '',
  ),
  FacilityInfo(
    id: 'awqaf_office',
    title: 'مكتب الأوقاف',
    subtitle: 'إدارة الشؤون الدينية والمساجد',
    description:
        'مكتب شؤون الأوقاف المسؤول عن رعاية وإشراف مساجد القرية وملحقاتها، ومتابعة الأئمة والخطباء ومقيمي الشعائر، وتنظيم القوافل والدروس الدعوية وتوثيق الوقف الخيري.',
    icon: Icons.account_balance_rounded,
    color: Color(0xFF6A1B9A),
    typeKey: InstitutionType.awqaf,
    services: [
      'الإشراف الدعوي والإداري على مساجد القرية',
      'تنظيم قوافل الوعظ والخطابة للأئمة والعلماء',
      'توفير احتياجات المساجد وصيانتها بالتنسيق مع الوزارة',
      'تسجيل ومتابعة مكاتب تحفيظ القرآن المعتمدة بالأوقاف',
    ],
    workingHours: 'الأحد - الخميس: ٨:٣٠ ص - ٢:٠٠ م',
    location: 'قرية أبوديشيشة - مكتب التفتيش الوقفي',
    phone: '',
  ),
];

/// بوابة «منشأة القرية» — شبكة أيقونات 2×4 تضم المنشآت الـ 8 الرئيسية بالقرية
class VillageFacilitiesScreen extends StatelessWidget {
  const VillageFacilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const QurityAppBar(
        title: 'منشأة القرية',
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        const spacing = 10.0;
        const hPadding = 16.0;
        // نسبة 0.89 تطابق تناسب بوابتي الخدمات الطبية وخدمات المزارع تماماً
        const childAspectRatio = 0.89;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.35)
                        : theme.colorScheme.primary.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                      width: 1.1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.domain_rounded,
                          color: theme.colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'صروح ومنشآت قرية أبوديشيشة',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: theme.colorScheme.primary,
                                fontSize: 14.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'المرافق الخدمية والتعليمية والصحية والشبابية والدينية',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(hPadding, 8, hPadding, 24),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = kVillageFacilities[index];
                    return _FacilityGridTile(
                      facility: item,
                      index: index,
                    );
                  },
                  childCount: kVillageFacilities.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: childAspectRatio,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// بطاقة المنشأة في الشبكة 2×4
class _FacilityGridTile extends StatelessWidget {
  const _FacilityGridTile({
    required this.facility,
    required this.index,
  });

  final FacilityInfo facility;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = facility.color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FacilityDetailScreen(facility: facility),
            ),
          );
        },
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: isDark
                  ? [
                      color.withValues(alpha: 0.16),
                      theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.4),
                    ]
                  : [
                      color.withValues(alpha: 0.10),
                      Colors.white,
                    ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.35 : 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.18 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // حاوية الأيقونة ثلاثية الأبعاد
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.95),
                        color,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    facility.icon,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                // اسم المنشأة
                Text(
                  facility.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 3),
                // الوصف المختصر
                Text(
                  facility.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? theme.colorScheme.onSurfaceVariant
                        : color.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 8),
                // زر الدخول الصغير
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'عرض التفاصيل',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 9,
                        color: color,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 250.ms, delay: (index * 40).ms).slideY(
          begin: 0.06,
          end: 0,
          duration: 250.ms,
          curve: Curves.easeOutQuad,
        );
  }
}

/// شاشة تفاصيل المنشأة
class FacilityDetailScreen extends StatefulWidget {
  const FacilityDetailScreen({super.key, required this.facility});

  final FacilityInfo facility;

  @override
  State<FacilityDetailScreen> createState() => _FacilityDetailScreenState();
}

class _FacilityDetailScreenState extends State<FacilityDetailScreen> {
  VillageContentService? _service;
  Stream<List<VillageInstitution>>? _institutionsStream;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    try {
      _service = VillageContentService();
      _institutionsStream = _service!.watchInstitutions();
      _checkAdmin();
    } catch (_) {
      // Safe fallback when running in tests without initialized Firebase
    }
  }

  Future<void> _checkAdmin() async {
    try {
      final admin = await canManageVillageContent();
      if (mounted) setState(() => _isAdmin = admin);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final f = widget.facility;
    final color = f.color;

    return Scaffold(
      appBar: QurityAppBar(
        title: f.title,
        actions: [
          if (_isAdmin && _institutionsStream != null)
            IconButton(
              tooltip: 'إدارة ${f.title}',
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => manageVillageContent<VillageInstitution>(
                context,
                title: f.title,
                accent: color,
                stream: _institutionsStream!,
                nameOf: (n) => n.name,
                subtitleOf: (n) => InstitutionType.label(n.type),
                remove: (id) =>
                    _service?.deleteDoc('village_institutions', id) ??
                    Future.value(),
                formBuilder: (ctx, editing) => InstitutionForm(
                  editing: editing ??
                      VillageInstitution(
                        name: '',
                        type: f.typeKey,
                        location: f.location,
                        workingHours: f.workingHours,
                        phone: f.phone,
                      ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'مشاركة بيانات المنشأة',
            icon: const Icon(Icons.share_rounded),
            onPressed: () {
              final body = [
                f.subtitle,
                '📍 الموقع: ${f.location}',
                '⏰ مواعيد العمل: ${f.workingHours}',
                if (f.phone.isNotEmpty) '📞 الهاتف: ${f.phone}',
                '',
                f.description,
                '',
                'تطبيق قرية أبوديشيشة',
              ].join('\n');
              ShareService.shareText(
                title: 'منشآت قرية أبوديشيشة - ${f.title}',
                body: body,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          // البطاقة العلوية الكبرى
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: isDark ? 0.35 : 0.14),
                  color.withValues(alpha: isDark ? 0.15 : 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(f.icon, size: 36, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        f.subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'قرية أبوديشيشة',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // بطاقة النبذة التعريفية
          _buildInfoSection(
            theme: theme,
            title: 'نبذة عن المنشأة',
            icon: Icons.info_outline_rounded,
            color: color,
            child: Text(
              f.description,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.65,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // بطاقة معلومات الاتصال ومواعيد العمل
          _buildInfoSection(
            theme: theme,
            title: 'بيانات الخدمة والموقع',
            icon: Icons.place_rounded,
            color: color,
            child: Column(
              children: [
                _buildDataRow(
                  icon: Icons.location_on_outlined,
                  color: color,
                  label: 'الموقع داخل القرية',
                  value: f.location,
                ),
                const Divider(height: 18),
                _buildDataRow(
                  icon: Icons.access_time_rounded,
                  color: color,
                  label: 'مواعيد العمل الرسمية',
                  value: f.workingHours,
                ),
                if (f.phone.isNotEmpty) ...[
                  const Divider(height: 18),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            Icon(Icons.phone_rounded, size: 16, color: color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'رقم التواصل / الخط الساخن',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              f.phone,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: color,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _callPhone(f.phone),
                        icon: const Icon(Icons.call_rounded, size: 16),
                        label: const Text('اتصال',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // الخدمات المقدمة
          _buildInfoSection(
            theme: theme,
            title: 'أبرز الخدمات والأنشطة',
            icon: Icons.checklist_rounded,
            color: color,
            child: Column(
              children: [
                for (final s in f.services) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // السجلات المسجلة في قاعدة بيانات المنشآت لهذا القسم
          if (_institutionsStream != null)
            StreamBuilder<List<VillageInstitution>>(
              stream: _institutionsStream,
            builder: (context, snap) {
              if (!snap.hasData) return const SizedBox.shrink();
              final all = snap.data!;
              final matched =
                  all.where((item) => item.type == f.typeKey).toList();

              if (matched.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.list_alt_rounded, color: color, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'السجلات والوحدات المعتمدة بالقرية (${matched.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final item in matched) ...[
                    Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: color.withValues(alpha: 0.25),
                          width: 1.1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            if (item.imageUrl.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: item.imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    width: 50,
                                    height: 50,
                                    color: color.withValues(alpha: 0.1),
                                    child: Icon(f.icon, color: color, size: 24),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(f.icon, color: color, size: 24),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  if (item.description.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                  if (item.location.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Icon(Icons.place_outlined,
                                            size: 12, color: color),
                                        const SizedBox(width: 3),
                                        Text(
                                          item.location,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (item.phone.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.phone_in_talk_rounded,
                                    color: color),
                                onPressed: () => _callPhone(item.phone),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _callPhone(String rawPhone) async {
    final cleaned = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: cleaned);
    await launchContactUrl(
      uri.toString(),
      unavailable: 'تعذّر الاتصال على هذا الجهاز',
      failed: 'فشل بدء المكالمة',
      mode: LaunchMode.platformDefault,
    );
  }

  Widget _buildInfoSection({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.28)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.28 : 0.18),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDataRow({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
