import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/medical_models.dart';
import '../../services/admin_service.dart';
import '../../services/image_upload_service.dart';
import '../../services/medical_service.dart';
import '../../services/share_service.dart';
import '../../services/user_service.dart';
import '../../widgets/qurity_app_bar.dart';
import 'medical_admin_screen.dart';

/// بوابة الخدمات الطبية — شبكة صور بلا إطارات أو عناوين (مثل الشبكة
/// الرئيسية وبوابة خدمات المزارع)، كل صورة تفتح شاشة قسمها.
class MedicalHomeScreen extends StatelessWidget {
  const MedicalHomeScreen({super.key});

  static const List<(String, String)> _sections = [
    ('المركز الطبي الخيري', 'assets/images/tebkhairy.jpg'),
    ('بنك دم القرية', 'assets/images/blood.jpg'),
    ('عيادات القرية', 'assets/images/doctor2.jpg'),
    ('صيدليات القرية', 'assets/images/doctor3.jpg'),
    ('معامل التحاليل', 'assets/images/doctor4.jpg'),
  ];

  static const List<Color> colors = [
    Color(0xFF00695C),
    Color(0xFFC62828),
    Color(0xFF00897B),
    Color(0xFF6F4E37),
    Color(0xFF6A1B9A),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const QurityAppBar(
          title: 'الخدمات الطبية', color: Color(0xFF00897B)),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        itemCount: _sections.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.95),
        itemBuilder: (context, index) => _MedicalSectionTile(
          index: index,
          label: _sections[index].$1,
          image: _sections[index].$2,
        ),
      ),
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
    final radius = BorderRadius.circular(18);
    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
            cacheWidth: 280,
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
  const MedicalSectionScreen({super.key, required this.index});
  final int index;

  @override
  State<MedicalSectionScreen> createState() => _MedicalSectionScreenState();
}

class _MedicalSectionScreenState extends State<MedicalSectionScreen> {
  final MedicalCenterService _centerService = MedicalCenterService();
  final VillageClinicService _clinicService = VillageClinicService();
  final PharmacyService _pharmacyService = PharmacyService();
  final MedicalLabService _labService = MedicalLabService();
  final AdminService _adminService = AdminService();
  bool _isMedicalAdmin = false;
  String _profileName = '';

  Color get _color => MedicalHomeScreen.colors[widget.index];
  String get _title => switch (widget.index) {
        0 => 'المركز الطبي الخيري',
        1 => 'بنك دم القرية',
        2 => 'عيادات القرية',
        3 => 'صيدليات القرية',
        _ => 'معامل التحاليل',
      };

  @override
  void initState() {
    super.initState();
    _loadProfile();
    if (widget.index == 0) _checkMedicalAdmin();
  }

  Future<void> _loadProfile() async {
    final u = await UserService().getCurrentUser();
    if (mounted) setState(() => _profileName = (u?.name ?? '').trim());
  }

  Future<void> _checkMedicalAdmin() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ok = await _adminService.isMedicalAdmin(uid);
    if (mounted) setState(() => _isMedicalAdmin = ok);
    if (ok) _centerService.seedIfEmpty().catchError((_) {});
  }

  String _userName() {
    if (_profileName.isNotEmpty) return _profileName;
    final u = FirebaseAuth.instance.currentUser;
    return u?.displayName ?? u?.email ?? 'مستخدم';
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
        return _ClinicsTab(snackbar: _snack);
      case 3:
        return _PharmaciesTab(snackbar: _snack);
      default:
        return _LabsTab(snackbar: _snack);
    }
  }

  Widget? _fab() {
    switch (widget.index) {
      case 0:
        if (!_isMedicalAdmin) return null;
        return FloatingActionButton.extended(
          heroTag: 'medical_section_fab_0',
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const MedicalCenterAdminScreen())),
          icon: const Icon(Icons.medical_information_rounded),
          label: const Text('إدارة المركز',
              style: TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: _color,
          foregroundColor: Colors.white,
        );
      case 2:
        return FloatingActionButton.extended(
          heroTag: 'medical_section_fab_2',
          onPressed: _addClinic,
          icon: const Icon(Icons.add_business_rounded),
          label: const Text('أضف عيادة',
              style: TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: _color,
          foregroundColor: Colors.white,
        );
      case 3:
        return FloatingActionButton.extended(
          heroTag: 'medical_section_fab_3',
          onPressed: _addPharmacy,
          icon: const Icon(Icons.add_rounded),
          label: const Text('أضف صيدلية',
              style: TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: _color,
          foregroundColor: Colors.white,
        );
      case 4:
        return FloatingActionButton.extended(
          heroTag: 'medical_section_fab_4',
          onPressed: _addLab,
          icon: const Icon(Icons.science_rounded),
          label: const Text('أضف معملاً',
              style: TextStyle(fontWeight: FontWeight.w800)),
          backgroundColor: _color,
          foregroundColor: Colors.white,
        );
      default:
        return null;
    }
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
      builder: (_) => _VillageClinicForm(userName: _userName(), userId: uid),
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
      builder: (_) => _PharmacyForm(userName: _userName(), userId: uid),
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
      builder: (_) => _LabForm(userName: _userName(), userId: uid),
    );
    if (res == null || !mounted) return;
    try {
      await _labService.create(res);
      _snack('تم إرسال بيانات المعمل، وسيظهر بعد موافقة الإدارة');
    } catch (e) {
      _snack('خطأ: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: QurityAppBar(title: _title, color: _color),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side:
            BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                      color: const Color(0xFF00897B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.medical_services_rounded,
                      color: Color(0xFF00897B)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(clinic.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 15)),
                      if (clinic.specialty.isNotEmpty)
                        Text(clinic.specialty,
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                if (clinic.fees > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('${clinic.fees.toStringAsFixed(0)} ج.م',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.teal)),
                  ),
              ],
            ),
            if (clinic.doctorName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(clinic.doctorName, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
            if (clinic.workingDays.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: clinic.workingDays
                    .map((d) => Chip(
                          label: Text(d, style: const TextStyle(fontSize: 10)),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
            if (clinic.workingHours.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(clinic.workingHours, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ],
            if (clinic.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(clinic.description,
                  style: TextStyle(
                      fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
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

  Future<void> _showDonorDialog() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      widget.snackbar('سجّل الدخول أولاً');
      return;
    }
    final name = widget.userNameProvider();
    final res = await showModalBottomSheet<BloodDonor>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DonorForm(userId: uid, userName: name),
    );
    if (res == null || !mounted) return;
    try {
      await _service.addDonor(res);
      widget.snackbar('تم إرسال بياناتك، وستظهر بعد موافقة الإدارة. شكراً لعطائك 🌟');
    } catch (e) {
      widget.snackbar('خطأ: $e');
    }
  }

  Future<void> _showRequestDialog() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      widget.snackbar('سجّل الدخول أولاً');
      return;
    }
    final name = widget.userNameProvider();
    final res = await showModalBottomSheet<BloodRequest>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BloodRequestForm(userId: uid, requesterName: name),
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
              ...donors.map((d) => _DonorCard(donor: d)),
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

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = BloodBankService();
    final uid = FirebaseAuth.instance.currentUser?.uid;
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
            final mine = r.userId == uid;
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
                                await service.closeRequest(r.id);
                                onSnackbar('تم إغلاق الطلب');
                              },
                              icon: const Icon(Icons.check_circle_outline_rounded,
                                  size: 16),
                              label: const Text('تمت الاستجابة'),
                            ),
                        ],
                      ),
                    ),
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
  const _DonorCard({required this.donor});
  final BloodDonor donor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color:
                Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.withValues(alpha: 0.12),
          child: Text(donor.bloodType.code,
              style:
                  const TextStyle(color: Colors.red, fontWeight: FontWeight.w900)),
        ),
        title:
            Text(donor.name, style: const TextStyle(fontWeight: FontWeight.w800)),
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
                  final uri = Uri(scheme: 'tel', path: donor.phone);
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                },
              )
            : null,
      ),
    );
  }
}

// ═══════════════════════ Tab 3: عيادات القرية ═══════════════════════
class _ClinicsTab extends StatefulWidget {
  const _ClinicsTab({required this.snackbar});
  final void Function(String) snackbar;

  @override
  State<_ClinicsTab> createState() => _ClinicsTabState();
}

class _ClinicsTabState extends State<_ClinicsTab> {
  final VillageClinicService _service = VillageClinicService();
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
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _ClinicCard(clinic: items[i]),
                    ),
            ),
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
    const accent = Color(0xFF00897B);
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side:
            BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        onTap: () =>
            Navigator.pushNamed(context, '/medical/clinic-detail',
                arguments: clinic),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14)),
                clipBehavior: Clip.antiAlias,
                child: clinic.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: clinic.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(
                            Icons.add_business_rounded,
                            color: accent),
                      )
                    : const Icon(Icons.add_business_rounded,
                        color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(clinic.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 15)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (clinic.specialty.isNotEmpty)
                          _Tag(clinic.specialty, accent),
                        if (clinic.ownerName.isNotEmpty)
                          _Tag('د. ${clinic.ownerName}',
                              theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                    if (clinic.workingHours.isNotEmpty ||
                        clinic.address.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        [
                          if (clinic.workingHours.isNotEmpty)
                            clinic.workingHours,
                          if (clinic.address.isNotEmpty) clinic.address,
                        ].join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

// ═══════════════════════ Tab 4: صيدليات القرية ═══════════════════════
class _PharmaciesTab extends StatefulWidget {
  const _PharmaciesTab({required this.snackbar});
  final void Function(String) snackbar;

  @override
  State<_PharmaciesTab> createState() => _PharmaciesTabState();
}

class _PharmaciesTabState extends State<_PharmaciesTab> {
  final PharmacyService _service = PharmacyService();
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
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side:
            BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        onTap: () =>
            Navigator.pushNamed(context, '/medical/pharmacy-detail',
                arguments: pharmacy),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14)),
                clipBehavior: Clip.antiAlias,
                child: pharmacy.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: pharmacy.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const Icon(
                            Icons.local_pharmacy_rounded, color: accent),
                      )
                    : const Icon(Icons.local_pharmacy_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(pharmacy.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15)),
                        ),
                        if (pharmacy.is24Hours)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Text('٢٤ ساعة',
                                style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: accent)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (pharmacy.ownerName.isNotEmpty)
                      Text(pharmacy.ownerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant)),
                    if (pharmacy.workingHours.isNotEmpty ||
                        pharmacy.address.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          [
                            if (pharmacy.workingHours.isNotEmpty)
                              pharmacy.workingHours,
                            if (pharmacy.address.isNotEmpty)
                              pharmacy.address,
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
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
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
          style: TextStyle(
              fontSize: 10.5, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

// ═══════════════════════ Tab 5: معامل التحاليل ═══════════════════════
class _LabsTab extends StatefulWidget {
  const _LabsTab({required this.snackbar});
  final void Function(String) snackbar;

  @override
  State<_LabsTab> createState() => _LabsTabState();
}

class _LabsTabState extends State<_LabsTab> {
  final MedicalLabService _service = MedicalLabService();
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
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side:
            BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        onTap: () =>
            Navigator.pushNamed(context, '/medical/lab-detail', arguments: lab),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14)),
                clipBehavior: Clip.antiAlias,
                child: lab.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: lab.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.science_rounded, color: accent),
                      )
                    : const Icon(Icons.science_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(lab.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900, fontSize: 15)),
                        ),
                        if (lab.homeCollection)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Text('سحب منزلي',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: accent)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (lab.category.isNotEmpty) _Tag(lab.category, accent),
                        if (lab.ownerName.isNotEmpty)
                          _Tag(lab.ownerName,
                              theme.colorScheme.onSurfaceVariant),
                      ],
                    ),
                    if (lab.workingHours.isNotEmpty ||
                        lab.address.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          [
                            if (lab.workingHours.isNotEmpty) lab.workingHours,
                            if (lab.address.isNotEmpty) lab.address,
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
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

class _LabForm extends StatefulWidget {
  const _LabForm({required this.userName, required this.userId});
  final String userName;
  final String userId;
  @override
  State<_LabForm> createState() => _LabFormState();
}

class _LabFormState extends State<_LabForm> {
  final _nameC = TextEditingController();
  final _ownerC = TextEditingController();
  final _phoneC = TextEditingController();
  final _addressC = TextEditingController();
  final _hoursC = TextEditingController();
  final _descC = TextEditingController();
  String _category = 'غير ذلك';
  bool _home = false;
  final List<String> _images = [];

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'إضافة معمل تحاليل',
      onSubmitted: () {
        if (_nameC.text.trim().isEmpty) return;
        Navigator.pop(
          context,
          MedicalLab(
            id: '',
            name: _nameC.text.trim(),
            category: _category,
            ownerName: _ownerC.text.trim(),
            phone: _phoneC.text.trim(),
            address: _addressC.text.trim(),
            workingHours: _hoursC.text.trim(),
            homeCollection: _home,
            description: _descC.text.trim(),
            imageUrls: List.from(_images),
            submittedBy: widget.userId,
            submittedByName: widget.userName,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MedicalImageField(
              maxImages: 3,
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
            items: kLabCategories
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
class _DonorForm extends StatefulWidget {
  const _DonorForm({required this.userId, required this.userName});
  final String userId;
  final String userName;
  @override
  State<_DonorForm> createState() => _DonorFormState();
}

class _DonorFormState extends State<_DonorForm> {
  late final _nameC = TextEditingController(text: widget.userName);
  final _phoneC = TextEditingController();
  final _ageC = TextEditingController();
  final _addressC = TextEditingController();
  BloodType _blood = BloodType.oPos;
  String _gender = 'ذكر';

  @override
  void initState() {
    super.initState();
    _phoneC.text = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'التسجيل كمتبرع بالدم',
      onSubmitted: () {
        if (_nameC.text.trim().isEmpty || _phoneC.text.trim().isEmpty) return;
        Navigator.pop(
          context,
          BloodDonor(
            id: '',
            userId: widget.userId,
            name: _nameC.text.trim(),
            phone: _phoneC.text.trim(),
            bloodType: _blood,
            age: int.tryParse(_ageC.text) ?? 0,
            gender: _gender,
            address: _addressC.text.trim(),
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

class _BloodRequestForm extends StatefulWidget {
  const _BloodRequestForm({required this.userId, required this.requesterName});
  final String userId;
  final String requesterName;
  @override
  State<_BloodRequestForm> createState() => _BloodRequestFormState();
}

class _BloodRequestFormState extends State<_BloodRequestForm> {
  final _patientC = TextEditingController();
  final _phoneC = TextEditingController();
  final _hospitalC = TextEditingController();
  final _unitsC = TextEditingController(text: '1');
  final _notesC = TextEditingController();
  BloodType _blood = BloodType.oPos;
  String _urgency = 'عادي';

  @override
  void initState() {
    super.initState();
    _phoneC.text = FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'طلب تبرع بالدم',
      onSubmitted: () {
        if (_phoneC.text.trim().isEmpty) return;
        Navigator.pop(
          context,
          BloodRequest(
            id: '',
            userId: widget.userId,
            requesterName: widget.requesterName,
            phone: _phoneC.text.trim(),
            patientName: _patientC.text.trim(),
            bloodType: _blood,
            units: int.tryParse(_unitsC.text) ?? 1,
            hospital: _hospitalC.text.trim(),
            urgency: _urgency,
            notes: _notesC.text.trim(),
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

class _VillageClinicForm extends StatefulWidget {
  const _VillageClinicForm({required this.userName, required this.userId});
  final String userName;
  final String userId;
  @override
  State<_VillageClinicForm> createState() => _VillageClinicFormState();
}

class _VillageClinicFormState extends State<_VillageClinicForm> {
  final _nameC = TextEditingController();
  final _ownerC = TextEditingController();
  final _phoneC = TextEditingController();
  final _addressC = TextEditingController();
  final _hoursC = TextEditingController();
  final _descC = TextEditingController();
  String _specialty = 'غير ذلك';
  final List<String> _images = [];

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'إضافة عيادة',
      onSubmitted: () {
        if (_nameC.text.trim().isEmpty) return;
        Navigator.pop(
          context,
          VillageClinic(
            id: '',
            name: _nameC.text.trim(),
            specialty: _specialty,
            ownerName: _ownerC.text.trim(),
            phone: _phoneC.text.trim(),
            address: _addressC.text.trim(),
            workingHours: _hoursC.text.trim(),
            description: _descC.text.trim(),
            imageUrls: List.from(_images),
            submittedBy: widget.userId,
            submittedByName: widget.userName,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MedicalImageField(
              maxImages: 3,
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
            items: kClinicSpecialties
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

class _PharmacyForm extends StatefulWidget {
  const _PharmacyForm({required this.userName, required this.userId});
  final String userName;
  final String userId;
  @override
  State<_PharmacyForm> createState() => _PharmacyFormState();
}

class _PharmacyFormState extends State<_PharmacyForm> {
  final _nameC = TextEditingController();
  final _ownerC = TextEditingController();
  final _phoneC = TextEditingController();
  final _addressC = TextEditingController();
  final _hoursC = TextEditingController();
  final _descC = TextEditingController();
  bool _is24 = false;
  final List<String> _images = [];

  @override
  Widget build(BuildContext context) {
    return _SheetScaffold(
      title: 'إضافة صيدلية',
      onSubmitted: () {
        if (_nameC.text.trim().isEmpty) return;
        Navigator.pop(
          context,
          Pharmacy(
            id: '',
            name: _nameC.text.trim(),
            ownerName: _ownerC.text.trim(),
            phone: _phoneC.text.trim(),
            address: _addressC.text.trim(),
            workingHours: _hoursC.text.trim(),
            is24Hours: _is24,
            description: _descC.text.trim(),
            imageUrls: List.from(_images),
            submittedBy: widget.userId,
            submittedByName: widget.userName,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MedicalImageField(
              maxImages: 3,
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

/// حقل صور متعددة يستخدم خدمة ImgBB الخاصة بالتطبيق.
class MedicalImageField extends StatefulWidget {
  final int maxImages;
  final ValueChanged<List<String>> onChanged;
  const MedicalImageField(
      {super.key, required this.maxImages, required this.onChanged});

  @override
  State<MedicalImageField> createState() => _MedicalImageFieldState();
}

class _MedicalImageFieldState extends State<MedicalImageField> {
  final ImagePicker _picker = ImagePicker();
  final ImageUploadService _uploader = ImageUploadService();
  final List<String> _urls = [];
  bool _uploading = false;

  bool get _atMax => _urls.length >= widget.maxImages;

  Future<void> _add() async {
    if (_atMax) return;
    setState(() => _uploading = true);
    try {
      final file = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1200,
          maxHeight: 1200);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final url = await _uploader.uploadImage(bytes);
      setState(() => _urls.add(url.imageUrl));
      widget.onChanged(List.of(_urls));
    } catch (_) {
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _remove(int i) {
    setState(() => _urls.removeAt(i));
    widget.onChanged(List.of(_urls));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library_rounded,
                size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text('الصور (${_urls.length}/${widget.maxImages})',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...List.generate(_urls.length, (i) => _thumb(theme, i)),
            if (!_atMax)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _uploading ? null : _add,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.5)),
                  ),
                  child: Center(
                    child: _uploading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.add_a_photo_rounded,
                            color: theme.colorScheme.primary),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _thumb(ThemeData theme, int i) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: _urls[i],
            width: 68,
            height: 68,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: () => _remove(i),
            child: Container(
              decoration: BoxDecoration(
                  color: theme.colorScheme.error, shape: BoxShape.circle),
              padding: const EdgeInsets.all(2),
              child:
                  const Icon(Icons.close_rounded, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
