import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/helpers.dart';
import '../../core/utils/launch_link.dart';
import '../../models/village_content_models.dart';
import '../../services/share_service.dart';
import '../../services/village_content_service.dart';
import '../../widgets/qurity_app_bar.dart';
import 'village_content_admin.dart';

/// بيانات المنشأة الأساسية الثابتة في قرية أبودشيشة
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

/// قائمة المنشآت الثمانية المعتمدة لقرية أبودشيشة
const List<FacilityInfo> kVillageFacilities = [
  FacilityInfo(
    id: 'youth_center',
    title: 'مركز الشباب',
    subtitle: 'أنشطة رياضية وثقافية',
    description:
        'مركز شباب قرية أبودشيشة، الملاذ الرياضي والثقافي لشباب وأشبال القرية، يضم ملاعب لممارسة كرة القدم والأنشطة الرياضية، وينظم الدورات والمسابقات الثقافية والاجتماعية على مدار العام.',
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
    location: 'قرية أبودشيشة - المنطقة الرياضية',
    phone: '',
  ),
  FacilityInfo(
    id: 'health_unit',
    title: 'الوحدة الصحية',
    subtitle: 'رعاية صحية وطب أسرة',
    description:
        'الوحدة الصحية لقرية أبودشيشة، تقدم خدمات الرعاية الصحية الأولية والتطعيمات الدورية للأطفال ومتابعة الحوامل وصرف الأدوية الأساسية والمبادرات الرئاسية الصحية لأهالي القرية.',
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
    location: 'قرية أبودشيشة - بجوار الكوبري وطريق القرية الرئيسي',
    phone: '',
  ),
  FacilityInfo(
    id: 'post_office',
    title: 'مكتب البريد',
    subtitle: 'خدمات بريدية وحكومية ومالية',
    description:
        'مكتب بريد قرية أبودشيشة، يقدم كافة المعاملات المالية والبريدية، وصرف المعاشات وتكافل وكرامة، وفتح حسابات التوفير، ودفع فواتير الخدمات العامة واستخراج بطاقات الدفع الإلكتروني.',
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
    location: 'قرية أبودشيشة - الشارع العام',
    phone: '16789',
  ),
  FacilityInfo(
    id: 'agricultural_coop',
    title: 'الجمعية الزراعية',
    subtitle: 'خدمات الفلاح ومستلزمات الإنتاج',
    description:
        'الجمعية التعاونية الزراعية بقرية أبودشيشة، مظلة المزارع والفلاح، توفر الأسمدة الزراعية المدعمة، وبطاقات الحيازة الإلكترونية (كارت الفلاح)، وتقدم الإرشاد الزراعي لمكافحة الآفات وتحسين الإنتاجية.',
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
    location: 'قرية أبودشيشة - وسط القرية بجوار الأراضي الزراعية',
    phone: '',
  ),
  FacilityInfo(
    id: 'schools',
    title: 'مدارس القرية',
    subtitle: 'التعليم العام والأساسي',
    description:
        'مدارس التعليم العام والأساسي بقرية أبودشيشة، تشتمل على المدارس الابتدائية والإعدادية لتعليم أبناء وبنات القرية، وترعى الأنشطة المدرسية والتعليمية والمسابقات التربوية.',
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
    location: 'قرية أبودشيشة - مجمع المدارس',
    phone: '',
  ),
  FacilityInfo(
    id: 'azhar_institutes',
    title: 'المعاهد الدينية',
    subtitle: 'التعليم الأزهري الشريف',
    description:
        'المعاهد الأزهرية ومكاتب تحفيظ القرآن الكريم بقرية أبودشيشة، تخرّج أجيالاً حافظين لكتاب الله متسلحين بالعلوم الشرعية والعربية والعلوم العامة على منهج الأزهر الشريف الوسطي المستنير.',
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
    location: 'قرية أبودشيشة - مجمع المعاهد الأزهرية',
    phone: '',
  ),
  FacilityInfo(
    id: 'mosques',
    title: 'مساجد القرية',
    subtitle: 'بيوت الله ومجالس الذكر',
    description:
        'مساجد ومصليات قرية أبودشيشة، منارات الهدى والسكينة والعبادة، تقام فيها الصلوات الخمس والجمعة، وحلقات تحفيظ القرآن ودروس العلم، وملتقيات الخير والمواساة لأهل القرية.',
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
    location: 'موزعة في كافة أنحاء وأحياء قرية أبودشيشة',
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
    location: 'قرية أبودشيشة - مكتب التفتيش الوقفي',
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
                              'صروح ومنشآت قرية أبودشيشة',
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

/// شاشة تفاصيل المنشأة مع إمكانية تعديل بياناتها وإدارة سجلاتها المخصصة
class FacilityDetailScreen extends StatefulWidget {
  const FacilityDetailScreen({super.key, required this.facility});

  final FacilityInfo facility;

  @override
  State<FacilityDetailScreen> createState() => _FacilityDetailScreenState();
}

class _FacilityDetailScreenState extends State<FacilityDetailScreen> {
  VillageContentService? _service;
  Stream<List<VillageInstitution>>? _institutionsStream;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _metaStream;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    try {
      _service = VillageContentService();
      _institutionsStream = _service!.watchInstitutions();
      _metaStream = FirebaseFirestore.instance
          .collection('village_institutions')
          .doc('facility_meta_${widget.facility.id}')
          .snapshots();
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

  Future<void> _openFacilityEditSheet({
    required String currentDesc,
    required String currentLocation,
    required String currentHours,
    required String currentPhone,
    required String currentSupervisor,
    required List<String> currentServices,
    required String currentImage,
  }) async {
    final f = widget.facility;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 14,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: _FacilityEditForm(
            facility: f,
            initialDesc: currentDesc,
            initialLocation: currentLocation,
            initialHours: currentHours,
            initialPhone: currentPhone,
            initialSupervisor: currentSupervisor,
            initialServices: currentServices,
            initialImage: currentImage,
          ),
        ),
      ),
    );
  }

  Future<void> _openRecordFormSheet([VillageInstitution? editing]) async {
    final f = widget.facility;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 14,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: _FacilityRecordForm(
            facility: f,
            editing: editing,
          ),
        ),
      ),
    );
  }

  void _showRecordDetail(VillageInstitution item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _FacilityRecordDetailSheet(
        facility: widget.facility,
        item: item,
        isAdmin: _isAdmin,
        onEdit: () {
          Navigator.pop(ctx);
          _openRecordFormSheet(item);
        },
        onDelete: () async {
          Navigator.pop(ctx);
          final ok = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('تأكيد الحذف'),
              content: Text('هل أنت متأكد من حذف «${item.name}» نهائياً؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('حذف'),
                ),
              ],
            ),
          );
          if (ok == true) {
            await _service?.deleteDoc('village_institutions', item.id);
            if (mounted) AppHelpers.showToast('تم حذف السجل بنجاح');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final f = widget.facility;
    final color = f.color;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _metaStream,
      builder: (context, metaSnap) {
        final metaData = metaSnap.data?.data();

        final desc =
            (metaData?['description'] as String?)?.trim().isNotEmpty == true
                ? (metaData!['description'] as String).trim()
                : f.description;
        final loc =
            (metaData?['location'] as String?)?.trim().isNotEmpty == true
                ? (metaData!['location'] as String).trim()
                : f.location;
        final hours =
            (metaData?['workingHours'] as String?)?.trim().isNotEmpty == true
                ? (metaData!['workingHours'] as String).trim()
                : f.workingHours;
        final phone = (metaData?['phone'] as String?)?.trim().isNotEmpty == true
            ? (metaData!['phone'] as String).trim()
            : f.phone;
        final supervisor = (metaData?['supervisor'] as String?)?.trim() ?? '';
        final imageUrl = (metaData?['imageUrl'] as String?)?.trim() ?? '';
        final rawServices = metaData?['services'] as List<dynamic>?;
        final services = (rawServices != null && rawServices.isNotEmpty)
            ? rawServices.map((e) => e.toString()).toList()
            : f.services;

        return Scaffold(
          appBar: QurityAppBar(
            title: f.title,
            actions: [
              if (_isAdmin) ...[
                IconButton(
                  tooltip: 'تعديل محتوى وبيانات ${f.title}',
                  icon: const Icon(Icons.edit_note_rounded, color: Colors.amber),
                  onPressed: () => _openFacilityEditSheet(
                    currentDesc: desc,
                    currentLocation: loc,
                    currentHours: hours,
                    currentPhone: phone,
                    currentSupervisor: supervisor,
                    currentServices: services,
                    currentImage: imageUrl,
                  ),
                ),
                IconButton(
                  tooltip: 'إضافة سجل جديد في ${f.title}',
                  icon: const Icon(Icons.add_circle_outline_rounded,
                      color: Colors.amber),
                  onPressed: () => _openRecordFormSheet(),
                ),
              ],
              IconButton(
                tooltip: 'مشاركة بيانات المنشأة',
                icon: const Icon(Icons.share_rounded),
                onPressed: () {
                  final body = [
                    f.subtitle,
                    '📍 الموقع: $loc',
                    '⏰ مواعيد العمل: $hours',
                    if (phone.isNotEmpty) '📞 الهاتف: $phone',
                    if (supervisor.isNotEmpty) '👤 المشرف: $supervisor',
                    '',
                    desc,
                    '',
                    'تطبيق قرية أبودشيشة',
                  ].join('\n');
                  ShareService.shareText(
                    title: 'منشآت قرية أبودشيشة - ${f.title}',
                    body: body,
                    imageUrls: imageUrl.isNotEmpty ? [imageUrl] : const [],
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
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'قرية أبودشيشة',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: color,
                                  ),
                                ),
                              ),
                              if (supervisor.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'إشراف: $supervisor',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: theme
                                          .colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (imageUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // بطاقة النبذة التعريفية
              _buildInfoSection(
                theme: theme,
                title: 'نبذة عن المنشأة',
                icon: Icons.info_outline_rounded,
                color: color,
                child: Text(
                  desc,
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
                      value: loc,
                    ),
                    const Divider(height: 18),
                    _buildDataRow(
                      icon: Icons.access_time_rounded,
                      color: color,
                      label: 'مواعيد العمل الرسمية',
                      value: hours,
                    ),
                    if (phone.isNotEmpty) ...[
                      const Divider(height: 18),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.phone_rounded,
                                size: 16, color: color),
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
                                  phone,
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
                            onPressed: () => _callPhone(phone),
                            icon: const Icon(Icons.call_rounded, size: 16),
                            label: const Text('اتصال',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800)),
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
                    for (final s in services) ...[
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

              // السجلات والوحدات المسجلة في قاعدة بيانات المنشآت لهذا القسم
              if (_institutionsStream != null)
                StreamBuilder<List<VillageInstitution>>(
                  stream: _institutionsStream,
                  builder: (context, snap) {
                    if (!snap.hasData) return const SizedBox.shrink();
                    final all = snap.data!;
                    final matched = all
                        .where((item) =>
                            item.type == f.typeKey &&
                            !item.id.startsWith('facility_meta_'))
                        .toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.list_alt_rounded,
                                color: color, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'السجلات والوحدات التابعة (${matched.length})',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w900,
                                color: color,
                              ),
                            ),
                            const Spacer(),
                            if (_isAdmin)
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: color,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('إضافة سجل',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800)),
                                onPressed: () => _openRecordFormSheet(),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (matched.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: color.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.folder_open_rounded,
                                    size: 32, color: color.withValues(alpha: 0.6)),
                                const SizedBox(height: 6),
                                Text(
                                  'لا توجد سجلات مضافة حالياً في ${f.title}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (_isAdmin) ...[
                                  const SizedBox(height: 8),
                                  FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: color,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 6),
                                    ),
                                    onPressed: () => _openRecordFormSheet(),
                                    icon: const Icon(Icons.add_rounded, size: 16),
                                    label: const Text('إضافة أول سجل الآن',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800)),
                                  ),
                                ],
                              ],
                            ),
                          )
                        else
                          for (final item in matched) ...[
                            Card(
                              elevation: 1,
                              margin: const EdgeInsets.only(bottom: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: color.withValues(alpha: 0.25),
                                  width: 1.1,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _showRecordDetail(item),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      if (item.imageUrl.isNotEmpty)
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: CachedNetworkImage(
                                            imageUrl: item.imageUrl,
                                            width: 56,
                                            height: 56,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) =>
                                                Container(
                                              width: 56,
                                              height: 56,
                                              color: color.withValues(alpha: 0.1),
                                              child: Icon(f.icon,
                                                  color: color, size: 24),
                                            ),
                                          ),
                                        )
                                      else
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(f.icon,
                                              color: color, size: 26),
                                        ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14,
                                              ),
                                            ),
                                            if (item.supervisor.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                item.supervisor,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w700,
                                                  color: color,
                                                ),
                                              ),
                                            ],
                                            if (item.stage.isNotEmpty ||
                                                item.location.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  if (item.stage.isNotEmpty) ...[
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: color.withValues(
                                                            alpha: 0.10),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      child: Text(
                                                        item.stage,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: color,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                  ],
                                                  if (item.location.isNotEmpty)
                                                    Expanded(
                                                      child: Text(
                                                        item.location,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: theme
                                                              .colorScheme
                                                              .onSurfaceVariant,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: 14,
                                          color: Colors.grey),
                                    ],
                                  ),
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
      },
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

/// نافذة عرض تفاصيل السجل بالكامل عند الضغط عليه
class _FacilityRecordDetailSheet extends StatelessWidget {
  const _FacilityRecordDetailSheet({
    required this.facility,
    required this.item,
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
  });

  final FacilityInfo facility;
  final VillageInstitution item;
  final bool isAdmin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = facility.color;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(facility.icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '${facility.title} — قرية أبودشيشة',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 14),

              if (item.imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // بطاقات البيانات التفصيلية المخصصة
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (item.supervisor.isNotEmpty)
                    _DetailChip(
                      icon: Icons.person_rounded,
                      label: item.supervisor,
                      color: color,
                    ),
                  if (item.stage.isNotEmpty)
                    _DetailChip(
                      icon: Icons.category_rounded,
                      label: item.stage,
                      color: color,
                    ),
                  if (item.capacity.isNotEmpty)
                    _DetailChip(
                      icon: Icons.groups_rounded,
                      label: item.capacity,
                      color: color,
                    ),
                  if (item.fees.isNotEmpty)
                    _DetailChip(
                      icon: Icons.payments_outlined,
                      label: item.fees,
                      color: color,
                    ),
                  if (item.location.isNotEmpty)
                    _DetailChip(
                      icon: Icons.place_rounded,
                      label: item.location,
                      color: color,
                    ),
                  if (item.workingHours.isNotEmpty)
                    _DetailChip(
                      icon: Icons.access_time_rounded,
                      label: item.workingHours,
                      color: color,
                    ),
                ],
              ),
              const SizedBox(height: 14),

              if (item.description.isNotEmpty) ...[
                const Text(
                  'التفاصيل والنبذة:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.15)),
                  ),
                  child: Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],

              if (item.services.isNotEmpty) ...[
                const Text(
                  'الخدمات والأنشطة المقدمة:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Column(
                  children: [
                    for (final s in item.services)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s,
                                style: const TextStyle(
                                    fontSize: 12.5, height: 1.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // أزرار العمل: اتصال، مشاركة، وإدارة
              Row(
                children: [
                  if (item.phone.isNotEmpty) ...[
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: color),
                        onPressed: () {
                          final cleaned =
                              item.phone.replaceAll(RegExp(r'[^0-9+]'), '');
                          if (cleaned.isNotEmpty) {
                            launchUrl(Uri(scheme: 'tel', path: cleaned));
                          }
                        },
                        icon: const Icon(Icons.call_rounded, size: 16),
                        label: const Text('اتصال مباشر'),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: color),
                      onPressed: () {
                        ShareService.shareText(
                          title: '${facility.title} - ${item.name}',
                          body: [
                            if (item.supervisor.isNotEmpty) item.supervisor,
                            if (item.location.isNotEmpty)
                              '📍 الموقع: ${item.location}',
                            if (item.workingHours.isNotEmpty)
                              '⏰ المواعيد: ${item.workingHours}',
                            if (item.phone.isNotEmpty) '📞 الهاتف: ${item.phone}',
                            '',
                            item.description,
                          ].join('\n'),
                          imageUrls:
                              item.imageUrl.isNotEmpty ? [item.imageUrl] : const [],
                        );
                      },
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: const Text('مشاركة'),
                    ),
                  ),
                ],
              ),

              if (isAdmin) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text('تعديل هذا السجل'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style:
                          FilledButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('حذف'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// نموذج تعديل بيانات المنشأة الأساسية بالصفحة
class _FacilityEditForm extends StatefulWidget {
  const _FacilityEditForm({
    required this.facility,
    required this.initialDesc,
    required this.initialLocation,
    required this.initialHours,
    required this.initialPhone,
    required this.initialSupervisor,
    required this.initialServices,
    required this.initialImage,
  });

  final FacilityInfo facility;
  final String initialDesc;
  final String initialLocation;
  final String initialHours;
  final String initialPhone;
  final String initialSupervisor;
  final List<String> initialServices;
  final String initialImage;

  @override
  State<_FacilityEditForm> createState() => _FacilityEditFormState();
}

class _FacilityEditFormState extends State<_FacilityEditForm> {
  late final _desc = TextEditingController(text: widget.initialDesc);
  late final _location = TextEditingController(text: widget.initialLocation);
  late final _hours = TextEditingController(text: widget.initialHours);
  late final _phone = TextEditingController(text: widget.initialPhone);
  late final _supervisor =
      TextEditingController(text: widget.initialSupervisor);
  late final _services =
      TextEditingController(text: widget.initialServices.join('\n'));
  late String _imageUrl = widget.initialImage;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _desc.dispose();
    _location.dispose();
    _hours.dispose();
    _phone.dispose();
    _supervisor.dispose();
    _services.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final sList = _services.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await FirebaseFirestore.instance
          .collection('village_institutions')
          .doc('facility_meta_${widget.facility.id}')
          .set({
        'type': 'facility_meta',
        'facilityId': widget.facility.id,
        'description': _desc.text.trim(),
        'location': _location.text.trim(),
        'workingHours': _hours.text.trim(),
        'phone': _phone.text.trim(),
        'supervisor': _supervisor.text.trim(),
        'services': sList,
        'imageUrl': _imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context);
      AppHelpers.showToast('تم حفظ تعديلات المنشأة بنجاح');
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'تعذر الحفظ: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.edit_note_rounded,
                color: widget.facility.color, size: 22),
            const SizedBox(width: 8),
            Text(
              'تعديل بيانات ${widget.facility.title}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: _supervisor,
          decoration: vdec('مثال: أ/ أحمد محمد (مدير المنشأة)',
              label: 'المشرف / المدير المسؤول'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _location,
          decoration: vdec('الموقع داخل القرية', label: 'الموقع'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _hours,
          decoration: vdec('مواعيد العمل الرسمية', label: 'مواعيد العمل'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: vdec('رقم التواصل / الخط الساخن', label: 'الهاتف'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _desc,
          maxLines: 3,
          decoration: vdec('نبذة تعريفية شاملة عن المنشأة', label: 'النبذة'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _services,
          maxLines: 4,
          decoration: vdec('اكتب كل خدمة في سطر مستقل',
              label: 'الخدمات والأنشطة (كل خدمة في سطر)'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final url = await pickAndUploadImage(context, current: _imageUrl);
                if (url != null && mounted) setState(() => _imageUrl = url);
              },
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
              label: Text(_imageUrl.isNotEmpty ? 'تغيير الصورة' : 'إضافة صورة'),
            ),
            if (_imageUrl.isNotEmpty) ...[
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: _imageUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: widget.facility.color),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white))
                : const Text('حفظ التعديلات'),
          ),
        ),
      ],
    );
  }
}

/// نموذج إضافة / تعديل سجل تفصيلي مخصص بحسب نوع المنشأة
class _FacilityRecordForm extends StatefulWidget {
  const _FacilityRecordForm({
    required this.facility,
    this.editing,
  });

  final FacilityInfo facility;
  final VillageInstitution? editing;

  @override
  State<_FacilityRecordForm> createState() => _FacilityRecordFormState();
}

class _FacilityRecordFormState extends State<_FacilityRecordForm> {
  late final _name = TextEditingController(text: widget.editing?.name ?? '');
  late final _supervisor =
      TextEditingController(text: widget.editing?.supervisor ?? '');
  late final _stage = TextEditingController(text: widget.editing?.stage ?? '');
  late final _capacity =
      TextEditingController(text: widget.editing?.capacity ?? '');
  late final _fees = TextEditingController(text: widget.editing?.fees ?? '');
  late final _location =
      TextEditingController(text: widget.editing?.location ?? '');
  late final _hours =
      TextEditingController(text: widget.editing?.workingHours ?? '');
  late final _phone = TextEditingController(text: widget.editing?.phone ?? '');
  late final _desc =
      TextEditingController(text: widget.editing?.description ?? '');
  late final _services = TextEditingController(
      text: widget.editing?.services.join('\n') ?? '');
  late List<String> _images = [...?widget.editing?.imageUrls];
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _supervisor.dispose();
    _stage.dispose();
    _capacity.dispose();
    _fees.dispose();
    _location.dispose();
    _hours.dispose();
    _phone.dispose();
    _desc.dispose();
    _services.dispose();
    super.dispose();
  }

  // مسميات مخصصة بحسب نوع المنشأة
  String get _nameLabel {
    switch (widget.facility.typeKey) {
      case InstitutionType.mosque:
        return 'اسم المسجد / المصلى';
      case InstitutionType.schools:
        return 'اسم المدرسة أو الصرح التعليمي';
      case InstitutionType.azhar:
        return 'اسم المعهد الأزهري أو دار التحفيظ';
      case InstitutionType.health:
        return 'اسم العيادة / القسم بالوحدة';
      case InstitutionType.youth:
        return 'اسم الملعب / النشاط / الصالة الرياضية';
      case InstitutionType.post:
        return 'اسم الشباك أو الخدمة البريدية';
      case InstitutionType.agri:
        return 'اسم القسم أو الخدمة الزراعية';
      case InstitutionType.awqaf:
        return 'اسم القسم أو التفتيش الوقفي';
      default:
        return 'اسم المنشأة أو السجل';
    }
  }

  String get _supervisorLabel {
    switch (widget.facility.typeKey) {
      case InstitutionType.mosque:
        return 'الإمام والخطيب / مقيم الشعائر';
      case InstitutionType.schools:
        return 'مدير المدرسة / الناظر';
      case InstitutionType.azhar:
        return 'شيخ المعهد / المحفّظ المشرف';
      case InstitutionType.health:
        return 'الطبيب / الأخصائي المشرف';
      case InstitutionType.youth:
        return 'المدرب / المشرف الرياضي';
      case InstitutionType.post:
        return 'مسؤول الشباك / الموظف المختص';
      case InstitutionType.agri:
        return 'المهندس الزراعي / أمين المخزن';
      case InstitutionType.awqaf:
        return 'المفتش الوقفي المسؤول';
      default:
        return 'المسؤول / المشرف';
    }
  }

  String get _stageLabel {
    switch (widget.facility.typeKey) {
      case InstitutionType.schools:
      case InstitutionType.azhar:
        return 'المرحلة التعليمية (ابتدائي، إعدادي…)';
      case InstitutionType.health:
        return 'التخصص الطبي أو نوع الرعاية';
      case InstitutionType.youth:
        return 'الفئة المستهدفة (ناشئين، شباب، عام)';
      case InstitutionType.agri:
        return 'نوع المحصول أو الخدمة';
      default:
        return 'التصنيف / الفئة';
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'اسم السجل مطلوب');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final sList = _services.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      await VillageContentService().saveInstitution(VillageInstitution(
        id: widget.editing?.id ?? '',
        name: _name.text.trim(),
        type: widget.facility.typeKey,
        description: _desc.text.trim(),
        location: _location.text.trim(),
        phone: _phone.text.trim(),
        workingHours: _hours.text.trim(),
        imageUrls: _images,
        supervisor: _supervisor.text.trim(),
        stage: _stage.text.trim(),
        capacity: _capacity.text.trim(),
        fees: _fees.text.trim(),
        services: sList,
        createdAt: widget.editing?.createdAt,
      ));

      if (!mounted) return;
      Navigator.pop(context);
      AppHelpers.showToast('تم حفظ السجل بنجاح');
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'تعذر الحفظ: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.facility.color;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(widget.facility.icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              widget.editing != null
                  ? 'تعديل سجل في ${widget.facility.title}'
                  : 'إضافة سجل جديد في ${widget.facility.title}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_error != null) ...[
          Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: _name,
          decoration: vdec('', label: _nameLabel),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _supervisor,
          decoration: vdec('', label: _supervisorLabel),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _stage,
                decoration: vdec('', label: _stageLabel),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _capacity,
                decoration: vdec('مثال: 500 مصلي / 6 فصول', label: 'السعة / الاستيعاب'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _fees,
                decoration: vdec('مجاني أو القيمة', label: 'الرسوم / الاشتراك'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: vdec('رقم التواصل', label: 'الهاتف'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _location,
          decoration: vdec('الموقع داخل القرية بالتحديد', label: 'الموقع'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _hours,
          decoration: vdec('مواعيد العمل أو الصلاة أو التدريب', label: 'المواعيد'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _desc,
          maxLines: 3,
          decoration: vdec('تفاصيل إضافية ونبذة عن هذا السجل', label: 'النبذة والتفاصيل'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _services,
          maxLines: 3,
          decoration: vdec('اكتب كل نشاط أو خدمة في سطر', label: 'الأنشطة والخدمات المقدمة'),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final url = await pickAndUploadImage(context);
                if (url != null && mounted) {
                  setState(() => _images = [url]);
                }
              },
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
              label: Text(_images.isNotEmpty ? 'تغيير الصورة' : 'إرفاق صورة'),
            ),
            if (_images.isNotEmpty) ...[
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: _images.first,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: color),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white))
                : Text(widget.editing != null ? 'تحديث السجل' : 'إضافة السجل'),
          ),
        ),
      ],
    );
  }
}
