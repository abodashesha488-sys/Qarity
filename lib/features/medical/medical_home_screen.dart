import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/product_categories.dart';
import '../../core/utils/helpers.dart';
import '../../core/utils/launch_link.dart';
import '../../models/data_models.dart';
import '../../models/medical_models.dart';
import '../../routes/app_routes.dart';
import '../../services/admin_service.dart';
import '../../services/image_upload_service.dart';
import '../../services/market_service.dart';
import '../../services/medical_service.dart';
import '../../services/share_service.dart';
import '../../services/user_service.dart';
import '../../widgets/clinic_photo_tile.dart';
import '../../widgets/document_field_editor.dart';
import '../../widgets/med_grid_tile.dart';
import '../../widgets/owner_actions.dart';
import '../../widgets/qurity_app_bar.dart';
import '../market/add_product.dart';
import 'medical_admin_screen.dart';
import 'optical_shop_detail_screen.dart';

/// بوابة الخدمات الطبية — شبكة صور بلا إطارات أو عناوين (مثل الشبكة
/// الرئيسية وبوابة خدمات المزارع)، كل صورة تفتح شاشة قسمها.

/// لون قسم «المستلزمات الطبية» — لا يتكرر مع ألوان الأقسام الأخرى في البوابة.
const Color kMedicalSuppliesAccent = Color(0xFF0097A7);

class MedicalHomeScreen extends StatelessWidget {
  const MedicalHomeScreen({super.key});

  static const List<(String, String)> _sections = [
    ('المركز الطبي الخيري', 'assets/images/tebkhairy.jpg'),
    ('بنك دم القرية', 'assets/images/blood.jpg'),
    ('عيادات القرية', 'assets/images/doctor2.jpg'),
    ('صيدليات القرية', 'assets/images/doctor3.jpg'),
    ('معامل التحاليل', 'assets/images/doctor4.jpg'),
    ('نظارات طبية', 'assets/images/nadara.jpg'),
    ('المستلزمات الطبية', 'assets/images/doctor5.jpg'),
  ];

  static const List<Color> colors = [
    Color(0xFF00695C),
    Color(0xFFC62828),
    Color(0xFF00897B),
    Color(0xFF6F4E37),
    Color(0xFF6A1B9A),
    kOpticalAccent,
    kMedicalSuppliesAccent,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const QurityAppBar(
          title: 'الخدمات الطبية'),
      // أربع صفوف في الشاشة الواحدة كما طلب المستخدم: ارتفاع البلاطة يُحسب من
      // ارتفاع الجسم المتاح (لا من نسبة ثابتة)، فيبقى السطر الرابع ظاهرًا على أي
      // مقاس شاشة. المحتوى والمسارات والصور لم تتغيّر — التنسيق وحده.
      body: LayoutBuilder(builder: (context, box) {
        const vPadding = 16.0 + 28.0;
        const spacing = 16.0;
        final extent = ((box.maxHeight - vPadding - 3 * spacing) / 4)
            .clamp(88.0, 240.0);
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          itemCount: _sections.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              mainAxisExtent: extent),
          itemBuilder: (context, index) => _MedicalSectionTile(
            index: index,
            label: _sections[index].$1,
            image: _sections[index].$2,
          ),
        );
      }),
    );
  }
}

class _MedicalSectionTile extends StatelessWidget {
  const _MedicalSectionTile(
      {required this.index, required this.label, required this.image});
  final int index;
  final String label;
  final String image;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: InkWell(
          borderRadius: radius,
          onTap: () =>
              Navigator.pushNamed(context, '/medical/section', arguments: index),
          child: Image.asset(
            image,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            // بلاطتان في السطر: العرض الفعلي ~172dp ⇒ ~520px عند DPR 3
            cacheWidth: 520,
            semanticLabel: label,
            errorBuilder: (context, error, stackTrace) => Center(
              child: Text(label, textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 45).ms).fadeIn(duration: 350.ms).scale(
          begin: const Offset(0.92, 0.92),
        );
  }
}

/// شاشة قسم طبي واحد — نفس محتوى التبويب السابق كاملاً مع FABه.
class MedicalSectionScreen extends StatefulWidget {
  const MedicalSectionScreen({
    super.key,
    required this.index,
    this.clinicService,
    this.pharmacyService,
    this.labService,
    this.opticalService,
    this.marketService,
  });
  final int index;

  /// قابلة للحقن لاختبار الأقسام على بيانات بلا Firebase (نمط المشروع).
  final VillageClinicService? clinicService;
  final PharmacyService? pharmacyService;
  final MedicalLabService? labService;
  final OpticalShopService? opticalService;
  final MarketService? marketService;

  @override
  State<MedicalSectionScreen> createState() => _MedicalSectionScreenState();
}

class _MedicalSectionScreenState extends State<MedicalSectionScreen> {
  // كسولتان: تُبنى خادم كل قسم عند أول استعماله لا عند فتح الشاشة، فلا تُرمَى
  // core/no-app حيث لا Firebase (اختبارات الواجهة بلا جلسة).
  late final MedicalCenterService _centerService = MedicalCenterService();
  late final VillageClinicService _clinicService =
      widget.clinicService ?? VillageClinicService();
  late final PharmacyService _pharmacyService =
      widget.pharmacyService ?? PharmacyService();
  late final MedicalLabService _labService =
      widget.labService ?? MedicalLabService();
  late final OpticalShopService _opticalService =
      widget.opticalService ?? OpticalShopService();
  late final MarketService _marketService =
      widget.marketService ?? MarketService();
  late final AdminService _adminService = AdminService();
  bool _isMedicalAdmin = false;
  String _profileName = '';
  int _opticalRefresh = 0;

  Color get _color => MedicalHomeScreen.colors[widget.index];
  String get _title => switch (widget.index) {
        0 => 'المركز الطبي الخيري',
        1 => 'بنك دم القرية',
        2 => 'عيادات القرية',
        3 => 'صيدليات القرية',
        5 => 'نظارات طبية',
        6 => 'المستلزمات الطبية',
        _ => 'معامل التحاليل',
      };

  @override
  void initState() {
    super.initState();
    _loadProfile();
    if (widget.index == 0) _checkMedicalAdmin();
  }

  Future<void> _loadProfile() async {
    // بلا جلسة (أو بلا Firebase في الاختبار) يبقى الاسم فارغًا: العرض له
    // بدائل، فلا يصح أن يُسقط شذوذٌ غير محاصر الشاشة كلها.
    String name = '';
    try {
      name = (await UserService().getCurrentUser())?.name.trim() ?? '';
    } catch (_) {
      name = '';
    }
    if (mounted) setState(() => _profileName = name);
  }

  Future<void> _checkMedicalAdmin() async {
    final String? uid;
    try {
      uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return;
    }
    if (uid == null) return;
    final ok = await _adminService.isMedicalAdmin(uid);
    if (mounted) setState(() => _isMedicalAdmin = ok);
    if (ok) _centerService.seedIfEmpty().catchError((_) {});
  }

  String _userName() {
    if (_profileName.isNotEmpty) return _profileName;
    try {
      final u = FirebaseAuth.instance.currentUser;
      return u?.displayName ?? u?.email ?? 'مستخدم';
    } catch (_) {
      return 'مستخدم';
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Widget _body() {
    switch (widget.index) {
      case 0:
        return _CenterTab(
          isMedicalAdmin: _isMedicalAdmin,
          onOpenAdmin: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MedicalCenterAdminScreen())),
        );
      case 1:
        return _BloodBankTab(
          userNameProvider: _userName,
          snackbar: _snack,
        );
      case 2:
        return _ClinicsTab(snackbar: _snack, service: _clinicService);
      case 3:
        return _PharmaciesTab(snackbar: _snack, service: _pharmacyService);
      case 4:
        return _LabsTab(snackbar: _snack, service: _labService);
      case 5:
        return _OpticalTab(
          snackbar: _snack,
          service: _opticalService,
          color: _color,
          refresh: _opticalRefresh,
        );
      case 6:
        return _SuppliesTab(snackbar: _snack, service: _marketService);
      default:
        return _LabsTab(snackbar: _snack, service: _labService);
    }
  }

  /// إجراء «+» في الهيدر لكل قسم، أو null حيث لا يوجد إدخال مستخدم:
  /// ٠ (إدارة المركز) يبقى بزرّه السفلي لأنه إدارة لا إضافة، و١ (بنك الدم)
  /// له مساراته داخل التبويب.
  ({VoidCallback run, String label})? _add() {
    return switch (widget.index) {
      2 => (run: _addClinic, label: 'أضف عيادة'),
      3 => (run: _addPharmacy, label: 'أضف صيدلية'),
      4 => (run: _addLab, label: 'أضف معملاً'),
      5 => (run: _addOpticalShop, label: 'أضف محل نظارات'),
      6 => (run: _addSupply, label: 'أضف مستلزمًا طبيًا'),
      _ => null,
    };
  }

  Widget? _fab() {
    if (widget.index != 0 || !_isMedicalAdmin) return null;
    return FloatingActionButton.extended(
      heroTag: 'medical_section_fab_0',
      onPressed: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const MedicalCenterAdminScreen())),
      icon: const Icon(Icons.medical_information_rounded),
      label: const Text('إدارة المركز', style: TextStyle(fontWeight: FontWeight.w800)),
      backgroundColor: _color,
      foregroundColor: Colors.white,
    );
  }

  Future<void> _addClinic() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _snack('سجّل الدخول أولاً');
      return;
    }
    final res = await showModalBottomSheet<VillageClinic>(
      context: context,
      isScrollControlled: true,
      builder: (_) => VillageClinicFormSheet(userName: _userName(), userId: uid),
    );
    if (res == null || !mounted) return;
    try {
      await _clinicService.create(res);
      _snack('تم إرسال بيانات العيادة، وستظهر بعد موافقة الإدارة');
    } catch (e) {
      _snack('خطأ: $e');
    }
  }

  Future<void> _addPharmacy() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _snack('سجّل الدخول أولاً');
      return;
    }
    final res = await showModalBottomSheet<Pharmacy>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PharmacyFormSheet(userName: _userName(), userId: uid),
    );
    if (res == null || !mounted) return;
    try {
      await _pharmacyService.create(res);
      _snack('تم إرسال بيانات الصيدلية، وستظهر بعد موافقة الإدارة');
    } catch (e) {
      _snack('خطأ: $e');
    }
  }

  Future<void> _addLab() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _snack('سجّل الدخول أولاً');
      return;
    }
    final res = await showModalBottomSheet<MedicalLab>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LabFormSheet(userName: _userName(), userId: uid),
    );
    if (res == null || !mounted) return;
    try {
      await _labService.create(res);
      _snack('تم إرسال بيانات المعمل، وسيظهر بعد موافقة الإدارة');
    } catch (e) {
      _snack('خطأ: $e');
    }
  }

  Future<void> _addOpticalShop() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _snack('سجّل الدخول أولاً');
      return;
    }
    final res = await showModalBottomSheet<OpticalShop>(
      context: context,
      isScrollControlled: true,
      builder: (_) => OpticalFormSheet(userName: _userName(), userId: uid),
    );
    if (res == null || !mounted) return;
    try {
      await _opticalService.create(res);
      setState(() => _opticalRefresh++);
      _snack('تم إرسال بيانات المحل، وسيظهر في الدليل بعد موافقة الإدارة');
    } catch (e) {
      _snack('خطأ: $e');
    }
  }

  /// المستلزمات الطبية منتجات سوق بامتياز: تُفتح نفس «إضافة منتج» بفئة هذا
  /// القسم وحدها (نفس عقد الوسائط الذي يستعمله محل النظارات)، فلا نموذج
  /// ثانٍ ولا مجموعة ثانية تُراجَع خارج قناة المنتجات القائمة.
  Future<void> _addSupply() async {
    try {
      if (FirebaseAuth.instance.currentUser?.uid == null) {
        _snack('سجّل الدخول أولاً');
        return;
      }
    } catch (_) {
      // لا Firebase في اختبارات الواجهة — يُترك المسار للشاشة نفسها.
    }
    if (!mounted) return;
    Navigator.pushNamed(context, AppRoutes.marketAdd,
        arguments: <String, dynamic>{
          kCategoryOptionsArgKey: const [kMedicalSuppliesCategory]
        });
  }

  @override
  Widget build(BuildContext context) {
    final add = _add();
    return Scaffold(
      appBar: QurityAppBar(
        title: _title,
        onAdd: add?.run,
        addTooltip: add?.label ?? 'إضافة',
      ),
      floatingActionButton: _fab(),
      body: _body(),
    );
  }
}

// ═══════════════════════ Tab 1: المركز الطبي الخيري ═══════════════════════
class _CenterTab extends StatelessWidget {
  const _CenterTab({required this.isMedicalAdmin, required this.onOpenAdmin});
  final bool isMedicalAdmin;
  final VoidCallback onOpenAdmin;

  static final Stream<List<MedicalCenterClinic>> _stream =
      MedicalCenterService().getClinicsStream();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<MedicalCenterClinic>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final clinics = (snapshot.data ?? [])
            .where((c) => c.isActive && c.isApproved)
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF00897B), Color(0xFF4DB6AC)],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.local_hospital_rounded,
                          color: Colors.white, size: 28),
                      SizedBox(width: 10),
                      Text('المركز الطبي الخيري',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'مركز طبي يقدّم خدماته لقرية أبوديشيشة بأجور رمزية عبر عيادات تخصصية ومعامل تحاليل وأقسام أشعة. يُرجى الالتزام بمواعيد كل عيادة.',
                    style: TextStyle(color: Colors.white, height: 1.5),
                  ),
                  if (isMedicalAdmin) ...[
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF00897B)),
                      onPressed: onOpenAdmin,
                      icon: const Icon(Icons.tune_rounded, size: 18),
                      label: const Text('إدارة العيادات والمواعيد'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('عيادات المركز (أجور رمزية)',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            if (clinics.isEmpty)
              const _MedEmpty(
                  icon: Icons.medical_information_rounded,
                  message: 'لا توجد عيادات مضافة بعد')
            else
              ...clinics.map((c) => _CenterClinicCard(clinic: c)),
          ],
        );
      },
    );
  }
}

class _CenterClinicCard extends StatelessWidget {
  const _CenterClinicCard({required this.clinic});
  final MedicalCenterClinic clinic;

  static const _accent = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: _accent.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClinicPhotoTile(imageUrl: clinic.imageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(clinic.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 15.5)),
                      const SizedBox(height: 4),
                      if (clinic.specialty.isNotEmpty)
                        _Pill(
                            icon: Icons.category_rounded,
                            text: clinic.specialty,
                            color: _accent),
                      if (clinic.doctorName.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.person_rounded,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                  clinic.doctorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ],
                      if (clinic.fees > 0) ...[
                        const SizedBox(height: 6),
                        _Pill(
                            icon: Icons.payments_rounded,
                            text:
                                'أجر رمزي ${clinic.fees.toStringAsFixed(0)} ج.م',
                            color: const Color(0xFFB8860B),
                            filled: true),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (clinic.workingHours.isNotEmpty ||
                clinic.workingDays.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (clinic.workingHours.isNotEmpty)
                    _Pill(
                        icon: Icons.access_time_rounded,
                        text: clinic.workingHours,
                        color: _accent,
                        filled: true),
                  if (clinic.workingDays.isNotEmpty)
                    _Pill(
                        icon: Icons.event_available_rounded,
                        text: clinic.workingDays.join(' • '),
                        color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ],
            if (clinic.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(clinic.description,
                  style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: theme.colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

/// وسم صغير موحد الشكل داخل بطاقة عيادة المركز (تخصص/مواعيد/أيام/أجر).
class _Pill extends StatelessWidget {
  const _Pill(
      {required this.icon,
      required this.text,
      required this.color,
      this.filled = false});
  final IconData icon;
  final String text;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: filled ? 0.10 : 0.0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: color)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════ Tab 2: بنك دم القرية ═══════════════════════
class _BloodBankTab extends StatefulWidget {
  const _BloodBankTab({required this.userNameProvider, required this.snackbar});
  final String Function() userNameProvider;
  final void Function(String) snackbar;

  @override
  State<_BloodBankTab> createState() => _BloodBankTabState();
}

class _BloodBankTabState extends State<_BloodBankTab> {
  final BloodBankService _service = BloodBankService();
  late final Stream<List<BloodDonor>> _donorsStream =
      _service.getApprovedDonorsStream();
  String? _filterType;

  String get _currentUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _showDonorDialog() async {
    final uid = _currentUid;
    if (uid.isEmpty) {
      widget.snackbar('سجّل الدخول أولاً');
      return;
    }
    final name = widget.userNameProvider();
    final res = await showModalBottomSheet<BloodDonor>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DonorFormSheet(userId: uid, userName: name),
    );
    if (res == null || !mounted) return;
    try {
      await _service.addDonor(res);
      widget.snackbar('تم إرسال بياناتك، وستظهر بعد موافقة الإدارة. شكراً لعطائك 🌟');
    } catch (e) {
      widget.snackbar('خطأ: $e');
    }
  }

  /// تعديل صاحب المتبرع لبياناته: تعود إلى المراجعة (البند ٨).
  Future<void> _openDonorEdit(BloodDonor donor) async {
    final name = widget.userNameProvider();
    final res = await showModalBottomSheet<BloodDonor>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          DonorFormSheet(userId: donor.userId, userName: name, existing: donor),
    );
    if (res == null || !mounted) return;
    try {
      await _service.updateDonor(res);
      widget.snackbar('تم حفظ التعديلات — عاد المتبرع للمراجعة');
    } catch (e) {
      widget.snackbar('تعذّر حفظ التعديل — تحقّق من الصلاحيات أو من الاتصال ($e)');
    }
  }

  Future<bool> _deleteDonor(BloodDonor donor) async {
    try {
      await _service.deleteDonor(donor.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _showRequestDialog() async {
    final uid = _currentUid;
    if (uid.isEmpty) {
      widget.snackbar('سجّل الدخول أولاً');
      return;
    }
    final name = widget.userNameProvider();
    final res = await showModalBottomSheet<BloodRequest>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BloodRequestFormSheet(userId: uid, requesterName: name),
    );
    if (res == null || !mounted) return;
    try {
      await _service.createRequest(res);
      widget.snackbar('تم إرسال الطلب، وسيظهر للجمهور بعد موافقة الإدارة');
    } catch (e) {
      widget.snackbar('خطأ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<BloodDonor>>(
      stream: _donorsStream,
      builder: (context, donorSnap) {
        final donors = (donorSnap.data ?? [])
            .where((d) => _filterType == null || d.bloodType.code == _filterType)
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style:
                        FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
                    onPressed: _showDonorDialog,
                    icon: const Icon(Icons.favorite_rounded, size: 18),
                    label: const Text('سجّل كمتبرع'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _showRequestDialog,
                    icon: const Icon(Icons.bloodtype_rounded, size: 18),
                    label: const Text('طلب تبرع بالدم'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('المتبرعون المتاحون',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('الكل'),
                      selected: _filterType == null,
                      onSelected: (_) => setState(() => _filterType = null),
                    ),
                  ),
                  for (final t in BloodType.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(t.code),
                        selected: _filterType == t.code,
                        onSelected: (_) => setState(() => _filterType = t.code),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (donorSnap.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (donors.isEmpty)
              const _MedEmpty(
                  icon: Icons.bloodtype_rounded,
                  message: 'لا يوجد متبرعون متاحون لهذه الفصيلة بعد')
            else
              ...donors.map((d) => _DonorCard(
                    donor: d,
                    currentUserId: _currentUid,
                    onEdit: () => _openDonorEdit(d),
                    onDelete: () => _deleteDonor(d),
                  )),
            const SizedBox(height: 18),
            Text('طلبات الدم المفتوحة',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            _OpenRequestsList(onSnackbar: widget.snackbar),
          ],
        );
      },
    );
  }
}

class _OpenRequestsList extends StatelessWidget {
  const _OpenRequestsList({required this.onSnackbar});
  final void Function(String) onSnackbar;
  // Stream واحد يُبنى lazily مرة فقط — لا يُعاد الاشتراك مع كل rebuild للأب.
  static final Stream<List<BloodRequest>> _requestsStream =
      BloodBankService().getOpenApprovedRequestsStream();
  static final BloodBankService _service = BloodBankService();

  /// بلا بوّابة `canLaunchUrl`: الفحص القبلي كان يرجع false على أندرويد 11+ حين لا
  /// تُرى حزمة الطلب، فيصمت الزر؛ التجربة المباشرة هي الدليل والفشل يُبلَّغ.
  Future<void> _call(String phone) async {
    final error = await launchPhoneCall(phone);
    if (error != null) AppHelpers.showToast(error, isError: true);
  }

  /// تعديل صاحب الطلب لبياناته: يعود إلى المراجعة (البند ٨).
  Future<void> _openEdit(BuildContext context, BloodRequest r) async {
    final uid = r.userId;
    final res = await showModalBottomSheet<BloodRequest>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          BloodRequestFormSheet(userId: uid, requesterName: r.requesterName, existing: r),
    );
    if (res == null || !context.mounted) return;
    try {
      await _service.updateRequest(res);
      onSnackbar('تم حفظ التعديلات — عاد الطلب للمراجعة');
    } catch (_) {
      onSnackbar('تعذّر حفظ التعديل — تحقّق من الصلاحيات أو من الاتصال');
    }
  }

  Future<bool> _delete(BloodRequest r) async {
    try {
      await _service.deleteRequest(r.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String uid = '';
    try {
      uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      uid = '';
    }
    return StreamBuilder<List<BloodRequest>>(
      stream: _requestsStream,
      builder: (context, snapshot) {
        final list = snapshot.data ?? [];
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (list.isEmpty) {
          return const _MedEmpty(
              icon: Icons.inbox_rounded, message: 'لا توجد طلبات مفتوحة حالياً');
        }
        return Column(
          children: list.map((r) {
            final mine = uid.isNotEmpty && r.userId == uid;
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: r.urgencyColor.withValues(alpha: 0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(r.bloodType.code,
                              style: const TextStyle(
                                  color: Colors.red, fontWeight: FontWeight.w900)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                              'طلب ${r.patientName.isNotEmpty ? r.patientName : 'لمريض'} • ${r.units} وحدة',
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: r.urgencyColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(r.urgency,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: r.urgencyColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        if (r.hospital.isNotEmpty)
                          _miniInfo(Icons.local_hospital_rounded, r.hospital),
                        if (r.phone.isNotEmpty)
                          _miniInfo(Icons.phone_rounded, r.phone),
                        _miniInfo(Icons.person_outline_rounded, r.requesterName),
                      ],
                    ),
                    if (r.notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(r.notes,
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => ShareService.shareText(
                                title:
                                    '🩸 طلب تبرع بالدم — فصيلة ${r.bloodType.code}',
                                body: [
                                  if (r.patientName.isNotEmpty)
                                    'المريض: ${r.patientName}',
                                  'الوحدات المطلوبة: ${r.units}',
                                  if (r.hospital.isNotEmpty)
                                    'المكان: ${r.hospital}',
                                  if (r.phone.isNotEmpty)
                                    'للتواصل: ${r.phone}',
                                ].join('\n')),
                            icon: const Icon(Icons.share_rounded, size: 16),
                            label: const Text('مشاركة الطلب'),
                          ),
                          if (r.phone.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () => _call(r.phone),
                              style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF00897B)),
                              icon: const Icon(Icons.call_rounded, size: 16),
                              label: const Text('اتصال'),
                            ),
                          if (mine)
                            TextButton.icon(
                              onPressed: () async {
                                try {
                                  await _service.closeRequest(r.id);
                                  onSnackbar('تم إغلاق الطلب');
                                } catch (_) {
                                  onSnackbar('تعذّر إغلاق الطلب — تحقّق من الصلاحيات أو من الاتصال');
                                }
                              },
                              icon: const Icon(Icons.check_circle_outline_rounded,
                                  size: 16),
                              label: const Text('تمت الاستجابة'),
                            ),
                        ],
                      ),
                    ),
                    if (mine) ...[
                      const SizedBox(height: 10),
                      OwnerActions(
                        keyTag: 'blood-request',
                        ownerId: r.userId,
                        currentUserId: uid,
                        itemName:
                            'طلب ${r.patientName.isNotEmpty ? r.patientName : 'لمريض'}',
                        editLabel: 'تعديل الطلب',
                        deleteLabel: 'حذف الطلب',
                        onEdit: () => _openEdit(context, r),
                        onDelete: () => _delete(r),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _miniInfo(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      );
}

class _DonorCard extends StatelessWidget {
  const _DonorCard({
    required this.donor,
    required this.currentUserId,
    required this.onEdit,
    required this.onDelete,
  });
  final BloodDonor donor;
  final String currentUserId;
  final VoidCallback onEdit;
  final Future<bool> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final owner = donor.userId;
    final isOwner = currentUserId.isNotEmpty && currentUserId == owner;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color:
                Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.withValues(alpha: 0.12),
              child: Text(donor.bloodType.code,
                  style:
                      const TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
            ),
            title: Text(donor.name,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(
                [
                  donor.gender,
                  donor.age > 0 ? '${donor.age} سنة' : '',
                  donor.address,
                ].where((e) => e.isNotEmpty).join(' • '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            trailing: donor.phone.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.call_rounded, color: Color(0xFF00897B)),
                    onPressed: () async {
                      final error = await launchPhoneCall(donor.phone);
                      if (error != null) {
                        AppHelpers.showToast(error, isError: true);
                      }
                    },
                  )
                : null,
          ),
          if (isOwner)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: OwnerActions(
                keyTag: 'donor-card',
                ownerId: owner,
                currentUserId: currentUserId,
                itemName: donor.name,
                editLabel: 'تعديل بياناتي',
                deleteLabel: 'حذف سجلّي',
                onEdit: onEdit,
                onDelete: onDelete,
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════ Tab 3: عيادات القرية ═══════════════════════
class _ClinicsTab extends StatefulWidget {
  const _ClinicsTab({required this.snackbar, this.service});
  final void Function(String) snackbar;
  final VillageClinicService? service;

  @override
  State<_ClinicsTab> createState() => _ClinicsTabState();
}

class _ClinicsTabState extends State<_ClinicsTab> {
  late final VillageClinicService _service =
      widget.service ?? VillageClinicService();
  final TextEditingController _search = TextEditingController();
  // تدفّق واحد مثبّت — إعادة بنائها كل ضغطة كانت تفقد مربع البحث التركيز.
  late final Stream<List<VillageClinic>> _stream = _service.getApprovedStream();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VillageClinic>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var items = snapshot.data ?? [];
        final q = _search.text.trim().toLowerCase();
        if (q.isNotEmpty) {
          items = items
              .where((c) =>
                  c.name.toLowerCase().contains(q) ||
                  c.specialty.toLowerCase().contains(q) ||
                  c.ownerName.toLowerCase().contains(q))
              .toList();
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'ابحث عن عيادة أو تخصص...',
                  isDense: true,
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const _MedEmpty(
                      icon: Icons.add_business_rounded,
                      message: 'لا توجد عيادات معتمدة بعد')
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                      gridDelegate: kMedGridDelegate,
                      itemCount: items.length,
                      itemBuilder: (context, i) => _ClinicCard(clinic: items[i]),
                    ),            ),
          ],
        );
      },
    );
  }
}

class _ClinicCard extends StatelessWidget {
  const _ClinicCard({required this.clinic});
  final VillageClinic clinic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MedGridTile(
      title: clinic.name,
      imageUrl: clinic.imageUrl,
      icon: Icons.add_business_rounded,
      accent: const Color(0xFF00897B),
      onTap: () => Navigator.pushNamed(context, '/medical/clinic-detail',
          arguments: clinic),
      tags: [
        if (clinic.specialty.isNotEmpty)
          _Tag(clinic.specialty, const Color(0xFF00897B)),
        if (clinic.ownerName.isNotEmpty)
          _Tag('د. ${clinic.ownerName}', theme.colorScheme.onSurfaceVariant),
      ],
      subtitle: [
        if (clinic.workingHours.isNotEmpty) clinic.workingHours,
        if (clinic.address.isNotEmpty) clinic.address,
      ].join(' • '),
    );
  }
}

// ═══════════════════════ Tab 4: صيدليات القرية ═══════════════════════
class _PharmaciesTab extends StatefulWidget {
  const _PharmaciesTab({required this.snackbar, this.service});
  final void Function(String) snackbar;
  final PharmacyService? service;

  @override
  State<_PharmaciesTab> createState() => _PharmaciesTabState();
}

class _PharmaciesTabState extends State<_PharmaciesTab> {
  late final PharmacyService _service = widget.service ?? PharmacyService();
  final TextEditingController _search = TextEditingController();
  late final Stream<List<Pharmacy>> _stream = _service.getApprovedStream();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Pharmacy>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var items = snapshot.data ?? [];
        final q = _search.text.trim().toLowerCase();
        if (q.isNotEmpty) {
          items = items
              .where((p) =>
                  p.name.toLowerCase().contains(q) ||
                  p.address.toLowerCase().contains(q) ||
                  p.ownerName.toLowerCase().contains(q))
              .toList();
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'ابحث عن صيدلية...',
                  isDense: true,
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const _MedEmpty(
                      icon: Icons.local_pharmacy_rounded,
                      message: 'لا توجد صيدليات معتمدة بعد')
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                      gridDelegate: kMedGridDelegate,
                      itemCount: items.length,
                      itemBuilder: (context, i) =>
                          _PharmacyCard(pharmacy: items[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  const _PharmacyCard({required this.pharmacy});
  final Pharmacy pharmacy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = Color(0xFF6F4E37);
    return MedGridTile(
      title: pharmacy.name,
      imageUrl: pharmacy.imageUrl,
      icon: Icons.local_pharmacy_rounded,
      accent: accent,
      onTap: () => Navigator.pushNamed(context, '/medical/pharmacy-detail',
          arguments: pharmacy),
      badge: pharmacy.is24Hours
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('٢٤ ساعة',
                  style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: accent)),
            )
          : null,
      tags: [
        if (pharmacy.ownerName.isNotEmpty)
          _Tag(pharmacy.ownerName, theme.colorScheme.onSurfaceVariant),
      ],
      subtitle: [
        if (pharmacy.workingHours.isNotEmpty) pharmacy.workingHours,
        if (pharmacy.address.isNotEmpty) pharmacy.address,
      ].join(' • '),
    );
  }
}

/// وسم صغير مشترك (تخصص/اسم طبيب).
class _Tag extends StatelessWidget {
  const _Tag(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          // سطر واحد دائمًا: الوسم داخل `Wrap` بعرض البطاقة (~١٥٢dp)، ونصّ
          // التخصص أو «د. فلان» الطويل كان يلتفّ سطرين داخل الوسم نفسه فتتجاوز
          // مجموعتا الأوسمة ارتفاع جسم البطاقة المقصوص (فيضان مقيس ٢px).
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 10.5, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

// ═══════════════════════ Tab 5: معامل التحاليل ═══════════════════════
class _LabsTab extends StatefulWidget {
  const _LabsTab({required this.snackbar, this.service});
  final void Function(String) snackbar;
  final MedicalLabService? service;

  @override
  State<_LabsTab> createState() => _LabsTabState();
}

class _LabsTabState extends State<_LabsTab> {
  late final MedicalLabService _service =
      widget.service ?? MedicalLabService();
  final TextEditingController _search = TextEditingController();
  late final Stream<List<MedicalLab>> _stream = _service.getApprovedStream();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MedicalLab>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var items = snapshot.data ?? [];
        final q = _search.text.trim().toLowerCase();
        if (q.isNotEmpty) {
          items = items
              .where((l) =>
                  l.name.toLowerCase().contains(q) ||
                  l.category.toLowerCase().contains(q) ||
                  l.ownerName.toLowerCase().contains(q) ||
                  l.address.toLowerCase().contains(q))
              .toList();
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'ابحث عن معمل أو نوع تحليل...',
                  isDense: true,
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const _MedEmpty(
                      icon: Icons.science_rounded,
                      message: 'لا توجد معامل معتمدة بعد')
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                      gridDelegate: kMedGridDelegate,
                      itemCount: items.length,
                      itemBuilder: (context, i) => _LabCard(lab: items[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _LabCard extends StatelessWidget {
  const _LabCard({required this.lab});
  final MedicalLab lab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const accent = Color(0xFF6A1B9A);
    return MedGridTile(
      title: lab.name,
      imageUrl: lab.imageUrl,
      icon: Icons.science_rounded,
      accent: accent,
      onTap: () =>
          Navigator.pushNamed(context, '/medical/lab-detail', arguments: lab),
      badge: lab.homeCollection
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: const Text('سحب منزلي',
                  style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: accent)),
            )
          : null,
      tags: [
        if (lab.category.isNotEmpty) _Tag(lab.category, accent),
        if (lab.ownerName.isNotEmpty)
          _Tag(lab.ownerName, theme.colorScheme.onSurfaceVariant),
      ],
      subtitle: [
        if (lab.workingHours.isNotEmpty) lab.workingHours,
        if (lab.address.isNotEmpty) lab.address,
      ].join(' • '),
    );
  }
}

/// نموذج معمل التحاليل — للإنشاء ولتعديل صاحب المعمل سجله (البند ٨).
class LabFormSheet extends StatefulWidget {
  const LabFormSheet(
      {super.key, required this.userName, required this.userId, this.existing});
  final String userName;
  final String userId;

  /// معمل يملكه المستخدم الحالي — الورقة تحفظ فوقه بدل إنشاء جديد.
  final MedicalLab? existing;
  @override
  State<LabFormSheet> createState() => _LabFormSheetState();
}

class _LabFormSheetState extends State<LabFormSheet> {
  late final _nameC = TextEditingController(text: widget.existing?.name ?? '');
  late final _ownerC =
      TextEditingController(text: widget.existing?.ownerName ?? '');
  late final _phoneC = TextEditingController(text: widget.existing?.phone ?? '');
  late final _addressC =
      TextEditingController(text: widget.existing?.address ?? '');
  late final _hoursC =
      TextEditingController(text: widget.existing?.workingHours ?? '');
  late final _descC =
      TextEditingController(text: widget.existing?.description ?? '');
  late bool _home = widget.existing?.homeCollection ?? false;
  late final List<String> _images =
      List.of(widget.existing?.imageUrls ?? const <String>[]);

  bool get _isEdit => widget.existing != null;

  /// نوع التحاليل المحفوظ قد يكون كُتب يدويًا من لوحة الإدارة، فلو لم يكن في
  /// القائمة لألقى `DropdownButtonFormField` «There should be exactly one item…».
  List<String> get _categoryOptions {
    final saved = widget.existing?.category.trim() ?? '';
    if (saved.isEmpty || kLabCategories.contains(saved)) return kLabCategories;
    return [saved, ...kLabCategories];
  }

  late String _category =
      _categoryOptions.contains(widget.existing?.category)
          ? widget.existing!.category
          : 'غير ذلك';

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: _isEdit ? 'تعديل المعمل' : 'إضافة معمل تحاليل',
      onSubmitted: () {
        if (_nameC.text.trim().isEmpty) return;
        final editing = widget.existing;
        Navigator.pop(
          context,
          MedicalLab(
            id: editing?.id ?? '',
            name: _nameC.text.trim(),
            category: _category,
            ownerName: _ownerC.text.trim(),
            phone: _phoneC.text.trim(),
            address: _addressC.text.trim(),
            workingHours: _hoursC.text.trim(),
            homeCollection: _home,
            description: _descC.text.trim(),
            imageUrls: List.from(_images),
            isApproved: editing?.isApproved ?? false,
            submittedBy: editing?.submittedBy ?? widget.userId,
            submittedByName: editing?.submittedByName ?? widget.userName,
            createdAt: editing?.createdAt,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MedicalImageField(
              maxImages: 3,
              initial: _images,
              onChanged: (l) {
                _images
                  ..clear()
                  ..addAll(l);
              }),
          const SizedBox(height: 12),
          _field(_nameC, 'اسم المعمل', Icons.science_rounded),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'نوع التحاليل'),
            items: _categoryOptions
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _category = v ?? _category),
            menuMaxHeight: 360,
          ),
          const SizedBox(height: 12),
          _field(_ownerC, 'المسؤول / مدير المعمل', Icons.person_rounded),
          const SizedBox(height: 12),
          _field(_phoneC, 'هاتف التواصل', Icons.phone_rounded,
              type: TextInputType.phone),
          const SizedBox(height: 12),
          _field(_addressC, 'العنوان', Icons.location_on_rounded),
          const SizedBox(height: 12),
          _field(_hoursC, 'مواعيد العمل', Icons.access_time_rounded),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('سحب عينات بالمنزل'),
            value: _home,
            onChanged: (v) => setState(() => _home = v),
          ),
          const SizedBox(height: 4),
          _field(_descC, 'نبذة وأهم التحاليل المتاحة', Icons.description_rounded,
              maxLines: 3),
        ],
      ),
    );
  }
}

// ═══════════════════════ نظارات طبية ═══════════════════════

/// تبويب محلات النظارات: الدليل العام (المعتمد داخل مدة عرضه) + قسم
/// «محلاتي غير الظاهرة» حتى يجدّد صاحبها عرضها المميز المنتهي.
class _OpticalTab extends StatefulWidget {
  const _OpticalTab({
    required this.snackbar,
    required this.color,
    this.service,
    this.refresh = 0,
  });

  final void Function(String) snackbar;
  final Color color;
  final OpticalShopService? service;
  final int refresh;

  @override
  State<_OpticalTab> createState() => _OpticalTabState();
}

class _OpticalTabState extends State<_OpticalTab> {
  final TextEditingController _search = TextEditingController();
  late final OpticalShopService _service =
      widget.service ?? OpticalShopService();
  late final Stream<List<OpticalShop>> _stream = _service.getApprovedStream();
  String? _uid;
  List<OpticalShop> _mine = const [];

  @override
  void initState() {
    super.initState();
    try {
      _uid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      _uid = null;
    }
    _loadMine();
  }

  @override
  void didUpdateWidget(covariant _OpticalTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refresh != widget.refresh) _loadMine();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadMine() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final list = await _service.getMine(uid);
      if (mounted) setState(() => _mine = list);
    } catch (_) {
      // قائمة إضافية لا تستحق إيقاظ المستخدم بخطأ.
    }
  }

  Future<void> _renew(OpticalShop shop) async {
    final days = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          OpticalRenewSheet(shopName: shop.name, featured: shop.isFeaturedAd),
    );
    if (days == null || !mounted) return;
    try {
      await _service.setFeaturedWindow(shop.id, days);
      widget.snackbar('تم تفعيل العرض المميز لمدة $days يومًا');
      await _loadMine();
    } catch (e) {
      widget.snackbar('تعذّر التجديد — تحقق من الصلاحيات: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OpticalShop>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final dirIds = (snapshot.data ?? []).map((s) => s.id).toSet();
        final hidden =
            _mine.where((s) => !dirIds.contains(s.id)).toList(growable: false);
        var items = snapshot.data ?? [];
        final q = _search.text.trim().toLowerCase();
        if (q.isNotEmpty) {
          items = items
              .where((s) =>
                  s.name.toLowerCase().contains(q) ||
                  s.ownerName.toLowerCase().contains(q) ||
                  s.address.toLowerCase().contains(q) ||
                  s.categories.any((c) => c.toLowerCase().contains(q)))
              .toList();
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'ابحث عن محل نظارات أو عدسات...',
                  isDense: true,
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            Expanded(
              child: (items.isEmpty && hidden.isEmpty)
                  ? const _MedEmpty(
                      icon: Icons.remove_red_eye_rounded,
                      message: 'لا توجد محلات نظارات معتمدة بعد')
                  : CustomScrollView(
                      slivers: [
                        if (hidden.isNotEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                      'محلاتي غير الظاهرة في الدليل (${hidden.length})',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14)),
                                  const SizedBox(height: 8),
                                  ...hidden.map((s) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10),
                                        child: _OpticalCard(
                                          shop: s,
                                          accent: widget.color,
                                          // الإعلان يُختار من صفحة المحل بعد الإنشاء،
                                          // فكل محل صاحبه يملك زر تفعيل العرض المميز.
                                          onRenew: () => _renew(s),
                                        ),
                                      )),
                                ],
                              ),
                            ),
                          ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                          sliver: SliverGrid(
                            gridDelegate: kMedGridDelegate,
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => _OpticalGridCard(
                                  shop: items[i], accent: widget.color),
                              childCount: items.length,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// بطاقة محل نظارات في شبكة الدليل (كرتان في السطر).
class _OpticalGridCard extends StatelessWidget {
  const _OpticalGridCard({required this.shop, required this.accent});
  final OpticalShop shop;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final live = shop.adLiveAt(DateTime.now());
    return MedGridTile(
      title: shop.name,
      imageUrl: shop.imageUrl,
      icon: Icons.remove_red_eye_rounded,
      accent: accent,
      goldBorder: live,
      onTap: () => Navigator.pushNamed(context, '/medical/optical-detail',
          arguments: shop),
      badge: live ? const _Tag('مميز', Color(0xFFB8860B)) : null,
      tags: [
        // وسمان كحدّ أقصى: ثلاثة وسوم بعرض ~١٧٢dp تلتفّ أسطرًا وتتجاوز ارتفاع
        // البطاقة، فيُكتفى بأول تصنيف وصاحب المحل.
        if (shop.categories.isNotEmpty) _Tag(shop.categories.first, accent),
        if (shop.ownerName.isNotEmpty)
          _Tag(shop.ownerName, theme.colorScheme.onSurfaceVariant),
      ],
      subtitle: [
        if (shop.workingHours.isNotEmpty) shop.workingHours,
        if (shop.address.isNotEmpty) shop.address,
      ].join(' • '),
    );
  }
}

class _OpticalCard extends StatelessWidget {
  const _OpticalCard(
      {required this.shop, required this.accent, this.onRenew});
  final OpticalShop shop;
  final Color accent;
  final VoidCallback? onRenew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    const gold = Color(0xFFB8860B);
    final live = shop.adLiveAt(now);
    final visible = shop.visibleAt(now);
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
            color: live
                ? gold
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: live ? 1.6 : 1),
      ),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/medical/optical-detail',
            arguments: shop),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14)),
                    clipBehavior: Clip.antiAlias,
                    child: shop.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: shop.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Icon(
                                Icons.remove_red_eye_rounded, color: accent),
                          )
                        : Icon(Icons.remove_red_eye_rounded, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(shop.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 15)),
                            ),
                            if (live)
                              const _Tag('مميز', gold),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (final c in shop.categories.take(2))
                              _Tag(c, accent),
                            if (shop.ownerName.isNotEmpty)
                              _Tag(shop.ownerName,
                                  theme.colorScheme.onSurfaceVariant),
                          ],
                        ),
                        if (shop.workingHours.isNotEmpty ||
                            shop.address.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              [
                                if (shop.workingHours.isNotEmpty)
                                  shop.workingHours,
                                if (shop.address.isNotEmpty) shop.address,
                              ].join(' • '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11.5, color: Colors.grey),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_left_rounded,
                      color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
              if (!shop.isApproved)
                _opticalStatusRow(
                    context, 'بانتظار موافقة الإدارة — يظهر في الدليل بعدها'),
              if (shop.isApproved && !visible)
                _opticalStatusRow(context, 'انتهت مدة العرض المميز'),
              if (onRenew != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextButton.icon(
                      onPressed: onRenew,
                      icon: const Icon(Icons.star_rounded, size: 18),
                      label: Text(
                          shop.isFeaturedAd
                              ? 'تجديد العرض المميز'
                              : 'تحويل الإعلان إلى عرض مميز',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _opticalStatusRow(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

/// نموذج محل النظارات — للإنشاء ولتعديل صاحب المحل سجله (البند ٨).
class OpticalFormSheet extends StatefulWidget {
  const OpticalFormSheet(
      {super.key, required this.userName, required this.userId, this.existing});
  final String userName;
  final String userId;

  /// محل يملكه المستخدم الحالي — الورقة تحفظ فوقه بدل إنشاء جديد.
  final OpticalShop? existing;

  @override
  State<OpticalFormSheet> createState() => _OpticalFormSheetState();
}

class _OpticalFormSheetState extends State<OpticalFormSheet> {
  late final _nameC = TextEditingController(text: widget.existing?.name ?? '');
  late final _ownerC =
      TextEditingController(text: widget.existing?.ownerName ?? '');
  late final _phoneC = TextEditingController(text: widget.existing?.phone ?? '');
  late final _addressC =
      TextEditingController(text: widget.existing?.address ?? '');
  late final _hoursC =
      TextEditingController(text: widget.existing?.workingHours ?? '');
  late final _descC =
      TextEditingController(text: widget.existing?.description ?? '');
  late final Set<String> _categories = {...widget.existing?.categories ?? const <String>[]};
  late final List<String> _images =
      List.of(widget.existing?.imageUrls ?? const <String>[]);

  bool get _isEdit => widget.existing != null;

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: _isEdit ? 'تعديل محل النظارات' : 'إضافة محل نظارات',
      onSubmitted: () {
        if (_nameC.text.trim().isEmpty) return;
        final editing = widget.existing;
        Navigator.pop(
          context,
          OpticalShop(
            id: editing?.id ?? '',
            name: _nameC.text.trim(),
            description: _descC.text.trim(),
            categories: _categories.toList(),
            ownerName: _ownerC.text.trim(),
            phone: _phoneC.text.trim(),
            address: _addressC.text.trim(),
            workingHours: _hoursC.text.trim(),
            imageUrls: List.from(_images),
            // نافذة العرض المميز قرار إداري/تجديد من صفحة المحل، فلا يمسّها الحفظ.
            adType: editing?.adType ?? kOpticalAdNormal,
            featuredUntil: editing?.featuredUntil,
            isApproved: editing?.isApproved ?? false,
            submittedBy: editing?.submittedBy ?? widget.userId,
            submittedByName: editing?.submittedByName ?? widget.userName,
            createdAt: editing?.createdAt,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MedicalImageField(
              maxImages: 3,
              initial: _images,
              onChanged: (l) {
                _images
                  ..clear()
                  ..addAll(l);
              }),
          const SizedBox(height: 12),
          _field(_nameC, 'اسم المحل', Icons.storefront_rounded),
          const Text('التخصصات',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kOpticalCategories.map((c) {
              final selected = _categories.contains(c);
              return FilterChip(
                label: Text(c),
                selected: selected,
                onSelected: (v) => setState(
                    () => v ? _categories.add(c) : _categories.remove(c)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _field(_ownerC, 'صاحب المحل / المسؤول', Icons.person_rounded),
          _field(_phoneC, 'هاتف التواصل', Icons.phone_rounded,
              type: TextInputType.phone),
          _field(_addressC, 'العنوان', Icons.location_on_rounded),
          _field(_hoursC, 'مواعيد العمل', Icons.access_time_rounded),
          const SizedBox(height: 6),
          const Text('نوع الإعلان (عادي / عرض مميز) يُختار من صفحة المحل بعد '
              'إضافته، من زر «تحويل الإعلان إلى عرض مميز».',
              style: TextStyle(fontSize: 11.5, height: 1.5)),
          const SizedBox(height: 12),
          _field(_descC, 'نبذة وأهم الماركات والخدمات',
              Icons.description_rounded,
              maxLines: 3),
        ],
      ),
    );
  }
}

// ═══════════════════════ المستلزمات الطبية ═══════════════════════
/// قسم «المستلزمات الطبية»: منتجات السوق المكتوبة بتصنيف
/// [kMedicalSuppliesCategory] فقط. لا مجموعة جديدة ولا مراجعة ثانية —
/// المنتج يُقبل/يُرفض من قناة «المنتجات» القائمة، والتصفية خادمية
/// بمساواتين (`isApproved` + `category`) بلا `orderBy` فلا فهرس مركّب.
class _SuppliesTab extends StatefulWidget {
  const _SuppliesTab({required this.snackbar, this.service});
  final void Function(String) snackbar;
  final MarketService? service;

  @override
  State<_SuppliesTab> createState() => _SuppliesTabState();
}

class _SuppliesTabState extends State<_SuppliesTab> {
  late final MarketService _service = widget.service ?? MarketService();
  final TextEditingController _search = TextEditingController();

  /// مثبّت في الحالة: إعادة بناء الشاشة (كل حرف بحث) كانت تعيد الاشتراك
  /// بالقائمة كاملة.
  late final Stream<List<MarketProduct>> _stream =
      _service.getProductsStream(category: kMedicalSuppliesCategory);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MarketProduct>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var items = [...snapshot.data ?? []];
        items.sort((a, b) => (b.createdAt ?? DateTime(1900))
            .compareTo(a.createdAt ?? DateTime(1900)));
        final q = _search.text.trim().toLowerCase();
        if (q.isNotEmpty) {
          items = items
              .where((p) =>
                  p.name.toLowerCase().contains(q) ||
                  p.description.toLowerCase().contains(q) ||
                  p.sellerName.toLowerCase().contains(q))
              .toList();
        }
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'ابحث عن مستلزم طبي...',
                  isDense: true,
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? const _MedEmpty(
                      icon: Icons.medical_services_rounded,
                      message: 'لا توجد مستلزمات طبية معتمدة بعد')
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                      gridDelegate: kMedGridDelegate,
                      itemCount: items.length,
                      itemBuilder: (context, i) =>
                          _SuppliesCard(product: items[i]),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SuppliesCard extends StatelessWidget {
  const _SuppliesCard({required this.product});
  final MarketProduct product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final p = product;
    final price = p.effectivePrice;
    return MedGridTile(
      title: p.name,
      imageUrl: p.imageUrls.isNotEmpty ? p.imageUrls.first : p.imageUrl,
      icon: Icons.medical_services_rounded,
      accent: kMedicalSuppliesAccent,
      onTap: () => Navigator.pushNamed(context, AppRoutes.marketProductDetail,
          arguments: p),
      // السعر في شارة بجوار العنوان: المستلزم يُقارن بثمنه أولًا، والشارة
      // تبقى داخل صفّ العنوان المقصوص فلا تفيض البطاقة.
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
            color: (p.hasActiveOffer ? theme.colorScheme.error : kMedicalSuppliesAccent)
                .withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(8)),
        child: Text('${price.toStringAsFixed(0)} ج.م',
            style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                color: p.hasActiveOffer
                    ? theme.colorScheme.error
                    : kMedicalSuppliesAccent)),
      ),
      tags: [
        if (p.hasActiveOffer)
          _Tag('-${p.discountPercent.round()}٪ عرض', theme.colorScheme.error),
        if (p.sellerName.isNotEmpty)
          _Tag(p.sellerName, theme.colorScheme.onSurfaceVariant),
        if (!p.isInStock) const _Tag('نفد المخزون', Colors.brown),
      ],
      subtitle: p.description,
    );
  }
}

// ═══════════════════════ Shared helpers ═══════════════════════
class _MedEmpty extends StatelessWidget {
  const _MedEmpty({required this.icon, required this.message});
  final IconData icon;
  final String message;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 52, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════ النماذج (Forms) ═══════════════════════
/// نموذج تسجيل المتبرع — للإنشاء ولتعديل صاحب التسجيل سجله (البند ٨).
class DonorFormSheet extends StatefulWidget {
  const DonorFormSheet(
      {super.key, required this.userId, required this.userName, this.existing});
  final String userId;
  final String userName;

  /// تسجيل يملكه المستخدم الحالي — الورقة تحفظ فوقه بدل تسجيل جديد.
  final BloodDonor? existing;
  @override
  State<DonorFormSheet> createState() => _DonorFormSheetState();
}

class _DonorFormSheetState extends State<DonorFormSheet> {
  late final _nameC =
      TextEditingController(text: widget.existing?.name ?? widget.userName);
  late final _phoneC = TextEditingController(
      text: widget.existing?.phone ??
          FirebaseAuth.instance.currentUser?.phoneNumber ??
          '');
  late final _ageC = TextEditingController(
      text: (widget.existing?.age ?? 0) > 0 ? '${widget.existing!.age}' : '');
  late final _addressC =
      TextEditingController(text: widget.existing?.address ?? '');
  late BloodType _blood = widget.existing?.bloodType ?? BloodType.oPos;
  late String _gender = widget.existing?.gender ?? 'ذكر';

  bool get _isEdit => widget.existing != null;

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: _isEdit ? 'تعديل تسجيل التبرع' : 'التسجيل كمتبرع بالدم',
      onSubmitted: () {
        if (_nameC.text.trim().isEmpty || _phoneC.text.trim().isEmpty) return;
        final editing = widget.existing;
        Navigator.pop(
          context,
          BloodDonor(
            id: editing?.id ?? '',
            userId: editing?.userId ?? widget.userId,
            name: _nameC.text.trim(),
            phone: _phoneC.text.trim(),
            bloodType: _blood,
            age: int.tryParse(_ageC.text) ?? 0,
            gender: _gender,
            address: _addressC.text.trim(),
            lastDonation: editing?.lastDonation,
            isAvailable: editing?.isAvailable ?? true,
            isApproved: editing?.isApproved ?? false,
            createdAt: editing?.createdAt,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _field(_nameC, 'الاسم', Icons.person_rounded),
          _field(_phoneC, 'رقم الهاتف', Icons.phone_rounded,
              type: TextInputType.phone),
          Row(
            children: [
              Expanded(
                  child: _field(_ageC, 'السن', Icons.cake_rounded,
                      type: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _gender,
                  decoration: const InputDecoration(labelText: 'النوع'),
                  items: const [
                    DropdownMenuItem(value: 'ذكر', child: Text('ذكر')),
                    DropdownMenuItem(value: 'أنثى', child: Text('أنثى')),
                  ],
                  onChanged: (v) => setState(() => _gender = v ?? _gender),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _blood.code,
            decoration: const InputDecoration(labelText: 'فصيلة الدم'),
            items: BloodType.values
                .map((t) => DropdownMenuItem(value: t.code, child: Text(t.label)))
                .toList(),
            onChanged: (v) => setState(() => _blood = BloodType.fromCode(v)),
          ),
          const SizedBox(height: 12),
          _field(_addressC, 'العنوان', Icons.location_on_rounded),
        ],
      ),
    );
  }
}

/// نموذج طلب التبرع — للإنشاء ولتعديل صاحب الطلب طلبه (البند ٨).
class BloodRequestFormSheet extends StatefulWidget {
  const BloodRequestFormSheet(
      {super.key,
      required this.userId,
      required this.requesterName,
      this.existing});
  final String userId;
  final String requesterName;

  /// طلب يملكه المستخدم الحالي — الورقة تحفظ فوقه بدل طلب جديد.
  final BloodRequest? existing;
  @override
  State<BloodRequestFormSheet> createState() => _BloodRequestFormSheetState();
}

class _BloodRequestFormSheetState extends State<BloodRequestFormSheet> {
  late final _patientC =
      TextEditingController(text: widget.existing?.patientName ?? '');
  late final _phoneC = TextEditingController(
      text: widget.existing?.phone ??
          FirebaseAuth.instance.currentUser?.phoneNumber ??
          '');
  late final _hospitalC =
      TextEditingController(text: widget.existing?.hospital ?? '');
  late final _unitsC =
      TextEditingController(text: '${widget.existing?.units ?? 1}');
  late final _notesC = TextEditingController(text: widget.existing?.notes ?? '');
  late BloodType _blood = widget.existing?.bloodType ?? BloodType.oPos;
  late String _urgency = widget.existing?.urgency ?? 'عادي';

  bool get _isEdit => widget.existing != null;

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: _isEdit ? 'تعديل طلب التبرع' : 'طلب تبرع بالدم',
      onSubmitted: () {
        if (_phoneC.text.trim().isEmpty) return;
        final editing = widget.existing;
        Navigator.pop(
          context,
          BloodRequest(
            id: editing?.id ?? '',
            userId: editing?.userId ?? widget.userId,
            requesterName: editing?.requesterName ?? widget.requesterName,
            phone: _phoneC.text.trim(),
            patientName: _patientC.text.trim(),
            bloodType: _blood,
            units: int.tryParse(_unitsC.text) ?? 1,
            hospital: _hospitalC.text.trim(),
            urgency: _urgency,
            notes: _notesC.text.trim(),
            status: editing?.status ?? 'open',
            isApproved: editing?.isApproved ?? false,
            createdAt: editing?.createdAt,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _field(_patientC, 'اسم المريض', Icons.person_rounded),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _blood.code,
                  decoration:
                      const InputDecoration(labelText: 'الفصيلة المطلوبة'),
                  items: BloodType.values
                      .map((t) =>
                          DropdownMenuItem(value: t.code, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _blood = BloodType.fromCode(v)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(_unitsC, 'عدد الوحدات', Icons.straighten_rounded,
                    type: TextInputType.number),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _field(_hospitalC, 'المستشفى / المكان', Icons.local_hospital_rounded),
          const SizedBox(height: 12),
          _field(_phoneC, 'هاتف التواصل', Icons.phone_rounded,
              type: TextInputType.phone),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _urgency,
            decoration: const InputDecoration(labelText: 'درجة الأهمية'),
            items: const [
              DropdownMenuItem(value: 'عادي', child: Text('عادي')),
              DropdownMenuItem(value: 'مستعجل', child: Text('مستعجل')),
              DropdownMenuItem(value: 'طارئ', child: Text('طارئ')),
            ],
            onChanged: (v) => setState(() => _urgency = v ?? _urgency),
          ),
          const SizedBox(height: 12),
          _field(_notesC, 'ملاحظات', Icons.description_rounded, maxLines: 3),
        ],
      ),
    );
  }
}

/// نموذج عيادة القرية — للإنشاء ولتعديل صاحب العيادة سجلها (البند ٨).
class VillageClinicFormSheet extends StatefulWidget {
  const VillageClinicFormSheet(
      {super.key, required this.userName, required this.userId, this.existing});
  final String userName;
  final String userId;

  /// عيادة يملكها المستخدم الحالي — الورقة تحفظ فوقها بدل إنشاء جديدة.
  final VillageClinic? existing;
  @override
  State<VillageClinicFormSheet> createState() => _VillageClinicFormSheetState();
}

class _VillageClinicFormSheetState extends State<VillageClinicFormSheet> {
  late final _nameC = TextEditingController(text: widget.existing?.name ?? '');
  late final _ownerC =
      TextEditingController(text: widget.existing?.ownerName ?? '');
  late final _phoneC = TextEditingController(text: widget.existing?.phone ?? '');
  late final _addressC =
      TextEditingController(text: widget.existing?.address ?? '');
  late final _hoursC =
      TextEditingController(text: widget.existing?.workingHours ?? '');
  late final _descC =
      TextEditingController(text: widget.existing?.description ?? '');
  late final List<String> _images =
      List.of(widget.existing?.imageUrls ?? const <String>[]);

  bool get _isEdit => widget.existing != null;

  /// تخصص العيادة المحفوظ قد يكون كُتب يدويًا من لوحة الإدارة، فلو لم يكن في
  /// القائمة لألقى `DropdownButtonFormField` «There should be exactly one item…»
  /// ولأبدّل تخصص عيادة صاحبها عند أول حفظ تعديل.
  List<String> get _specialtyOptions {
    final saved = widget.existing?.specialty.trim() ?? '';
    if (saved.isEmpty || kClinicSpecialties.contains(saved)) {
      return kClinicSpecialties;
    }
    return [saved, ...kClinicSpecialties];
  }

  late String _specialty =
      _specialtyOptions.contains(widget.existing?.specialty)
          ? widget.existing!.specialty
          : 'غير ذلك';

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: _isEdit ? 'تعديل العيادة' : 'إضافة عيادة',
      onSubmitted: () {
        if (_nameC.text.trim().isEmpty) return;
        final editing = widget.existing;
        Navigator.pop(
          context,
          VillageClinic(
            // التعديل يبقي النسب والموافقة كما هي: `OwnerContentService.edit`
            // هو من يعيدها إلى طابور المراجعة، ولا يلمس `submittedBy`.
            id: editing?.id ?? '',
            name: _nameC.text.trim(),
            specialty: _specialty,
            ownerName: _ownerC.text.trim(),
            phone: _phoneC.text.trim(),
            address: _addressC.text.trim(),
            workingHours: _hoursC.text.trim(),
            description: _descC.text.trim(),
            imageUrls: List.from(_images),
            isApproved: editing?.isApproved ?? false,
            submittedBy: editing?.submittedBy ?? widget.userId,
            submittedByName: editing?.submittedByName ?? widget.userName,
            createdAt: editing?.createdAt,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MedicalImageField(
              maxImages: 3,
              initial: _images,
              onChanged: (l) {
                _images
                  ..clear()
                  ..addAll(l);
              }),
          const SizedBox(height: 12),
          _field(_nameC, 'اسم العيادة', Icons.add_business_rounded),
          DropdownButtonFormField<String>(
            initialValue: _specialty,
            decoration: const InputDecoration(labelText: 'التخصص'),
            items: _specialtyOptions
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _specialty = v ?? _specialty),
            menuMaxHeight: 360,
          ),
          const SizedBox(height: 12),
          _field(_ownerC, 'اسم الطبيب', Icons.person_rounded),
          const SizedBox(height: 12),
          _field(_phoneC, 'هاتف التواصل', Icons.phone_rounded,
              type: TextInputType.phone),
          const SizedBox(height: 12),
          _field(_addressC, 'العنوان', Icons.location_on_rounded),
          const SizedBox(height: 12),
          _field(_hoursC, 'مواعيد العمل', Icons.access_time_rounded),
          const SizedBox(height: 12),
          _field(_descC, 'نبذة', Icons.description_rounded, maxLines: 3),
        ],
      ),
    );
  }
}

/// نموذج صيدلية القرية — للإنشاء ولتعديل صاحب الصيدلية سجلها (البند ٨).
class PharmacyFormSheet extends StatefulWidget {
  const PharmacyFormSheet(
      {super.key, required this.userName, required this.userId, this.existing});
  final String userName;
  final String userId;

  /// صيدلية يملكها المستخدم الحالي — الورقة تحفظ فوقها بدل إنشاء جديدة.
  final Pharmacy? existing;
  @override
  State<PharmacyFormSheet> createState() => _PharmacyFormSheetState();
}

class _PharmacyFormSheetState extends State<PharmacyFormSheet> {
  late final _nameC = TextEditingController(text: widget.existing?.name ?? '');
  late final _ownerC =
      TextEditingController(text: widget.existing?.ownerName ?? '');
  late final _phoneC = TextEditingController(text: widget.existing?.phone ?? '');
  late final _addressC =
      TextEditingController(text: widget.existing?.address ?? '');
  late final _hoursC =
      TextEditingController(text: widget.existing?.workingHours ?? '');
  late final _descC =
      TextEditingController(text: widget.existing?.description ?? '');
  late bool _is24 = widget.existing?.is24Hours ?? false;
  late final List<String> _images =
      List.of(widget.existing?.imageUrls ?? const <String>[]);

  bool get _isEdit => widget.existing != null;

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: _isEdit ? 'تعديل الصيدلية' : 'إضافة صيدلية',
      onSubmitted: () {
        if (_nameC.text.trim().isEmpty) return;
        final editing = widget.existing;
        Navigator.pop(
          context,
          Pharmacy(
            id: editing?.id ?? '',
            name: _nameC.text.trim(),
            ownerName: _ownerC.text.trim(),
            phone: _phoneC.text.trim(),
            address: _addressC.text.trim(),
            workingHours: _hoursC.text.trim(),
            is24Hours: _is24,
            description: _descC.text.trim(),
            imageUrls: List.from(_images),
            isApproved: editing?.isApproved ?? false,
            submittedBy: editing?.submittedBy ?? widget.userId,
            submittedByName: editing?.submittedByName ?? widget.userName,
            createdAt: editing?.createdAt,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MedicalImageField(
              maxImages: 3,
              initial: _images,
              onChanged: (l) {
                _images
                  ..clear()
                  ..addAll(l);
              }),
          const SizedBox(height: 12),
          _field(_nameC, 'اسم الصيدلية', Icons.local_pharmacy_rounded),
          const SizedBox(height: 12),
          _field(_ownerC, 'اسم الصيدلي / المسؤول', Icons.person_rounded),
          const SizedBox(height: 12),
          _field(_phoneC, 'هاتف التواصل', Icons.phone_rounded,
              type: TextInputType.phone),
          const SizedBox(height: 12),
          _field(_addressC, 'العنوان', Icons.location_on_rounded),
          const SizedBox(height: 12),
          _field(_hoursC, 'مواعيد العمل', Icons.access_time_rounded),
          const SizedBox(height: 6),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('تعمل على مدار ٢٤ ساعة'),
            value: _is24,
            onChanged: (v) => setState(() => _is24 = v),
          ),
          const SizedBox(height: 12),
          _field(_descC, 'نبذة', Icons.description_rounded, maxLines: 3),
        ],
      ),
    );
  }
}

class _SheetScaffold extends StatelessWidget {
  const _SheetScaffold(
      {required this.title, required this.onSubmitted, required this.child});
  final String title;
  final VoidCallback onSubmitted;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(title,
                  style:
                      const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              const Spacer(),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded)),
            ],
          ),
          Flexible(child: SingleChildScrollView(child: child)),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: onSubmitted,
            child: const Text('إرسال للمراجعة',
                style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

Widget _field(TextEditingController c, String label, IconData icon,
    {TextInputType? type, int maxLines = 1}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    ),
  );
}

/// حقل صور طبي يستخدم المحرّر المشترك `ImageListEditor` — لا picker ولا uploader
/// خاصين به. [initial] يعرض الصور المحفوظة مسبقاً عند التعديل، و[onError] يبلّغ
/// فشل الرفع بدل ابتلاعه — صورة تُفقد بصمتًا أسوأ من صورة بلا رفع.
class MedicalImageField extends StatefulWidget {
  final int maxImages;
  final ValueChanged<List<String>> onChanged;
  final List<String> initial;
  final ValueChanged<String>? onError;
  final ValueChanged<bool>? onBusyChanged;

  /// اختياري لاختبار الحقل بلا معرض جهاز ولا شبكة.
  final ImageUploadService? uploader;
  final ImageBytesSource? bytesSource;
  const MedicalImageField(
      {super.key,
      required this.maxImages,
      required this.onChanged,
      this.initial = const [],
      this.onError,
      this.onBusyChanged,
      this.uploader,
      this.bytesSource});

  @override
  State<MedicalImageField> createState() => _MedicalImageFieldState();
}

class _MedicalImageFieldState extends State<MedicalImageField> {
  late final List<String> _urls = List.of(widget.initial);

  @override
  Widget build(BuildContext context) {
    return ImageListEditor(
      label: 'الصور',
      fieldKey: 'medicalImages',
      urls: _urls,
      maxImages: widget.maxImages,
      single: widget.maxImages == 1,
      uploader: widget.uploader,
      bytesSource: widget.bytesSource,
      // المقاس نفسه الذي كان الحقل يلتقط به: معالج أصغر قبل الرفع.
      maxSide: 1200,
      onError: widget.onError,
      onBusyChanged: widget.onBusyChanged,
      onChanged: (urls) {
        setState(() {
          _urls
            ..clear()
            ..addAll(urls);
        });
        widget.onChanged(urls);
      },
    );
  }
}
